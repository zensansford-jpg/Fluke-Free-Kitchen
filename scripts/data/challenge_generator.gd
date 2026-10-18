class_name ChallengeGenerator
extends RefCounted
## The endless challenge generator.
##
## It picks a recipe the player has unlocked, builds a validated sequence of
## minigames from it, and hands back a challenge dictionary the kitchen can run.
## It is deliberately small and deterministic: given the same seed and the same
## list of discovered recipes it produces the same sequence, so a bug can be
## reproduced instead of chased.
##
## The rules it never breaks:
##
##   * it only ever returns a challenge whose steps all validate;
##   * it avoids repeating the same recipe in quick succession, but if the pool is
##     small (or empty of unseen recipes) it still returns something valid rather
##     than spinning — it can never loop forever looking for variety;
##   * if there is genuinely nothing valid to cook it returns an empty dictionary,
##     and the caller says so. It does not invent a challenge.

## How many recent recipes to steer away from before allowing a repeat.
const RECENT_MAX := 3

var seed_value: int = 0
var rng := RandomNumberGenerator.new()
var _history: Array[String] = []
var _counter := 0


## Starts a run. A seed of 0 means "random", which is what normal play uses; tests
## pass a real seed so the sequence is reproducible.
func begin(seed_input: int = 0) -> void:
	seed_value = seed_input
	if seed_value == 0:
		rng.randomize()
		seed_value = rng.seed
	else:
		rng.seed = seed_value
	_history.clear()
	_counter = 0


func history() -> Array[String]:
	return _history.duplicate()


func set_history(list: Array) -> void:
	_history.clear()
	for entry in list:
		_history.append(str(entry))


# ------------------------------------------------------------------ catalogue --
## The recipes that pass validation. Computed once and cached; a recipe that cannot
## be played must never reach a player, so the generator works only from this list.
static var _valid_cache: Array = []


static func valid_recipes() -> Array:
	if not _valid_cache.is_empty():
		return _valid_cache
	var out: Array = []
	for entry in RecipeDB.recipes():
		if RecipeDB.validate(entry).is_empty():
			out.append(entry)
	_valid_cache = out
	return out


static func is_playable(recipe_id: String) -> bool:
	for entry in valid_recipes():
		if str(entry.get("id", "")) == recipe_id:
			return true
	return false


# ------------------------------------------------------------------- building --
## Builds one challenge from one recipe. `difficulty` overrides the recipe's own
## level when non-negative, which is how Endless mode escalates.
func build(recipe: Dictionary, difficulty: int = -1) -> Dictionary:
	if recipe.is_empty():
		return {}
	var recipe_id := str(recipe.get("id", ""))
	if not is_playable(recipe_id):
		return {}
	var level := int(recipe.get("difficulty", 1)) if difficulty < 0 else difficulty
	level = clampi(level, 1, 3)
	var steps := RecipeDB.build_steps(recipe, level)
	if steps.is_empty():
		return {}

	_counter += 1
	var quiz: Array = recipe.get("quiz", [])
	var required: Array = []
	if not quiz.is_empty():
		required.append(str(quiz[0]))

	return {
		"id": "ch_%s_%d" % [recipe_id, _counter],
		"index": 2,
		"title": recipe.get("name", {}),
		"goal": recipe.get("about", {}),
		"objective_short": recipe.get("about", {}),
		"recipe_id": recipe_id,
		"real": bool(recipe.get("real", true)),
		"difficulty": level,
		"steps": steps,
		"quiz": quiz,
		"required_quiz": required,
		"lessons": recipe.get("lessons", []),
		"tags": recipe.get("tags", []),
		"generated": true,
		"seed": seed_value,
	}


## The next Endless Kitchen challenge.
##
## `discovered` is the list of recipe ids the player has found. Returns an empty
## dictionary only when the catalogue has nothing valid to offer at all.
func next(difficulty: int, discovered: Array, allow_safety_variation: bool = true) -> Dictionary:
	var pool: Array = []
	for entry in valid_recipes():
		var recipe: Dictionary = entry
		if not RecipeDB.is_unlocked(recipe, discovered):
			continue
		pool.append(recipe)
	if pool.is_empty():
		# Nothing unlocked yet (a fresh profile with an odd catalogue). Fall back to
		# any valid recipe at all so the mode still works.
		pool = valid_recipes().duplicate()
	if pool.is_empty():
		return {}

	# Prefer recipes at or below the requested difficulty, then widen if needed.
	var wanted: Array = []
	for entry in pool:
		if int((entry as Dictionary).get("difficulty", 1)) <= difficulty:
			wanted.append(entry)
	if wanted.is_empty():
		wanted = pool

	# Avoid the recipes just played — but never at the cost of having nothing.
	var fresh: Array = []
	for entry in wanted:
		if not _history.has(str((entry as Dictionary).get("id", ""))):
			fresh.append(entry)
	if fresh.is_empty():
		fresh = wanted

	var recipe: Dictionary = fresh[rng.randi_range(0, fresh.size() - 1)]
	var challenge := build(recipe, difficulty)
	if challenge.is_empty():
		# A recipe that validated a moment ago failed to build: skip it and try the
		# fallback rather than returning nothing.
		challenge = _fallback(discovered)
	if challenge.is_empty():
		return {}

	if allow_safety_variation:
		_maybe_add_safety_variation(challenge)
	_remember(str(challenge.get("recipe_id", "")))
	return challenge


## A guaranteed-valid challenge for when variety temporarily runs out.
func _fallback(discovered: Array) -> Dictionary:
	for entry in valid_recipes():
		if RecipeDB.is_unlocked(entry, discovered):
			var challenge := build(entry)
			if not challenge.is_empty():
				return challenge
	var any: Array = valid_recipes()
	if any.is_empty():
		return {}
	return build(any[0])


func _remember(recipe_id: String) -> void:
	if recipe_id.is_empty():
		return
	_history.append(recipe_id)
	while _history.size() > RECENT_MAX:
		_history.remove_at(0)


## Occasionally turns the final serving decision into a "this one came off the pan
## early" situation. It only ever *replaces* the serve step with the undercooked
## variant; it never touches the cook step or the safety figures, and the situation
## is stated plainly so nothing is misrepresented.
func _maybe_add_safety_variation(challenge: Dictionary) -> void:
	if rng.randf() > 0.25:
		return
	var steps: Array = challenge.get("steps", [])
	for i in range(steps.size() - 1, -1, -1):
		var step: Dictionary = steps[i]
		if str(step.get("kind", "")) != "serve":
			continue
		step["dish_state"] = "undercooked"
		step["prompt"] = {
			"en": "This fish came off the pan after only a moment. Is it ready to serve?",
			"th": "ปลาตัวนี้ออกจากกระทะได้เพียงครู่เดียว พร้อมเสิร์ฟหรือยัง",
		}
		step["tags"] = ["safety-decision"]
		var tags: Array = challenge.get("tags", [])
		tags.append("safety-decision")
		challenge["tags"] = tags
		return


# --------------------------------------------------------------- validation ---
## Checks a built challenge before it is shown. A challenge that fails here is not
## played: the caller can ask for another one. Every step is held to the same
## standard as a hand-written recipe, payload and all.
func validate(challenge: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	if challenge.is_empty():
		problems.append("there is no challenge")
		return problems
	var steps: Array = challenge.get("steps", [])
	if steps.is_empty():
		problems.append("the challenge has no steps")
		return problems
	problems.append_array(RecipeDB.validate_steps(steps))
	return problems
