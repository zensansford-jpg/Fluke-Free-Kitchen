class_name MainMenu
## The title screen.
##
## Settings, "How to play" and "About & sources" open as modal overlays, which
## keeps navigation to a small number of scenes.

extends MenuScreen

var _star_summary: Control
var _language_holder: HBoxContainer


func _ready() -> void:
	super()
	AudioManager.play_music("menu")
	_build()
	SaveData.save_changed.connect(_refresh_summary)


func _build() -> void:
	var column := scroll_page(34, 10)

	column.add_child(centred(UIFactory.title(Loc.t("app.title"), 50)))
	column.add_child(centred(UIFactory.wrap(Loc.t("app.subtitle"), 19, UIFactory.TEXT_DIM)))

	_star_summary = _build_star_summary()
	column.add_child(centred(_star_summary))

	column.add_child(centred(make_button(Loc.t("menu.play"), true, func() -> void: Game.go_to_levels())))

	# The secondary entries sit two to a row: seven full-width buttons stacked
	# vertically do not fit a 1280x720 canvas, and a title screen whose last
	# button is off-screen is worse than a slightly denser one. On a phone they
	# collapse to a single column.
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(2)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.add_child(grid_button(Loc.t("menu.journal"), func() -> void: Game.navigate("journal")))
	grid.add_child(grid_button(Loc.t("menu.assessment"), func() -> void: Game.navigate("assessment")))
	grid.add_child(grid_button(Loc.t("menu.how_to_play"), func() -> void: show_overlay(_how_to_play_panel())))
	grid.add_child(grid_button(Loc.t("menu.about"), func() -> void: show_overlay(_sources_panel())))
	grid.add_child(grid_button(Loc.t("menu.settings"), func() -> void: show_overlay(_settings_panel())))
	grid.add_child(grid_button(Loc.t("menu.quit"), func() -> void: Game.quit_game()))
	column.add_child(centred(grid))

	add_child(_language_button())
	add_child(_footer())


## A button inside the two-column grid. It asks for a column's width rather than a
## whole row's, so the pair still fits a 768 pixel tablet instead of pushing the
## page wider than the window.
func grid_button(text: String, action: Callable) -> Button:
	var b := make_button(text, false, action)
	UIFactory.responsive_grid_size(b, 380.0, 2, 1, 54.0, 12)
	return b


# -------------------------------------------------------------- star summary ---
func _build_star_summary() -> Control:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	var row := UIFactory.hbox(20)
	panel.add_child(row)
	row.add_child(_summary_cell(Loc.t("levels.total_stars"),
		"%d / %d" % [SaveData.total_stars(), LevelDB.levels().size() * GameConfig.STARS_MAX],
		"StarsValue", UIFactory.ACCENT))
	row.add_child(_summary_cell(Loc.t("levels.title"),
		"%d / %d" % [SaveData.levels_completed(), LevelDB.levels().size()],
		"CompletedValue", UIFactory.TEXT_BRIGHT))
	return panel


func _summary_cell(caption: String, value: String, node_name: String, colour: Color) -> VBoxContainer:
	var col := UIFactory.vbox(4)
	col.add_child(UIFactory.label(caption, 16, UIFactory.TEXT_DIM))
	var value_label := UIFactory.label(value, 24, colour, true)
	value_label.name = node_name
	col.add_child(value_label)
	return col


func _refresh_summary() -> void:
	if _star_summary == null or not is_instance_valid(_star_summary):
		return
	var stars := _star_summary.find_child("StarsValue", true, false)
	if stars is Label:
		(stars as Label).text = "%d / %d" % [SaveData.total_stars(), LevelDB.levels().size() * GameConfig.STARS_MAX]
	var completed := _star_summary.find_child("CompletedValue", true, false)
	if completed is Label:
		(completed as Label).text = "%d / %d" % [SaveData.levels_completed(), LevelDB.levels().size()]


# ----------------------------------------------------------------- chrome ------
## A TH / EN switch in the top-right corner so a reviewer can flip the whole
## game's language without hunting through the settings screen.
func _language_button() -> Control:
	_language_holder = UIFactory.hbox(12)
	# Top-right on a wide window; on a narrow one that corner collides with the
	# centred title, so the switch moves to the bottom of the page instead.
	if UIFactory.viewport_size().x >= 900.0:
		_language_holder.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_language_holder.offset_left = -320.0
		_language_holder.offset_top = 20.0
		_language_holder.offset_right = -28.0
		_language_holder.offset_bottom = 72.0
	else:
		_language_holder.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_language_holder.offset_left = 16.0
		_language_holder.offset_right = -16.0
		_language_holder.offset_top = -112.0
		_language_holder.offset_bottom = -64.0
	_language_holder.alignment = BoxContainer.ALIGNMENT_END

	_language_holder.add_child(UIFactory.label("%s: %s" % [
		Loc.t("settings.language"), Loc.language_label(Settings.language),
	], 18, UIFactory.TEXT_DIM))

	var b := UIFactory.button("TH / EN", 18, 110.0)
	UIFactory.style_button(b, UIFactory.TEXT_BRIGHT, false)
	b.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		Settings.set_language("en" if Settings.language == "th" else "th")
		_rebuild_all())
	_language_holder.add_child(b)
	return _language_holder


