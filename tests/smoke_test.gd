extends Node
## Headless smoke test: verifies every autoload loads and does its job.
##
## Run with:
##   godot --headless --path <project> res://tests/smoke_test.tscn

const TestWindow := preload("res://tests/test_window.gd")

func _ready() -> void:
	TestWindow.use(1280, 720)
	var failures: Array[String] = []
	print("--- Fluke Free Kitchen smoke test ---")

	var autoloads := ["Settings", "SaveData", "Loc", "Learning", "Education", "Game", "AudioManager", "InputManager"]
	for n in autoloads:
		var node := get_node_or_null(NodePath("/root/" + n))
		if node == null:
			failures.append("autoload /root/%s is missing" % n)
		else:
			print("  autoload ok: %s" % n)

	var loc := get_node_or_null("/root/Loc")
	if loc != null:
		var problems: Array = loc.validate_table()
		if problems.is_empty():
			print("  interface strings: %d keys, Thai + English present" % loc.string_count())
		else:
			for p in problems:
				failures.append("loc: %s" % p)
		if loc.t("menu.play") == "menu.play":
			failures.append("loc: a known key returned itself")
		var thai: String = loc.t("menu.play")
		if loc.language == "th" and thai == "Play":
			failures.append("loc: Thai is the default language but returned English text")

	var edu := get_node_or_null("/root/Education")
	if edu != null:
		var problems: Array = edu.validate_database()
		if problems.is_empty():
			print("  lesson database: %d lessons, %d sources, all valid" % [
				edu.all_lessons().size(), edu.all_sources().size(),
			])
		else:
			for p in problems:
				failures.append("education: %s" % p)

	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		var missing: Array[String] = []
		for s in ["chop", "wash", "sizzle", "star", "level_complete", "ui_click"]:
			if not audio.has_stream(s):
				missing.append(s)
		for s in AudioManager.LOOP_NAMES:
			if not audio.has_stream(s):
				missing.append(s)
		if missing.is_empty():
			print("  audio: %d procedural streams, %d sustained beds generated" % [
				AudioManager.SFX_NAMES.size(), AudioManager.LOOP_NAMES.size()])
		else:
			failures.append("audio: missing streams %s" % str(missing))
		# A bed must start and stop cleanly, and a stop must always clear the intent
		# so leaving a level can never leave a hiss behind.
		audio.play_loop("loop_sizzle")
		if not audio.is_loop_playing("loop_sizzle"):
			failures.append("audio: starting a sustained bed did not register")
		audio.stop_all_loops(0.0)
		if not audio.active_loops().is_empty():
			failures.append("audio: a bed survived stop_all_loops")

	var save := get_node_or_null("/root/SaveData")
	if save != null:
		print("  save: version=%d levels=%d" % [save.VERSION, save.levels.size()])

	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		print("  settings: language=%s quality=%s" % [settings.language, settings.quality])

	var game := get_node_or_null("/root/Game")
	if game != null:
		print("  game: state=%d" % game.state)

	failures.append_array(_check_content())
	failures.append_array(_check_scoring())
	failures.append_array(_check_assessment())
	failures.append_array(_check_learning_export())
	failures.append_array(_check_participant_code())
	failures.append_array(_check_reset())

	print("--- results ---")
	if failures.is_empty():
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("  FAIL: " + f)
		print("SMOKE TEST FAILED (%d problems)" % failures.size())
		get_tree().quit(1)


# ------------------------------------------------------------- content checks ---
## Every claim in a level must point at a lesson, question or container that
## actually exists, and every interaction must be one the factory can build.
func _check_content() -> Array[String]:
	var problems: Array[String] = []

	problems.append_array(TaskFactory.validate_data())
	if problems.is_empty():
		print("  level data: %d challenges, every step valid" % LevelDB.levels().size())

	var unbuildable: Array[String] = []
	for kind: String in TaskFactory.known_kinds():
		var task: KitchenTask = TaskFactory.create(kind)
		if task == null:
			unbuildable.append(kind)
		else:
			task.free()
	if unbuildable.is_empty():
		print("  task factory: all %d interaction kinds build" % TaskFactory.known_kinds().size())
	else:
		problems.append("task factory cannot build: %s" % str(unbuildable))

	var quiz_refs := 0
	var lesson_refs := 0
	var myth_refs := 0
	for level in LevelDB.levels():
		var level_id := str(level.get("id", ""))
		if QuizDB.required_ids(level_id).is_empty():
			problems.append("challenge '%s' has no required knowledge question" % level_id)
		for qid in level.get("quiz", []):
			quiz_refs += 1
			if QuizDB.by_id(str(qid)).is_empty():
				problems.append("challenge '%s' references unknown question '%s'" % [level_id, str(qid)])
		for lesson_id in level.get("lessons", []):
			lesson_refs += 1
			if not Education.has_lesson(str(lesson_id)):
				problems.append("challenge '%s' references unknown lesson '%s'" % [level_id, str(lesson_id)])
		for entry in level.get("steps", []):
			var step: Dictionary = entry
			var step_id := str(step.get("id", ""))
			var step_lesson := str(step.get("lesson", ""))
			if not step_lesson.is_empty() and not Education.has_lesson(step_lesson):
				problems.append("step '%s' references unknown lesson '%s'" % [step_id, step_lesson])
			for claim_id in step.get("corrects", []):
				myth_refs += 1
				if Education.misconception(str(claim_id)).is_empty():
					problems.append("step '%s' references unknown misconception '%s'" % [step_id, str(claim_id)])
	print("  references: %d questions, %d lessons, %d myth corrections all resolve" % [
		quiz_refs, lesson_refs, myth_refs])

	for key in Game.SCENES.keys():
		var path := str(Game.SCENES[key])
		if not ResourceLoader.exists(path):
			problems.append("screen '%s' points at missing %s" % [key, path])
	print("  scenes: %d screens present on disk" % Game.SCENES.size())

	return problems


