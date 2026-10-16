extends Node
## SaveManager (autoload name: `SaveData`).
##
## Persists long-term progress in a versioned JSON file:
##   * per-challenge stars, best score and attempts
##   * the learning log (see `Learning`)
##   * the optional before/after knowledge-check answers
##
## Writes go to a temporary file first and are then swapped in, so a crash
## during a save cannot leave a half-written file behind.
##
## **No personal information is ever stored and no network access is used.**
## The saved file contains only game progress and anonymous quiz answers.

signal save_changed

const SAVE_PATH := "user://save_v2.json"
const TEMP_PATH := "user://save_v2.json.tmp"
const BACKUP_PATH := "user://save_v2.corrupt.json"
const LEGACY_V1_PATH := "user://save_v1.json"
const LEGACY_V1_BACKUP := "user://save_v1_runner_backup.json"
const VERSION := 2
## Longest case code we accept. Short on purpose: it is a label, not data.
const CODE_MAX := 16

## level id -> { stars, best_score, attempts, completed, best_accuracy }
var levels: Dictionary = {}
## Learning log payload. Owned and written by the `Learning` autoload.
var learning: Dictionary = {}
## { "pre": {...}, "post": {...} }
var assessment: Dictionary = {}
var total_runs: int = 0

## Researcher-assigned anonymous case code, used only by the optional
## before/after knowledge check so a record can be matched to a paper consent
## form. Empty unless a teacher typed one in, and never a name.
## See `docs/STUDY_PROTOCOL.md`.
var participant_code: String = ""

## Set when the last load had to repair or reject a file, so the UI can warn.
var last_load_error: String = ""

var _save_suspended := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progress()


# ------------------------------------------------------------------ loading ---
func load_progress() -> void:
	last_load_error = ""
	levels = {}
	learning = {}
	assessment = {}
	total_runs = 0
	participant_code = ""

	if not FileAccess.file_exists(SAVE_PATH):
		_quarantine_legacy_file()
		return

	var text := _read_text(SAVE_PATH)
	if text.is_empty():
		last_load_error = "progress file was unreadable"
		return
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_load_error = "progress file was not valid JSON; starting fresh"
		_quarantine(SAVE_PATH, BACKUP_PATH)
		return

	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version != VERSION:
		# A file from a different product generation (the 3D runner) is kept
		# aside rather than silently misinterpreted.
		last_load_error = "progress from an older version was reset"
		_quarantine(SAVE_PATH, BACKUP_PATH)
		return

	var levels_data: Variant = data.get("levels", {})
	if typeof(levels_data) == TYPE_DICTIONARY:
		levels = (levels_data as Dictionary).duplicate(true)
	var learning_data: Variant = data.get("learning", {})
	if typeof(learning_data) == TYPE_DICTIONARY:
		learning = (learning_data as Dictionary).duplicate(true)
	var assessment_data: Variant = data.get("assessment", {})
	if typeof(assessment_data) == TYPE_DICTIONARY:
		assessment = (assessment_data as Dictionary).duplicate(true)
	# Re-sanitised on load: a hand-edited file must not be able to put arbitrary
	# text into the export.
	var code: Variant = data.get("participant_code", "")
	if typeof(code) == TYPE_STRING:
		participant_code = sanitise_code(code)
	total_runs = int(data.get("total_runs", 0))


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


## Moves a file we cannot use into a clearly-named backup, so nothing is lost.
func _quarantine(from_path: String, to_path: String) -> void:
	if not FileAccess.file_exists(from_path):
		return
	var file := FileAccess.open(from_path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var out := FileAccess.open(to_path, FileAccess.WRITE)
	if out == null:
		return
	out.store_string(text)
	out.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(from_path))


## The endless-runner build wrote `save_v1.json`. Keep it out of the way but
## keep it, in case anyone wants to look at it.
func _quarantine_legacy_file() -> void:
	if not FileAccess.file_exists(LEGACY_V1_PATH):
		return
	if not FileAccess.file_exists(LEGACY_V1_BACKUP):
		_quarantine(LEGACY_V1_PATH, LEGACY_V1_BACKUP)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_V1_PATH))


# ------------------------------------------------------------------- saving ---
func save() -> void:
	if _save_suspended:
		return
	var data := {
		"version": VERSION,
		"levels": levels,
		"learning": learning,
		"assessment": assessment,
		"total_runs": total_runs,
		"participant_code": participant_code,
	}
	var text := JSON.stringify(data, "\t")
	var temp := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if temp == null:
		push_warning("SaveData: could not write %s" % TEMP_PATH)
		return
	temp.store_string(text)
	temp.close()

	# Swap the temp file into place. DirAccess.rename handles an existing
	# destination by replacing it on every platform we target.
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if err != OK:
		# Fall back to a plain copy so progress is not lost.
		var copy_err := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(TEMP_PATH),
			ProjectSettings.globalize_path(SAVE_PATH)
		)
		if copy_err != OK:
			push_warning("SaveData: could not commit save file (error %d)" % copy_err)
	save_changed.emit()


