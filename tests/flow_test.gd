extends Node
## End-to-end flow test: plays all three challenges without a human.
##
## It drives the real scripts — the kitchen screen, the task factory, the
## knowledge cards, the mandatory knowledge check and the result screen — using
## the same signals a player's actions produce. Nothing is stubbed, so a broken
## wire between two systems fails here rather than in front of a judge.
##
## What it does **not** do is check how anything looks or feels: it runs headless.
## Visual polish needs a real window, and that is stated plainly in the QA notes
## rather than being implied by a green test.
##
## Run with:
##   godot --headless --path <project> res://tests/flow_test.tscn

const TestWindow := preload("res://tests/test_window.gd")

var failures: Array[String] = []


func _ready() -> void:
	# Stretch mode is disabled, so a headless run must state the window size it
	# wants or every screen is laid out for a 64x64 viewport.
	TestWindow.use(1280, 720)
	await TestWindow.settle(2)
	await _run()
	_report()


func _run() -> void:
	print("--- Fluke Free Kitchen flow test ---")
	# Nothing in this test should ever reach the player's save file.
	SaveData.suspend_disk_writes(true)
	for level_id in LevelDB.ids():
		await _play_level(level_id)
	await _check_journal()
	SaveData.suspend_disk_writes(false)
	_finish_cleanup()


func _finish_cleanup() -> void:
	Game.abandon_level()
	Game.change_state(Game.State.MENU)


# ------------------------------------------------------------------ one level ---
func _play_level(level_id: String) -> void:
	Game.current_level_id = level_id
	Game.change_state(Game.State.PLAYING)

	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await _frames(2)

	var level: Dictionary = screen.get("level")
	if level.is_empty():
		failures.append("%s: the kitchen screen did not load the challenge" % level_id)
		screen.queue_free()
		return

	var steps: Array = level.get("steps", [])
	print("  %s (%s): %d steps" % [level_id, LevelDB.title(level), steps.size()])

	for i in steps.size():
		var step: Dictionary = steps[i]
		var step_id := str(step.get("id", ""))
		var task: KitchenTask = screen.call("current_task")

		if task == null:
			failures.append("%s: no task was created for step %d ('%s')" % [level_id, i, step_id])
			break
		if screen.call("current_step_index") != i:
			failures.append("%s: the runner is on step %d but the test is on %d" % [
				level_id, screen.call("current_step_index"), i])
			break
		if task.step_id() != step_id:
			failures.append("%s: step %d built '%s' instead of '%s'" % [level_id, i, task.step_id(), step_id])
			break
		if task.settled:
			failures.append("%s: step '%s' was already scored before it began" % [level_id, step_id])
		if task.kitchen == null:
			failures.append("%s: step '%s' has no kitchen reference" % [level_id, step_id])

		# Complete the step through its own outcome signal, which is exactly what
		# a real success does.
		task.succeed()
		await _frames(2)

		var lesson_id := str(step.get("lesson", ""))
		if lesson_id.is_empty():
			continue

		var card: Node = _find(screen, func(node: Node) -> bool: return node is LessonCard)
		if card == null:
			failures.append("%s: step '%s' teaches '%s' but no knowledge card appeared" % [
				level_id, step_id, lesson_id])
			continue
		card.emit_signal("dismissed")
		await _frames(2)

	# -------------------------------------------------- the mandatory check ---
	var quiz: Node = _find(screen, func(node: Node) -> bool: return node is QuizCard)
	if quiz == null:
		failures.append("%s: the knowledge check never appeared" % level_id)
	else:
		await _answer_quiz(quiz, level_id)

	# -------------------------------------------------------------- result ---
	if not screen.call("result_visible"):
		failures.append("%s: the result screen did not appear" % level_id)
	else:
		# The stars pop in a fraction of a second after the panel is built.
		await _seconds(0.6)
		var stars: StarRow = _find(screen, func(node: Node) -> bool: return node is StarRow)
		if stars == null:
			failures.append("%s: the result screen has no star row" % level_id)
		elif stars.stars != GameConfig.STARS_MAX:
			failures.append("%s: a fully correct run showed %d of %d stars" % [
				level_id, stars.stars, GameConfig.STARS_MAX])
		if SaveData.stars_for(level_id) != GameConfig.STARS_MAX:
			failures.append("%s: saved progress recorded %d stars" % [level_id, SaveData.stars_for(level_id)])
		if not SaveData.is_completed(level_id):
			failures.append("%s: a completed challenge was not marked complete" % level_id)

		# Scoring invariants. A score above the level maximum is not a cosmetic
		# problem — it means the same action or question was counted twice.
		var summary: Dictionary = Game.last_result
		var asked := QuizDB.for_level(level_id).size()
		if int(summary.get("quiz_answered", 0)) != asked:
			failures.append("%s: %d knowledge questions were recorded but the challenge asks %d" % [
				level_id, int(summary.get("quiz_answered", 0)), asked])
		if int(summary.get("quiz_correct", 0)) > asked:
			failures.append("%s: %d correct answers recorded for %d questions" % [
				level_id, int(summary.get("quiz_correct", 0)), asked])
		if int(summary.get("score", 0)) > int(summary.get("max_score", 0)):
			failures.append("%s: score %d is above the challenge maximum of %d" % [
				level_id, int(summary.get("score", 0)), int(summary.get("max_score", 0))])
		if int(summary.get("steps_completed", 0)) != steps.size():
			failures.append("%s: %d of %d steps were recorded" % [
				level_id, int(summary.get("steps_completed", 0)), steps.size()])

		print("    result: %d stars, score %d/%d, %d questions answered" % [
			SaveData.stars_for(level_id), int(summary.get("score", 0)),
			int(summary.get("max_score", 0)), int(summary.get("quiz_answered", 0))])

	Game.abandon_level()
	screen.queue_free()
	await _frames(2)


