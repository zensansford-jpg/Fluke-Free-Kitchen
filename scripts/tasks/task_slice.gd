class_name SliceTask
extends KitchenTask
## Prepare an ingredient with the knife: `slice` chops vegetables or herbs and
## `prep_fish` cleans and scores the fish on the board.
##
## The interaction is the same in both cases and is deliberately forgiving: a
## sideways drag across the food counts as one cut, and a cut that starts on bare
## bench is ignored rather than punished. No pixel precision is required, and the
## result of every cut appears immediately — a cut line on the food and a small
## scatter of pieces — so the gesture explains itself without a sentence.

const CUT_MIN_PIXELS := 80.0
const BOARD_TOP := 0.075
## How far from the board's centre a press may land and still count.
const REACH_X := 0.8
const REACH_Z := 0.6

var _board: Node3D = null
var _food: Node3D = null
var _knife: Node3D = null
var _band: MeshInstance3D = null
var _board_top_y := 0.0
var _strokes := 3
var _done := 0
var _pressing := false
var _press_start := Vector2.ZERO
var _travelled := 0.0
var _ghost: GhostPointer = null
var _progress: ProgressBar = null
var _active := false
var _busy := false
var _mode := "chop"
## The colour of the food being cut, used to tint the knife line and the pieces.
var _pieces := StandardMaterial3D.new()


func begin() -> void:
	var kind := str(step.get("kind", "slice"))
	if kind == "prep_fish":
		_mode = "prep"
	else:
		_mode = str(step.get("mode", "chop"))
	_strokes = clampi(int(step.get("strokes", 3)), 1, 6)
	build_prompt_bar(gesture_hint_for(str(step.get("kind", "slice"))))
	_spawn()
	_build_progress()

	_ghost = GhostPointer.new()
	add_child(_ghost)
	if bool(step.get("demo", true)):
		_play_demo()
		run_demo_then(_enable, 2.2)
	else:
		_enable()


func _enable() -> void:
	_active = true


## Input is only accepted once the demonstration has finished, so nothing is asked
## of the player before they have seen what to do.
func is_accepting_input() -> bool:
	return _active and not settled


func abort() -> void:
	_active = false
	_pressing = false


func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.2)


# --------------------------------------------------------------------- the set ---
func _spawn() -> void:
	_board = KitchenProps.chopping_board(kitchen.set_root, kitchen.centre_slot(), false)
	_board_top_y = _board.global_position.y + BOARD_TOP

	if _mode == "prep":
		_food = KitchenProps.fish(_board, Vector3(0, 0.08, 0))
		_food.scale = Vector3(0.62, 0.5, 0.62)
		# Pieces of prepared fish: pale, so they read as flesh rather than vegetables.
		_pieces.albedo_color = Color(0.88, 0.75, 0.71)
	else:
		_food = _ingredient_visual()
		_food.position = Vector3(0, 0.07, 0)
		_pieces.albedo_color = _ingredient_colour()

	# A bright band across the board is the target: the thing to draw the knife
	# through. It says "cut here" with light instead of a sentence.
	_band = KitchenProps.glow_box(_board, Vector3(0.86, 0.02, 0.14),
		Vector3(0, 0.20, 0), Color(1.0, 0.86, 0.36), 1.05, "slice_target")

	_knife = KitchenProps.knife(kitchen.set_root, kitchen.centre_slot() + Vector3(0, 0.55, 0.5))
	_knife.visible = false


func _ingredient_visual() -> Node3D:
	var ingredient_id := str(step.get("ingredient", ""))
	if ingredient_id.is_empty():
		return KitchenProps.vegetable_pile(_board, Vector3.ZERO)
	# Use the ingredient's own colour and shape where the catalogue knows it, so the
	# thing being chopped is the thing the recipe asked for.
	var spec := RecipeDB.ingredient_by_id(ingredient_id)
	if not spec.is_empty():
		return KitchenProps.ingredient_mound(_board, Vector3.ZERO, _ingredient_colour())
	var trimmed := KitchenProps.visual_for(ingredient_id)
	_board.add_child(trimmed)
	return trimmed


