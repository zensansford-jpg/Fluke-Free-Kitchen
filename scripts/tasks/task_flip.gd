class_name FlipTask
extends KitchenTask
## Flip the fish in the pan — the signature action of the kitchen.
##
## The fish follows a real arc: it rises, turns over about the axis across its body,
## and lands back in the pan. When it lands its cooking state is nudged, because
## that is what a flip does; it never decides safety, which only the cook step does.
##
## Three inputs do the same thing, so nobody is left out: a tap on the fish, an
## upward swipe, or the on-screen Flip button. No motion sensor is involved, and the
## task never pretends one is.

## How far up the pointer must travel, in pixels, for a swipe to read as a flip.
const SWIPE_UP_PIXELS := 40.0
const REACH := 1.0

var _flips := 1
var _done := 0
var _fish: Node3D = null
var _candidate := false
var _press := Vector2.ZERO
var _flipping := false
var _active := false
var _wok_centre := Vector3.ZERO
var _progress: ProgressBar = null
var _button: Button = null
var _ghost: GhostPointer = null


func begin() -> void:
	_flips = clampi(int(step.get("flips", 1)), 1, 4)
	build_prompt_bar(gesture_hint_for("flip"))
	_fish = kitchen.place_fish_in_wok()
	_wok_centre = kitchen.wok_world_position()
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
	_flipping = false


func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.2)


# --------------------------------------------------------------------- the set ---
func _build_progress() -> void:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 460.0, 150.0, -320.0)
	remember_box(panel, 460.0, 150.0, -320.0)
	var v := UIFactory.vbox(8)
	panel.add_child(v)
	v.add_child(UIFactory.label(Loc.t("task.flip"), 19, UIFactory.ACCENT, true))
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = float(_flips)
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 22)
	UIFactory.style_progress(_progress, UIFactory.GOOD)
	v.add_child(_progress)

	# The accessible fallback. A player on a keyboard, or simply unsure of the
	# gesture, gets the same result as a swipe.
	_button = UIFactory.button(Loc.t("task.flip_button"), 20, 220.0)
	UIFactory.style_button(_button, UIFactory.ACCENT, true)
	_button.pressed.connect(_do_flip)
	v.add_child(UIFactory.centre_row(_button))
	add_child(panel)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(screen_position: Vector2) -> void:
	if not _active or settled or _flipping:
		return
	var point := kitchen.pointer_on_plane(screen_position, _wok_centre.y + 0.3)
	var offset := Vector2(point.x - _wok_centre.x, point.z - _wok_centre.z)
	_candidate = offset.length() <= REACH
	_press = screen_position


func pointer_released(screen_position: Vector2) -> void:
	if not _candidate:
		return
	_candidate = false
	# A tap and an upward swipe both read as "flip it".
	var upward := _press.y - screen_position.y
	if upward >= 0.0 or absf(screen_position.x - _press.x) < 24.0:
		_do_flip()


func _do_flip() -> void:
	if not _active or settled or _flipping:
		return
	_flipping = true
	register_attempt()
	AudioManager.play_sfx("sweep", 0.04)
	if _fish == null or not is_instance_valid(_fish):
		_on_flip_done()
		return
	var start_y := _fish.position.y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_fish, "position:y", 0.62, 0.26)
	tween.parallel().tween_property(_fish, "position:z", -0.10, 0.26)
	tween.parallel().tween_property(_fish, "rotation:x", -PI, 0.26)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_fish, "position:y", start_y, 0.24)
	tween.parallel().tween_property(_fish, "position:z", 0.0, 0.24)
	tween.parallel().tween_property(_fish, "rotation:x", -TAU, 0.24)
	tween.tween_callback(_on_flip_done)


func _on_flip_done() -> void:
	_flipping = false
	_done += 1
	if _progress != null:
		_progress.value = float(_done)
	# A flip moves the fish onto its other side, so the cooking continues on the
	# surface that was facing the pan. This is presentation only.
	kitchen.set_fish_browning(minf(1.2, 0.2 * float(_done)))
	AudioManager.play_sfx("pop", 0.04)
	kitchen.play_effect("steam", _wok_centre + Vector3(0, 0.2, 0))
	if _done >= _flips:
		_finish()


func _finish() -> void:
	if settled:
		return
	_active = false
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("sparkle", _wok_centre + Vector3(0, 0.34, 0))
	flash_message(Loc.t("feedback.flipped"), UIFactory.GOOD)
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
	var point := kitchen.world_to_screen(_wok_centre + Vector3(0, 0.25, 0))
	if point.x < 0.0:
		point = viewport * Vector2(0.68, 0.62)
	# A short upward swipe over the pan, then back down: the gesture to copy.
	_ghost.play([
		(point + Vector2(0, 40)) / viewport,
		(point - Vector2(0, 60)) / viewport,
	])
