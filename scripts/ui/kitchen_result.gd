class_name KitchenResult
extends Control
## The end-of-challenge screen.
##
## It reports four separate things rather than one number, because they mean
## different things: how much was done, how much was done without a mistake, how
## the food-safety decisions went, and how the knowledge check went. The star row
## is the headline, and the note underneath says out loud what the scoring means.

signal retry_pressed()
signal next_pressed()
signal levels_pressed()
signal journal_pressed()

var _star_row: StarRow = null
var _panel: PanelContainer = null
var _buttons_grid: GridContainer = null


func _ready() -> void:
	UIFactory.fill(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UIFactory.backdrop())


## Re-centres the result card for the current window size.
func apply_layout() -> void:
	if _panel != null and is_instance_valid(_panel):
		UIFactory.centre_box(_panel, 740.0, 660.0)
	if _buttons_grid != null and is_instance_valid(_buttons_grid):
		_buttons_grid.columns = UIFactory.columns(2)
	UIFactory.refresh_responsive(self)


func show_result(level: Dictionary, result: Dictionary, save_info: Dictionary) -> void:
	for child in get_children():
		if child is ColorRect:
			continue
		child.queue_free()

	_panel = UIFactory.panel(UIFactory.PANEL_COLOR)
	add_child(_panel)
	UIFactory.centre_box(_panel, 740.0, 660.0)

	# The card is tall: on a short window its body scrolls rather than pushing the
	# action buttons off the bottom edge.
	var scroll := ScrollContainer.new()
	scroll.name = "ResultScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	var v := UIFactory.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	var passed := bool(result.get("passed", false))
	v.add_child(_centred(UIFactory.title(
		Loc.t("result.title") if passed else Loc.t("result.title_retry"), 34)))

	_star_row = StarRow.new()
	_star_row.configure(GameConfig.STARS_MAX, 46.0, 12.0)
	v.add_child(_centred(_star_row))

	if bool(save_info.get("new_best_score", false)):
		v.add_child(_centred(UIFactory.label(Loc.t("result.new_best"), 20, UIFactory.GOOD, true)))

	v.add_child(UIFactory.wrap(LevelDB.title(level), 20, UIFactory.TEXT_DIM))

	var steps_total := int(result.get("steps_total", 0))
	var steps_first := int(result.get("steps_first_try", 0))
	var safety_total := int(result.get("safety_total", 0))
	var safety_first := int(result.get("safety_first_try", 0))
	var quiz_correct := int(result.get("quiz_correct", 0))
	var quiz_answered := int(result.get("quiz_answered", 0))

	v.add_child(_row(Loc.t("result.score"),
		"%d / %d" % [int(result.get("score", 0)), int(result.get("max_score", 0))], UIFactory.ACCENT))
	v.add_child(_row(Loc.t("result.correct_actions"),
		"%d / %d %s" % [steps_first, steps_total, Loc.t("result.first_try")], UIFactory.TEXT_BRIGHT))
	v.add_child(_row(Loc.t("result.safety"),
		"%d / %d %s" % [safety_first, safety_total, Loc.t("result.first_try")], UIFactory.TEXT_BRIGHT))
	v.add_child(_row(Loc.t("result.knowledge"),
		"%d / %d" % [quiz_correct, quiz_answered], UIFactory.GOOD))
	v.add_child(_row(Loc.t("result.time"),
		_format_time(float(result.get("seconds", 0.0))), UIFactory.TEXT_DIM))

	v.add_child(UIFactory.wrap(Loc.t("result.education_note"), 16, UIFactory.TEXT_DIM))

	var mode := int(result.get("mode", 0))
	if mode == Game.Mode.FREE_COOK:
		v.add_child(UIFactory.wrap(Loc.t("free.experimental_note"), 16, UIFactory.ACCENT))
	elif mode != Game.Mode.STORY and not bool(result.get("real", true)):
		v.add_child(UIFactory.wrap(Loc.t("result.variation_note"), 16, UIFactory.ACCENT))
	if mode == Game.Mode.ENDLESS:
		v.add_child(_row(Loc.t("endless.streak_label"),
			str(int(save_info.get("streak", 0))), UIFactory.ACCENT))
		v.add_child(_row(Loc.t("endless.run_score"),
			str(int(save_info.get("run_score", 0))), UIFactory.TEXT_BRIGHT))

	# Two to a row on a desktop, one on a phone. The buttons expand to fill their
	# columns, so nothing is ever clipped.
	_buttons_grid = GridContainer.new()
	_buttons_grid.columns = UIFactory.columns(2)
	_buttons_grid.add_theme_constant_override("h_separation", 10)
	_buttons_grid.add_theme_constant_override("v_separation", 8)
	if mode == Game.Mode.ENDLESS:
		# In the Endless Kitchen the natural next action is another challenge, and
		# the natural way out is to end the run.
		_buttons_grid.add_child(_button(Loc.t("endless.next"), true, func() -> void: next_pressed.emit()))
		_buttons_grid.add_child(_button(Loc.t("endless.end_run"), false, func() -> void: levels_pressed.emit()))
	else:
		_buttons_grid.add_child(_button(Loc.t("result.retry"), false, func() -> void: retry_pressed.emit()))
		if mode == Game.Mode.STORY and LevelDB.next_level_id(str(level.get("id", ""))) != "":
			_buttons_grid.add_child(_button(Loc.t("result.next_level"), true, func() -> void: next_pressed.emit()))
		elif mode != Game.Mode.STORY:
			_buttons_grid.add_child(_button(Loc.t("result.back_dishes"), true, func() -> void: levels_pressed.emit()))
	_buttons_grid.add_child(_button(Loc.t("journal.title"), false, func() -> void: journal_pressed.emit()))
	if mode != Game.Mode.ENDLESS:
		_buttons_grid.add_child(_button(Loc.t("result.to_levels"), false, func() -> void: levels_pressed.emit()))
	v.add_child(_buttons_grid)

	# Animate the stars in, and let the sound land with them.
	await get_tree().create_timer(0.25).timeout
	if not is_inside_tree():
		return
	var stars := int(result.get("stars", 0))
	_star_row.set_stars(stars, true)
	if stars > 0:
		AudioManager.play_sfx("star_full" if stars >= GameConfig.STARS_MAX else "star")


# --------------------------------------------------------------------- widgets ---
## A compact caption-and-value line. It sets its own padding instead of using the
## shared panel style, because five of these stacked at the shared 20px padding
## push the actions off the bottom of the screen.
func _row(caption: String, value: String, colour: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIFactory.CARD_COLOR
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.10)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)

	var row := UIFactory.hbox(12)
	panel.add_child(row)
	var left := UIFactory.label(caption, 17, UIFactory.TEXT_DIM)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(UIFactory.label(value, 19, colour, true))
	return panel


func _button(text: String, primary: bool, action: Callable) -> Button:
	var button := UIFactory.button(text, 19, 200.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.style_button(button, UIFactory.ACCENT if primary else UIFactory.TEXT_BRIGHT, primary)
	button.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		action.call())
	return button


func _centred(control: Control) -> HBoxContainer:
	return UIFactory.centre_row(control)


static func _format_time(seconds: float) -> String:
	var whole := int(maxf(0.0, seconds))
	return "%d:%02d" % [whole / 60, whole % 60]
