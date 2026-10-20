class_name DishSelect
## The dish browser for Let's Cook.
##
## Every dish is a card with a picture drawn from the catalogue, and every card
## carries its **provenance grade** in plain words: a documented dish, a regional
## variation, a fusion dish or a game composition. The four are different claims
## about the world, so they are never allowed to look alike. Locked dishes are
## shown, dimmed, so the player can see what is coming without being told it exists
## for no reason.
##
## Nothing is unlocked by grinding: a dish opens when the dish it comes from has
## been finished. The first dishes have no dependency at all, so there is always
## something good to cook from the very first visit.

extends MenuScreen

## The active filter. `all` is the default; the others narrow the list without
## changing the order, so the grid always reads the same way.
enum Filter { ALL, OPEN, FAVOURITES, DOCUMENTED, REGIONAL, OTHER }

var _filter := Filter.ALL
## The current query, lower-cased. Kept on the instance so a resize reflows the
## same set of dishes rather than resetting what the player typed.
var _query := ""


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	var column := scroll_page(30, 16)
	column.add_child(title_block("dishes.title", "dishes.subtitle"))

	var discovered := SaveData.discovered_ids()
	column.add_child(centred(UIFactory.chip(
		"%s: %d / %d" % [Loc.t("dishes.discovered"), SaveData.discovered_count(),
			RecipeDB.recipe_count()],
		UIFactory.ACCENT)))

	if RecipeDB.recipe_count() == 0:
		column.add_child(centred(UIFactory.wrap(Loc.t("dishes.none"), 20, UIFactory.TEXT_DIM)))
		column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))
		return

	# The browser bar: a search box, a row of filters and a random pick. With a
	# catalogue that now runs from documented tradition to game compositions, a
	# flat list stops being navigable — this is what makes it usable.
	column.add_child(_browse_bar())

	# What you cooked last, kept as a one-line convenience above the grid — the
	# search box can find these again, but this says it without typing.
	_recent_row(column)

	var matches := _matching_recipes()
	if matches.is_empty():
		column.add_child(centred(UIFactory.wrap(Loc.t("dishes.no_matches"), 19, UIFactory.TEXT_DIM)))
		column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))
		return

	column.add_child(centred(UIFactory.chip(
		"%s: %d" % [Loc.t("dishes.matches"), matches.size()], UIFactory.TEXT_DIM)))

	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(3)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	var index := 0
	for recipe in matches:
		var card := _recipe_card(recipe, discovered)
		grid.add_child(card)
		UIFactory.entrance(card, 0.04 + float(index % 9) * 0.035)
		index += 1
	column.add_child(centred(grid))

	column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))


# --------------------------------------------------------------------- browsing ---
## The search box, the filter row and the random button.
##
## Every control rebuilds the page on change rather than mutating the grid, so
## there is exactly one path that decides what is on screen and a resize cannot
## disagree with it.
func _browse_bar() -> VBoxContainer:
	var v := UIFactory.vbox(10)

	var pair := UIFactory.search_row(Loc.t("dishes.search"))
	var field: LineEdit = pair[1]
	field.text = _query
	field.text_changed.connect(func(text: String) -> void:
		_query = text.strip_edges().to_lower()
		rebuild_for_size())
	v.add_child(pair[0])

	var tags := UIFactory.tag_row(8)
	for entry in _filter_entries():
		var spec: Dictionary = entry
		var id := int(spec["id"])
		var button := UIFactory.button(str(spec["label"]), 17, 0.0)
		button.custom_minimum_size = Vector2(0, 42)
		UIFactory.style_button(button, UIFactory.ACCENT, id == _filter)
		button.pressed.connect(func() -> void:
			AudioManager.play_ui("ui_click")
			_filter = id
			rebuild_for_size())
		tags.add_child(button)
	v.add_child(centred(tags))

	v.add_child(centred(_random_button()))
	return v