## The catalogue colour of the ingredient on the board, or a leaf green for the
## generic vegetable pile.
func _ingredient_colour() -> Color:
	var spec := RecipeDB.ingredient_by_id(str(step.get("ingredient", "")))
	if spec.is_empty():
		return Color(0.45, 0.62, 0.34)
	var colour: Color = spec.get("colour", Color(0.45, 0.62, 0.34))
	return colour


func _build_progress() -> void:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 460.0, 130.0, -320.0)
	remember_box(panel, 460.0, 130.0, -320.0)
	var v := UIFactory.vbox(8)
	panel.add_child(v)
	var title := Loc.t("task.prep_fish") if _mode == "prep" else Loc.t("task.chop")
	v.add_child(UIFactory.label(title, 19, UIFactory.ACCENT, true))
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = float(_strokes)
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 22)
	UIFactory.style_progress(_progress, UIFactory.GOOD)
	v.add_child(_progress)
	add_child(panel)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(screen_position: Vector2) -> void:
	if not _active or settled or _busy:
		return
	var point := kitchen.pointer_on_plane(screen_position, _board_top_y + 0.12)
	if absf(point.x - _board.global_position.x) > REACH_X:
		return
	if absf(point.z - _board.global_position.z) > REACH_Z:
		return
	_pressing = true
	_press_start = screen_position
	_travelled = 0.0


func pointer_moved(screen_position: Vector2) -> void:
	if not _pressing:
		return
	_travelled = maxf(_travelled, absf(screen_position.x - _press_start.x))


func pointer_released(_screen_position: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false
	if _travelled >= CUT_MIN_PIXELS:
		_cut()


func _cut() -> void:
	if settled or _busy:
		return
	_busy = true
	_done += 1
	register_attempt()
	if _progress != null:
		_progress.value = float(_done)

	var z := lerpf(-0.18, 0.18, float(_done) / float(maxi(1, _strokes)))
	PropFactory.box(_food, Vector3(0.5, 0.006, 0.02), "hair", Vector3(0, 0.16, z))
	_scatter(z)
	_animate_knife()
	AudioManager.play_sfx("chop", 0.05)
	kitchen.play_effect("sparkle", _food.global_position + Vector3(0, 0.24, 0))

	if _done >= _strokes:
		_finish()
	else:
		_busy = false


## A couple of small pieces hop away from the cut line: the visible result of the
## action, so the player can see the ingredient has actually changed. The pieces are
## tinted with the food's own colour, so what falls away matches what was cut.
func _scatter(z: float) -> void:
	for side: float in [-1.0, 1.0]:
		var piece := MeshInstance3D.new()
		piece.mesh = PropFactory.unit_box()
		piece.material_override = _pieces
		piece.scale = Vector3(0.07, 0.05, 0.07)
		piece.position = Vector3(side * 0.18, 0.09, z)
		_board.add_child(piece)
		Anim.prop(piece, "position",
			piece.position + Vector3(side * 0.12, -0.03, 0.05), 0.25, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _animate_knife() -> void:
	if _knife == null or not is_instance_valid(_knife):
		return
	_knife.visible = true
	var base := kitchen.centre_slot()
	_knife.position = base + Vector3(-0.5, 0.34, 0.28)
	_knife.rotation_degrees = Vector3(0, 90, -20)
	var t := Anim.move_to(_knife, base + Vector3(0.5, 0.16, 0.28), 0.22, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	if t != null:
		t.tween_callback(func() -> void: _knife.visible = false)


func _finish() -> void:
	if settled:
		return
	_busy = true
	_band.visible = false
	Anim.scale_to(_food, _food.scale * Vector3(0.96, 0.9, 1.04), 0.3, Tween.TRANS_BACK, Tween.EASE_OUT)
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("sparkle", _food.global_position + Vector3(0, 0.3, 0))
	flash_message(Loc.t("feedback.prepped"), UIFactory.GOOD)
	await get_tree().create_timer(0.5, false).timeout
	succeed()


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or _board == null:
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0:
		return
	var centre := kitchen.world_to_screen(_board.global_position + Vector3(0, 0.2, 0))
	if centre.x < 0.0:
		centre = viewport * 0.5
	_ghost.play([
		Vector2(centre.x - 120.0, centre.y) / viewport,
		Vector2(centre.x + 120.0, centre.y) / viewport,
	])
