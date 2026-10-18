extends Node
## GameManager (autoload name: `Game`).
##
## Owns the application flow: which of the game's screens is active, which
## challenge is being played, and whether a challenge run is currently open for
## scoring. It also owns navigation, so scene changes happen in exactly one
## place and the end-to-end flow test can drive them.
##
## Pausing is engine-level (`get_tree().paused`) and is mirrored in `state` so
## that UI can react without polling.

signal state_changed(state: int, previous: int)
signal level_started(level_id: String)
signal level_finished(level_id: String, result: Dictionary)

enum State {
	MENU,
	LEVEL_SELECT,
	ASSESSMENT,
	SOURCES,
	PLAYING,
	PAUSED,
	RESULT,
	JOURNAL,
	MODES,
	DISH_SELECT,
	FREE_COOK,
}

## What kind of run is open. The kitchen behaves the same way in all of them; what
## differs is which challenge it was given and where the result is recorded.
enum Mode {
	STORY,
	COOK,
	ENDLESS,
	FREE_COOK,
}

## Screen key -> scene file. Navigation only ever goes through this table.
const SCENES := {
	"menu": "res://scenes/main/main_menu.tscn",
	"modes": "res://scenes/main/mode_select.tscn",
	"levels": "res://scenes/main/level_select.tscn",
	"dishes": "res://scenes/main/dish_select.tscn",
	"free_cook": "res://scenes/main/free_cook.tscn",
	"kitchen": "res://scenes/kitchen/kitchen.tscn",
	"journal": "res://scenes/journal/journal.tscn",
	"assessment": "res://scenes/assessment/assessment.tscn",
}

var state: State = State.MENU
var current_level_id: String = ""
## A generated or chosen challenge (recipe, endless, free cook). Empty during the
## three story challenges, which are looked up from `LevelDB` by `current_level_id`.
var current_challenge: Dictionary = {}
var mode: Mode = Mode.STORY
var current_recipe_id: String = ""
## Endless Kitchen: the current run's length and score so far.
var endless_streak: int = 0
var endless_score: int = 0
var last_result: Dictionary = {}
## True between `start_level` and `finish_level` — i.e. while a run's score may
## still change. The score screen freezes once this is false.
var run_active := false
var run_finished := false

var _generator: ChallengeGenerator = null

## Seconds the screen spends fading to black before a new screen is loaded, and
## fading back in afterwards. Long enough to feel deliberate, short enough that
## nobody waits for it.
const FADE_OUT_TIME := 0.16
const FADE_IN_TIME := 0.24
const FADE_COLOR := Color(0.03, 0.04, 0.07, 1.0)

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
## True while a screen change is in progress, so a second click cannot start a
## second transition on top of the first.
var _navigating := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# The game starts on the main menu; the main scene is the menu itself, so
	# there is nothing to navigate to yet.
	state = State.MENU
	_build_fade()
	# Open on a soft fade-in rather than a hard cut.
	_fade_rect.color = FADE_COLOR
	_fade_to(0.0, 0.6)


# -------------------------------------------------------------------- state ---
func change_state(new_state: State) -> void:
	if new_state == state:
		return
	var previous := state
	state = new_state
	# Pausing is expressed through the state machine so timers and animation
	# freeze consistently everywhere.
	get_tree().paused = (new_state == State.PAUSED)
	state_changed.emit(int(new_state), int(previous))


func is_run_active() -> bool:
	return run_active


func is_run_finished() -> bool:
	return run_finished


# -------------------------------------------------------------- navigation ---
## Screen changes happen in one place, and every one of them fades through black
## so the game never hard-cuts between a warm kitchen and a menu.
##
## The scene change happens a fraction of a second after this returns, so the
## return value only says whether the screen name is known. A missing scene file
## is a build error, not a runtime condition, and `tests/smoke_test.tscn` checks
## that all five screens exist.
func navigate(key: String) -> bool:
	if not SCENES.has(key):
		push_warning("Game: unknown screen '%s'." % key)
		return false
	if _navigating:
		return true
	get_tree().paused = false
	_apply_state_for(key)
	_transition(str(SCENES[key]))
	return true


func _apply_state_for(key: String) -> void:
	match key:
		"menu":
			change_state(State.MENU)
		"levels":
			change_state(State.LEVEL_SELECT)
		"modes":
			change_state(State.MODES)
		"dishes":
			change_state(State.DISH_SELECT)
		"free_cook":
			change_state(State.FREE_COOK)
		"assessment":
			change_state(State.ASSESSMENT)
		"sources":
			change_state(State.SOURCES)
		"journal":
			change_state(State.JOURNAL)


func _transition(scene_path: String) -> void:
	_navigating = true
	await _fade_to(1.0, FADE_OUT_TIME)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_warning("Game: could not open screen '%s' (error %d)." % [scene_path, err])
	# Two frames let the new screen be added and laid out before it is revealed,
	# so the fade never lights up a half-built UI.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, FADE_IN_TIME)
	_navigating = false


