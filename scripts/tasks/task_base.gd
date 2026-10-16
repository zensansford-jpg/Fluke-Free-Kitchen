class_name KitchenTask
extends Control
## Base class for every interactive step in a challenge.
##
## A task is a `Control` that the step runner adds on top of the kitchen. Two
## families exist:
##   * text tasks (choose an option, order steps, tick a checklist) build their
##     own panel and use buttons;
##   * physical tasks (drag, swipe, hold) leave the screen transparent and use
##     `_unhandled_input` plus the camera from `kitchen` to manipulate the 3D set.
##
## A task never scores itself and never advances the level: it reports what
## happened through signals and the runner decides what it means. That keeps the
## scoring rules in one place (`KitchenSession`) and makes every task testable on
## its own.

signal finished(success: bool)
## Emitted whenever the player does something unsafe or incorrect. The runner
## uses it to log the mistake and to show the explanation that came with it.
signal mistake(made: Dictionary)

var step: Dictionary = {}
## The `KitchenScene` this task is running inside. Physical tasks use its camera,
## its bench slots and its effects.
var kitchen: KitchenScene = null
## The challenge HUD. Text tasks put their instruction bar in the HUD's prompt
## slot, which is what keeps the bar and the HUD controls from ever overlapping on
## a narrow screen.
var hud: KitchenHUD = null

var attempts := 0
var mistakes := 0
## True once a correct answer has been given; guards against double scoring.
var settled := false

var _reason_panel: PanelContainer = null
## The stacked area under the HUD: instruction bar, demo banner, correction.
var _prompt_area: VBoxContainer = null
## Bottom boxes that must be re-placed when the window is resized.
var _boxes: Array = []
## Content-fitted bottom sheets that must be re-measured when the window resizes.
var _sheets: Array = []


func _ready() -> void:
	UIFactory.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_area = UIFactory.vbox(8)
	_prompt_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if hud != null and hud.prompt_slot != null:
		hud.prompt_slot.add_child(_prompt_area)
	else:
		# A task built without a kitchen screen (tests, tools) still gets a
		# sensible place to put its instruction bar.
		_prompt_area.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_prompt_area.offset_left = 24.0
		_prompt_area.offset_right = -24.0
		_prompt_area.offset_top = 108.0
		_prompt_area.offset_bottom = 380.0
		add_child(_prompt_area)


func _exit_tree() -> void:
	if _prompt_area != null and is_instance_valid(_prompt_area):
		_prompt_area.queue_free()


# ----------------------------------------------------------------- pointer input ---
## Physical tasks implement these three callbacks. The base translates mouse and
## touch events into them, so a drag behaves identically on a desktop and on a
## phone without every task repeating the event plumbing.
func pointer_pressed(_screen_position: Vector2) -> void:
	pass


func pointer_moved(_screen_position: Vector2) -> void:
	pass


func pointer_released(_screen_position: Vector2) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			pointer_pressed(button.position)
		else:
			pointer_released(button.position)
		accept_event()
	elif event is InputEventMouseMotion:
		pointer_moved((event as InputEventMouseMotion).position)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			pointer_pressed(touch.position)
		else:
			pointer_released(touch.position)
		accept_event()
	elif event is InputEventScreenDrag:
		pointer_moved((event as InputEventScreenDrag).position)


# --------------------------------------------------------------------- content ---
func step_id() -> String:
	return str(step.get("id", ""))


func prompt_text() -> String:
	return LessonDB.local(step.get("prompt"))


func corrects() -> Array:
	return step.get("corrects", [])


func lesson_id() -> String:
	return str(step.get("lesson", ""))


# ------------------------------------------------------------------- lifecycle ---
## Called by the runner once the task is in the tree and the 3D set is built.
func begin() -> void:
	pass


## Called when the task is being discarded (restart, pause-quit, level end).
func abort() -> void:
	pass


# -------------------------------------------------------------------- outcomes ---
func succeed() -> void:
	if settled:
		return
	settled = true
	finished.emit(true)


