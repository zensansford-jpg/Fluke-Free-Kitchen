extends Node
## SaveManager (autoload name: `SaveData`).
##
## Persists long-term progress in a versioned JSON file:
##   * per-challenge stars, best score and attempts
##   * discovered fish dishes, their mastery and best score
##   * Endless Kitchen records
##   * favourites and recently played dishes
##   * the player's own saved dishes (the cookbook), stored as compositions so the
##     steps are always rebuilt rather than trusted from disk
##   * achievements, each tied to a real event
##   * the learning log (see `Learning`)
##   * the optional before/after knowledge-check answers
##
## **File version 3.** The format is versioned and migrated forward: a version 2
## file is upgraded in place (its challenges, learning log and quiz answers are kept
## and the new fields are added empty), and anything older or unreadable is moved
## aside rather than guessed at. Writes go to a temporary file which is then swapped
## in, so a crash mid-save cannot leave a half-written file behind.
##
## **No personal information is ever stored and no network access is used.** The
## saved file contains only game progress and anonymous quiz answers.

signal save_changed

const SAVE_PATH := "user://save_v3.json"
const TEMP_PATH := "user://save_v3.json.tmp"
const BACKUP_PATH := "user://save_v3.corrupt.json"
const LEGACY_V2_PATH := "user://save_v2.json"
const LEGACY_V2_BACKUP := "user://save_v2_migrated.json"
const LEGACY_V1_PATH := "user://save_v1.json"
const LEGACY_V1_BACKUP := "user://save_v1_runner_backup.json"
const VERSION := 3
## How many recently played dishes to remember for the "recent" row.
const RECENT_MAX := 8
## Longest case code we accept. Short on purpose: it is a label, not data.
const CODE_MAX := 16

## level id -> { stars, best_score, attempts, completed, best_accuracy }
var levels: Dictionary = {}
## recipe id -> { discovered, attempts, best_score, stars, mastered }
var recipes: Dictionary = {}
## { best_score, best_streak, runs, best_streak_recipe }
var endless: Dictionary = {}
## Recipe ids the player starred, in the order they were starred.
var favourites: Array = []
## Recipe ids, most recent first.
var recent: Array = []
## The player's own dishes, in the order they were saved. Each entry is the
## *composition* only (fish, method, ingredients, garnish, plating, name); the
## kitchen rebuilds the steps from it, so a save never carries a stale step list.
var cookbook: Array = []
## recipe id or "free" -> number of free-cook runs finished.
var free_cook_runs: int = 0
## achievement id -> ISO timestamp it was unlocked.
var achievements: Dictionary = {}
## Learning log payload (owned by `Learning`).
var learning: Dictionary = {}
## The optional before/after knowledge-check answers.
var assessment: Dictionary = {}
var total_runs: int = 0

## A short, non-identifying label the researcher may have assigned.
var participant_code: String = ""

## A human-readable note about the last load: a migration, a reset, a corrupt file.
var last_load_error: String = ""

var _save_suspended := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progress()


# ------------------------------------------------------------------ loading ---
func load_progress() -> void:
	last_load_error = ""
	_clear_in_memory()

	if FileAccess.file_exists(SAVE_PATH):
		_load_current()
		return

	# No version 3 file yet. A version 2 file can be upgraded; anything older is
	# kept aside.
	if FileAccess.file_exists(LEGACY_V2_PATH):
		if _migrate_from_v2():
			save()
		return

	_quarantine_legacy_file()


func _clear_in_memory() -> void:
	levels = {}
	recipes = {}
	endless = {}
	favourites = []
	recent = []
	cookbook = []
	free_cook_runs = 0
	achievements = {}
	learning = {}
	assessment = {}
	total_runs = 0
	participant_code = ""


func _load_current() -> void:
	var text := _read_text(SAVE_PATH)
	if text.is_empty():
		last_load_error = "progress file was unreadable; starting fresh"
		return
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_load_error = "progress file was not valid JSON; it was kept aside and progress starts fresh"
		_quarantine(SAVE_PATH, BACKUP_PATH)
		return

	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version != VERSION:
		last_load_error = "progress file version %d is not usable; it was kept aside" % version
		_quarantine(SAVE_PATH, BACKUP_PATH)
		return

	_absorb(data)
	last_load_error = ""


