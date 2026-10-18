class_name ModeSelect
## The door into the three ways to play.
##
##   * Let's Cook    — pick a real dish and cook it step by step.
##   * Endless Kitchen — one validated challenge after another.
##   * Free Cook     — your own fish and method, labelled as a creation.
##
## The page also shows the player's own records, so there is something to be proud
## of on the way in.

extends MenuScreen


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	var column := scroll_page(30, 18)
	column.add_child(title_block("modes.title", "modes.subtitle"))

	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(2)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.add_child(_mode_card("modes.cook_title", "modes.cook_body", "modes.cook_cta",
		UIFactory.ACCENT, func() -> void: Game.navigate("dishes")))
	grid.add_child(_mode_card("modes.endless_title", "modes.endless_body", "modes.endless_cta",
		UIFactory.GOOD, func() -> void: Game.start_endless()))
	grid.add_child(_mode_card("modes.free_title", "modes.free_body", "modes.free_cta",
		Color(0.5, 0.8, 0.95), func() -> void: Game.navigate("free_cook")))
	grid.add_child(_mode_card("modes.cookbook_title", "modes.cookbook_body", "modes.cookbook_cta",
		Color(0.85, 0.6, 0.95), func() -> void: Game.navigate("cookbook")))
	column.add_child(centred(grid))

	column.add_child(centred(_records_panel()))
	column.add_child(centred(back_button(func() -> void: Game.go_to_menu())))


func rebuild_for_size() -> void:
	clear_page()
	_build()


func _mode_card(title_key: String, body_key: String, cta_key: String, accent: Color,
		action: Callable) -> PanelContainer:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.responsive_grid_size(panel, 330.0, 2, 1, 420.0, 18)
	var v := UIFactory.vbox(10)
	panel.add_child(v)
	v.add_child(UIFactory.wrap(Loc.t(title_key), 26, accent, true))
	v.add_child(UIFactory.wrap(Loc.t(body_key), 18, UIFactory.TEXT_DIM))
	v.add_child(gap(6))
	var button := make_button(Loc.t(cta_key), true, action, 200.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The button lives inside a grid card, so its minimum has to fit the *inner*
	# column: the card's 20 pixel padding on each side comes out of the column before
	# the button gets its share. Without this a 200 pixel button keeps a two column
	# grid wider than a 768 pixel tablet.
	UIFactory.responsive_grid_size(button, 200.0, 2, 1, 54.0, 18, 40.0)
	v.add_child(centred(button))
	return panel


func _records_panel() -> PanelContainer:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	UIFactory.responsive_grid_size(panel, 640.0, 1, 1, 900.0, 0)
	var v := UIFactory.vbox(6)
	panel.add_child(v)
	v.add_child(UIFactory.label(Loc.t("modes.records_title"), 20, UIFactory.TEXT_BRIGHT, true))

	var endless := SaveData.endless_stats()
	v.add_child(_record_row(Loc.t("modes.record_dishes"),
		"%d / %d" % [SaveData.discovered_count(), RecipeDB.recipe_count()]))
	v.add_child(_record_row(Loc.t("modes.record_endless"),
		str(int(endless.get("best_streak", 0)))))
	v.add_child(_record_row(Loc.t("modes.record_achievements"),
		"%d / %d" % [SaveData.unlocked_achievements().size(), AchievementDB.list().size()]))
	return panel


func _record_row(caption: String, value: String) -> HBoxContainer:
	var row := UIFactory.hbox(10)
	var left := UIFactory.label(caption, 18, UIFactory.TEXT_DIM)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(UIFactory.label(value, 19, UIFactory.ACCENT, true))
	return row