## "Surprise me": cooks a dish drawn at random from whatever the current query and
## filter are showing, preferring one that is already open. A random pick that
## ignored the search box would be a way to bypass what the player just asked for.
func _random_button() -> Button:
	var button := UIFactory.button(Loc.t("dishes.random"), 19, 240.0)
	UIFactory.style_button(button, UIFactory.GOOD, true)
	button.pressed.connect(_cook_random)
	return button


## The filter chips that are worth showing. A filter with nothing behind it is not
## offered, so the row never presents a dead end.
func _filter_entries() -> Array:
	var out: Array = [{"id": Filter.ALL, "label": Loc.t("dishes.filter_all")}]
	var counts := _filter_counts()
	if int(counts.get(Filter.OPEN, 0)) > 0:
		out.append({"id": Filter.OPEN, "label": Loc.t("dishes.filter_open")})
	if int(counts.get(Filter.FAVOURITES, 0)) > 0:
		out.append({"id": Filter.FAVOURITES, "label": Loc.t("dishes.filter_favourites")})
	if int(counts.get(Filter.DOCUMENTED, 0)) > 0:
		out.append({"id": Filter.DOCUMENTED, "label": Loc.t("dishes.filter_documented")})
	if int(counts.get(Filter.REGIONAL, 0)) > 0:
		out.append({"id": Filter.REGIONAL, "label": Loc.t("dishes.filter_regional")})
	if int(counts.get(Filter.OTHER, 0)) > 0:
		out.append({"id": Filter.OTHER, "label": Loc.t("dishes.filter_other")})
	return out


func _filter_counts() -> Dictionary:
	var discovered := SaveData.discovered_ids()
	var counts := {Filter.OPEN: 0, Filter.FAVOURITES: 0, Filter.DOCUMENTED: 0, Filter.REGIONAL: 0, Filter.OTHER: 0}
	for recipe in RecipeDB.recipes():
		if RecipeDB.is_unlocked(recipe, discovered):
			counts[Filter.OPEN] = int(counts[Filter.OPEN]) + 1
		if SaveData.is_favourite(str(recipe.get("id", ""))):
			counts[Filter.FAVOURITES] = int(counts[Filter.FAVOURITES]) + 1
		match RecipeDB.provenance(recipe):
			RecipeDB.DOCUMENTED:
				counts[Filter.DOCUMENTED] = int(counts[Filter.DOCUMENTED]) + 1
			RecipeDB.REGIONAL:
				counts[Filter.REGIONAL] = int(counts[Filter.REGIONAL]) + 1
			_:
				counts[Filter.OTHER] = int(counts[Filter.OTHER]) + 1
	return counts


## The dishes that survive the current query and filter, in catalogue order.
##
## The search looks at the dish's name, the fish it uses, its ingredients and its
## descriptive text, which is what makes "tilapia" or "lemongrass" a way in. It
## matches in both languages, so a player searching in Thai finds the same dishes
## as one searching in English.
func _matching_recipes() -> Array:
	var discovered := SaveData.discovered_ids()
	var out: Array = []
	for recipe in _sorted_recipes():
		if not _passes_filter(recipe, discovered):
			continue
		if not _query.is_empty() and not _matches_query(recipe):
			continue
		out.append(recipe)
	return out


func _passes_filter(recipe: Dictionary, discovered: Array) -> bool:
	var recipe_id := str(recipe.get("id", ""))
	match _filter:
		Filter.OPEN:
			return RecipeDB.is_unlocked(recipe, discovered)
		Filter.FAVOURITES:
			return SaveData.is_favourite(recipe_id)
		Filter.DOCUMENTED:
			return RecipeDB.provenance(recipe) == RecipeDB.DOCUMENTED
		Filter.REGIONAL:
			return RecipeDB.provenance(recipe) == RecipeDB.REGIONAL
		Filter.OTHER:
			return not RecipeDB.is_traditional(recipe)
	return true


func _matches_query(recipe: Dictionary) -> bool:
	return RecipeDB.matches_query(recipe, _query)