## Reports a wrong choice. `option` is the dictionary the player tapped, which
## usually carries its own `why` explanation; `reason` is the signal the runner
## shows to the player.
func register_mistake(option: Dictionary = {}, reason: Dictionary = {}) -> void:
	attempts += 1
	mistakes += 1
	var payload := {
		"step": step_id(),
		"option": str(option.get("id", "")),
		"why": option.get("why", {}),
		"reason": reason,
	}
	mistake.emit(payload)


func register_attempt() -> void:
	attempts += 1


# --------------------------------------------------------------------- widgets ---
## The instruction bar shown at the top of the screen for every task, so the
## player always knows what is being asked even when the panel below changes.
##
## It is added to the HUD's prompt slot rather than positioned with fixed
## offsets: the slot is full-width at every screen size and the bar therefore
## stacks neatly above the demo banner and the correction instead of colliding
## with the challenge card or the pause button.
func build_prompt_bar(gesture_key: String = "") -> PanelContainer:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := UIFactory.hbox(14)
	panel.add_child(row)

	var text := UIFactory.wrap(prompt_text(), 21)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text)

	if not gesture_key.is_empty():
		var chip := UIFactory.panel(UIFactory.CARD_COLOR)
		chip.add_child(UIFactory.label(Loc.t(gesture_key), 17, UIFactory.ACCENT, true))
		row.add_child(chip)

	_prompt_area.add_child(panel)
	return panel


## Records a bottom box so `apply_layout()` can re-place it after a resize.
func remember_box(control: Control, width: float, height: float, centre_offset: float = 0.0) -> void:
	_boxes.append({"node": control, "w": width, "h": height, "off": centre_offset})


## A bottom sheet whose height follows its own content: exactly as tall as it needs
## to be, and only scrolling when the window is genuinely too short for it.
##
## `measured` is the node whose minimum height is the real content height — the
## inner box, not the scroll wrapper, which reports nothing on its scrolling axis.
func content_sheet(child: Control, measured: Control, width: float = 99999.0,
		centre_offset: float = 0.0) -> PanelContainer:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	panel.add_child(child)
	add_child(panel)
	var entry := {"panel": panel, "measured": measured, "w": width, "off": centre_offset}
	_sheets.append(entry)
	_fit_sheet(entry)
	# A second pass once the content has been laid out at the sheet's real width.
	call_deferred("_refit_measured")
	return panel


## Re-measures the fitted sheets. Tasks call this when a panel grows a line of text
## (an explanation appearing, a step moving between columns).
func refit_sheets() -> void:
	for entry in _sheets:
		_fit_sheet(entry)
	call_deferred("_refit_measured")


## Second measuring pass. The minimum height a wrapped label reports is the height
## it would need at its *narrowest* width, which for a sentence of Thai is absurdly
## tall; by now the content has been laid out at the real width, so the height it
## actually took is the right one to fit the sheet to.
func _refit_measured() -> void:
	if not is_inside_tree():
		return
	for entry in _sheets:
		var measured = entry.get("measured")
		if is_instance_valid(measured):
			var control := measured as Control
			if control.size.y > 0.0:
				entry["actual"] = control.size.y
		_fit_sheet(entry)


func _fit_sheet(entry: Dictionary) -> void:
	var panel = entry.get("panel")
	if not is_instance_valid(panel):
		return
	var needed := 190.0
	var measured = entry.get("measured")
	if is_instance_valid(measured):
		var content_height := float(entry.get("actual", 0.0))
		if content_height <= 0.0:
			content_height = (measured as Control).get_combined_minimum_size().y
		needed = maxf(190.0, content_height + 64.0)
	var vp := UIFactory.viewport_size()
	var margin := float(UIFactory.ui_margin())
	var top := margin + 190.0
	if hud != null and is_instance_valid(hud):
		top = hud.content_top()
	UIFactory.bottom_box(panel, float(entry.get("w")), needed, float(entry.get("off")),
		margin, maxf(160.0, vp.y - margin - top))