# -------------------------------------------------------------------- fade ---
## A full-screen wash the autoload owns, so it survives the screen change it is
## covering. It never intercepts the pointer: it is a cosmetic layer only.
func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "ScreenFade"
	# Above every screen (kitchen modals sit at 30–40) but below nothing that
	# matters, because it is invisible whenever it is transparent.
	_fade_layer.layer = 90
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "Wash"
	_fade_rect.color = Color(FADE_COLOR.r, FADE_COLOR.g, FADE_COLOR.b, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Explicit anchors and offsets: the anchors preset alone collapses an in-tree
	# plain Control to nothing (see docs/PROJECT_AUDIT.md §8).
	_fade_rect.anchor_left = 0.0
	_fade_rect.anchor_top = 0.0
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.offset_left = 0.0
	_fade_rect.offset_top = 0.0
	_fade_rect.offset_right = 0.0
	_fade_rect.offset_bottom = 0.0
	_fade_layer.add_child(_fade_rect)


func _fade_to(alpha: float, seconds: float) -> void:
	if _fade_rect == null:
		return
	_fade_rect.visible = true
	if seconds <= 0.0:
		_fade_rect.color.a = alpha
		_fade_rect.visible = alpha > 0.001
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", alpha, seconds)
	await tween.finished
	_fade_rect.visible = alpha > 0.001


func go_to_menu() -> void:
	navigate("menu")


func go_to_levels() -> void:
	navigate("levels")


func go_to_modes() -> void:
	navigate("modes")


# ---------------------------------------------------------------- challenge ---
## Begins a run of any kind. The four public starters below all funnel through here,
## so `run_active`, the fade and the state change happen in exactly one place.
func _begin_run() -> bool:
	last_result = {}
	run_active = true
	run_finished = false
	var ok := navigate("kitchen")
	if not ok:
		run_active = false
		return false
	change_state(State.PLAYING)
	level_started.emit(current_level_id)
	return true


## The three story challenges.
func start_level(level_id: String) -> bool:
	mode = Mode.STORY
	current_level_id = level_id
	current_recipe_id = ""
	current_challenge = {}
	return _begin_run()


## Let's Cook: a chosen recipe, at the recipe's own difficulty.
func start_recipe(recipe_id: String, difficulty: int = -1) -> bool:
	var recipe := RecipeDB.recipe_by_id(recipe_id)
	if recipe.is_empty():
		push_warning("Game: no recipe named '%s'." % recipe_id)
		return false
	if _generator == null:
		_generator = ChallengeGenerator.new()
		_generator.begin(0)
	var challenge := _generator.build(recipe, difficulty)
	if challenge.is_empty() or not _generator.validate(challenge).is_empty():
		push_warning("Game: recipe '%s' could not be built into a challenge." % recipe_id)
		return false
	mode = Mode.COOK
	current_recipe_id = recipe_id
	current_challenge = challenge
	current_level_id = str(challenge.get("id", ""))
	return _begin_run()


## Endless Kitchen: begins a run and asks for the first challenge.
func start_endless() -> bool:
	mode = Mode.ENDLESS
	endless_streak = 0
	endless_score = 0
	return next_endless()


## The next challenge in an Endless run. Difficulty climbs gently with the streak
## so a good player keeps meeting new dishes, and the generator falls back safely
## when the pool runs thin.
func next_endless() -> bool:
	if _generator == null:
		_generator = ChallengeGenerator.new()
		_generator.begin(0)
	var difficulty := clampi(1 + endless_streak / 3, 1, 3)
	var challenge := _generator.next(difficulty, SaveData.discovered_ids(), true)
	if challenge.is_empty():
		push_warning("Game: the Endless Kitchen found nothing valid to cook.")
		mode = Mode.STORY
		return false
	current_challenge = challenge
	current_recipe_id = str(challenge.get("recipe_id", ""))
	current_level_id = str(challenge.get("id", ""))
	return _begin_run()


## Free Cook: an experimental dish, built from a fish and a method rather than a
## named recipe. It is always labelled experimental in the UI.
func start_free_cook(fish_id: String, method_id: String) -> bool:
	var challenge := RecipeDB.build_free_cook(fish_id, method_id)
	if challenge.is_empty():
		push_warning("Game: free cook could not build '%s' / '%s'." % [fish_id, method_id])
		return false
	mode = Mode.FREE_COOK
	current_recipe_id = ""
	current_challenge = challenge
	current_level_id = str(challenge.get("id", ""))
	return _begin_run()


## Restarts the current run from the beginning. Run data resets; saved progress
## (stars, best scores, discoveries, learning log) does not.
func restart_level() -> bool:
	if not current_challenge.is_empty():
		# Replay the same generated challenge rather than rolling a new one, so a
		# retry really is a retry.
		return _begin_run()
	if current_level_id.is_empty():
		return false
	return start_level(current_level_id)


## Called by the kitchen when the challenge is finished. Once this has run the
## score is frozen: no further points can be added.
func finish_level(result: Dictionary) -> void:
	if run_finished:
		return
	run_active = false
	run_finished = true
	last_result = result.duplicate(true)
	change_state(State.RESULT)
	level_finished.emit(current_level_id, last_result)


func abandon_level() -> void:
	run_active = false
	run_finished = false
	current_level_id = ""
	current_challenge = {}
	current_recipe_id = ""
	mode = Mode.STORY


# --------------------------------------------------------------------- pause ---
func pause() -> void:
	if state == State.PLAYING:
		change_state(State.PAUSED)


func resume() -> void:
	if state == State.PAUSED:
		change_state(State.PLAYING)


func toggle_pause() -> void:
	if state == State.PLAYING:
		pause()
	elif state == State.PAUSED:
		resume()


# --------------------------------------------------------------------- quit ---
func quit_game() -> void:
	AudioManager.stop_all()
	SaveData.save()
	Settings.save_settings()
	get_tree().quit()
