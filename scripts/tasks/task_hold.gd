class_name HoldTask
extends KitchenTask
## Two gestures that share one idea: keeping the heat on.
##
##   `hold`          — press and hold until a ring fills. Used to heat the pan.
##   `cook_through`  — hold to raise the temperature inside the fish, then keep
##                     holding while it stays at or above the safe temperature.
##
## The second one is the reason this class exists. The player cannot pass it by
## tapping quickly or by holding forever without watching: the fish has to reach a
## safe internal temperature (63 °C, from the CDC guidance in docs/REFERENCES.md)
## and stay there long enough. Letting go early simply cools the fish down, which
## is a demonstration of the point rather than a punishment.

const KIND_HOLD := "hold"
const KIND_COOK := "cook_through"

var _kind := KIND_HOLD
var _holding := false
var _active := false

var _duration := 2.0
var _success_sound := "sizzle"

var _temperature := GameConfig.COOK_START_TEMP_C
var _safe_temperature := GameConfig.COOK_SAFE_TEMP_C
var _safe_needed := GameConfig.COOK_HOLD_SECONDS
var _safe_time := 0.0
var _reached_safe := false
var _warned_early := false
## How far the surface of the fish has coloured. Presentation only: nothing in the
## pass/fail logic reads it, and the panel says so.
var _browning := 0.0
var _burnt := false
var _burnt_sheet: PanelContainer = null
## Outcome B. True once the player has chosen to serve a fish whose inside is not
## proven safe. Like the burnt outcome it can only happen by a deliberate choice:
## there is no path through the cook that serves undercooked fish by accident.
var _served_unsafe := false
var _serve_sheet: PanelContainer = null
## The temperature panel, kept so the burnt outcome can take the screen and give it
## back: two panels on top of each other would hide the explanation behind meters
## that no longer mean anything.
var _cook_panel: PanelContainer = null

var _ring: RingProgress = null
var _temperature_bar: ProgressBar = null
var _safe_bar: ProgressBar = null
var _temperature_label: Label = null
var _bar_at_safe := false
var _ghost: GhostPointer = null


func begin() -> void:
	_kind = str(step.get("kind", KIND_HOLD))
	_duration = maxf(0.4, float(step.get("duration", 2.0)))
	_success_sound = str(step.get("success_sound", "sizzle"))
	_safe_temperature = clampf(float(step.get("safe_temp", GameConfig.COOK_SAFE_TEMP_C)),
		GameConfig.COOK_START_TEMP_C, GameConfig.COOK_MAX_TEMP_C)
	_safe_needed = maxf(0.5, float(step.get("hold_seconds", GameConfig.COOK_HOLD_SECONDS)))
	_temperature = GameConfig.COOK_START_TEMP_C
	_browning = 0.0
	_burnt = false
	_served_unsafe = false

	build_prompt_bar(gesture_hint_for(_kind))
	if _kind == KIND_COOK:
		kitchen.place_fish_in_wok()
		_build_cook_panel()
	else:
		_build_hold_panel()

	_ghost = GhostPointer.new()
	add_child(_ghost)
	if bool(step.get("demo", false)):
		_play_demo()
		run_demo_then(_enable, 2.6)
	else:
		_enable()

	set_process(true)


func _enable() -> void:
	_active = true


## Input is only accepted once the demonstration has finished, so nothing is asked
## of the player before they have seen what to do.
func is_accepting_input() -> bool:
	return _active and not settled


## Re-plays the press-and-hold demonstration on request.
func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.5)


func abort() -> void:
	_active = false
	_holding = false
	_burnt = false
	_served_unsafe = false


# --------------------------------------------------------------------- panels ---
func _build_hold_panel() -> void:
	# The press-and-hold panel is a content-fitted bottom sheet rather than a fixed
	# box. A ring and a prompt come out taller than the old 190 pixel box on a small
	# screen, and a box that asks for less height than its content needs hangs off
	# the bottom edge; the sheet measures itself instead.
	var body := UIFactory.vbox(6)
	var prompt := UIFactory.wrap(Loc.t("task.press_stove"), 19, UIFactory.ACCENT, true)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(prompt)

	_ring = RingProgress.new()
	_ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(_ring)

	content_sheet(body, body, 340.0, -300.0)