## Copies the readable fields out of a parsed save, defensively: a hand-edited file
## must not be able to put arbitrary text or types into the game.
func _absorb(data: Dictionary) -> void:
	var levels_data: Variant = data.get("levels", {})
	if typeof(levels_data) == TYPE_DICTIONARY:
		levels = (levels_data as Dictionary).duplicate(true)
	var recipes_data: Variant = data.get("recipes", {})
	if typeof(recipes_data) == TYPE_DICTIONARY:
		recipes = (recipes_data as Dictionary).duplicate(true)
	var endless_data: Variant = data.get("endless", {})
	if typeof(endless_data) == TYPE_DICTIONARY:
		endless = (endless_data as Dictionary).duplicate(true)
	var learning_data: Variant = data.get("learning", {})
	if typeof(learning_data) == TYPE_DICTIONARY:
		learning = (learning_data as Dictionary).duplicate(true)
	var assessment_data: Variant = data.get("assessment", {})
	if typeof(assessment_data) == TYPE_DICTIONARY:
		assessment = (assessment_data as Dictionary).duplicate(true)
	var achievements_data: Variant = data.get("achievements", {})
	if typeof(achievements_data) == TYPE_DICTIONARY:
		achievements = (achievements_data as Dictionary).duplicate(true)
	favourites = _string_array(data.get("favourites", []))
	recent = _string_array(data.get("recent", []))
	cookbook = _cookbook_array(data.get("cookbook", []))
	free_cook_runs = int(data.get("free_cook_runs", 0))
	var code: Variant = data.get("participant_code", "")
	if typeof(code) == TYPE_STRING:
		participant_code = sanitise_code(code)
	total_runs = int(data.get("total_runs", 0))


## Upgrades a version 2 file. Everything the player earned is carried over; the new
## fields start empty. The old file is renamed rather than deleted, so the previous
## save survives if anything about the upgrade is wrong.
func _migrate_from_v2() -> bool:
	var text := _read_text(LEGACY_V2_PATH)
	if text.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_quarantine(LEGACY_V2_PATH, LEGACY_V2_BACKUP)
		return false
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != 2:
		_quarantine(LEGACY_V2_PATH, LEGACY_V2_BACKUP)
		return false

	var levels_data: Variant = data.get("levels", {})
	if typeof(levels_data) == TYPE_DICTIONARY:
		levels = (levels_data as Dictionary).duplicate(true)
	var learning_data: Variant = data.get("learning", {})
	if typeof(learning_data) == TYPE_DICTIONARY:
		learning = (learning_data as Dictionary).duplicate(true)
	var assessment_data: Variant = data.get("assessment", {})
	if typeof(assessment_data) == TYPE_DICTIONARY:
		assessment = (assessment_data as Dictionary).duplicate(true)
	var code: Variant = data.get("participant_code", "")
	if typeof(code) == TYPE_STRING:
		participant_code = sanitise_code(code)
	total_runs = int(data.get("total_runs", 0))

	# The three challenges a v2 player finished become discovered "recipes" in the
	# new sense only where a dish actually corresponds to them. Rather than guess,
	# nothing is discovered automatically; existing challenge progress is untouched.
	_quarantine(LEGACY_V2_PATH, LEGACY_V2_BACKUP)
	last_load_error = "progress from version 2 was upgraded; challenges and learning log kept"
	return true


func _string_array(value: Variant) -> Array:
	var out: Array = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for entry in (value as Array):
		if typeof(entry) == TYPE_STRING and not out.has(entry):
			out.append(str(entry))
	return out


