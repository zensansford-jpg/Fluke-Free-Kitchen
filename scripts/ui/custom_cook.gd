class_name CustomCook
## The recipe creator: the player builds a dish of their own.
##
## Every choice comes from the same real catalogue the rest of the game uses — real
## fish, real ingredients, real methods — and the finished dish is held to the same
## validator as a hand-written recipe before it can be cooked. It is never presented
## as a traditional recipe: the game labels it plainly as the player's own creation,
## and the mandatory safe-cook step is present exactly as it is everywhere else.
##
## The composition is what gets saved to the cookbook, so a saved dish is always run
## with the current rules rather than a stale step list.

extends MenuScreen

## The dish being built. Kept on the instance so a resize or a re-selection reflows
## the same dish instead of resetting it. The name is held here too and restored into
## the field, because a rebuild frees the old field.
var _name := ""
var _fish_id := ""
var _method_id := ""
var _ingredients: Array = []
var _garnish: Array = []
var _plating_id := ""

var _message := ""
var _message_good := false
var _just_saved := false

## Live references so typing a name updates the message and the buttons without
## rebuilding the page (which would move the caret on every keystroke).
var _status_label: Label = null
var _cook_button: Button = null
var _save_button: Button = null


func _ready() -> void:
	super()
	# Sensible starting choices so the page is usable at once and the preview shows a
	# real plate. Nothing is hidden: the player can change all of them.
	if _fish_id.is_empty() and not RecipeDB.fish().is_empty():
		_fish_id = str((RecipeDB.fish()[0] as Dictionary).get("id", ""))
	if _method_id.is_empty() and not RecipeDB.methods().is_empty():
		_method_id = str((RecipeDB.methods()[0] as Dictionary).get("id", ""))
	if _plating_id.is_empty() and not RecipeDB.plating_styles().is_empty():
		_plating_id = str((RecipeDB.plating_styles()[0] as Dictionary).get("id", ""))
	_build()


