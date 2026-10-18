class_name ServeTask
extends KitchenTask
## The serving decision — a real choice made in the kitchen, not a question.
##
## The dish sits on the plate and the character waits. Two things can be done: serve
## it, or check it first. Which one is right depends on the state the recipe put the
## dish in:
##
##   * `safe`        — the fish was cooked through, so serving it is correct and the
##                     character celebrates.
##   * `undercooked` — a short situation ("this one came off the pan early"). Serving
##                     it is the mistake; checking it is the correct, careful action.
##
## The mistake branch keeps exposure risk, infection and cancer apart and offers a
## way straight back, so it teaches without ever trapping the player.

var _state := "safe"
var _plate: DropZone = null
var _probe: DropZone = null
var _pressed_zone: DropZone = null
var _active := false
var _served := false
var _sheet: PanelContainer = null
var _hint: Label = null
var _ghost: GhostPointer = null


func begin() -> void:
	_state = str(step.get("dish_state", "safe"))
	build_prompt_bar(gesture_hint_for("serve"))
	_spawn_plate()
	_spawn_probe()
	_build_panel()

	_ghost = GhostPointer.new()
	add_child(_ghost)
	if bool(step.get("demo", true)):
		_play_demo()
		run_demo_then(_enable, 2.0)
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
	_dismiss_sheet()


func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.1)


# --------------------------------------------------------------------- the set ---
func _spawn_plate() -> void:
	_plate = DropZone.new()
	_plate.name = "ServePlate"
	kitchen.set_root.add_child(_plate)
	_plate.position = Vector3(0.34, KitchenProps.BENCH_Y, 0.30)
	var hit := Vector3(0.72, 0.4, 0.72)
	_plate.configure("serve", hit, {"en": "Serve the dish", "th": "เสิร์ฟจานนี้"})
	_plate.set_visual(Color(0.95, 0.86, 0.5, 0.34))
	_plate.fit_visual_to(hit)
	var prop := KitchenProps.zone_prop("ready_plate")
	if prop != null:
		_plate.add_child(prop)
	var fish := KitchenProps.visual_for("cooked_fish")
	fish.position = Vector3(0, 0.12, 0)
	fish.scale = Vector3(0.6, 0.5, 0.6)
	_plate.add_child(fish)


func _spawn_probe() -> void:
	_probe = DropZone.new()
	_probe.name = "CheckProbe"
	kitchen.set_root.add_child(_probe)
	_probe.position = Vector3(-0.62, KitchenProps.BENCH_Y, 0.42)
	var hit := Vector3(0.5, 0.5, 0.5)
	_probe.configure("check", hit, {"en": "Check first", "th": "ตรวจก่อน"})
	_probe.set_visual(Color(0.5, 0.8, 0.95, 0.30))
	_probe.fit_visual_to(hit)
	# A slim probe with a red tip: the "look before you serve" tool.
	PropFactory.cyl(_probe, 0.02, 0.36, "steel", Vector3(0, 0.2, 0))
	PropFactory.sphere(_probe, 0.04, "sign_red", Vector3(0, 0.4, 0))


func _build_panel() -> void:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 460.0, 120.0, -320.0)
	remember_box(panel, 460.0, 120.0, -320.0)
	var v := UIFactory.vbox(6)
	panel.add_child(v)
	_hint = UIFactory.wrap(Loc.t("task.serve_or_check"), 19, UIFactory.ACCENT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_hint)
	add_child(panel)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(screen_position: Vector2) -> void:
	if not _active or settled or _served:
		return
	_pressed_zone = _zone_under(screen_position)


func pointer_released(screen_position: Vector2) -> void:
	if not _active or settled or _served:
		return
	var zone := _zone_under(screen_position)
	if zone == null or zone != _pressed_zone:
		_pressed_zone = null
		return
	_pressed_zone = null
	if zone.zone_id == "serve":
		_serve()
	else:
		_check()


func _zone_under(screen_position: Vector2) -> DropZone:
	var hit := kitchen.raycast_pointer(screen_position)
	if not bool(hit.get("hit", false)):
		return null
	var collider: Variant = hit.get("collider")
	if collider is DropZone:
		return collider
	return null


# --------------------------------------------------------------------- outcomes ---
func _serve() -> void:
	if _state == "safe":
		_serve_safe()
	else:
		_serve_unsafe()


func _serve_safe() -> void:
	_served = true
	_active = false
	register_attempt()
	AudioManager.play_sfx("star_full")
	kitchen.react("celebrate")
	kitchen.play_effect("sparkle", _plate.global_position + Vector3(0, 0.4, 0))
	flash_message(Loc.t("feedback.served_ready"), UIFactory.GOOD)
	await get_tree().create_timer(0.6, false).timeout
	succeed()


func _check() -> void:
	register_attempt()
	kitchen.react("think")
	if _state == "safe":
		# Checking a good dish is not wrong; it just is not necessary. A gentle
		# nudge, no mistake.
		show_reason(Loc.t("feedback.already_ready"), UIFactory.ACCENT)
		return
	_served = true
	_active = false
	AudioManager.play_sfx("tap_ok")
	kitchen.react("happy")
	flash_message(Loc.t("feedback.good_catch"), UIFactory.GOOD)
	await get_tree().create_timer(0.6, false).timeout
	succeed()


## Outcome B, in the serve step: the player chose to serve a fish that is not proven
## safe. The mistake is recorded, the message keeps exposure, infection and cancer
## apart, and "put it back" returns straight to the decision.
func _serve_unsafe() -> void:
	if _served:
		return
	register_mistake({"id": "served_unsafe"}, {"reason": "unsafe_serve"})
	AudioManager.play_sfx("tap_bad")
	kitchen.react("worried")
	kitchen.play_effect("smoke", _plate.global_position + Vector3(0, 0.2, 0))
	show_reason(Loc.t("feedback.unsafe_serve"), UIFactory.BAD)

	var body := UIFactory.vbox(10)
	body.add_child(UIFactory.wrap(Loc.t("task.unsafe_serve_detail"), 18, UIFactory.TEXT_DIM))
	var back := UIFactory.button(Loc.t("task.take_it_back"), 21, 280.0)
	UIFactory.style_button(back, UIFactory.ACCENT, true)
	back.pressed.connect(_dismiss_sheet)
	body.add_child(UIFactory.centre_row(back))
	_sheet = content_sheet(body, body, 560.0)


func _dismiss_sheet() -> void:
	if _sheet != null and is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = null


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or _probe == null or _plate == null:
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0:
		return
	var from := kitchen.world_to_screen(_probe.global_position + Vector3(0, 0.3, 0)) / viewport
	var to := kitchen.world_to_screen(_plate.global_position + Vector3(0, 0.3, 0)) / viewport
	if from.x < 0.0 or to.x < 0.0:
		from = Vector2(0.4, 0.56)
		to = Vector2(0.56, 0.56)
	_ghost.play([from, to])
