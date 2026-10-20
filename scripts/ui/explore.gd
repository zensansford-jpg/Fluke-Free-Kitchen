class_name Explore
## Discover: a paged, picture-first browser over the composed dishes.
##
## The kitchen can compose an unbounded number of dishes from real fish, ingredients
## and methods, so a fixed "unlock list" would be a lie. This page shows a page of
## them at a time and lets the player ask for more, without ever building the whole
## set up front: dishes are composed lazily, a page at a time, and only what has been
## asked for exists.
##
## Every dish here is composed by the game and labelled as such — it is never
## presented as a traditional recipe — and every one is validated and carries the
## same mandatory safe-cook step as everything else. The pool is de-duplicated by
## composition, so asking for more pages never just reshuffles the same handful.
##
## The loaded dishes are cached on the instance, so a resize reflows exactly the
## dishes on screen instead of rolling new ones.

extends MenuScreen

## How many dishes one page holds.
const PAGE_SIZE := 6
## The most seeds to scan while looking for a page's worth of fresh dishes, so an
## unlucky run of near-duplicates can never spin forever.
const SCAN_LIMIT := 400

var _entries: Array = []
var _seen: Dictionary = {}
var _cursor := 20261018


func _ready() -> void:
	super()
	_load_page()
	_build()


func _build() -> void:
	var column := scroll_page(30, 16)
	column.add_child(title_block("explore.title", "explore.subtitle"))
	column.add_child(centred(UIFactory.wrap(Loc.t("explore.note"), 16, UIFactory.ACCENT)))
	column.add_child(centred(UIFactory.chip(
		"%s %d" % [Loc.t("explore.count"), _entries.size()], UIFactory.TEXT_DIM)))

	var grid := GridContainer.new()
	grid.columns = UIFactory.columns(3, 1)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	for i in _entries.size():
		var card := _dish_card(_entries[i])
		grid.add_child(card)
		UIFactory.entrance(card, 0.05 + float(i % 6) * 0.045)
	column.add_child(centred(grid))

	var more := make_button(Loc.t("explore.more"), true, func() -> void:
		_load_page()
		rebuild_for_size(), 260.0)
	column.add_child(centred(more))
	column.add_child(centred(back_button(func() -> void: Game.go_to_modes())))


func rebuild_for_size() -> void:
	clear_page()
	_build()


## Composes the next page of dishes, skipping any whose composition has already been
## shown. Bounded by `SCAN_LIMIT` so a run of duplicates cannot hang the page.
func _load_page() -> void:
	var added := 0
	var scanned := 0
	while added < PAGE_SIZE and scanned < SCAN_LIMIT:
		scanned += 1
		var seed_value := _cursor
		_cursor += 1
		var dish := RecipeDB.generate_dish(seed_value)
		if dish.is_empty():
			continue
		var recipe := RecipeDB.generate_recipe(seed_value)
		var signature := RecipeDB.composition_signature(recipe)
		if _seen.has(signature):
			continue
		_seen[signature] = true
		_entries.append({"seed": seed_value, "recipe": recipe})
		added += 1


func _dish_card(entry: Dictionary) -> PanelContainer:
	var recipe: Dictionary = entry["recipe"]
	var seed_value := int(entry["seed"])
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	# The card lives in a grid, so its minimum has to fit its column, and the button
	# inside it has to fit the column *inside* the card's padding.
	UIFactory.responsive_grid_size(panel, 340.0, 3, 1, 440.0, 18)

	var v := UIFactory.vbox(8)
	panel.add_child(v)

	var preview := DishPreview.new()
	preview.custom_minimum_size = Vector2(0, 130)
	preview.configure(recipe, true)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(preview)

	v.add_child(UIFactory.wrap(RecipeDB.local(recipe.get("name", {})), 21, UIFactory.TEXT_BRIGHT, true))
	v.add_child(UIFactory.wrap(RecipeDB.local(recipe.get("about", {})), 15, UIFactory.TEXT_DIM))
	v.add_child(UIFactory.wrap(Loc.t("explore.note"), 14, Color(0.62, 0.72, 0.92)))

	var cook := UIFactory.button(Loc.t("explore.cook"), 19, 200.0)
	UIFactory.style_button(cook, UIFactory.GOOD, true)
	cook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.responsive_grid_size(cook, 200.0, 3, 1, 52.0, 18, 40.0)
	cook.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		Game.start_generated(seed_value))
	v.add_child(centred(cook))

	return panel