func _build_cook_panel() -> void:
	# The cook panel is content-fitted, not a fixed box: the safe-level line, the two
	# meters and the two pieces of guidance genuinely need more than 300 pixels on a
	# 320 pixel phone, and a box shorter than its content would hang off the bottom
	# edge. The sheet measures itself and stays on screen at every size.
	var v := UIFactory.vbox(8)

	# The caption and the reading share a line; the safe level sits on its own line.
	# Stacking them is what keeps the panel narrow enough for a 320 pixel phone: the
	# old single row put four labels side by side and asked for 385 pixels of width.
	var header := UIFactory.hbox(10)
	var caption := UIFactory.wrap(Loc.t("task.temperature"), 19, UIFactory.TEXT_DIM)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(caption)
	_temperature_label = UIFactory.label("%.0f°C" % _temperature, 22, UIFactory.ACCENT, true)
	header.add_child(_temperature_label)
	v.add_child(header)
	v.add_child(UIFactory.wrap(Loc.t("task.safe_zone") + " ≥ %.0f°C" % _safe_temperature,
		18, UIFactory.GOOD, true))

	_temperature_bar = ProgressBar.new()
	# The bar starts at 0 °C rather than at the starting temperature: a meter that
	# sits at zero when nothing has happened yet reads as "not working", and the
	# player should see the fish warm up from cold.
	_temperature_bar.min_value = 0.0
	_temperature_bar.max_value = GameConfig.COOK_MAX_TEMP_C
	_temperature_bar.value = _temperature
	_temperature_bar.show_percentage = false
	_temperature_bar.custom_minimum_size = Vector2(0, 26)
	UIFactory.style_progress(_temperature_bar, UIFactory.ACCENT)
	v.add_child(_temperature_bar)

	# The "keep holding" hint sits above the one deliberate way out of the step:
	# serving the fish before it is safe. Keeping the button on its own centred row
	# rather than beside the hint is what lets both fit a phone: side by side they
	# summed to more width than a 320 pixel screen has, and the choice is what
	# outcome B exists to teach.
	var keep_hint := UIFactory.wrap(Loc.t("task.keep_holding"), 18, UIFactory.TEXT_DIM)
	v.add_child(keep_hint)
	var serve := UIFactory.button(Loc.t("task.serve_now"), 17, 150.0)
	UIFactory.style_button(serve, UIFactory.BAD, false)
	serve.pressed.connect(_serve_unsafe)
	v.add_child(UIFactory.centre_row(serve))
	_safe_bar = ProgressBar.new()
	_safe_bar.min_value = 0.0
	_safe_bar.max_value = _safe_needed
	_safe_bar.value = 0.0
	_safe_bar.show_percentage = false
	_safe_bar.custom_minimum_size = Vector2(0, 24)
	UIFactory.style_progress(_safe_bar, UIFactory.GOOD)
	v.add_child(_safe_bar)

	# The fish visibly browns as it cooks. That is a nice thing to watch and a bad
	# thing to trust, so the panel says which measurement actually matters.
	v.add_child(UIFactory.wrap(Loc.t("task.colour_not_proof"), 15, UIFactory.TEXT_DIM))

	_cook_panel = content_sheet(v, v, 470.0, -310.0)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(_screen_position: Vector2) -> void:
	if not _active or settled:
		return
	_holding = true


func pointer_released(_screen_position: Vector2) -> void:
	if not _holding:
		return
	_holding = false
	if _kind == KIND_COOK and _reached_safe and not settled and not _warned_early:
		_warned_early = true
		show_reason(Loc.t("feedback.released_early"), UIFactory.ACCENT)


func _process(delta: float) -> void:
	if not _active or settled:
		return

	if _kind == KIND_HOLD:
		if _holding:
			_hold_progress(delta)
		return

	_cook_progress(delta)


func _hold_progress(delta: float) -> void:
	if _ring != null:
		_ring.value = minf(1.0, _ring.value + delta / _duration)
	kitchen.set_wok_heat(_ring.value if _ring != null else 0.0)
	if _ring != null and _ring.value > 0.35:
		kitchen.puff_steam(kitchen.wok_world_position(), 0.3)
	if _ring != null and _ring.value >= 1.0:
		_finish_hold()


