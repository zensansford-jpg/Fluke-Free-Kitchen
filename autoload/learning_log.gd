extends Node
## LearningLog (autoload name: `Learning`).
##
## Records *what the player actually engaged with* — separately from their score.
## A high score never implies learning, so the two are deliberately stored apart.
##
## The log answers the questions the competition and the research plan need:
##   * which learning activities were completed?
##   * which knowledge questions were answered correctly?
##   * which misconceptions were corrected?
##   * which prevention lessons were covered?
##
## Storage is delegated to `SaveData` (one writer, one file). This node holds no
## cache, so a reset from the settings menu is reflected immediately.

signal learning_recorded(kind: String, key: String)

const ACTIVITIES := "activities"
const LESSONS := "lessons"
const MISCONCEPTIONS := "misconceptions"
const QUESTIONS := "questions"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_shape()


func _ensure_shape() -> void:
	var store := SaveData.learning
	for key in [ACTIVITIES, LESSONS, MISCONCEPTIONS, QUESTIONS]:
		if typeof(store.get(key)) != TYPE_DICTIONARY:
			store[key] = {}


func _commit() -> void:
	SaveData.save()


# ----------------------------------------------------------------- recording ---
## Records one finished interactive step, e.g. `record_activity("l1", "wash_hands")`.
func record_activity(level_id: String, activity_id: String) -> void:
	if level_id.is_empty() or activity_id.is_empty():
		return
	_ensure_shape()
	var store := SaveData.learning
	var activities: Dictionary = store[ACTIVITIES]
	var key := "%s.%s" % [level_id, activity_id]
	if activities.has(key):
		return
	activities[key] = true
	learning_recorded.emit("activity", key)
	_commit()


## Records that a health lesson was shown *and* seen through by the player.
func record_lesson(lesson_id: String) -> void:
	if lesson_id.is_empty():
		return
	_ensure_shape()
	var store := SaveData.learning
	var lessons: Dictionary = store[LESSONS]
	if lessons.has(lesson_id):
		return
	lessons[lesson_id] = true
	learning_recorded.emit("lesson", lesson_id)
	_commit()


## Records that a myth was corrected. Correcting is one-way: once a player has
## seen the explanation, the journal keeps it even if they later mis-tap.
func record_misconception(topic_id: String) -> void:
	if topic_id.is_empty():
		return
	_ensure_shape()
	var store := SaveData.learning
	var myths: Dictionary = store[MISCONCEPTIONS]
	if myths.has(topic_id):
		return
	myths[topic_id] = true
	learning_recorded.emit("misconception", topic_id)
	_commit()


## Records an answer to a knowledge-check question. A question counts as
## "correct" once the player has answered it correctly at least once.
func record_question(question_id: String, correct: bool) -> void:
	if question_id.is_empty():
		return
	_ensure_shape()
	var store := SaveData.learning
	var questions: Dictionary = store[QUESTIONS]
	var entry: Dictionary = questions.get(question_id, {"correct": false, "attempts": 0})
	entry["attempts"] = int(entry.get("attempts", 0)) + 1
	entry["correct"] = bool(entry.get("correct", false)) or correct
	questions[question_id] = entry
	learning_recorded.emit("question", question_id)
	_commit()


# ------------------------------------------------------------------- queries ---
func has_activity(level_id: String, activity_id: String) -> bool:
	var activities: Dictionary = SaveData.learning.get(ACTIVITIES, {})
	return activities.has("%s.%s" % [level_id, activity_id])


func has_lesson(lesson_id: String) -> bool:
	var lessons: Dictionary = SaveData.learning.get(LESSONS, {})
	return lessons.has(lesson_id)


func has_misconception(topic_id: String) -> bool:
	var myths: Dictionary = SaveData.learning.get(MISCONCEPTIONS, {})
	return myths.has(topic_id)


func question_entry(question_id: String) -> Dictionary:
	var questions: Dictionary = SaveData.learning.get(QUESTIONS, {})
	var entry: Variant = questions.get(question_id)
	if typeof(entry) != TYPE_DICTIONARY:
		return {"correct": false, "attempts": 0}
	return (entry as Dictionary).duplicate(true)


func is_question_correct(question_id: String) -> bool:
	return bool(question_entry(question_id).get("correct", false))


func activities_completed() -> int:
	return (SaveData.learning.get(ACTIVITIES, {}) as Dictionary).size()


func lessons_covered() -> int:
	return (SaveData.learning.get(LESSONS, {}) as Dictionary).size()


func misconceptions_corrected() -> int:
	return (SaveData.learning.get(MISCONCEPTIONS, {}) as Dictionary).size()


func questions_attempted() -> int:
	return (SaveData.learning.get(QUESTIONS, {}) as Dictionary).size()


func questions_correct() -> int:
	var questions: Dictionary = SaveData.learning.get(QUESTIONS, {})
	var count := 0
	for key in questions.keys():
		if bool((questions[key] as Dictionary).get("correct", false)):
			count += 1
	return count


## True when every one of `question_ids` has been answered correctly at least
## once. Used to gate a full-completion result behind the level's knowledge check.
func all_questions_correct(question_ids: Array) -> bool:
	for qid in question_ids:
		if not is_question_correct(str(qid)):
			return false
	return true


# ------------------------------------------------------------------- export ---
## Builds an anonymous record suitable for the research plan's data export.
## It contains no name, no school, no device identifier and no free text. The
## single text field is `participant_code`, which is empty unless a teacher
## typed in a code of their own choosing, and which is filtered down to
## A-Z / 0-9 / `-` / `_` on the way in *and* on the way out (see
## `SaveData.sanitise_code`).
func export_anonymised() -> Dictionary:
	var lessons: Dictionary = SaveData.learning.get(LESSONS, {})
	var myths: Dictionary = SaveData.learning.get(MISCONCEPTIONS, {})
	var questions: Dictionary = SaveData.learning.get(QUESTIONS, {})
	var activities: Dictionary = SaveData.learning.get(ACTIVITIES, {})

	var question_report := {}
	for qid in questions.keys():
		var entry: Dictionary = questions[qid]
		question_report[qid] = {
			"correct": bool(entry.get("correct", false)),
			"attempts": int(entry.get("attempts", 0)),
		}

	return {
		"format": "fluke-free-kitchen-learning-log",
		"format_version": 1,
		"game_version": GameConfig.GAME_VERSION,
		"exported_at": Time.get_datetime_string_from_system(true),
		"participant_code": SaveData.participant_code,
		"levels": SaveData.levels.duplicate(true),
		"activities_completed": activities.keys(),
		"lessons_covered": lessons.keys(),
		"misconceptions_corrected": myths.keys(),
		"questions": question_report,
		"assessment": SaveData.assessment.duplicate(true),
		"totals": {
			"runs": SaveData.total_runs,
			"stars": SaveData.total_stars(),
			"levels_completed": SaveData.levels_completed(),
		},
	}


## Writes the anonymous record to `user://` and returns the absolute path, or an
## empty string if it could not be written.
func write_export_file(file_name: String = "fluke_free_kitchen_results.json") -> String:
	var path := "user://" + file_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(export_anonymised(), "\t"))
	file.close()
	return ProjectSettings.globalize_path(path)