# ---------------------------------------------------------------------- quiz ---
func _answer_quiz(quiz: Node, level_id: String) -> void:
	var questions := QuizDB.for_level(level_id)
	if questions.is_empty():
		failures.append("%s: the knowledge check has no questions" % level_id)
		return

	for entry in questions:
		var question: Dictionary = entry
		var question_id := str(question.get("id", "?"))
		var correct_label := ""
		for option_entry in question.get("options", []):
			var option: Dictionary = option_entry
			if bool(option.get("correct", false)):
				correct_label = LessonDB.local(option.get("label"))
				break

		if correct_label.is_empty():
			failures.append("%s: question '%s' has no correct option" % [level_id, question_id])
			return

		var option_button := _button_with_text(quiz, correct_label)
		if option_button == null:
			failures.append("%s: question '%s' never offered its correct answer" % [level_id, question_id])
			return
		option_button.emit_signal("pressed")
		await _frames(2)

		var advance := _advance_button(quiz)
		if advance == null:
			failures.append("%s: no way onwards after answering '%s' correctly" % [level_id, question_id])
			return
		advance.emit_signal("pressed")
		await _frames(2)


func _advance_button(quiz: Node) -> Button:
	for text in [Loc.t("feedback.continue"), Loc.t("quiz.next")]:
		var button := _button_with_text(quiz, text)
		if button != null:
			return button
	return null


# -------------------------------------------------------------------- journal ---
func _check_journal() -> void:
	if Learning.lessons_covered() == 0:
		failures.append("journal: playing every challenge recorded no lessons at all")
		return

	Game.change_state(Game.State.JOURNAL)
	var journal: Node = load("res://scenes/journal/journal.tscn").instantiate()
	add_child(journal)
	await _frames(2)
	journal.call("show_tab", Journal.TAB_KNOWLEDGE)
	await _frames(2)

	var texts := _collect_text(journal)
	var shown := 0
	for lesson_id in LevelDB.all_lesson_ids():
		if not Learning.has_lesson(str(lesson_id)):
			continue
		var title := Education.title(str(lesson_id))
		if not title.is_empty() and texts.has(title):
			shown += 1

	print("  journal: %d lessons recorded, %d of them shown in the knowledge tab" % [
		Learning.lessons_covered(), shown])
	if shown == 0:
		failures.append("journal: recorded lessons are not shown in the knowledge tab")
	if not texts.has("%s: %d" % [Loc.t("journal.misconceptions"), Learning.misconceptions_corrected()]):
		# The myth heading is built from live numbers; if the count line is
		# missing the tab did not build fully.
		failures.append("journal: the corrected-myths section did not build")

	journal.queue_free()
	await _frames(2)


# --------------------------------------------------------------------- helpers ---
func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


func _find(root: Node, predicate: Callable) -> Node:
	if predicate.call(root):
		return root
	for child in root.get_children():
		var found := _find(child, predicate)
		if found != null:
			return found
	return null


func _button_with_text(root: Node, text: String) -> Button:
	# Only buttons the player could press: a question's retired buttons are freed
	# with `queue_free`, so they linger in the tree until the end of the frame.
	var button: Button = _find(root, func(node: Node) -> bool:
		return node is Button \
			and (node as Button).text == text \
			and not (node as Button).disabled \
			and (node as Button).is_visible_in_tree())
	return button


func _collect_text(root: Node) -> Array[String]:
	var texts: Array[String] = []
	if root is Label:
		texts.append((root as Label).text)
	for child in root.get_children():
		texts.append_array(_collect_text(child))
	return texts


func _report() -> void:
	print("--- results ---")
	if failures.is_empty():
		print("FLOW TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("FLOW TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
