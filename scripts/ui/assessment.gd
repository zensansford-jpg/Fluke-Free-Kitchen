class_name Assessment
## The optional before/after knowledge check.
##
## Two short runs of six questions. The player may take either set, in either
## order, and results are stored anonymously. A wrong answer shows a short
## explanation and moves on — this instrument measures understanding, it does
## not gate progress or punish mistakes.

extends MenuScreen

var _page: VBoxContainer
var _set_name := AssessmentDB.SET_PRE
var _index := 0
var _correct := 0
var _answers: Dictionary = {}
## The optional case-code field, alive only while the intro is on screen.
var _code_field: LineEdit = null
## The function that draws whatever is on screen right now, so a window resize can
## redraw the identical view instead of dropping the player back to the intro.
var _redraw: Callable = Callable()


func _ready() -> void:
	super()
	_show_intro()


func rebuild_for_size() -> void:
	# Commit whatever is half-typed before the field is freed by the rebuild, so
	# a window resize while a code is being entered cannot lose it.
	_commit_code()
	if _redraw.is_valid():
		_redraw.call()
	else:
		_show_intro()


# ------------------------------------------------------------------- layout ---
func _reset() -> void:
	clear_page()
	_code_field = null
	_page = scroll_page(36, 14)


func _column(title_key: String) -> VBoxContainer:
	_reset()
	_page.add_child(centred(UIFactory.title(Loc.t(title_key), 36)))
	return _page


# -------------------------------------------------------------------- intro ---
func _show_intro() -> void:
	_redraw = _show_intro
	var column := _column("assessment.title")
	column.add_child(centred(UIFactory.wrap(Loc.t("assessment.intro"), 19, UIFactory.TEXT_DIM)))
	column.add_child(centred(_code_row()))

	# The two sittings sit side by side on a desktop and stack on a phone.
	var cards := GridContainer.new()
	cards.columns = UIFactory.columns(2)
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	cards.add_child(_status_card(Loc.t("assessment.pre"), SaveData.assessment_result(AssessmentDB.SET_PRE)))
	cards.add_child(_status_card(Loc.t("assessment.post"), SaveData.assessment_result(AssessmentDB.SET_POST)))
	column.add_child(centred(cards))

	column.add_child(centred(make_button(Loc.t("assessment.start_pre"), true,
		func() -> void: _begin(AssessmentDB.SET_PRE), 420.0)))
	column.add_child(centred(make_button(Loc.t("assessment.start_post"), false,
		func() -> void: _begin(AssessmentDB.SET_POST), 420.0)))

	column.add_child(centred(make_button(Loc.t("assessment.clear"), false, func() -> void:
		SaveData.clear_assessment()
		AudioManager.play_ui("ui_back")
		_show_intro(), 420.0)))

	column.add_child(centred(UIFactory.wrap(Loc.t("assessment.not_measured"), 16, UIFactory.TEXT_DIM)))
	column.add_child(centred(back_button(func() -> void: Game.go_to_menu())))


func _status_card(caption: String, result: Dictionary) -> Control:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.responsive_grid_size(panel, 460.0, 2, 1, 0.0, 12)
	var row := UIFactory.hbox(12)
	panel.add_child(row)
	var left := UIFactory.label(caption, 19, UIFactory.TEXT_DIM)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var value := Loc.t("assessment.pending")
	var colour := UIFactory.TEXT_DIM
	if not result.is_empty():
		value = "%d %s %d" % [int(result.get("score", 0)), Loc.t("assessment.of"), int(result.get("total", 0))]
		colour = UIFactory.GOOD
	row.add_child(UIFactory.label(value, 19, colour, true))
	return panel


## The optional case code. It lives here rather than in Settings because it is
## part of the research instrument, not a player preference — and the game says
## plainly on screen that it is optional and is not a name.
func _code_row() -> Control:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.responsive_grid_size(panel, 460.0, 2, 1, 0.0, 12)
	var column := UIFactory.vbox(6)
	panel.add_child(column)
	column.add_child(UIFactory.label(Loc.t("assessment.code"), 19, UIFactory.TEXT_DIM))
	_code_field = UIFactory.text_input(
		Loc.t("assessment.code_placeholder"), SaveData.participant_code, SaveData.CODE_MAX)
	_code_field.focus_exited.connect(_commit_code)
	_code_field.text_submitted.connect(func(_text: String) -> void: _commit_code())
	column.add_child(_code_field)
	column.add_child(UIFactory.wrap(Loc.t("assessment.code_hint"), 15, UIFactory.TEXT_DIM))
	return panel


## Persists the field's contents, sanitised. Called on focus loss, on Enter, and
## before either question set begins, so an export can never miss a code the
## player actually typed.
func _commit_code() -> void:
	if _code_field == null or not is_instance_valid(_code_field):
		return
	var code := SaveData.sanitise_code(_code_field.text)
	if _code_field.text != code:
		_code_field.text = code
	SaveData.set_participant_code(code)


