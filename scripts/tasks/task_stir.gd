class_name StirTask
extends KitchenTask
## Stir the pot: the player moves the pointer in circles and the mixture responds.
##
## The gesture is measured by the angle the pointer sweeps around the pot, not by
## how far it travels, so a small confident circle and a big lazy one both count and
## a straight wiggle does not. Each completed turn is one circle; the step asks for
## a small number of them, so there is no endless grinding.

## Radius around the pot centre, in metres, inside which a pointer counts as stirring.
const REACH := 0.55
## Largest angle step accepted in one frame, to reject pointer jumps.
const MAX_STEP := 0.55
## How far above the vessel's rim the mound of food sits. The rim is the vessel's own
## origin (see `KitchenProps.bowl`), so a small lift puts the mixture *in* the pan
## with only its top heaped over the lip.
const MIXTURE_LIFT := 0.04

var _circles := 3
var _swept := 0.0
var _last_angle := 0.0
var _has_angle := false
var _pressing := false
var _centre := Vector3.ZERO
var _top_y := 0.0
var _mixture: MeshInstance3D = null
var _spoon: Node3D = null
var _progress: ProgressBar = null
var _ghost: GhostPointer = null
var _active := false
var _busy := false


func begin() -> void:
	_circles = clampi(int(step.get("circles", 3)), 1, 6)
	build_prompt_bar(gesture_hint_for("stir"))
	_spawn()
	_build_progress()

	_ghost = GhostPointer.new()
	add_child(_ghost)
	if bool(step.get("demo", true)):
		_play_demo()
		run_demo_then(_enable, 2.4)
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
	var vessel := str(step.get("vessel", "wok"))
	if vessel == "wok" and kitchen.wok() != null:
		_centre = kitchen.wok_world_position()
	else:
		# A mixing bowl for the pan-less case. Its anchor is the rim, which is what the
		# pointer circles around and what the mixture is heaped into.
		var bowl_node := KitchenProps.bowl(kitchen.set_root, 0.34, "sign_white",
			kitchen.centre_slot() + Vector3(0, KitchenProps.bowl_rim(0.34), 0))
		_centre = bowl_node.global_position
	_top_y = _centre.y + 0.18

	_mixture = PropFactory.sphere(kitchen.set_root, 0.24, "sign_white",
		_centre + Vector3(0, MIXTURE_LIFT, 0), Vector3(1.0, 0.42, 1.0))
	_spoon = KitchenProps.knife(kitchen.set_root, _centre + Vector3(0.3, 0.22, 0))
	_spoon.rotation_degrees = Vector3(90, 0, 0)


func _build_progress() -> void:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 440.0, 130.0, -330.0)
	remember_box(panel, 440.0, 130.0, -330.0)
	var v := UIFactory.vbox(8)
	panel.add_child(v)
	v.add_child(UIFactory.label(Loc.t("task.stir"), 19, UIFactory.ACCENT, true))
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = float(_circles)
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 22)
	UIFactory.style_progress(_progress, UIFactory.GOOD)
	v.add_child(_progress)
	add_child(panel)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(_screen_position: Vector2) -> void:
	if not _active or settled or _busy:
		return
	_pressing = true
	_has_angle = false


func pointer_released(_screen_position: Vector2) -> void:
	_pressing = false
	_has_angle = false


func pointer_moved(screen_position: Vector2) -> void:
	if not _pressing or settled:
		return
	var point := kitchen.pointer_on_plane(screen_position, _top_y)
	var offset := Vector2(point.x - _centre.x, point.z - _centre.z)
	if offset.length() > REACH:
		_has_angle = false
		return
	var angle := atan2(offset.y, offset.x)
	if _has_angle:
		var step_angle := wrapf(angle - _last_angle, -PI, PI)
		if absf(step_angle) <= MAX_STEP:
			_swept += absf(step_angle)
			_stirred(step_angle)
	_last_angle = angle
	_has_angle = true
	if _progress != null:
		_progress.value = minf(float(_circles), _swept / TAU)
	if _swept >= float(_circles) * TAU:
		_finish()


func _stirred(delta: float) -> void:
	if _spoon != null and is_instance_valid(_spoon):
		_spoon.rotation.y += delta
	if _mixture != null and is_instance_valid(_mixture):
		_mixture.rotation.y += delta * 1.4
		# The surface rolls a little: the mixture visibly reacts to the movement.
		_mixture.position.y = _centre.y + MIXTURE_LIFT + sin(_swept * 2.0) * 0.012


func _finish() -> void:
	if settled or _busy:
		return
	_busy = true
	_active = false
	AudioManager.play_sfx("stir")
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("bubble", _centre + Vector3(0, 0.28, 0))
	flash_message(Loc.t("feedback.stirred"), UIFactory.GOOD)
	await get_tree().create_timer(0.5, false).timeout
	succeed()


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0:
		return
	var centre := kitchen.world_to_screen(_centre + Vector3(0, 0.2, 0))
	if centre.x < 0.0:
		centre = viewport * 0.5
	var points: Array = []
	for i in 13:
		var a := float(i) / 12.0 * TAU
		points.append(Vector2(centre.x + cos(a) * 74.0, centre.y + sin(a) * 44.0) / viewport)
	_ghost.play(points)
