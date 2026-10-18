class_name FreeCook
## Free Cook: choose any fish and any cooking method.
##
## A smaller, reliable version of the idea — two straightforward choices and then
## the same kitchen as everywhere else. The dish the player makes is always labelled
## as their own creation, never as a traditional recipe, and the mandatory
## cook-through step is still there: an unsafe preparation cannot become safe just
## because it was mixed with something else.

extends MenuScreen

var _fish_id := ""
var _method_id := ""


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	var column := scroll_page(30, 16)
	column.add_child(title_block("free.title", "free.subtitle"))

	column.add_child(UIFactory.label(Loc.t("free.fish"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(_fish_grid()))
	if not _fish_id.is_empty():
		column.add_child(centred(_fish_note()))

	column.add_child(UIFactory.label(Loc.t("free.method"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(_method_grid()))

	var start := UIFactory.button(Loc.t("free.start"), 24, 320.0)
	UIFactory.style_button(start, UIFactory.GOOD, true)
	start.disabled = _fish_id.is_empty() or _method_id.is_empty()
	start.pressed.connect(_start)
	column.add_child(centred(start))
	if start.disabled:
		column.add_child(centred(UIFactory.wrap(Loc.t("free.pick_both"), 16, UIFactory.TEXT_DIM)))

	column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))


func rebuild_for_size() -> void:
	clear_page()
	_build()


func _fish_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(4, 2)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for entry in RecipeDB.fish():
		var fish: Dictionary = entry
		var fish_id := str(fish.get("id", ""))
		var button := UIFactory.button(_fish_label(fish), 18, 200.0)
		var selected := fish_id == _fish_id
		UIFactory.style_button(button, UIFactory.ACCENT, selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# These buttons *are* the grid children, so their minimum has to be capped to
		# their column: nine natural-width buttons asked for 836 pixels where a 768
		# pixel tablet only has 708.
		UIFactory.responsive_grid_size(button, 200.0, 4, 2, 54.0, 12)
		button.pressed.connect(func() -> void:
			_fish_id = fish_id
			rebuild_for_size())
		grid.add_child(button)
	return grid


## The fish name plus an honesty marker: a colour variety says so in the button, so
## the list never reads as if it held more species than it does.
func _fish_label(fish: Dictionary) -> String:
	var name := LessonDB.text(fish, "name", Loc.language)
	if not str(fish.get("variant_of", "")).is_empty():
		name += " ·"
	return name


func _fish_note() -> Label:
	var fish := RecipeDB.fish_by_id(_fish_id)
	if fish.is_empty():
		return UIFactory.label("", 16, UIFactory.TEXT_DIM)
	var parts: Array = []
	var note := LessonDB.text(fish, "note", Loc.language)
	if not note.is_empty():
		parts.append(note)
	parts.append(Loc.t("free.freshwater_note") if bool(fish.get("fluke_host", false))
		else Loc.t("free.sea_note"))
	var text := ""
	for i in parts.size():
		if i > 0:
			text += "  "
		text += str(parts[i])
	return UIFactory.wrap(text, 16, UIFactory.TEXT_DIM)


func _method_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(3, 2)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for entry in RecipeDB.methods():
		var method: Dictionary = entry
		var method_id := str(method.get("id", ""))
		var button := UIFactory.button(RecipeDB.method_display_name(method), 18, 220.0)
		var selected := method_id == _method_id
		UIFactory.style_button(button, UIFactory.GOOD, selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIFactory.responsive_grid_size(button, 220.0, 3, 2, 54.0, 12)
		button.pressed.connect(func() -> void:
			_method_id = method_id
			rebuild_for_size())
		grid.add_child(button)
	return grid


func _start() -> void:
	if _fish_id.is_empty() or _method_id.is_empty():
		return
	Game.start_free_cook(_fish_id, _method_id)
