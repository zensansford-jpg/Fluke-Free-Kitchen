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
	var heading := title_block("modes.title", "modes.subtitle")
	column.add_child(heading)
	UIFactory.entrance(heading, 0.02)

	# The five doors fan in left to right, so the eye reads them as a set of
	# choices rather than a wall of panels that arrived at once.
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(2)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	var doors: Array = [
		_mode_card("modes.cook_title", "modes.cook_body", "modes.cook_cta", "pot",
			UIFactory.ACCENT, func() -> void: Game.navigate("dishes")),
		_mode_card("modes.endless_title", "modes.endless_body", "modes.endless_cta",
			"endless", UIFactory.GOOD, func() -> void: Game.start_endless()),
		_mode_card("modes.free_title", "modes.free_body", "modes.free_cta", "sparkle",
			Color(0.5, 0.8, 0.95), func() -> void: Game.navigate("free_cook")),
		_mode_card("modes.cookbook_title", "modes.cookbook_body", "modes.cookbook_cta",
			"book", Color(0.85, 0.6, 0.95), func() -> void: Game.navigate("cookbook")),
		_mode_card("modes.explore_title", "modes.explore_body", "modes.explore_cta",
			"compass", Color(0.55, 0.9, 0.8), func() -> void: Game.navigate("explore")),
	]
	for i in doors.size():
		grid.add_child(doors[i])
		UIFactory.entrance(doors[i], 0.08 + float(i) * 0.055)
	column.add_child(centred(grid))

	var records := _records_panel()
	column.add_child(centred(records))
	UIFactory.entrance(records, 0.08 + float(doors.size()) * 0.055)
	var back := back_button(func() -> void: Game.go_to_menu())
	column.add_child(centred(back))
	UIFactory.entrance(back, 0.44)


func rebuild_for_size() -> void:
	clear_page()
	_build()


func _mode_card(title_key: String, body_key: String, cta_key: String, icon_kind: String,
		accent: Color, action: Callable) -> PanelContainer:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.responsive_grid_size(panel, 330.0, 2, 1, 420.0, 18)
	var v := UIFactory.vbox(10)
	panel.add_child(v)

	# The glyph sits above the words, tinted with the card's accent: five cards
	# that differ only by a heading read as a form, five that carry a drawn
	# emblem read as five places to go.
	var emblem := UIFactory.icon(icon_kind, 46.0, accent)
	v.add_child(centred(emblem))
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
	var head := UIFactory.hbox(9)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UIFactory.icon("star", 22.0, UIFactory.ACCENT))
	head.add_child(UIFactory.label(Loc.t("modes.records_title"), 20, UIFactory.TEXT_BRIGHT, true))
	v.add_child(centred(head))

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
