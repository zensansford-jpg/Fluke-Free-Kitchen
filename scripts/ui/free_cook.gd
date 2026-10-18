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
## The composed dishes on show, and the seed they were drawn from. Kept on the
## instance so a resize reflows the same dishes instead of rolling new ones.
var _composed: Array = []
var _compose_seed := 1200


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

	# Composed dishes: the same real fish, ingredients and methods, arranged by the
	# game. This is the "unlimited cuisine" idea made concrete — the player can never
	# run out of something new to cook, and every composed dish is still held to the
	# same validator and the same mandatory safe-cook step as a written recipe.
	column.add_child(gap(18))
	column.add_child(UIFactory.label(Loc.t("free.composed_title"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(UIFactory.wrap(Loc.t("free.composed_note"), 16, UIFactory.TEXT_DIM)))
	column.add_child(centred(_composed_grid()))
	var surprise := UIFactory.button(Loc.t("free.surprise"), 20, 260.0)
	UIFactory.style_button(surprise, UIFactory.ACCENT, false)
	surprise.pressed.connect(_surprise)
	column.add_child(centred(surprise))

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


# ----------------------------------------------------------- composed dishes ---
## Three dishes the game composed itself, from the seed the page is currently on.
## Generated once and cached so the row does not change under the player on resize.
func _composed_grid() -> GridContainer:
	if _composed.is_empty():
		_composed = RecipeDB.generated_pool(3, _compose_seed)
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(3, 1)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	for entry in _composed:
		var dish: Dictionary = entry
		grid.add_child(_composed_card(dish))
	return grid


func _composed_card(dish: Dictionary) -> PanelContainer:
	var card := UIFactory.panel(UIFactory.CARD_COLOR)
	# A grid child, so its minimum is capped to its column. The card's own 20 pixel
	# padding is what the button inside measures against (see `inset` below).
	UIFactory.responsive_grid_size(card, 300.0, 3, 1, 360.0, 18)
	var v := UIFactory.vbox(10)
	card.add_child(v)

	var preview := DishPreview.new()
	preview.custom_minimum_size = Vector2(0, 130)
	# The preview is drawn from the recipe, not the challenge: same seed, so the same
	# dish, and the silhouette comes from the fish the dish actually names.
	preview.configure(RecipeDB.generate_recipe(int(dish.get("seed", 0))), true)
	v.add_child(preview)

	v.add_child(UIFactory.wrap(RecipeDB.local(dish.get("title", {})), 19, UIFactory.TEXT_BRIGHT))
	v.add_child(UIFactory.wrap(Loc.t("free.experimental_note"), 14, UIFactory.TEXT_DIM))

	var cook := UIFactory.button(Loc.t("free.cook_this"), 18, 160.0)
	UIFactory.style_button(cook, UIFactory.GOOD, true)
	cook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.responsive_grid_size(cook, 160.0, 3, 1, 48.0, 18, 40.0)
	var seed_value := int(dish.get("seed", 0))
	cook.pressed.connect(func() -> void: Game.start_generated(seed_value))
	v.add_child(centred(cook))
	return card


## Rolls a fresh set of composed dishes and rebuilds the page around them.
func _surprise() -> void:
	_compose_seed += 3
	_composed.clear()
	rebuild_for_size()
