class_name TapCorrectTask
extends KitchenTask
## "Tap the correct item" and "choose the safer option".
##
## The two kinds share one implementation because they are the same interaction
## with different wording: a small set of labelled choices, exactly one of which
## is right. A wrong choice is explained, is never removed from the list, and can
## be tried again — the design forbids shaming a player or blocking progress.

var _sheet: PanelContainer
var _options_box: VBoxContainer
var _buttons: Dictionary = {}
var _wrong_ids: Array[String] = []
var _explain_label: Label
var _locked := false


func begin() -> void:
	build_prompt_bar(gesture_hint_for(str(step.get("kind", ""))))
	_build_sheet()
	_set_options_enabled(false)
	if bool(step.get("demo", false)):
		run_demo_then(_enable_and_prompt, 1.6)
	else:
		_enable_and_prompt()


func _enable_and_prompt() -> void:
	_set_options_enabled(true)


# --------------------------------------------------------------------- layout ---
func _build_sheet() -> void:
	_options_box = UIFactory.vbox(10)
	_options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var options: Array = step.get("options", [])
	var wide := options.size() <= 2
	for option in options:
		var option_dict: Dictionary = option
		var option_id := str(option_dict.get("id", ""))

		var row := UIFactory.hbox(12)
		var button := UIFactory.button(LessonDB.local(option_dict.get("label")), 21, 0.0)
		UIFactory.responsive_min_size(button, 0.0, 78.0 if wide else 62.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if "autowrap_mode" in button:
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIFactory.style_button(button, UIFactory.TEXT_BRIGHT, false)
		button.pressed.connect(_on_option_pressed.bind(option_dict))
		row.add_child(button)
		_options_box.add_child(row)
		_buttons[option_id] = button

	_explain_label = UIFactory.wrap("", 18, UIFactory.TEXT_DIM)
	_explain_label.visible = false
	_options_box.add_child(_explain_label)

	# The sheet is fitted to the options, so every choice is fully on screen and
	# none has to be scrolled to.
	var scroll := scroll_body()
	scroll.add_child(_options_box)
	_sheet = content_sheet(scroll, _options_box)


func _set_options_enabled(on: bool) -> void:
	for id in _buttons.keys():
		if _wrong_ids.has(str(id)):
			continue
		(_buttons[id] as Button).disabled = not on


# ------------------------------------------------------------------ interaction ---
func _on_option_pressed(option: Dictionary) -> void:
	if _locked:
		return
	_locked = true
	register_attempt()
	var option_id := str(option.get("id", ""))
	var button := _buttons.get(option_id) as Button
	var is_correct := bool(option.get("correct", false))

	if is_correct:
		if button != null:
			UIFactory.style_button(button, UIFactory.GOOD, true)
		_explain_label.visible = false
		AudioManager.play_sfx("tap_ok")
		await get_tree().create_timer(0.45, false).timeout
		succeed()
		return

	# A wrong choice: mark it, explain it, and leave the rest available.
	AudioManager.play_sfx("tap_bad")
	if button != null:
		UIFactory.style_button(button, UIFactory.BAD, true)
		button.disabled = true
	if not _wrong_ids.has(option_id):
		_wrong_ids.append(option_id)

	var why := LessonDB.local(option.get("why"))
	if why.is_empty():
		why = Loc.t("feedback.almost")
	_explain_label.text = "%s %s" % [Loc.t("feedback.explanation") + ":", why]
	_explain_label.visible = true
	refit_sheets()
	register_mistake(option)

	_locked = false
	_set_options_enabled(true)