# ------------------------------------------------------------- scoring checks ---
## The scoring rules are the part of the design that is easiest to get subtly
## wrong, so they are checked directly rather than only through play.
func _check_scoring() -> Array[String]:
	var problems: Array[String] = []
	var level := LevelDB.by_id("l1")
	var step_ids: Array[String] = []
	for entry in level.get("steps", []):
		step_ids.append(str((entry as Dictionary).get("id", "")))
	var required := QuizDB.required_ids("l1")

	# A careful, fully-correct run earns everything.
	var perfect := KitchenSession.new()
	perfect.begin(level)
	for step_id in step_ids:
		perfect.record_step(step_id, 1, 0)
	for qid in level.get("quiz", []):
		var key := str(qid)
		perfect.record_quiz(key, true, required.has(key), 1)
	if not perfect.passed():
		problems.append("scoring: a fully correct run was not counted as passed")
	if perfect.stars() != GameConfig.STARS_MAX:
		problems.append("scoring: a fully correct run earned %d stars, expected %d" % [
			perfect.stars(), GameConfig.STARS_MAX])

	# A high-scoring but careless run must not reach three stars: marks come from
	# accuracy, not from raw points.
	var careless := KitchenSession.new()
	careless.begin(level)
	for step_id in step_ids:
		careless.record_step(step_id, 2, 1)
	for qid in level.get("quiz", []):
		var key := str(qid)
		careless.record_quiz(key, true, required.has(key), 1)
	if careless.stars() >= GameConfig.STARS_MAX:
		problems.append("scoring: a careless run still earned three stars")
	if careless.accuracy() != 0.0:
		problems.append("scoring: first-try accuracy should be 0 after a mistake on every step")

	# Skipping the education cannot earn completion.
	var skipped := KitchenSession.new()
	skipped.begin(level)
	for step_id in step_ids:
		skipped.record_step(step_id, 1, 0)
	for qid in level.get("quiz", []):
		var key := str(qid)
		skipped.record_quiz(key, false, required.has(key), 3)
	if skipped.passed():
		problems.append("scoring: a wrong required answer still counted as complete")
	if skipped.stars() != 0:
		problems.append("scoring: a run that failed the knowledge check still earned stars")

	# An unfinished run must not count either.
	var partial := KitchenSession.new()
	partial.begin(level)
	partial.record_step(step_ids[0], 1, 0)
	if partial.completion() >= 1.0:
		problems.append("scoring: an unfinished run reported full completion")

	if problems.is_empty():
		print("  scoring: perfect run = %d stars, careless run = %d stars, education required" % [
			perfect.stars(), careless.stars()])
	return problems


# ---------------------------------------------------------- assessment checks ---
func _check_assessment() -> Array[String]:
	var problems: Array[String] = []
	var pre := AssessmentDB.questions(AssessmentDB.SET_PRE)
	var post := AssessmentDB.questions(AssessmentDB.SET_POST)
	if pre.is_empty() or post.is_empty():
		problems.append("assessment: the before/after question sets are not both populated")
		return problems

	var pre_pairs: Array[int] = []
	for entry in pre:
		var question: Dictionary = entry
		pre_pairs.append(int(question.get("pair", -1)))
		if (question.get("options", []) as Array).size() < 2:
			problems.append("assessment: question '%s' has too few options" % str(question.get("id", "?")))
		if str(question.get("explain", "")).is_empty():
			problems.append("assessment: question '%s' has no explanation" % str(question.get("id", "?")))
	for entry in post:
		var question: Dictionary = entry
		var pair := int(question.get("pair", -1))
		if not pre_pairs.has(pair):
			problems.append("assessment: post question '%s' has no matching before question (pair %d)" % [
				str(question.get("id", "?")), pair])
	if problems.is_empty():
		print("  assessment: %d before and %d after questions, paired by topic" % [pre.size(), post.size()])
	return problems