func _cook_progress(delta: float) -> void:
	if _holding:
		_temperature = minf(GameConfig.COOK_MAX_TEMP_C, _temperature + GameConfig.COOK_HEAT_RATE * delta)
	else:
		_temperature = maxf(GameConfig.COOK_START_TEMP_C, _temperature - GameConfig.COOK_COOL_RATE * delta)

	# Surface browning, from how hot the pan has been for how long. This is the
	# picture, not the test: it never feeds back into the safety check below.
	var heat := inverse_lerp(GameConfig.COOK_SEAR_TEMP_C, GameConfig.COOK_MAX_TEMP_C, _temperature)
	if heat > 0.0:
		_browning += GameConfig.COOK_BROWN_RATE * heat * delta
		kitchen.set_fish_browning(_browning)
	if _browning >= GameConfig.COOK_BURNT_AT:
		_burn_the_fish()
		return

	var at_safe := _temperature >= _safe_temperature
	if _holding and at_safe:
		_safe_time = min(_safe_needed, _safe_time + delta)
	elif not at_safe:
		# Cooling down loses ground, but never all of it in one go.
		_safe_time = maxf(0.0, _safe_time - delta * 0.35)

	if at_safe and not _reached_safe:
		_reached_safe = true
		AudioManager.play_sfx("sizzle")
		kitchen.play_effect("steam", kitchen.wok_world_position())

	_update_cook_ui()
	kitchen.set_wok_heat(inverse_lerp(GameConfig.COOK_START_TEMP_C, GameConfig.COOK_MAX_TEMP_C, _temperature))
	if _temperature > 40.0:
		kitchen.puff_steam(kitchen.wok_world_position(), 0.26)

	if _safe_time >= _safe_needed:
		_finish_cook()


func _update_cook_ui() -> void:
	if _temperature_bar != null:
		_temperature_bar.value = _temperature
	if _safe_bar != null:
		_safe_bar.value = _safe_time
	var at_safe := _temperature >= _safe_temperature
	if _temperature_label != null:
		_temperature_label.text = "%.0f°C" % _temperature
		_temperature_label.add_theme_color_override("font_color", UIFactory.GOOD if at_safe else UIFactory.ACCENT)
	# The meter itself turns green the moment the fish is safe, so the message is
	# carried by colour as well as by the number.
	if at_safe != _bar_at_safe and _temperature_bar != null:
		_bar_at_safe = at_safe
		UIFactory.style_progress(_temperature_bar, UIFactory.GOOD if at_safe else UIFactory.ACCENT)


# --------------------------------------------------------------------- outcomes ---
func _finish_hold() -> void:
	AudioManager.play_sfx(_success_sound)
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("steam", kitchen.wok_world_position())
	flash_message(Loc.t("task.pan_ready"), UIFactory.GOOD)
	await get_tree().create_timer(0.5, false).timeout
	succeed()


func _finish_cook() -> void:
	AudioManager.play_sfx("sizzle")
	AudioManager.play_sfx("star_full")
	kitchen.react("celebrate")
	kitchen.play_effect("sparkle", kitchen.wok_world_position() + Vector3(0, 0.3, 0))
	flash_message(Loc.t("feedback.cooked"), UIFactory.GOOD)
	await get_tree().create_timer(0.6, false).timeout
	succeed()