## Cooks a dish picked at random from what is currently on screen. A random pick
## that ignored the filter would be a way to bypass the "ready to cook" view.
func _cook_random() -> void:
	var pool := _matching_recipes()
	var open: Array = []
	for recipe in pool:
		if RecipeDB.is_unlocked(recipe, SaveData.discovered_ids()):
			open.append(recipe)
	var from: Array = open if not open.is_empty() else pool
	if from.is_empty():
		return
	AudioManager.play_ui("ui_click")
	var pick: Dictionary = from[randi() % from.size()]
	Game.start_recipe(str(pick.get("id", "")))



func rebuild_for_size() -> void:
	clear_page()
	_build()


func _sorted_recipes() -> Array:
	var out: Array = []
	for recipe in RecipeDB.real_recipes():
		out.append(recipe)
	for recipe in RecipeDB.variations():
		out.append(recipe)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := int(a.get("difficulty", 1))
		var db := int(b.get("difficulty", 1))
		if da != db:
			return da < db
		# Within a difficulty, the better-attested dishes come first, so the list
		# reads as a progression from documented tradition to game composition.
		var grade_a := RecipeDB.PROVENANCE_ORDER.find(RecipeDB.provenance(a))
		var grade_b := RecipeDB.PROVENANCE_ORDER.find(RecipeDB.provenance(b))
		return grade_a < grade_b)
	return out


func _recent_row(column: VBoxContainer) -> void:
	var recent := SaveData.recent_ids()
	if recent.is_empty():
		return
	var names: Array = []
	for recipe_id in recent:
		var recipe := RecipeDB.recipe_by_id(str(recipe_id))
		if not recipe.is_empty():
			names.append(RecipeDB.title(recipe))
	if names.is_empty():
		return
	var joined := ""
	for i in names.size():
		if i > 0:
			joined += ", "
		joined += str(names[i])
	column.add_child(centred(UIFactory.wrap(
		"%s: %s" % [Loc.t("dishes.recent"), joined], 16, UIFactory.TEXT_DIM)))