## Keeps only entries from a parsed save that a dish can actually be rebuilt from.
## A hand-edited file must not be able to smuggle a malformed recipe into the
## kitchen: anything that is not a dictionary with an id, a method and a fish is
## dropped. The steps are never trusted from disk — they are always rebuilt.
func _cookbook_array(value: Variant) -> Array:
	var out: Array = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for entry in (value as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var recipe: Dictionary = entry
		if str(recipe.get("id", "")).is_empty():
			continue
		if str(recipe.get("method", "")).is_empty():
			continue
		var fish: Variant = recipe.get("fish", [])
		if typeof(fish) != TYPE_ARRAY or (fish as Array).is_empty():
			continue
		out.append(recipe.duplicate(true))
	return out


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


## The endless-runner build wrote `save_v1.json`. Keep it out of the way but keep it.
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
		"recipes": recipes,
		"endless": endless,
		"favourites": favourites,
		"recent": recent,
		"cookbook": cookbook,
		"free_cook_runs": free_cook_runs,
		"achievements": achievements,
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


## Records the outcome of one finished challenge attempt and reports what changed,
## so the result screen can celebrate a new best without doing its own comparisons.
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
	_evaluate_achievements()
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


# ----------------------------------------------------------------- recipes --
func recipe_stats(recipe_id: String) -> Dictionary:
	var stored: Variant = recipes.get(recipe_id)
	if typeof(stored) != TYPE_DICTIONARY:
		return {"discovered": false, "attempts": 0, "best_score": 0, "stars": 0, "mastered": false}
	return (stored as Dictionary).duplicate(true)


func is_discovered(recipe_id: String) -> bool:
	return bool(recipe_stats(recipe_id).get("discovered", false))


func discovered_ids() -> Array:
	var out: Array = []
	for key in recipes.keys():
		if bool((recipes[key] as Dictionary).get("discovered", false)):
			out.append(str(key))
	return out


func discovered_count() -> int:
	return discovered_ids().size()


## Marks a recipe as found. Discovery happens when a dish is finished, not when it
## is first listed, so the count reflects real cooking.
func discover_recipe(recipe_id: String) -> bool:
	if recipe_id.is_empty():
		return false
	if is_discovered(recipe_id):
		return false
	var stats := recipe_stats(recipe_id)
	stats["discovered"] = true
	recipes[recipe_id] = stats
	return true


## Records one finished dish. Returns what changed, for the result screen.
func record_recipe_result(recipe_id: String, stars: int, score: int, accuracy: float, completed: bool) -> Dictionary:
	var stats := recipe_stats(recipe_id)
	var prev_best := int(stats.get("best_score", 0))
	var prev_stars := int(stats.get("stars", 0))
	var was_new := not bool(stats.get("discovered", false))

	stats["discovered"] = true
	stats["attempts"] = int(stats.get("attempts", 0)) + 1
	stats["best_score"] = maxi(prev_best, score)
	stats["stars"] = maxi(prev_stars, stars)
	stats["best_accuracy"] = maxf(float(stats.get("best_accuracy", 0.0)), accuracy)
	stats["mastered"] = bool(stats.get("mastered", false)) or (stars >= GameConfig.STARS_MAX and completed)
	recipes[recipe_id] = stats
	push_recent(recipe_id)

	total_runs += 1
	_evaluate_achievements()
	save()

	return {
		"new_best_score": score > prev_best,
		"new_best_stars": stars > prev_stars,
		"prev_best_score": prev_best,
		"prev_stars": prev_stars,
		"new_discovery": was_new,
	}


func mastered_count() -> int:
	var count := 0
	for key in recipes.keys():
		if bool((recipes[key] as Dictionary).get("mastered", false)):
			count += 1
	return count


func recipe_stars_total() -> int:
	var sum := 0
	for key in recipes.keys():
		sum += int((recipes[key] as Dictionary).get("stars", 0))
	return sum


# ------------------------------------------------------- favourites / recent --
func is_favourite(recipe_id: String) -> bool:
	return favourites.has(recipe_id)


func toggle_favourite(recipe_id: String) -> bool:
	if recipe_id.is_empty():
		return false
	if favourites.has(recipe_id):
		favourites.erase(recipe_id)
		save()
		return false
	favourites.append(recipe_id)
	save()
	return true


func favourite_ids() -> Array:
	return favourites.duplicate()


func push_recent(recipe_id: String) -> void:
	if recipe_id.is_empty():
		return
	recent.erase(recipe_id)
	recent.insert(0, recipe_id)
	while recent.size() > RECENT_MAX:
		recent.remove_at(recent.size() - 1)


func recent_ids() -> Array:
	return recent.duplicate()


# ----------------------------------------------------------------- cookbook ---
## The player's own saved dishes, newest last. A defensive copy, so a screen cannot
## change the stored list by accident.
func saved_recipes() -> Array:
	var out: Array = []
	for entry in cookbook:
		if typeof(entry) == TYPE_DICTIONARY:
			out.append((entry as Dictionary).duplicate(true))
	return out


func saved_recipe_count() -> int:
	return cookbook.size()


func has_saved_recipe(recipe_id: String) -> bool:
	if recipe_id.is_empty():
		return false
	for entry in cookbook:
		if str((entry as Dictionary).get("id", "")) == recipe_id:
			return true
	return false


## Finds one saved dish by id, so it can be cooked again from the cookbook.
func saved_recipe(recipe_id: String) -> Dictionary:
	for entry in cookbook:
		var recipe: Dictionary = entry
		if str(recipe.get("id", "")) == recipe_id:
			return recipe.duplicate(true)
	return {}


## Adds a dish to the cookbook. The same dish (same derived id) is not stored twice,
## so saving a favourite twice is idempotent. Returns true when the book changed.
func save_recipe(recipe: Dictionary) -> bool:
	if recipe.is_empty() or str(recipe.get("id", "")).is_empty():
		return false
	if has_saved_recipe(str(recipe.get("id", ""))):
		return false
	cookbook.append(recipe.duplicate(true))
	_evaluate_achievements()
	save()
	return true


func remove_saved_recipe(recipe_id: String) -> bool:
	if recipe_id.is_empty():
		return false
	for i in range(cookbook.size() - 1, -1, -1):
		if str((cookbook[i] as Dictionary).get("id", "")) == recipe_id:
			cookbook.remove_at(i)
			save()
			return true
	return false


# ----------------------------------------------------------------- endless --
func endless_stats() -> Dictionary:
	return {
		"best_score": int(endless.get("best_score", 0)),
		"best_streak": int(endless.get("best_streak", 0)),
		"runs": int(endless.get("runs", 0)),
	}


## Updates the Endless Kitchen records. `streak` is the running run length and
## `score` the running run total at the moment the challenge finished. `count_run`
## is false when the finished challenge has already been counted elsewhere (which
## is the normal path: the recipe record counts it), so a single challenge is never
## counted as two runs. Returns true if this set a record.
func record_endless(score: int, streak: int, count_run: bool = false) -> bool:
	var prev_best := int(endless.get("best_score", 0))
	var prev_streak := int(endless.get("best_streak", 0))
	endless["best_score"] = maxi(prev_best, score)
	endless["best_streak"] = maxi(prev_streak, streak)
	endless["runs"] = int(endless.get("runs", 0)) + 1
	if count_run:
		total_runs += 1
	_evaluate_achievements()
	save()
	return score > prev_best or streak > prev_streak


func record_free_cook() -> void:
	free_cook_runs += 1
	total_runs += 1
	_evaluate_achievements()
	save()


# ------------------------------------------------------------ achievements --
func has_achievement(achievement_id: String) -> bool:
	return achievements.has(achievement_id)


func unlocked_achievements() -> Array:
	var out: Array = []
	for entry in AchievementDB.list():
		var achievement_id := str(entry.get("id", ""))
		if achievements.has(achievement_id):
			out.append(entry)
	return out


func unlock_achievement(achievement_id: String) -> bool:
	if achievement_id.is_empty() or achievements.has(achievement_id):
		return false
	if AchievementDB.by_id(achievement_id).is_empty():
		return false
	achievements[achievement_id] = Time.get_datetime_string_from_system(true)
	return true


## Checks every achievement rule against the real state and unlocks whatever has
## actually been earned. Called after recording progress, never on its own.
func _evaluate_achievements() -> void:
	var cooked := _recipes_cooked()
	var found := discovered_count()
	if cooked >= 1:
		unlock_achievement("first_dish")
	if cooked >= 3:
		unlock_achievement("three_dishes")
	if found >= 5:
		unlock_achievement("five_dishes")
	if int(endless.get("best_streak", 0)) >= 10:
		unlock_achievement("endless_ten")
	if has_achievement("flip_master") == false and is_discovered("chl_flip_master"):
		unlock_achievement("flip_master")
	for key in recipes.keys():
		if int((recipes[key] as Dictionary).get("stars", 0)) >= GameConfig.STARS_MAX:
			unlock_achievement("perfect_dish")
			break
	var real_total := 0
	for entry in RecipeDB.real_recipes():
		real_total += 1
	if real_total > 0 and _real_discovered() >= real_total:
		unlock_achievement("collector")
	if saved_recipe_count() >= 1:
		unlock_achievement("signature_dish")


func _recipes_cooked() -> int:
	var count := 0
	for key in recipes.keys():
		if int((recipes[key] as Dictionary).get("attempts", 0)) > 0:
			count += 1
	return count


func _real_discovered() -> int:
	var count := 0
	for entry in RecipeDB.real_recipes():
		if is_discovered(str(entry.get("id", ""))):
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
## half-written temporary file, a quarantined corrupt file, and the older-version
## files. A player who resets progress means *all* of it, and a leftover older save
## is exactly the kind of thing that makes progress come back from the dead.
## Settings are deliberately untouched — resetting progress is not the same as
## resetting preferences.
func reset_progress() -> void:
	_clear_in_memory()
	if not _save_suspended:
		for path in [SAVE_PATH, TEMP_PATH, BACKUP_PATH, LEGACY_V2_PATH, LEGACY_V2_BACKUP,
				LEGACY_V1_PATH, LEGACY_V1_BACKUP]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_changed.emit()
