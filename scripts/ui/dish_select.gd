class_name DishSelect
## The dish browser for Let's Cook.
##
## Every dish is a card with a picture drawn from the catalogue, whether it is a
## real Thai dish or a game challenge (the two are labelled differently on purpose).
## Locked dishes are shown, dimmed, so the player can see what is coming without
## being told it exists for no reason.
##
## Nothing is unlocked by grinding: a dish opens when the dish it comes from has
## been finished. The first dishes have no dependency at all, so there is always
## something good to cook from the very first visit.

extends MenuScreen


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

	_recent_row(column)

	if RecipeDB.recipe_count() == 0:
		column.add_child(centred(UIFactory.wrap(Loc.t("dishes.none"), 20, UIFactory.TEXT_DIM)))
		column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))
		return

	# Real dishes first, then the challenge variations, each in catalogue order and
	# sorted by difficulty so the grid reads as a menu that opens up.
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(3)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	var index := 0
	for recipe in _sorted_recipes():
		var card := _recipe_card(recipe, discovered)
		grid.add_child(card)
		UIFactory.entrance(card, 0.04 + float(index % 9) * 0.035)
		index += 1
	column.add_child(centred(grid))

	column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))


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
		return bool(a.get("real", true)) and not bool(b.get("real", true)))
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
	# cooked, and whether it is a documented dish or a game variation. Each is a
	# capsule now, so the differences are visible at a glance instead of being
	# three lines of small grey text in a row. They wrap, because three Thai
	# capsules on one unbending line are wider than a phone screen.
	var badges := UIFactory.tag_row(6)
	badges.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var real := bool(recipe.get("real", true))
	badges.add_child(UIFactory.chip(
		Loc.t("dishes.real") if real else Loc.t("dishes.variation_short"),
		UIFactory.ACCENT if real else Color(0.62, 0.72, 0.92), true))
	if not real and not _cooked_on_a_stove(recipe):
		badges.add_child(UIFactory.chip(Loc.t("dishes.no_heat"), Color(0.62, 0.72, 0.92)))
	var region := RecipeDB.region_of(recipe)
	if not region.is_empty():
		badges.add_child(UIFactory.chip(region, Color(0.55, 0.9, 0.8)))
	v.add_child(badges)

	v.add_child(UIFactory.wrap(RecipeDB.about(recipe), 16, UIFactory.TEXT_DIM))

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


func _difficulty_text(difficulty: int) -> String:
	var out := ""
	for i in 3:
		out += "*" if i < difficulty else "-"
	return out