## Used by tests that want to exercise the in-memory state without touching disk.
func suspend_disk_writes(value: bool) -> void:
	_save_suspended = value


# ------------------------------------------------------------------ levels --
func level_stats(level_id: String) -> Dictionary:
	var stored: Variant = levels.get(level_id)
	if typeof(stored) != TYPE_DICTIONARY:
		return {"stars": 0, "best_score": 0, "attempts": 0, "completed": false, "best_accuracy": 0.0}
	return (stored as Dictionary).duplicate(true)


func stars_for(level_id: String) -> int:
	return int(level_stats(level_id).get("stars", 0))


func best_score_for(level_id: String) -> int:
	return int(level_stats(level_id).get("best_score", 0))


func is_completed(level_id: String) -> bool:
	return bool(level_stats(level_id).get("completed", false))


## Records the outcome of one finished attempt and reports what changed, so the
## result screen can celebrate a new best without doing its own comparisons.
func record_level_result(level_id: String, stars: int, score: int, accuracy: float, completed: bool) -> Dictionary:
	var stats := level_stats(level_id)
	var prev_best := int(stats.get("best_score", 0))
	var prev_stars := int(stats.get("stars", 0))

	stats["attempts"] = int(stats.get("attempts", 0)) + 1
	stats["best_score"] = maxi(prev_best, score)
	stats["stars"] = maxi(prev_stars, stars)
	stats["best_accuracy"] = maxf(float(stats.get("best_accuracy", 0.0)), accuracy)
	stats["completed"] = bool(stats.get("completed", false)) or completed
	levels[level_id] = stats

	total_runs += 1
	save()

	return {
		"new_best_score": score > prev_best,
		"new_best_stars": stars > prev_stars,
		"prev_best_score": prev_best,
		"prev_stars": prev_stars,
	}


func total_stars() -> int:
	var sum := 0
	for key in levels.keys():
		sum += int((levels[key] as Dictionary).get("stars", 0))
	return sum


func levels_completed() -> int:
	var count := 0
	for key in levels.keys():
		if bool((levels[key] as Dictionary).get("completed", false)):
			count += 1
	return count


# -------------------------------------------------------------- assessment ---
func assessment_result(kind: String) -> Dictionary:
	var stored: Variant = assessment.get(kind)
	if typeof(stored) != TYPE_DICTIONARY:
		return {}
	return (stored as Dictionary).duplicate(true)


func record_assessment(kind: String, payload: Dictionary) -> void:
	var entry := payload.duplicate(true)
	entry["taken"] = true
	entry["saved_at"] = Time.get_datetime_string_from_system(true)
	assessment[kind] = entry
	save()


func clear_assessment() -> void:
	assessment = {}
	save()


# -------------------------------------------------------- participant code ---
## Keeps a researcher-assigned case code anonymous and file-safe: A–Z, 0–9,
## hyphen and underscore only, upper-cased, at most `CODE_MAX` characters.
## Anything else is dropped rather than stored, so a typed name cannot end up in
## the save file or in the export.
func sanitise_code(raw: String) -> String:
	var out := ""
	for ch in raw.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "-" or ch == "_":
			out += ch
		if out.length() >= CODE_MAX:
			break
	return out


## Stores the case code. Never required: most players leave it empty, and an
## empty code is a perfectly valid state.
func set_participant_code(raw: String) -> void:
	var code := sanitise_code(raw)
	if code == participant_code:
		return
	participant_code = code
	save()


# ------------------------------------------------------------------- reset ---
## Erases every trace of progress on this device. Used by "Reset all progress".
##
## This removes the whole family of files, not just the current one: the save, a
## half-written temporary file, a quarantined corrupt file, and the runner-era
## `v1` files. A player who resets progress means *all* of it, and a leftover
## `save_v1.json` is exactly the kind of thing that makes a save come back from
## the dead. Settings are deliberately untouched — resetting progress is not the
## same as resetting preferences.
func reset_progress() -> void:
	levels = {}
	learning = {}
	assessment = {}
	total_runs = 0
	participant_code = ""
	last_load_error = ""
	if not _save_suspended:
		for path in [SAVE_PATH, TEMP_PATH, BACKUP_PATH, LEGACY_V1_PATH, LEGACY_V1_BACKUP]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_changed.emit()
