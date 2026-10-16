class_name ChecklistTask
extends KitchenTask
## "Tick every action that is correct."
##
## Used to close the prevention challenge. The player must tick all of the safe
## actions and none of the unsafe ones, and gets a written reason for every wrong
## tick. Partial credit is not silently given: the task only finishes when the
## ticks are exactly right.

var _checks: Dictionary = {}
var _explain: Label
var _confirm: Button


func begin() -> void:
	build_prompt_bar(gesture_hint_for("checklist"))
	_build()
	_set_enabled(false)
	if bool(step.get("demo", false)):
		run_demo_then(_enable, 1.6)
	else:
		_enable()


func _enable() -> void:
	_set_enabled(true)


func _set_enabled(on: bool) -> void:
	for id in _checks.keys():
		(_checks[id] as CheckBox).disabled = not on
	if _confirm != null:
		_confirm.disabled = not on


# --------------------------------------------------------------------- layout ---
func _build() -> void:
	var box := UIFactory.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for option in step.get("options", []):
		var option_dict: Dictionary = option
		var option_id := str(option_dict.get("id", ""))
		var check := UIFactory.check(LessonDB.local(option_dict.get("label")), false)
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if "autowrap_mode" in check:
			check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(check)
		_checks[option_id] = check

	_explain = UIFactory.wrap("", 17, UIFactory.TEXT_DIM)
	_explain.visible = false
	box.add_child(_explain)

	_confirm = UIFactory.button(Loc.t("feedback.continue"), 21, 260.0)
	UIFactory.style_button(_confirm, UIFactory.ACCENT, true)
	_confirm.pressed.connect(_on_confirm)
	box.add_child(UIFactory.centre_row(_confirm))

	# Everything lives in one scrolling body that the sheet is fitted to, so the
	# ticks, the explanation and the confirm button are always all reachable.
	var scroll := scroll_body()
	scroll.add_child(box)
	content_sheet(scroll, box)


# ------------------------------------------------------------------ interaction ---
func _on_confirm() -> void:
	register_attempt()

	var chosen: Array[String] = []
	var correct: Array[String] = []
	for option in step.get("options", []):
		var option_dict: Dictionary = option
		var option_id := str(option_dict.get("id", ""))
		if bool((_checks[option_id] as CheckBox).button_pressed):
			chosen.append(option_id)
		if bool(option_dict.get("correct", false)):
			correct.append(option_id)

	var wrong_ticks: Array[String] = []
	for id in chosen:
		if not correct.has(id):
			wrong_ticks.append(id)
	var missed: Array[String] = []
	for id in correct:
		if not chosen.has(id):
			missed.append(id)

	chosen.sort()
	correct.sort()
	if chosen == correct:
		AudioManager.play_sfx("star_full")
		succeed()
		return

	# Explain every wrong tick, and clear it so the player can correct it.
	AudioManager.play_sfx("tap_bad")
	var lines: Array[String] = []
	for id in wrong_ticks:
		var option := _option_by_id(id)
		(_checks[id] as CheckBox).button_pressed = false
		var why := LessonDB.local(option.get("why"))
		if not why.is_empty():
			lines.append("• " + why)
		register_mistake(option)
	if not missed.is_empty():
		lines.append("• " + Loc.t("feedback.missed_correct"))
	_explain.text = "%s:\n%s" % [Loc.t("feedback.explanation"), "\n".join(lines)]
	_explain.visible = true
	refit_sheets()


func _option_by_id(option_id: String) -> Dictionary:
	for option in step.get("options", []):
		var option_dict: Dictionary = option
		if str(option_dict.get("id", "")) == option_id:
			return option_dict
	return {}
