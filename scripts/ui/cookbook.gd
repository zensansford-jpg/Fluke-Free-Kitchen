class_name Cookbook
## The player's own saved dishes.
##
## Each card shows a dish the player built in the recipe creator, drawn from the same
## fish silhouette the kitchen uses, and lets them cook it again or remove it. The
## label is honest throughout: these are the player's own creations, not traditional
## recipes, and cooking one still runs the full safety-checked challenge.

extends MenuScreen


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	var column := scroll_page(30, 16)
	column.add_child(title_block("cookbook.title", "cookbook.subtitle"))

	var saved := SaveData.saved_recipes()
	column.add_child(centred(UIFactory.label(
		"%s: %d" % [Loc.t("cookbook.count"), saved.size()], 18, UIFactory.TEXT_DIM)))

	if saved.is_empty():
		column.add_child(centred(UIFactory.wrap(Loc.t("cookbook.empty"), 20, UIFactory.TEXT_DIM)))
	else:
		var grid := GridContainer.new()
		grid.columns = UIFactory.columns(3, 1)
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 18)
		for entry in saved:
			var recipe: Dictionary = entry
			grid.add_child(_recipe_card(recipe))
		column.add_child(centred(grid))

	var create := make_button(Loc.t("cookbook.create"), true,
		func() -> void: Game.navigate("custom"), 240.0)
	column.add_child(centred(create))
	column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))


func rebuild_for_size() -> void:
	clear_page()
	_build()


func _recipe_card(recipe: Dictionary) -> PanelContainer:
	var recipe_id := str(recipe.get("id", ""))
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.responsive_grid_size(panel, 340.0, 3, 1, 440.0, 18)

	var v := UIFactory.vbox(8)
	panel.add_child(v)

	var preview := DishPreview.new()
	preview.custom_minimum_size = Vector2(0, 130)
	preview.configure(recipe, true)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(preview)

	v.add_child(UIFactory.wrap(RecipeDB.local(recipe.get("name", {})), 23, UIFactory.TEXT_BRIGHT, true))
	v.add_child(UIFactory.wrap(Loc.t("cookbook.made_by_you"), 15, Color(0.62, 0.72, 0.92)))
	v.add_child(UIFactory.wrap(_summary(recipe), 16, UIFactory.TEXT_DIM))

	var cook := make_button(Loc.t("cookbook.cook"), true,
		func() -> void: Game.start_saved(recipe_id), 180.0)
	cook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.responsive_grid_size(cook, 180.0, 3, 1, 54.0, 18, 40.0)
	v.add_child(centred(cook))

	var remove := UIFactory.button(Loc.t("cookbook.delete"), 17, 180.0)
	UIFactory.style_button(remove, UIFactory.BAD, false)
	remove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.responsive_grid_size(remove, 180.0, 3, 1, 48.0, 18, 40.0)
	remove.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_back")
		SaveData.remove_saved_recipe(recipe_id)
		rebuild_for_size())
	v.add_child(centred(remove))

	return panel


## One line describing the dish: its method and how many ingredients it uses.
func _summary(recipe: Dictionary) -> String:
	var method := RecipeDB.method_by_id(str(recipe.get("method", "")))
	var method_name := RecipeDB.method_display_name(method) if not method.is_empty() \
		else str(recipe.get("method", ""))
	var ingredients: Array = recipe.get("ingredients", [])
	return "%s: %s   ·   %s: %d" % [Loc.t("custom.method"), method_name,
		Loc.t("cookbook.ingredients"), ingredients.size()]
