class_name Journal
## The recipe and knowledge journal.
##
## Three tabs:
##   * Recipes   — the dish for each challenge, unlocked as challenges are done
##   * Knowledge — every lesson, marked learned / not yet, plus corrected myths
##   * Progress  — stars, questions answered correctly, and the anonymous export
##
## This is the screen that answers "what has this player actually covered?", as
## distinct from "what score did they get?".

extends MenuScreen

const TABS := ["journal.tab_recipes", "journal.tab_lessons", "journal.tab_progress"]
const TAB_RECIPES := 0
const TAB_KNOWLEDGE := 1
const TAB_PROGRESS := 2

## The width each tab button asks for, and the gap between them. Used to decide
## whether the tabs fit as buttons or have to become a dropdown.
const TAB_BUTTON_WIDTH := 240.0
const TAB_SEPARATION := 10

var _tab_buttons: Array[Button] = []
var _tab_option: OptionButton = null
var _body: MarginContainer
var _active_tab := 0


func _ready() -> void:
	super()
	_build()


func rebuild_for_size() -> void:
	clear_page()
	_build()


func _build() -> void:
	var margin := content_margin(36)
	add_child(margin)

	var column := UIFactory.vbox(14)
	margin.add_child(column)
	column.add_child(title_block("journal.title", ""))
	column.add_child(_build_tab_bar())

	_body = content_margin(6)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_body)

	column.add_child(centred(back_button(func() -> void: Game.go_to_menu())))

	show_tab(_active_tab)


## Three buttons on a desktop; a dropdown when the buttons would not fit side by
## side, where three Thai tab labels would have to be clipped.
func _build_tab_bar() -> Control:
	_tab_buttons.clear()
	_tab_option = null

	if not _tab_bar_fits():
		var names: Array[String] = []
		for key in TABS:
			names.append(Loc.t(key))
		var chooser := UIFactory.option(names, _active_tab)
		UIFactory.responsive_min_size(chooser, 320.0, 50.0)
		chooser.item_selected.connect(func(index: int) -> void: show_tab(index))
		_tab_option = chooser
		return centred(chooser)

	var bar := UIFactory.hbox(TAB_SEPARATION)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in TABS.size():
		var b := UIFactory.button(Loc.t(TABS[i]), 19, TAB_BUTTON_WIDTH)
		var index := i
		b.pressed.connect(func() -> void:
			AudioManager.play_ui("ui_click")
			show_tab(index))
		_tab_buttons.append(b)
		bar.add_child(b)
	return bar


## Whether three tab buttons fit across the page. A label's minimum width is its
## own text, so the bar is measured from the button width the bar asks for rather
## than assumed to fit: at 768 pixels three of them are 60 pixels too wide.
func _tab_bar_fits() -> bool:
	var need := TAB_BUTTON_WIDTH * float(TABS.size()) \
		+ float(TAB_SEPARATION) * float(TABS.size() - 1) \
		+ float(UIFactory.ui_margin()) * 2.0
	return UIFactory.viewport_size().x >= need


## Brings one tab to the front. Public so a screen can deep-link into a tab.
func show_tab(index: int) -> void:
	_active_tab = clampi(index, 0, TABS.size() - 1)
	for i in _tab_buttons.size():
		var b := _tab_buttons[i]
		UIFactory.style_button(b, UIFactory.ACCENT if i == _active_tab else UIFactory.TEXT_BRIGHT, i == _active_tab)
	if _tab_option != null:
		_tab_option.selected = _active_tab
	for child in _body.get_children():
		child.queue_free()
	match _active_tab:
		0:
			_body.add_child(_recipes_tab())
		1:
			_body.add_child(_knowledge_tab())
		_:
			_body.add_child(_progress_tab())


func _scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


# ------------------------------------------------------------------ recipes ---
func _recipes_tab() -> Control:
	var scroll := _scroll()
	var list := UIFactory.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for level in LevelDB.levels():
		var level_id := str(level.get("id", ""))
		var dish: Dictionary = level.get("dish", {})
		var done := SaveData.is_completed(level_id)
		var card := UIFactory.panel(UIFactory.CARD_COLOR)
		var v := UIFactory.vbox(8)
		card.add_child(v)

		v.add_child(UIFactory.wrap(LevelDB.title(level), 22, UIFactory.ACCENT, true))
		if not done:
			v.add_child(UIFactory.wrap(Loc.t("levels.locked_hint"), 17, UIFactory.TEXT_DIM))
			list.add_child(card)
			continue

		v.add_child(UIFactory.wrap(LessonDB.text(dish, "name", Loc.language), 20, UIFactory.TEXT_BRIGHT, true))
		v.add_child(UIFactory.wrap(LessonDB.text(dish, "looks_like", Loc.language), 17, UIFactory.TEXT_DIM))

		var ing := UIFactory.vbox(2)
		ing.add_child(UIFactory.label(Loc.t("journal.tab_recipes"), 16, UIFactory.TEXT_DIM))
		var ing_line: Array[String] = []
		for item in dish.get("ingredients", []):
			ing_line.append(LessonDB.local(item))
		ing.add_child(UIFactory.wrap(", ".join(ing_line), 17))
		v.add_child(ing)

		var steps := UIFactory.vbox(2)
		var n := 1
		for step in dish.get("method", []):
			steps.add_child(UIFactory.wrap("%d. %s" % [n, LessonDB.local(step)], 17, UIFactory.TEXT_DIM))
			n += 1
		v.add_child(steps)

		list.add_child(card)
	return scroll


