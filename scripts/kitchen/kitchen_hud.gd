class_name KitchenHUD
extends Control
## The always-on strip of information during a challenge: which challenge, which
## step, and the two buttons that must never be buried (hint and pause).
##
## It deliberately shows no live score. Tension about points would work against a
## game whose whole point is that the player slows down and thinks.
##
## The strip reflows instead of overlapping: on a wide window the card sits on the
## left and the buttons on the right; on a narrow one the buttons take the first
## row and the card sits underneath, reduced to a single line. The task's
## instruction bar is added to `prompt_slot`, which this class keeps directly
## below the strip, so the two can never collide at any window size.

signal pause_pressed()
signal hint_pressed()

const BUTTON_WIDTH_WIDE := 130.0
const BUTTON_WIDTH_COMPACT := 96.0
const ROW_HEIGHT := 54.0
const CARD_HEIGHT_WIDE := 118.0
const CARD_HEIGHT_COMPACT := 78.0

var prompt_slot: VBoxContainer = null

var _level: Dictionary = {}
var _step_text := ""
var _info: PanelContainer = null
var _buttons: HBoxContainer = null
var _step_label: Label = null
var _compact := false


func _ready() -> void:
	UIFactory.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_unhandled_input(false)


func setup(level: Dictionary) -> void:
	_level = level
	_build()


func set_step(index: int, total: int) -> void:
	_step_text = "%s %d / %d" % [Loc.t("hud.step"), index, total]
	if _step_label != null and is_instance_valid(_step_label):
		_step_label.text = _step_text


## Empties the instruction-bar area. The step runner calls this between steps so a
## task that was freed without cleaning up cannot leave a stale bar on screen.
func clear_prompt() -> void:
	if prompt_slot == null:
		return
	for child in prompt_slot.get_children():
		prompt_slot.remove_child(child)
		child.queue_free()


## Re-places the strip for the current window size. Called at build time and again
## whenever the kitchen is resized.
func apply_layout() -> void:
	var compact := UIFactory.is_compact()
	if compact != _compact or _info.get_child_count() == 0:
		_compact = compact
		_rebuild_info()

	for child in _buttons.get_children():
		UIFactory.responsive_min_size(child, BUTTON_WIDTH_COMPACT if compact else BUTTON_WIDTH_WIDE, ROW_HEIGHT)
	UIFactory.refresh_responsive(self)

	var margin := float(UIFactory.ui_margin())
	if compact:
		_buttons.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_buttons.offset_left = margin
		_buttons.offset_right = -margin
		_buttons.offset_top = margin
		_buttons.offset_bottom = margin + ROW_HEIGHT
		_info.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_info.offset_left = margin
		_info.offset_right = -margin
		_info.offset_top = margin + ROW_HEIGHT + 8.0
		_info.offset_bottom = margin + ROW_HEIGHT + 8.0 + CARD_HEIGHT_COMPACT
		_place_prompt(margin + ROW_HEIGHT + 8.0 + CARD_HEIGHT_COMPACT + 8.0, margin)
	else:
		_info.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_info.offset_left = margin
		_info.offset_right = margin + 230.0
		_info.offset_top = margin
		_info.offset_bottom = margin + CARD_HEIGHT_WIDE
		_buttons.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_buttons.offset_left = -(margin + BUTTON_WIDTH_WIDE * 2.0 + 10.0)
		_buttons.offset_right = -margin
		_buttons.offset_top = margin
		_buttons.offset_bottom = margin + CARD_HEIGHT_WIDE
		_place_prompt(margin + CARD_HEIGHT_WIDE + 8.0, margin)


func _place_prompt(top: float, margin: float) -> void:
	prompt_slot.set_anchors_preset(Control.PRESET_TOP_WIDE)
	prompt_slot.offset_left = margin
	prompt_slot.offset_right = -margin
	prompt_slot.offset_top = top
	prompt_slot.offset_bottom = top + 260.0


## The first screen row a task panel may use without covering the instruction bar.
## Tasks use it to cap their own bottom panels, which is what keeps the bar and the
## panel from overlapping at any window size.
func content_top() -> float:
	if prompt_slot == null or not is_instance_valid(prompt_slot):
		return 190.0
	return prompt_slot.position.y + prompt_slot.get_combined_minimum_size().y + 10.0


# ------------------------------------------------------------------- building ---
func _build() -> void:
	# The card and the buttons are both part of the top strip; they are placed
	# entirely by `apply_layout()`, so a resize only has to call it again.
	_info = UIFactory.panel(UIFactory.CARD_COLOR)
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_info)

	_buttons = UIFactory.hbox(10)
	_buttons.alignment = BoxContainer.ALIGNMENT_END

	var hint := UIFactory.button(Loc.t("task.skip_demo"), 18, BUTTON_WIDTH_WIDE)
	UIFactory.style_overlay_button(hint, UIFactory.TEXT_BRIGHT)
	hint.tooltip_text = Loc.t("task.watch_demo")
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		hint_pressed.emit())
	_buttons.add_child(hint)

	var pause := UIFactory.button(Loc.t("hud.pause"), 18, BUTTON_WIDTH_WIDE)
	UIFactory.style_overlay_button(pause, UIFactory.ACCENT)
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		pause_pressed.emit())
	_buttons.add_child(pause)

	add_child(_buttons)

	prompt_slot = UIFactory.vbox(8)
	prompt_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(prompt_slot)

	apply_layout()


## The card content is different in the two layouts: three stacked lines when
## there is room, one line when there is not.
func _rebuild_info() -> void:
	for child in _info.get_children():
		_info.remove_child(child)
		child.queue_free()
	_step_label = null

	if _compact:
		var row := UIFactory.hbox(8)
		_info.add_child(row)
		var name_label := UIFactory.label(LevelDB.title(_level), 18, UIFactory.TEXT_BRIGHT, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_text = true
		row.add_child(name_label)
		_step_label = UIFactory.label(_step_text, 15, UIFactory.ACCENT, true)
		row.add_child(_step_label)
		return

	var v := UIFactory.vbox(2)
	_info.add_child(v)
	v.add_child(UIFactory.label(Loc.t("hud.challenge"), 15, UIFactory.TEXT_DIM))
	var wide_name := UIFactory.label(LevelDB.title(_level), 19, UIFactory.TEXT_BRIGHT, true)
	wide_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wide_name.clip_text = true
	v.add_child(wide_name)
	_step_label = UIFactory.label(_step_text, 16, UIFactory.ACCENT, true)
	v.add_child(_step_label)