# ------------------------------------------------------------- learning export ---
func _check_learning_export() -> Array[String]:
	var problems: Array[String] = []
	var learning := get_node_or_null("/root/Learning")
	if learning == null:
		return ["learning: the Learning autoload is missing"]

	# Exercise the log in memory only: nothing here should touch the player's file.
	var previous_levels: Dictionary = SaveData.levels.duplicate(true)
	var previous_learning: Dictionary = SaveData.learning.duplicate(true)
	SaveData.suspend_disk_writes(true)
	learning.record_activity("l1", "wash_hands")
	learning.record_lesson("clean_hands")
	learning.record_misconception("same_board_ok")
	learning.record_question("q_l1_separate", true)
	if not learning.has_activity("l1", "wash_hands"):
		problems.append("learning: a recorded activity was not found again")
	if not learning.has_misconception("same_board_ok"):
		problems.append("learning: a corrected misconception was not recorded")
	if not learning.is_question_correct("q_l1_separate"):
		problems.append("learning: a correct answer was not recorded")

	var record: Dictionary = learning.export_anonymised()
	for key in ["format", "format_version", "levels", "activities_completed", "lessons_covered",
			"misconceptions_corrected", "questions", "totals"]:
		if not record.has(key):
			problems.append("learning export: missing '%s'" % key)
	var text := JSON.stringify(record)
	for forbidden in ["name", "school", "email", "student"]:
		if text.findn(forbidden) >= 0:
			problems.append("learning export: contains something resembling personal data ('%s')" % forbidden)

	SaveData.levels = previous_levels
	SaveData.learning = previous_learning
	SaveData.suspend_disk_writes(false)
	if problems.is_empty():
		print("  learning export: anonymous record has every required field")
	return problems


# ------------------------------------------------------- participant code ---
## The case code is the only piece of text the game ever stores, so it gets its
## own check: it must be filtered to a safe alphabet, capped in length, optional,
## and carried into the export.
func _check_participant_code() -> Array[String]:
	var problems: Array[String] = []
	var learning := get_node_or_null("/root/Learning")
	var previous_code := SaveData.participant_code
	SaveData.suspend_disk_writes(true)

	var messy := SaveData.sanitise_code("a b/c!? d-e_f")
	if messy != "ABCD-E_F":
		problems.append("code: sanitising kept something it should not (%s)" % messy)
	var long_code := SaveData.sanitise_code("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
	if long_code.length() != SaveData.CODE_MAX:
		problems.append("code: a long code was not capped (%d characters)" % long_code.length())
	if not SaveData.sanitise_code("").is_empty():
		problems.append("code: an empty code did not stay empty")

	if learning != null:
		SaveData.set_participant_code("")
		var empty_record: Dictionary = learning.export_anonymised()
		if str(empty_record.get("participant_code", "MISSING")) != "":
			problems.append("code: with nothing entered, the export did not carry an empty code")
		SaveData.set_participant_code("b-07")
		var record: Dictionary = learning.export_anonymised()
		if str(record.get("participant_code", "")) != "B-07":
			problems.append("code: the export did not carry the code that was entered")

	SaveData.participant_code = previous_code
	SaveData.suspend_disk_writes(false)
	if problems.is_empty():
		print("  participant code: optional, filtered to A-Z 0-9 - _, capped, and carried into the export")
	return problems


## "Reset all progress" must leave nothing behind. This is the one check that
## touches the real user directory, so it saves every existing file first and puts
## it back afterwards: a test that could destroy a save is not worth running.
func _check_reset() -> Array[String]:
	var problems: Array[String] = []
	var paths := [SaveData.SAVE_PATH, SaveData.TEMP_PATH, SaveData.BACKUP_PATH,
		SaveData.LEGACY_V1_PATH, SaveData.LEGACY_V1_BACKUP]
	var kept := {}
	for path in paths:
		if FileAccess.file_exists(path):
			kept[path] = FileAccess.get_file_as_bytes(path)
	var kept_levels: Dictionary = SaveData.levels.duplicate(true)
	var kept_learning: Dictionary = SaveData.learning.duplicate(true)

	# Plant a file of every kind, put progress in memory, then reset.
	for path in paths:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			_restore_files(paths, kept)
			return ["reset: could not create '%s' to test with" % path]
		file.store_string("{\"planted\": true}")
		file.close()
	SaveData.levels = {"l1": {"stars": 3}}
	SaveData.learning = {"activities": {"l1.wash_hands": true}}
	SaveData.reset_progress()

	for path in paths:
		if FileAccess.file_exists(path):
			problems.append("reset: '%s' survived a reset" % path)
	if not SaveData.levels.is_empty() or not SaveData.learning.is_empty():
		problems.append("reset: progress survived in memory")

	_restore_files(paths, kept)
	SaveData.levels = kept_levels
	SaveData.learning = kept_learning
	if problems.is_empty():
		print("  reset: progress clears from disk and memory, old files included")
	return problems


func _restore_files(paths: Array, kept: Dictionary) -> void:
	for path in paths:
		if kept.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_buffer(kept[path])
				file.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