# ----------------------------------------------------------------- questions ---
func _begin(set_name: String) -> void:
	_commit_code()
	_set_name = set_name
	_index = 0
	_correct = 0
	_answers = {}
	AudioManager.play_ui("ui_click")
	_show_question()


func _show_question() -> void:
	var list := AssessmentDB.questions(_set_name)
	if _index >= list.size():
		_finish()
		return
	_redraw = _show_question
	var question: Dictionary = list[_index]

	var column := _column("assessment.title")
	column.add_child(centred(UIFactory.label(
		Loc.t("quiz.question_of", [_index + 1, list.size()]), 17, UIFactory.TEXT_DIM)))
	column.add_child(centred(UIFactory.label(
		Loc.t("assessment.pre") if _set_name == AssessmentDB.SET_PRE else Loc.t("assessment.post"),
		17, UIFactory.ACCENT)))
	column.add_child(centred(UIFactory.wrap(AssessmentDB.text(question, "question"), 24)))
	column.add_child(gap(6))

	for option in question.get("options", []):
		var b := UIFactory.button(LessonDB.local((option as Dictionary).get("label")), 20, 620.0)
		UIFactory.style_button(b, UIFactory.TEXT_BRIGHT, false)
		var option_dict: Dictionary = option
		b.pressed.connect(func() -> void: _answer(question, option_dict))
		column.add_child(centred(b))


func _answer(question: Dictionary, chosen: Dictionary) -> void:
	var is_correct := bool(chosen.get("correct", false))
	if is_correct:
		_correct += 1
		AudioManager.play_ui("tap_ok")
	else:
		AudioManager.play_ui("error_soft")
	_answers[str(question.get("id", ""))] = {
		"chosen": str(chosen.get("id", "")),
		"correct": is_correct,
	}
	_show_answer(question, chosen)


func _show_answer(question: Dictionary, chosen: Dictionary) -> void:
	var is_correct := bool(chosen.get("correct", false))
	_redraw = _show_answer.bind(question, chosen)
	var column := _column("assessment.title")
	column.add_child(centred(UIFactory.label(
		Loc.t("quiz.correct") if is_correct else Loc.t("quiz.incorrect"),
		26, UIFactory.GOOD if is_correct else UIFactory.BAD, true)))
	column.add_child(centred(UIFactory.wrap(AssessmentDB.text(question, "question"), 20, UIFactory.TEXT_DIM)))
	column.add_child(centred(UIFactory.callout(AssessmentDB.text(question, "explain"),
		UIFactory.GOOD if is_correct else UIFactory.ACCENT)))
	column.add_child(centred(make_button(Loc.t("quiz.next"), true, func() -> void:
		_index += 1
		_show_question(), 300.0)))


# ------------------------------------------------------------------- result ---
func _finish() -> void:
	var total := AssessmentDB.count(_set_name)
	SaveData.record_assessment(_set_name, {
		"score": _correct,
		"total": total,
		"answers": _answers,
	})
	AudioManager.play_ui("star_full")
	_show_result()


func _show_result() -> void:
	_redraw = _show_result
	var total := AssessmentDB.count(_set_name)
	var column := _column("assessment.title")
	column.add_child(centred(UIFactory.label(
		Loc.t("assessment.result_pre") if _set_name == AssessmentDB.SET_PRE else Loc.t("assessment.result_post"),
		22, UIFactory.ACCENT)))
	var stars := StarRow.new()
	stars.configure(3, 56.0, 12.0)
	stars.stars = int(round(float(_correct) / maxf(1.0, float(total)) * 3.0))
	stars.custom_minimum_size = Vector2(0, 70)
	column.add_child(centred(stars))
	column.add_child(centred(UIFactory.label("%d %s %d" % [_correct, Loc.t("assessment.of"), total], 34, UIFactory.TEXT_BRIGHT, true)))
	column.add_child(centred(UIFactory.wrap(Loc.t("assessment.not_measured"), 17, UIFactory.TEXT_DIM)))
	column.add_child(gap(6))
	column.add_child(centred(make_button(Loc.t("assessment.export"), false, func() -> void:
		var path := Learning.write_export_file()
		AudioManager.play_ui("ui_click")
		show_overlay(_export_panel(path)), 380.0)))
	column.add_child(centred(back_button(func() -> void:
		AudioManager.play_ui("ui_back")
		_show_intro())))


func _export_panel(path: String) -> Control:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	var v := UIFactory.vbox(10)
	panel.add_child(v)
	v.add_child(UIFactory.title(Loc.t("assessment.export"), 26))
	v.add_child(UIFactory.wrap(Loc.t("assessment.exported"), 18))
	if not path.is_empty():
		v.add_child(UIFactory.wrap(path, 14, UIFactory.TEXT_DIM))
	v.add_child(centred(close_button()))
	return panel
