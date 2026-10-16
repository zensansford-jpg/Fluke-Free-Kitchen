class_name OrderStepsTask
extends KitchenTask
## "Put these steps in the right order."
##
## The correct sequence is the order the steps appear in the level data. The pool
## is shuffled for display and the player taps them one at a time; a tap that is
## not the next expected step is explained and the pool stays put, so a player who
## is thinking their way to the answer is never punished for exploring.

var _pool_box: VBoxContainer
var _placed_box: VBoxContainer
var _buttons: Dictionary = {}
var _expected: Array[String] = []
var _placed: Array[String] = []
var _explain: Label
var _sheet: PanelContainer
var _columns: GridContainer


func apply_layout() -> void:
	super()
	if _columns != null:
		_columns.columns = UIFactory.columns(2)


func begin() -> void:
	_expected.clear()
	for entry in step.get("steps", []):
		_expected.append(str((entry as Dictionary).get("id", "")))
	build_prompt_bar(gesture_hint_for("order_steps"))
	_build()
	_set_enabled(false)
	if bool(step.get("demo", false)):
		run_demo_then(_enable, 1.6)
	else:
		_enable()


func _enable() -> void:
	_set_enabled(true)


func _set_enabled(on: bool) -> void:
	for id in _buttons.keys():
		(_buttons[id] as Button).disabled = not on


# --------------------------------------------------------------------- layout ---
func _build() -> void:
	var body := UIFactory.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Two columns on a wide window, stacked on a phone.
	_columns = GridContainer.new()
	_columns.columns = UIFactory.columns(2)
	_columns.add_theme_constant_override("h_separation", 18)
	_columns.add_theme_constant_override("v_separation", 14)
	body.add_child(_columns)

	# Left: the shuffled pool.
	var left := UIFactory.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(UIFactory.label(Loc.t("task.order_pool"), 18, UIFactory.TEXT_DIM))
	_pool_box = UIFactory.vbox(8)
	left.add_child(_pool_box)
	_columns.add_child(left)

	# Right: the order being built.
	var right := UIFactory.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(UIFactory.label(Loc.t("task.order_placed"), 18, UIFactory.ACCENT))
	_placed_box = UIFactory.vbox(6)
	right.add_child(_placed_box)
	_columns.add_child(right)

	_explain = UIFactory.wrap("", 17, UIFactory.TEXT_DIM)
	_explain.visible = false
	body.add_child(_explain)

	var shuffled: Array = step.get("steps", []).duplicate()
	shuffled.shuffle()
	for entry in shuffled:
		var entry_dict: Dictionary = entry
		var entry_id := str(entry_dict.get("id", ""))
		var button := UIFactory.button(LessonDB.local(entry_dict.get("label")), 20, 0.0)
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if "autowrap_mode" in button:
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIFactory.style_button(button, UIFactory.TEXT_BRIGHT, false)
		button.pressed.connect(_on_step_tapped.bind(entry_dict))
		_buttons[entry_id] = button
		_pool_box.add_child(button)

	# Built last, then measured: the sheet is fitted to the rows it actually has.
	var scroll := scroll_body()
	scroll.add_child(body)
	_sheet = content_sheet(scroll, body)


# ------------------------------------------------------------------ interaction ---
func _on_step_tapped(entry: Dictionary) -> void:
	if _expected.is_empty():
		return
	var entry_id := str(entry.get("id", ""))
	var expected_id := _expected[mini(_placed.size(), _expected.size() - 1)]

	if entry_id == expected_id:
		register_attempt()
		AudioManager.play_sfx("tap_ok")
		_placed.append(entry_id)
		var button := _buttons[entry_id] as Button
		if button != null:
			button.disabled = true
			UIFactory.style_button(button, UIFactory.GOOD, true)
			button.text = "%d. %s" % [_placed.size(), LessonDB.local(entry.get("label"))]
			_pool_box.remove_child(button)
			_placed_box.add_child(button)
			refit_sheets()
		if _placed.size() == _expected.size():
			AudioManager.play_sfx("star_full")
			await get_tree().create_timer(0.5, false).timeout
			succeed()
		return

	AudioManager.play_sfx("tap_bad")
	_explain.text = Loc.t("feedback.wrong_order")
	_explain.visible = true
	refit_sheets()
	register_mistake(entry, {"en": "That step comes later.", "th": "ขั้นนี้มาทีหลัง"})
