class_name SwipeCleanTask
extends KitchenTask
## Swipe across the chopping board to wash it clean.
##
## The board carries a layer of grime whose opacity follows how much of the
## surface the player has actually scrubbed. Coverage is measured on a small grid
## and samples are interpolated between frames, so a fast swipe does not leave a
## trail of "missed" squares behind it — the measurement follows the intent.

const BOARD_WIDTH := 0.95
const BOARD_DEPTH := 0.62
const BOARD_TOP := 0.075
const COLS := 5
const ROWS := 3
## Radius of the scrubbing motion, in metres.
const BRUSH := 0.075

var _board: Node3D = null
var _grime: MeshInstance3D = null
var _grime_material: StandardMaterial3D = null
var _board_top_y := 0.0
var _cells: Dictionary = {}
var _coverage := 0.0
var _required := 0.85
var _pressing := false
var _has_last := false
var _last_point := Vector3.ZERO
var _progress: ProgressBar = null
var _ghost: GhostPointer = null
var _active := false
var _scrub_cooldown := 0.0
## Whether the running-water bed is playing, so the gesture only reaches the audio
## manager when it changes.
var _watering := false


func begin() -> void:
	_required = clampf(float(step.get("coverage", 0.85)), 0.4, 1.0)
	build_prompt_bar(gesture_hint_for("swipe_clean"))
	_spawn_board()
	_build_progress()

	_ghost = GhostPointer.new()
	add_child(_ghost)
	if bool(step.get("demo", false)):
		_play_demo()
		run_demo_then(_enable, 2.6)
	else:
		_enable()


func _enable() -> void:
	_active = true


## Input is only accepted once the demonstration has finished, so nothing is asked
## of the player before they have seen what to do.
func is_accepting_input() -> bool:
	return _active and not settled


## Re-plays the sweeping demonstration on request.
func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.4)


func abort() -> void:
	_active = false
	_set_water(false)


func _exit_tree() -> void:
	# The running water belongs to this step; leaving it always turns the tap off.
	_set_water(false)
	super._exit_tree()


## Running water sits under the scrub hits while the player is working the board, so
## the wash reads as a continuous action rather than a series of taps.
func _set_water(on: bool) -> void:
	if on == _watering:
		return
	_watering = on
	if on:
		AudioManager.play_loop("loop_wash", -14.0)
	else:
		AudioManager.stop_loop("loop_wash")


# --------------------------------------------------------------------- the set ---
func _spawn_board() -> void:
	_board = KitchenProps.chopping_board(kitchen.set_root, kitchen.centre_slot(), true)
	_board_top_y = _board.global_position.y + BOARD_TOP
	_grime = _board.get_node_or_null("Grime") as MeshInstance3D
	if _grime != null:
		_grime_material = _grime.material_override as StandardMaterial3D


func _build_progress() -> void:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 520.0, 120.0)
	remember_box(panel, 520.0, 120.0)
	var v := UIFactory.vbox(8)
	panel.add_child(v)
	v.add_child(UIFactory.label(Loc.t("task.clean_all"), 19, UIFactory.ACCENT, true))
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 22)
	UIFactory.style_progress(_progress, UIFactory.GOOD)
	v.add_child(_progress)
	add_child(panel)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(screen_position: Vector2) -> void:
	if not _active or settled:
		return
	_pressing = true
	_has_last = false
	_set_water(true)
	_scrub(screen_position)


func pointer_moved(screen_position: Vector2) -> void:
	if not _active or settled or not _pressing:
		return
	_scrub(screen_position)


func pointer_released(_screen_position: Vector2) -> void:
	_pressing = false
	_has_last = false
	_set_water(false)


func _scrub(screen_position: Vector2) -> void:
	var point := kitchen.pointer_on_plane(screen_position, _board_top_y)
	if _has_last:
		var distance := _last_point.distance_to(point)
		var steps := clampi(int(ceil(distance / BRUSH)), 1, 14)
		for i in range(1, steps + 1):
			_paint(_last_point.lerp(point, float(i) / float(steps)))
	else:
		_paint(point)
	_last_point = point
	_has_last = true

	_scrub_cooldown = maxf(0.0, _scrub_cooldown - 0.02)
	if _scrub_cooldown <= 0.0 and _coverage < _required:
		AudioManager.play_sfx("scrub")
		_scrub_cooldown = 0.24


func _paint(point: Vector3) -> void:
	if _board == null:
		return
	var local := point - _board.global_position
	var half_w := BOARD_WIDTH * 0.5
	var half_d := BOARD_DEPTH * 0.5
	if absf(local.x) > half_w + BRUSH or absf(local.z) > half_d + BRUSH:
		return

	var col := clampi(int(floor((local.x + half_w) / BOARD_WIDTH * float(COLS))), 0, COLS - 1)
	var row := clampi(int(floor((local.z + half_d) / BOARD_DEPTH * float(ROWS))), 0, ROWS - 1)
	var key := row * COLS + col
	if _cells.has(key):
		return

	_cells[key] = true
	var before := _coverage
	_coverage = float(_cells.size()) / float(COLS * ROWS)
	_apply_wear()
	if _coverage > before:
		kitchen.play_effect("clean", point + Vector3(0, 0.08, 0))
	if _coverage >= _required:
		_finish()


func _apply_wear() -> void:
	if _grime_material != null:
		_grime_material.albedo_color.a = clampf(1.0 - _coverage / maxf(_required, 0.01), 0.0, 1.0)
	if _progress != null:
		_progress.value = _coverage


func _finish() -> void:
	if settled:
		return
	_set_water(false)
	if _grime != null:
		_grime.visible = false
	AudioManager.play_sfx("wash")
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("clean", _board.global_position + Vector3(0, 0.25, 0))
	kitchen.play_effect("splash", _board.global_position + Vector3(0, 0.1, 0))
	flash_message(Loc.t("feedback.cleaned"), UIFactory.GOOD)
	await get_tree().create_timer(0.6, false).timeout
	succeed()


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or _board == null:
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0:
		return
	var centre := kitchen.world_to_screen(_board.global_position + Vector3(0, 0.09, 0))
	if centre.x < 0.0:
		centre = viewport * 0.5
	var points: Array = []
	for row in 3:
		var y := centre.y - 24.0 + float(row) * 24.0
		points.append(Vector2(centre.x - 115.0, y) / viewport)
		points.append(Vector2(centre.x + 115.0, y) / viewport)
	_ghost.play(points)