# ---------------------------------------------------------------- knowledge ---
func _knowledge_tab() -> Control:
	var scroll := _scroll()
	var list := UIFactory.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	list.add_child(UIFactory.wrap(
		"%s: %d / %d" % [Loc.t("journal.covered"), Learning.lessons_covered(), LevelDB.all_lesson_ids().size()],
		20, UIFactory.ACCENT, true))

	for lesson_id in LevelDB.all_lesson_ids():
		var lesson := Education.lesson(lesson_id)
		if lesson.is_empty():
			continue
		var covered := Learning.has_lesson(lesson_id)
		var card := UIFactory.panel(UIFactory.CARD_COLOR if covered else UIFactory.PANEL_COLOR)
		var v := UIFactory.vbox(6)
		card.add_child(v)
		var head := UIFactory.hbox(10)
		head.add_child(UIFactory.wrap(
			LessonDB.text(lesson, "title", Loc.language), 20,
			UIFactory.TEXT_BRIGHT if covered else UIFactory.TEXT_DIM, true))
		head.add_child(UIFactory.label(
			Loc.t("journal.covered") if covered else Loc.t("journal.not_covered"),
			15, UIFactory.GOOD if covered else UIFactory.TEXT_DIM))
		v.add_child(head)
		if covered:
			v.add_child(UIFactory.wrap(Education.simple(lesson), 17))
			v.add_child(UIFactory.wrap(Education.detail(lesson), 16, UIFactory.TEXT_DIM))
			for source in Education.sources_for(lesson):
				v.add_child(UIFactory.wrap("• %s — %s" % [
					str(source.get("publisher", "")), str(source.get("title", "")),
				], 13, UIFactory.TEXT_DIM))
		list.add_child(card)

	# Corrected misconceptions.
	var myths := UIFactory.vbox(6)
	myths.add_child(UIFactory.wrap(
		"%s: %d" % [Loc.t("journal.misconceptions"), Learning.misconceptions_corrected()],
		20, UIFactory.ACCENT, true))
	for claim in LessonDB.misconceptions():
		var claim_id := str(claim.get("id", ""))
		if not Learning.has_misconception(claim_id):
			continue
		myths.add_child(UIFactory.label(Loc.t("journal.myth_belief"), 16, UIFactory.BAD))
		myths.add_child(UIFactory.callout(Education.claim_text(claim), UIFactory.BAD, 16))
		var lesson := Education.lesson(str(claim.get("lesson", "")))
		if not lesson.is_empty():
			myths.add_child(UIFactory.label(Loc.t("journal.myth_truth"), 16, UIFactory.GOOD))
			myths.add_child(UIFactory.wrap(Education.simple(lesson), 16, UIFactory.TEXT_BRIGHT))
	list.add_child(myths)
	return scroll


# ----------------------------------------------------------------- progress ---
func _progress_tab() -> Control:
	var scroll := _scroll()
	var list := UIFactory.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var total_lessons := LevelDB.all_lesson_ids().size()
	var total_questions := LevelDB.all_question_ids().size()
	var fraction := 0.0
	if total_lessons + total_questions > 0:
		fraction = float(Learning.lessons_covered() + Learning.questions_correct()) / float(total_lessons + total_questions)

	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.value = fraction
	bar.custom_minimum_size = Vector2(0, 26)
	UIFactory.style_progress(bar, UIFactory.GOOD)
	list.add_child(UIFactory.wrap("%s: %d%%" % [Loc.t("journal.overall"), int(round(fraction * 100.0))], 20, UIFactory.ACCENT, true))
	list.add_child(bar)

	list.add_child(_stat_row(Loc.t("hud.stars_earned"), "%d / %d" % [SaveData.total_stars(), LevelDB.levels().size() * GameConfig.STARS_MAX]))
	list.add_child(_stat_row(Loc.t("journal.questions_correct"), "%d / %d" % [Learning.questions_correct(), total_questions]))
	list.add_child(_stat_row(Loc.t("journal.activities"), "%d" % Learning.activities_completed()))
	list.add_child(_stat_row(Loc.t("journal.misconceptions"), "%d" % Learning.misconceptions_corrected()))

	var pre := SaveData.assessment_result("pre")
	var post := SaveData.assessment_result("post")
	list.add_child(_stat_row(Loc.t("assessment.result_pre"), _assessment_text(pre)))
	list.add_child(_stat_row(Loc.t("assessment.result_post"), _assessment_text(post)))

	var export := make_button(Loc.t("assessment.export"), false, func() -> void:
		var path := Learning.write_export_file()
		AudioManager.play_ui("ui_click")
		show_overlay(_export_panel(path)), 340.0)
	list.add_child(centred(export))
	list.add_child(UIFactory.callout(Loc.t("assessment.not_measured"), UIFactory.TEXT_DIM, 15))
	return scroll


func _assessment_text(result: Dictionary) -> String:
	if result.is_empty():
		return Loc.t("assessment.pending")
	return "%d %s %d" % [int(result.get("score", 0)), Loc.t("assessment.of"), int(result.get("total", 0))]


func _stat_row(caption: String, value: String) -> HBoxContainer:
	var row := UIFactory.hbox(10)
	var left := UIFactory.label(caption, 18, UIFactory.TEXT_DIM)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(UIFactory.label(value, 18, UIFactory.TEXT_BRIGHT, true))
	return row


func _export_panel(path: String) -> Control:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	var v := UIFactory.vbox(10)
	panel.add_child(v)
	v.add_child(UIFactory.title(Loc.t("assessment.export"), 26))
	v.add_child(UIFactory.wrap(Loc.t("assessment.exported"), 18))
	if not path.is_empty():
		v.add_child(UIFactory.wrap(path, 14, UIFactory.TEXT_DIM))
	v.add_child(UIFactory.wrap(Loc.t("assessment.not_measured"), 15, UIFactory.TEXT_DIM))
	v.add_child(centred(close_button()))
	return panel