func _recipe_card(recipe: Dictionary, discovered: Array) -> PanelContainer:
	var recipe_id := str(recipe.get("id", ""))
	var unlocked := RecipeDB.is_unlocked(recipe, discovered)
	var stats := SaveData.recipe_stats(recipe_id)
	var is_discovered := bool(stats.get("discovered", false))

	var panel := UIFactory.panel(UIFactory.CARD_COLOR if unlocked else UIFactory.PANEL_COLOR)
	UIFactory.responsive_grid_size(panel, 340.0, 3, 1, 440.0, 18)

	var v := UIFactory.vbox(8)
	panel.add_child(v)

	var preview := DishPreview.new()
	preview.custom_minimum_size = Vector2(0, 130)
	preview.configure(recipe, unlocked)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(preview)

	v.add_child(UIFactory.wrap(RecipeDB.title(recipe), 23, UIFactory.TEXT_BRIGHT, true))

	# The facts that let a player choose: where the dish is from, how it is
	# cooked, and — in plain words — how well attested the dish is. Each is a
	# capsule now, so the differences are visible at a glance instead of being
	# three lines of small grey text in a row. They wrap, because three Thai
	# capsules on one unbending line are wider than a phone screen.
	#
	# The provenance grade replaces the old real/not flag: a documented dish, a
	# regional variation, a fusion dish and a game composition are four different
	# claims, and the card now says which one it is making.
	var badges := UIFactory.tag_row(6)
	badges.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grade := RecipeDB.provenance(recipe)
	badges.add_child(UIFactory.chip(
		RecipeDB.provenance_label(recipe), _provenance_colour(grade), true))
	if not RecipeDB.is_traditional(recipe) and not _cooked_on_a_stove(recipe):
		badges.add_child(UIFactory.chip(Loc.t("dishes.no_heat"), Color(0.62, 0.72, 0.92)))
	var region := RecipeDB.region_of(recipe)
	if not region.is_empty():
		badges.add_child(UIFactory.chip(region, Color(0.55, 0.9, 0.8)))
	v.add_child(badges)

	v.add_child(UIFactory.wrap(RecipeDB.about(recipe), 16, UIFactory.TEXT_DIM))
	v.add_child(UIFactory.wrap(RecipeDB.provenance_note(recipe), 15, UIFactory.TEXT_DIM))

	var difficulty := int(recipe.get("difficulty", 1))
	v.add_child(UIFactory.label(
		"%s: %s" % [Loc.t("dishes.difficulty"), _difficulty_text(difficulty)],
		16, UIFactory.TEXT_DIM))

	if is_discovered:
		var stars := StarRow.new()
		stars.configure(GameConfig.STARS_MAX, 34.0, 9.0)
		stars.stars = int(stats.get("stars", 0))
		stars.custom_minimum_size = Vector2(0, 44)
		v.add_child(centred(stars))
		var best := int(stats.get("best_score", 0))
		v.add_child(centred(UIFactory.label(
			"%s: %s" % [Loc.t("dishes.best"), str(best) if best > 0 else Loc.t("dishes.best_none")],
			16, UIFactory.TEXT_DIM)))
	else:
		v.add_child(centred(UIFactory.label(Loc.t("dishes.locked"), 16, UIFactory.TEXT_DIM)))

	# Favourites are available once the dish has actually been cooked.
	if is_discovered:
		var fav := UIFactory.button(
			Loc.t("dishes.favourited") if SaveData.is_favourite(recipe_id) else Loc.t("dishes.favourite"),
			16, 200.0)
		UIFactory.style_button(fav, UIFactory.ACCENT, SaveData.is_favourite(recipe_id))
		fav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Same inner-column cap as the mode cards: the button must fit the card's
		# column, not its own preferred width.
		UIFactory.responsive_grid_size(fav, 200.0, 3, 1, 54.0, 18, 40.0)
		fav.pressed.connect(func() -> void:
			SaveData.toggle_favourite(recipe_id)
			rebuild_for_size())
		v.add_child(centred(fav))

	v.add_child(gap(4))

	if unlocked:
		var label := Loc.t("dishes.cook_again") if is_discovered else Loc.t("dishes.cook")
		var start := make_button(label, true,
			func() -> void: Game.start_recipe(recipe_id), 180.0)
		start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIFactory.responsive_grid_size(start, 180.0, 3, 1, 54.0, 18, 40.0)
		v.add_child(centred(start))
	else:
		var locked := UIFactory.button(Loc.t("dishes.locked"), 19, 180.0)
		locked.disabled = true
		locked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIFactory.responsive_grid_size(locked, 180.0, 3, 1, 54.0, 18, 40.0)
		UIFactory.style_button(locked, UIFactory.TEXT_DIM, false)
		v.add_child(centred(locked))
		v.add_child(centred(UIFactory.wrap(Loc.t("dishes.locked_hint"), 15, UIFactory.TEXT_DIM)))

	return panel


## Whether a recipe is cooked over heat at all. A dish that is dressed cold is
## shown with its own badge, because "no cooking step" is part of what the card
## has to say — and it is the reason such a dish carries no temperature rule.
func _cooked_on_a_stove(recipe: Dictionary) -> bool:
	for step in recipe.get("steps", []):
		if step is Dictionary and str(step.get("kind", "")) in ["hold", "cook_through", "stir", "flip"]:
			return true
	return false


## The capsule colour for a provenance grade, so the four claims are told apart by
## more than the words: warm gold for a documented dish, cooler tints as the claim
## gets weaker. Colour is never the only signal — the label is always beside it.
func _provenance_colour(grade: String) -> Color:
	match grade:
		RecipeDB.DOCUMENTED:
			return UIFactory.ACCENT
		RecipeDB.REGIONAL:
			return Color(0.62, 0.86, 0.62)
		RecipeDB.FUSION:
			return Color(0.80, 0.68, 0.92)
		RecipeDB.CREATED:
			return Color(0.96, 0.72, 0.52)
		_:
			return Color(0.62, 0.72, 0.92)


func _difficulty_text(difficulty: int) -> String:
	var out := ""
	for i in 3:
		out += "*" if i < difficulty else "-"
	return out