## Outcome C: the surface burnt before the inside was safely cooked. The step stops,
## says what happened, and offers a quick retry of the same fish — the lesson is
## "watch the heat", not "start the challenge over".
##
## The mistake is recorded before the retry is offered, so retrying is a fair way to
## continue and never a way to erase what happened.
func _burn_the_fish() -> void:
	if _burnt:
		return
	_burnt = true
	_active = false
	_holding = false
	register_mistake({"id": "burnt"}, {"reason": "burnt"})
	AudioManager.play_sfx("tap_bad")
	kitchen.react("worried")
	kitchen.play_effect("smoke", kitchen.wok_world_position() + Vector3(0, 0.2, 0))
	kitchen.shake(0.05)
	show_reason(Loc.t("feedback.burnt"), UIFactory.BAD)
	if _cook_panel != null and is_instance_valid(_cook_panel):
		_cook_panel.visible = false

	var body := UIFactory.vbox(10)
	body.add_child(UIFactory.wrap(Loc.t("task.burnt_detail"), 18, UIFactory.TEXT_DIM))
	var again := UIFactory.button(Loc.t("task.retry_cook"), 21, 280.0)
	UIFactory.style_button(again, UIFactory.ACCENT, true)
	again.pressed.connect(_restart_cook)
	body.add_child(UIFactory.centre_row(again))
	_burnt_sheet = content_sheet(body, body, 560.0)


## Outcome B: the player chooses to serve the fish before the inside is proven safe.
##
## The step stops and says what serving it would mean — plainly, in words, with no
## picture of anyone being ill, which is why this is written as a risk and not as an
## illness. The message keeps three separate things separate: being exposed to the
## larvae, being infected, and getting cancer.
##
## Two ways out are offered, so the message is skippable rather than a wall: start a
## fresh fish, or simply take this one back and keep cooking it. The mistake is
## recorded first, so neither way erases it.
func _serve_unsafe() -> void:
	if _served_unsafe or settled or not _active:
		return
	_served_unsafe = true
	_active = false
	_holding = false
	register_mistake({"id": "served_unsafe"}, {"reason": "unsafe_serve"})
	AudioManager.play_sfx("tap_bad")
	kitchen.react("worried")
	kitchen.play_effect("smoke", kitchen.wok_world_position() + Vector3(0, 0.16, 0))
	show_reason(Loc.t("feedback.unsafe_serve"), UIFactory.BAD)
	if _cook_panel != null and is_instance_valid(_cook_panel):
		_cook_panel.visible = false

	var body := UIFactory.vbox(10)
	body.add_child(UIFactory.wrap(Loc.t("task.unsafe_serve_detail"), 18, UIFactory.TEXT_DIM))
	var again := UIFactory.button(Loc.t("task.retry_cook"), 21, 280.0)
	UIFactory.style_button(again, UIFactory.ACCENT, true)
	again.pressed.connect(_restart_cook)
	var keep := UIFactory.button(Loc.t("task.keep_cooking"), 19, 280.0)
	UIFactory.style_button(keep, UIFactory.TEXT_DIM, false)
	keep.pressed.connect(_resume_cook)
	body.add_child(UIFactory.centre_row(again))
	body.add_child(UIFactory.centre_row(keep))
	_serve_sheet = content_sheet(body, body, 560.0)


## Dismisses the unsafe-serving message and hands the same undercooked fish back:
## the player chose to keep cooking rather than start over.
func _resume_cook() -> void:
	if _serve_sheet != null and is_instance_valid(_serve_sheet):
		_serve_sheet.queue_free()
	_serve_sheet = null
	_served_unsafe = false
	if _cook_panel != null and is_instance_valid(_cook_panel):
		_cook_panel.visible = true
	_update_cook_ui()
	_active = true


## Puts a raw fish back in the pan and resets the heat, the timer and the colour.
func _restart_cook() -> void:
	if _burnt_sheet != null and is_instance_valid(_burnt_sheet):
		_burnt_sheet.queue_free()
	_burnt_sheet = null
	if _serve_sheet != null and is_instance_valid(_serve_sheet):
		_serve_sheet.queue_free()
	_serve_sheet = null
	_served_unsafe = false
	_burnt = false
	_temperature = GameConfig.COOK_START_TEMP_C
	_browning = 0.0
	_safe_time = 0.0
	_reached_safe = false
	_warned_early = false
	kitchen.place_fish_in_wok()
	if _cook_panel != null and is_instance_valid(_cook_panel):
		_cook_panel.visible = true
	_update_cook_ui()
	_active = true


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0:
		return
	var point := kitchen.world_to_screen(kitchen.wok_world_position() + Vector3(0, 0.25, 0))
	if point.x < 0.0:
		point = viewport * Vector2(0.68, 0.62)
	var normalised := point / viewport
	_ghost.play([normalised, normalised], true)
