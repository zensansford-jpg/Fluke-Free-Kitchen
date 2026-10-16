class_name QuizCard
extends PanelContainer
## The mandatory knowledge check that closes every challenge.
##
## Two rules make this more than a quiz screen:
##   * a required question cannot be left behind until it is answered correctly —
##     with the explanation shown, so the retry is where the learning happens;
##   * an answer is written to the learning log as it happens, so the journal and
##     the research export reflect what the player actually understood rather than
##     only what they scored.
##
## Nothing here is timed, and there is no attempt limit.

signal answered(question_id: String, correct: bool, attempts: int)
signal finished()

var _questions: Array = []
var _required: Array = []
var _index := 0
var _attempts := 0
var _box: VBoxContainer = null
var _feedback: Label = null
var _buttons: Array[Button] = []
var _question: Dictionary = {}


func run(questions: Array, required_ids: Array) -> void:
	UIFactory.style_panel(self, UIFactory.PANEL_COLOR)
	_questions = questions
	_required = required_ids
	_index = 0
	_box = UIFactory.vbox(10)
	add_child(_box)
	_show_current()


func _show_current() -> void:
	for child in _box.get_children():
		child.queue_free()
	_buttons.clear()
	_attempts = 0
	_feedback = null

	if _index >= _questions.size():
		finished.emit()
		return

	_question = _questions[_index]
	var question_id := str(_question.get("id", ""))
	var is_required := _required.has(question_id)

	_box.add_child(UIFactory.label(Loc.t("quiz.title"), 16, UIFactory.TEXT_DIM))
	_box.add_child(UIFactory.label(Loc.t("quiz.question_of", [_index + 1, _questions.size()]), 17, UIFactory.ACCENT, true))
	if is_required:
		_box.add_child(UIFactory.wrap(Loc.t("quiz.required_note"), 16, UIFactory.GOOD))
	_box.add_child(UIFactory.wrap(QuizDB.text(_question, "question"), 22))

	for entry in _question.get("options", []):
		var option: Dictionary = entry
		var button := UIFactory.button(LessonDB.local(option.get("label")), 20, 0.0)
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if "autowrap_mode" in button:
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIFactory.style_button(button, UIFactory.TEXT_BRIGHT, false)
		button.pressed.connect(_on_option.bind(option))
		_box.add_child(button)
		_buttons.append(button)

	_feedback = UIFactory.wrap("", 18, UIFactory.TEXT_DIM)
	_feedback.visible = false
	_box.add_child(_feedback)


func _on_option(option: Dictionary) -> void:
	_attempts += 1
	var question_id := str(_question.get("id", ""))
	var correct := bool(option.get("correct", false))
	Learning.record_question(question_id, correct)

	if correct:
		_lock_buttons()
		AudioManager.play_sfx("tap_ok")
		for claim_id in _question.get("corrects", []):
			Learning.record_misconception(str(claim_id))
		var explanation := Education.simple(str(_question.get("lesson", "")))
		_show_feedback("%s %s" % [Loc.t("quiz.correct"), explanation], UIFactory.GOOD)
		_resolve(true)
		return

	# A wrong answer is explained, and the button is retired so the same mistake
	# cannot be repeated by accident.
	AudioManager.play_sfx("tap_bad")
	var why := LessonDB.local(option.get("why"))
	if why.is_empty():
		why = Loc.t("feedback.almost")
	_show_feedback("%s %s" % [Loc.t("quiz.incorrect"), why], UIFactory.BAD)
	for button in _buttons:
		if button.text == LessonDB.local(option.get("label")):
			button.disabled = true
			UIFactory.style_button(button, UIFactory.BAD, true)

	var is_required := _required.has(question_id)
	if not is_required:
		# An optional question that was answered wrongly is finished: the
		# explanation has been read, so the remaining buttons are retired. Leaving
		# them live would let the same question be answered twice, which would
		# double-count its knowledge points.
		_lock_buttons()
		_resolve(false)


func _resolve(correct: bool) -> void:
	var question_id := str(_question.get("id", ""))
	answered.emit(question_id, correct, _attempts)
	_show_advance()


func _show_advance() -> void:
	var last := _index >= _questions.size() - 1
	var button := UIFactory.button(Loc.t("feedback.continue") if last else Loc.t("quiz.next"), 20, 220.0)
	UIFactory.style_button(button, UIFactory.ACCENT, true)
	button.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		_index += 1
		_show_current())
	var row := UIFactory.centre_row(button)
	_box.add_child(row)


func _show_feedback(text: String, colour: Color) -> void:
	if _feedback == null:
		return
	_feedback.text = text
	_feedback.visible = true
	_feedback.add_theme_color_override("font_color", colour)


func _lock_buttons() -> void:
	for button in _buttons:
		button.disabled = true