## A scrollable body for a bottom sheet. The sheet is a fixed-height box, so its
## body has to scroll when the content is taller than the box (a short window, or
## a long Thai list).
static func scroll_body() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return scroll


## Re-places every recorded box and re-fits every recorded minimum size. Called by
## the kitchen when the window changes size, so a resize never resets the step.
func apply_layout() -> void:
	for entry in _boxes:
		var node = entry.get("node")
		if is_instance_valid(node):
			UIFactory.bottom_box(node, float(entry.get("w")), float(entry.get("h")), float(entry.get("off")))
	for entry in _sheets:
		_fit_sheet(entry)
	UIFactory.refresh_responsive(self)


## The gesture hint shown on the instruction bar for this task's kind.
static func gesture_hint_for(kind: String) -> String:
	match kind:
		"drag_to":
			return "task.drag"
		"swipe_clean":
			return "task.drag"
		"hold", "cook_through":
			return "task.hold"
		"tap_correct", "choose_safer", "checklist", "order_steps":
			return "task.tap"
		_:
			return ""


## Standard explanatory card used after a mistake: what went wrong, and (when the
## option supplies it) why. Retry wording is deliberately kind.
func explanation_card(reason_text: String, detail_text: String = "") -> PanelContainer:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 620.0, 200.0)
	var v := UIFactory.vbox(8)
	panel.add_child(v)
	v.add_child(UIFactory.label(reason_text, 22, UIFactory.ACCENT, true))
	if not detail_text.is_empty():
		v.add_child(UIFactory.wrap(detail_text, 18, UIFactory.TEXT_DIM))
	v.add_child(UIFactory.label(Loc.t("feedback.try_again"), 18, UIFactory.TEXT_BRIGHT))
	return panel


## Plays the sound that matches the outcome of a step.
func celebrate() -> void:
	AudioManager.play_sfx("tap_ok")


# ------------------------------------------------------------------ demo & toast ---
## Shows the "watch, then try it yourself" banner and only then calls `callback`.
##
## Demonstrating before asking is a hard rule of the design: no task may present
## an interaction the player has not seen. Text tasks demonstrate the gesture with
## this banner; physical tasks additionally animate a ghost pointer.
func run_demo_then(callback: Callable, seconds: float = 1.5) -> void:
	var banner := UIFactory.panel(UIFactory.CARD_COLOR)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := UIFactory.label(Loc.t("task.watch_demo"), 22, UIFactory.ACCENT, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0, 44)
	banner.add_child(label)
	_prompt_area.add_child(banner)
	await get_tree().create_timer(seconds, false).timeout
	if not is_inside_tree():
		return
	label.text = Loc.t("task.your_turn")
	AudioManager.play_ui("pop")
	await get_tree().create_timer(0.7, false).timeout
	if not is_inside_tree():
		return
	banner.queue_free()
	if callback.is_valid():
		callback.call()


## Re-shows the demonstration, for a player who looked away or forgot the gesture.
## Nothing is scored differently for asking.
func replay_demo() -> void:
	run_demo_then(Callable(), 1.5)


## A small transient message, used for encouragement and for gentle corrections.
func flash_message(text: String, colour: Color = UIFactory.TEXT_BRIGHT) -> void:
	var toast := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(toast, 560.0, 76.0)
	var label := UIFactory.label(text, 20, colour, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_child(label)
	add_child(toast)
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.1)
	tween.tween_interval(1.7)
	tween.tween_property(toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(toast.queue_free)


## A short written correction shown just under the instruction bar. Physical tasks
## use this instead of a dialog so the player can keep their hands on the food.
func show_reason(text: String, colour: Color = UIFactory.BAD) -> void:
	if _reason_panel != null and is_instance_valid(_reason_panel):
		_reason_panel.queue_free()
		_reason_panel = null
	if text.is_empty():
		return
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text_label := UIFactory.wrap(text, 18, colour)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(text_label)
	_prompt_area.add_child(panel)
	_reason_panel = panel
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
