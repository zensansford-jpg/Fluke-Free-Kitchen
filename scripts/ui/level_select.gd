class_name LevelSelect
## The challenge picker. Each card shows the challenge, its objective, the stars
## earned so far and the best score, and locks until the previous challenge has
## been completed.

extends MenuScreen


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	var column := scroll_page(30, 16)
	column.add_child(title_block("levels.title", "levels.subtitle"))

	# Three cards side by side on a desktop, one at a time on a phone.
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(3)
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	for level in LevelDB.levels():
		grid.add_child(_level_card(level))
	column.add_child(centred(grid))

	column.add_child(centred(back_button(func() -> void: Game.go_to_menu())))


func rebuild_for_size() -> void:
	clear_page()
	_build()


func _level_card(level: Dictionary) -> PanelContainer:
	var level_id := str(level.get("id", ""))
	var unlocked := LevelDB.is_unlocked(level)

	var panel := UIFactory.panel(UIFactory.CARD_COLOR if unlocked else UIFactory.PANEL_COLOR)
	UIFactory.responsive_grid_size(panel, 360.0, 3, 1, 430.0, 20)

	var v := UIFactory.vbox(10)
	panel.add_child(v)

	var index_label := UIFactory.label(Loc.t("common.level_n", [int(level.get("index", 0))]), 17, UIFactory.TEXT_DIM)
	v.add_child(index_label)
	v.add_child(UIFactory.wrap(LevelDB.title(level), 26, UIFactory.TEXT_BRIGHT, true))
	v.add_child(UIFactory.wrap(LevelDB.objective_short(level), 18, UIFactory.TEXT_DIM))

	var stars := StarRow.new()
	stars.configure(GameConfig.STARS_MAX, 40.0, 10.0)
	stars.stars = SaveData.stars_for(level_id)
	stars.custom_minimum_size = Vector2(0, 54)
	v.add_child(centred(stars))

	var best := SaveData.best_score_for(level_id)
	v.add_child(centred(UIFactory.label(
		"%s: %s" % [Loc.t("levels.best"), str(best) if best > 0 else Loc.t("levels.best_none")],
		17, UIFactory.TEXT_DIM)))

	v.add_child(gap(6))

	if unlocked:
		var label := Loc.t("levels.replay") if SaveData.is_completed(level_id) else Loc.t("levels.play")
		var start := make_button(label, true, func() -> void: Game.start_level(level_id), 160.0)
		# The button fills the card rather than asking for a fixed width. A fixed 300
		# would become the card's minimum width, and three 340 pixel cards need 1060
		# pixels — which is what pushed this page off a 768 pixel tablet.
		start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(centred(start))
	else:
		var locked := UIFactory.button(Loc.t("levels.locked"), 20, 160.0)
		locked.disabled = true
		locked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIFactory.style_button(locked, UIFactory.TEXT_DIM, false)
		v.add_child(centred(locked))
		v.add_child(centred(UIFactory.wrap(Loc.t("levels.locked_hint"), 16, UIFactory.TEXT_DIM)))

	v.add_child(gap(4))
	v.add_child(centred(UIFactory.label(
		"%s: %d | %s: %d" % [
			Loc.t("hud.stars_earned"), SaveData.stars_for(level_id),
			Loc.t("journal.questions_correct"), _questions_correct(level_id),
		], 15, UIFactory.TEXT_DIM)))

	return panel


func _questions_correct(level_id: String) -> int:
	var count := 0
	for q in QuizDB.for_level(level_id):
		if Learning.is_question_correct(str(q.get("id", ""))):
			count += 1
	return count