## Language changes have to rebuild every label, so the whole screen is rebuilt
## in place. Progress on disk is untouched.
func _rebuild_all() -> void:
	hide_overlay()
	_rebuild_page()


## Rebuilds the page (everything except the modal overlay) so a resize can change
## the layout's *shape*, not just its widths. An open modal is left alone: its
## panel already re-fits itself through `refresh_responsive()`.
func _rebuild_page() -> void:
	clear_page()
	_build()


func rebuild_for_size() -> void:
	_rebuild_page()


func _footer() -> Control:
	var holder := HBoxContainer.new()
	holder.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	holder.offset_left = 32.0
	holder.offset_right = -32.0
	holder.offset_top = -40.0
	holder.offset_bottom = -12.0
	# The competition line is the first thing to go when there is no room for it.
	if not UIFactory.is_compact():
		var left := UIFactory.label(Loc.t("app.competition"), 15, UIFactory.TEXT_DIM)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.add_child(left)
	else:
		holder.add_child(UIFactory.spacer())
	holder.add_child(UIFactory.label("v%s" % GameConfig.GAME_VERSION, 15, UIFactory.TEXT_DIM))
	return holder


# ------------------------------------------------------------------ panels -----
func _how_to_play_panel() -> Control:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	UIFactory.responsive_min_size(panel, 700.0)
	var v := UIFactory.vbox(12)
	panel.add_child(v)
	v.add_child(UIFactory.title(Loc.t("how.title"), 32))
	v.add_child(UIFactory.wrap(Loc.t("how.intro"), 19))
	v.add_child(UIFactory.callout(Loc.t("how.mouse"), UIFactory.ACCENT))
	v.add_child(UIFactory.wrap(Loc.t("how.touch"), 18, UIFactory.TEXT_DIM))
	v.add_child(UIFactory.wrap(Loc.t("how.retry"), 18, UIFactory.TEXT_DIM))

	var helpers := UIFactory.vbox(6)
	for key in ["task.watch_demo", "task.tap", "task.drag", "task.hold"]:
		helpers.add_child(UIFactory.label("• " + Loc.t(key), 18, UIFactory.TEXT_DIM))
	v.add_child(helpers)
	v.add_child(UIFactory.wrap("%s — %s" % [Loc.t("hud.pause"), InputManager.primary_keys_text()], 16, UIFactory.TEXT_DIM))
	v.add_child(centred(close_button()))
	return panel


func _sources_panel() -> Control:
	var panel := UIFactory.panel(UIFactory.PANEL_COLOR)
	UIFactory.responsive_min_size(panel, 780.0)
	var v := UIFactory.vbox(10)
	panel.add_child(v)
	v.add_child(UIFactory.title(Loc.t("sources.title"), 32))
	v.add_child(UIFactory.wrap(Loc.t("sources.intro"), 18, UIFactory.TEXT_DIM))

	var scroll := ScrollContainer.new()
	UIFactory.responsive_min_size(scroll, 740.0, 380.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := UIFactory.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for source in Education.all_sources():
		var card := UIFactory.panel(UIFactory.CARD_COLOR)
		var cv := UIFactory.vbox(4)
		card.add_child(cv)
		cv.add_child(UIFactory.label(str(source.get("publisher", "")), 18, UIFactory.ACCENT, true))
		cv.add_child(UIFactory.wrap(str(source.get("title", "")), 17))
		cv.add_child(UIFactory.wrap(str(source.get("url", "")), 14, UIFactory.TEXT_DIM))
		list.add_child(card)
	v.add_child(scroll)

	v.add_child(UIFactory.callout(Loc.t("lesson.disclaimer"), UIFactory.GOOD, 16))
	v.add_child(UIFactory.label("%s: %s" % [Loc.t("sources.reviewed"), Education.review_date()], 15, UIFactory.TEXT_DIM))
	v.add_child(centred(close_button()))
	return panel


func _settings_panel() -> Control:
	var settings := SettingsPanel.new()
	UIFactory.responsive_min_size(settings, 720.0)
	settings.closed.connect(hide_overlay)
	return settings