func _build() -> void:
	_set_default_message()

	var column := scroll_page(30, 16)
	column.add_child(title_block("custom.title", "custom.subtitle"))

	column.add_child(UIFactory.label(Loc.t("custom.name_label"), 21, UIFactory.ACCENT, true))
	var field := UIFactory.text_input(Loc.t("custom.name_hint"), _name, 24)
	UIFactory.responsive_min_size(field, 360.0, 50.0)
	field.text_changed.connect(func(text: String) -> void:
		_name = text
		_refresh_status())
	column.add_child(centred(field))

	column.add_child(UIFactory.label(Loc.t("custom.fish"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(_fish_grid()))
	if not _fish_id.is_empty():
		column.add_child(centred(_fish_note()))

	column.add_child(UIFactory.label(Loc.t("custom.method"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(_method_grid()))

	column.add_child(UIFactory.label(Loc.t("custom.ingredients"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(UIFactory.wrap(Loc.t("custom.ingredients_hint"), 15, UIFactory.TEXT_DIM)))
	column.add_child(centred(_ingredient_grid()))

	column.add_child(UIFactory.label(Loc.t("custom.garnish"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(UIFactory.wrap(Loc.t("custom.garnish_hint"), 15, UIFactory.TEXT_DIM)))
	column.add_child(centred(_garnish_grid()))

	column.add_child(UIFactory.label(Loc.t("custom.plating"), 21, UIFactory.ACCENT, true))
	column.add_child(centred(_plating_grid()))

	column.add_child(gap(6))
	column.add_child(centred(_preview_card()))

	# The status line says either "ready to cook" or the one thing that is missing,
	# so the disabled buttons never leave the player guessing.
	_status_label = UIFactory.wrap(_message, 17, _status_colour())
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(centred(_status_label))

	_cook_button = UIFactory.button(Loc.t("custom.cook"), 22, 260.0)
	UIFactory.style_button(_cook_button, UIFactory.GOOD, true)
	_cook_button.disabled = _compose().is_empty()
	# Recomposed at press time, not build time, so a name typed since the last rebuild
	# is part of the dish that gets cooked.
	_cook_button.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		Game.start_custom(_compose()))
	column.add_child(centred(_cook_button))

	_save_button = UIFactory.button(Loc.t("custom.save"), 20, 260.0)
	UIFactory.style_button(_save_button, UIFactory.ACCENT, false)
	_save_button.disabled = _compose().is_empty()
	_save_button.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		_save(_compose()))
	column.add_child(centred(_save_button))

	column.add_child(centred(back_button(func() -> void: Game.navigate("cookbook"))))


func rebuild_for_size() -> void:
	clear_page()
	_build()


# ----------------------------------------------------------------- selection ---
func _fish_grid() -> GridContainer:
	var grid := _grid(4, 2)
	for entry in RecipeDB.fish():
		var fish: Dictionary = entry
		var fish_id := str(fish.get("id", ""))
		grid.add_child(_toggle(_fish_label(fish), fish_id == _fish_id, UIFactory.ACCENT, 200.0, 4, 2,
			func() -> void:
				_fish_id = fish_id
				rebuild_for_size()))
	return grid


func _method_grid() -> GridContainer:
	var grid := _grid(3, 2)
	for entry in RecipeDB.methods():
		var method: Dictionary = entry
		var method_id := str(method.get("id", ""))
		grid.add_child(_toggle(RecipeDB.method_display_name(method), method_id == _method_id, UIFactory.GOOD,
			220.0, 3, 2,
			func() -> void:
				_method_id = method_id
				rebuild_for_size()))
	return grid


func _ingredient_grid() -> GridContainer:
	var grid := _grid(2, 1)
	for entry in RecipeDB.ingredients():
		var ingredient: Dictionary = entry
		var ingredient_id := str(ingredient.get("id", ""))
		grid.add_child(_toggle(LessonDB.text(ingredient, "name", Loc.language),
			_ingredients.has(ingredient_id), UIFactory.ACCENT, 240.0, 2, 1,
			func() -> void:
				_toggle_in(_ingredients, ingredient_id, RecipeDB.CUSTOM_INGREDIENT_MAX)
				rebuild_for_size()))
	return grid


func _garnish_grid() -> GridContainer:
	var grid := _grid(2, 1)
	for entry in RecipeDB.garnishes():
		var garnish: Dictionary = entry
		var garnish_id := str(garnish.get("id", ""))
		grid.add_child(_toggle(LessonDB.text(garnish, "name", Loc.language),
			_garnish.has(garnish_id), UIFactory.GOOD, 240.0, 2, 1,
			func() -> void:
				_toggle_in(_garnish, garnish_id, RecipeDB.CUSTOM_GARNISH_MAX)
				rebuild_for_size()))
	return grid


func _plating_grid() -> GridContainer:
	var grid := _grid(3, 2)
	for entry in RecipeDB.plating_styles():
		var plating: Dictionary = entry
		var plating_id := str(plating.get("id", ""))
		grid.add_child(_toggle(LessonDB.text(plating, "name", Loc.language),
			plating_id == _plating_id, UIFactory.ACCENT, 220.0, 3, 2,
			func() -> void:
				_plating_id = plating_id
				rebuild_for_size()))
	return grid


func _grid(wide: int, narrow: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(wide, narrow)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	return grid


## One selectable chip. A chosen chip is filled, an unchosen one is outlined, so the
## current dish reads at a glance without any extra label.
func _toggle(text: String, selected: bool, accent: Color, natural: float,
		wide: int, narrow: int, action: Callable) -> Button:
	var button := UIFactory.button(text, 18, natural)
	UIFactory.style_button(button, accent, selected)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# These buttons are the grid children, so their minimum has to be capped to their
	# column or a full ingredient list would push the page past a tablet edge.
	UIFactory.responsive_grid_size(button, natural, wide, narrow, 54.0, 12)
	button.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		action.call())
	return button


## Adds or removes an id from a list, never letting it grow past `maximum`. Tapping a
## chosen chip removes it, so a mistaken tap is undone the same way it was made.
func _toggle_in(list: Array, value: String, maximum: int) -> void:
	if list.has(value):
		list.erase(value)
		return
	if list.size() >= maximum:
		return
	list.append(value)


# ------------------------------------------------------------------ composing ---
## The recipe for the current choices, or `{}` when the dish is not yet cookable.
func _compose() -> Dictionary:
	if _fish_id.is_empty() or _method_id.is_empty() or _plating_id.is_empty():
		return {}
	return RecipeDB.custom_recipe(_name, _fish_id, _method_id, _ingredients, _garnish, _plating_id)


## Recomputes the status line and the buttons after a name edit, without rebuilding the
## page (which would move the caret to the end of the field on every keystroke).
func _refresh_status() -> void:
	_set_default_message()
	if _status_label != null and is_instance_valid(_status_label):
		_status_label.text = _message
		_status_label.add_theme_color_override("font_color", _status_colour())
	var ready := not _compose().is_empty()
	for button in [_cook_button, _save_button]:
		if button != null and is_instance_valid(button):
			(button as Button).disabled = not ready


func _set_default_message() -> void:
	if _just_saved:
		return
	if _name.strip_edges().is_empty():
		_message = Loc.t("custom.need_name")
		_message_good = false
		return
	if _ingredients.is_empty():
		_message = Loc.t("custom.need_ingredient")
		_message_good = false
		return
	if _compose().is_empty():
		_message = Loc.t("custom.need_ingredient")
		_message_good = false
		return
	_message = Loc.t("custom.ready")
	_message_good = true


func _status_colour() -> Color:
	if _message.is_empty():
		return UIFactory.TEXT_DIM
	return UIFactory.GOOD if _message_good else UIFactory.ACCENT


func _save(recipe: Dictionary) -> void:
	if recipe.is_empty():
		return
	SaveData.save_recipe(recipe)
	_just_saved = true
	_message = Loc.t("custom.saved")
	_message_good = true
	rebuild_for_size()


func _preview_card() -> PanelContainer:
	var recipe := _compose()
	# The preview needs a recipe-shaped dictionary for the fish silhouette. Before the
	# dish is valid there is still a fish choice, so a preview is built from that and
	# the texture never goes blank while the player is deciding.
	var preview_recipe := recipe
	if preview_recipe.is_empty():
		preview_recipe = {
			"fish": [_fish_id] if not _fish_id.is_empty() else [],
			"garnish": _garnish,
		}
	var card := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.responsive_grid_size(card, 420.0, 1, 1, 420.0, 0)
	var v := UIFactory.vbox(8)
	card.add_child(v)
	v.add_child(UIFactory.label(Loc.t("custom.preview"), 20, UIFactory.TEXT_BRIGHT, true))
	var preview := DishPreview.new()
	preview.custom_minimum_size = Vector2(0, 150)
	preview.configure(preview_recipe, true)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(preview)
	if not recipe.is_empty():
		v.add_child(centred(UIFactory.label(
			"%s: %s" % [Loc.t("custom.difficulty"),
				_difficulty_text(int(recipe.get("difficulty", 1)))],
			16, UIFactory.TEXT_DIM)))
	return card


func _fish_note() -> Label:
	var fish := RecipeDB.fish_by_id(_fish_id)
	if fish.is_empty():
		return UIFactory.label("", 16, UIFactory.TEXT_DIM)
	return UIFactory.wrap(Loc.t("custom.freshwater_note") if bool(fish.get("fluke_host", false))
		else Loc.t("free.sea_note"), 16, UIFactory.TEXT_DIM)


## The fish name plus an honesty marker: a colour variety says so in the chip, so the
## list never reads as if it held more species than it does.
func _fish_label(fish: Dictionary) -> String:
	var fish_name := LessonDB.text(fish, "name", Loc.language)
	if not str(fish.get("variant_of", "")).is_empty():
		fish_name += " ·"
	return fish_name


func _difficulty_text(difficulty: int) -> String:
	var out := ""
	for i in 3:
		out += "*" if i < difficulty else "-"
	return out
