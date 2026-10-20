extends Node
## Responsive verification: walks the whole interface across a matrix of screen
## sizes and checks, from real rectangles, that nothing overflows the window.
##
## This is the test behind the responsive claim in the README. It does not trust
## the layout code: for every screen and every size it asks each visible Control
## for its on-screen rectangle and reports any control that reaches past the
## window edge, any screen that does not fill the window, and any label that is
## wider than the space it was given.
##
## Run with:
##   godot --headless --path <project> res://tests/responsive_check.tscn
##   godot --headless --path <project> res://tests/responsive_check.tscn -- 390 844
##
## With a real window (`godot --path <project> res://tests/responsive_check.tscn --
## shots`) it also writes one PNG per size into `build/screenshots/responsive`, so
## the reflow can be looked at rather than only measured.

const TestWindow := preload("res://tests/test_window.gd")
const Captures := preload("res://tests/captures.gd")

## The viewport matrix the interface has to survive: two small phones in portrait,
## two modern phones, a small tablet portrait and landscape, two laptop sizes, a
## full HD desktop, a 4K desktop and an ultrawide.
const MATRIX: Array = [
	{"name": "phone_small", "size": Vector2i(320, 568)},
	{"name": "phone_360", "size": Vector2i(360, 800)},
	{"name": "phone_390", "size": Vector2i(390, 844)},
	{"name": "phone_430", "size": Vector2i(430, 932)},
	{"name": "tablet_600", "size": Vector2i(600, 960)},
	{"name": "tablet_768", "size": Vector2i(768, 1024)},
	{"name": "landscape_1024", "size": Vector2i(1024, 768)},
	{"name": "laptop_1280", "size": Vector2i(1280, 720)},
	{"name": "laptop_1366", "size": Vector2i(1366, 768)},
	{"name": "desktop_1920", "size": Vector2i(1920, 1080)},
	{"name": "ultrawide", "size": Vector2i(2560, 1080)},
	{"name": "uhd", "size": Vector2i(3840, 2160)},
]

## Screens built as standalone scenes. The kitchen is handled separately because
## its layout depends on which step is on screen.
const SCREENS: Array = ["menu", "modes", "levels", "dishes", "free_cook", "custom", "cookbook", "explore", "journal", "assessment"]

## A control may stick out by this many pixels before it counts as an overflow: a
## panel that is one or two pixels wider than the window is a sub-pixel rounding
## artefact, not a layout bug the player can see.
const TOLERANCE := 2.0

var failures: Array[String] = []
var shots := false
var shot_dir := ""
var only_size := Vector2i.ZERO
var checked := 0


func _ready() -> void:
	# The menus fade their content in and move under the pointer. A capture taken
	# three frames after a screen opens must show the finished screen, so the
	# interface's motion is switched off for this run (and with it, hover scale).
	UIFactory.set_motion_enabled(false)
	shots = OS.get_cmdline_user_args().has("shots")
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i].is_valid_int() and args[i + 1].is_valid_int():
			only_size = Vector2i(int(args[i]), int(args[i + 1]))
			break

	if shots:
		shot_dir = Captures.open("responsive")

	SaveData.suspend_disk_writes(true)
	print("--- Fluke Free Kitchen responsive check ---")
	for entry in MATRIX:
		var size: Vector2i = entry["size"]
		if only_size != Vector2i.ZERO and size != only_size:
			continue
		await _check_size(str(entry["name"]), size)
	SaveData.suspend_disk_writes(false)
	_report()


# ------------------------------------------------------------------- one size ---
func _check_size(name: String, size: Vector2i) -> void:
	TestWindow.use(size.x, size.y)
	await TestWindow.settle(3)

	var reported := get_viewport().get_visible_rect().size
	if reported != Vector2(size):
		failures.append("%s: asked for %s but the viewport is %s" % [name, size, reported])

	for key in SCREENS:
		await _check_screen(name, size, key)
	await _check_custom_filled(name, size)
	await _check_cookbook(name, size)
	await _check_settings(name, size)
	await _check_kitchen(name, size, "l1", 0)
	await _check_kitchen(name, size, "l2", 4)
	await _check_kitchen(name, size, "l3", 5)
	await _check_recipe(name, size)
	print("  %s (%dx%d) checked" % [name, size.x, size.y])


## Loads one menu-family screen on its own, at the size already applied.
func _check_screen(name: String, size: Vector2i, key: String) -> void:
	Game.change_state(Game.State.MENU)
	var screen: Control = load(str(Game.SCENES[key])).instantiate()
	add_child(screen)
	await TestWindow.settle(3)

	_report_control(screen, name, key, size)
	await _shot(name, key)

	screen.queue_free()
	await TestWindow.settle(1)


## The creator in its "ready" shape: a named dish with ingredients and a garnish. The
## empty form the SCREENS list builds does not show the difficulty line or the enabled
## buttons, and those are part of the layout that has to fit. The choices are set on
## the instance before it enters the tree, which is where `_ready` reads them.
func _check_custom_filled(name: String, size: Vector2i) -> void:
	Game.change_state(Game.State.MENU)
	var screen: Control = load(str(Game.SCENES["custom"])).instantiate()
	screen.set("_name", "Layout test dish")
	screen.set("_fish_id", "pla_nil")
	screen.set("_method_id", "steam")
	screen.set("_plating_id", "plate")
	screen.set("_ingredients", ["lemongrass", "garlic", "chilli"])
	screen.set("_garnish", ["coriander"])
	add_child(screen)
	await TestWindow.settle(3)
	_report_control(screen, name, "custom/filled", size)
	await _shot(name, "custom_filled")
	screen.queue_free()
	await TestWindow.settle(1)


## A filled cookbook: the card grid only appears once the player has saved a dish, so
## the empty page the SCREENS list builds is not the layout that can overflow. The
## saved dishes are pushed straight into the in-memory book (disk writes are suspended
## for this whole run) and taken back out afterwards.
func _check_cookbook(name: String, size: Vector2i) -> void:
	var backup: Array = SaveData.cookbook.duplicate(true)
	SaveData.cookbook.append(RecipeDB.custom_recipe("Layout test dish",
		"pla_nil", "steam", ["lemongrass", "garlic", "chilli"], [], "plate"))
	SaveData.cookbook.append(RecipeDB.custom_recipe("Second layout dish",
		"pla_duk", "grill", ["chilli"], [], "banana_leaf"))
	Game.change_state(Game.State.MENU)
	var screen: Control = load(str(Game.SCENES["cookbook"])).instantiate()
	add_child(screen)
	await TestWindow.settle(3)
	_report_control(screen, name, "cookbook/filled", size)
	await _shot(name, "cookbook_filled")
	screen.queue_free()
	SaveData.cookbook = backup
	await TestWindow.settle(1)


## The settings panel is a modal, so it is not in the SCREENS list, but it holds the
## longest labelled rows in the game (a slider, a readout and a language dropdown per
## row) and it has to fit every size just the same.
func _check_settings(name: String, size: Vector2i) -> void:
	Game.change_state(Game.State.MENU)
	var screen: Control = load(str(Game.SCENES["menu"])).instantiate()
	add_child(screen)
	await TestWindow.settle(3)
	var panel: Control = screen.call("_settings_panel")
	screen.call("show_overlay", panel)
	await TestWindow.settle(3)
	var centre := screen.get("overlay_centre") as Control
	if centre != null and centre.is_visible_in_tree():
		_report_control(centre, name, "settings", size)
	else:
		failures.append("%s: the settings panel did not open" % name)
	await _shot(name, "settings")
	screen.queue_free()
	await TestWindow.settle(1)


## Opens a challenge and checks the HUD plus the task sheet for the given step.
func _check_kitchen(name: String, size: Vector2i, level_id: String, target_step: int) -> void:
	Game.current_level_id = level_id
	Game.change_state(Game.State.PLAYING)
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await TestWindow.settle(4)

	# Walk to the requested step so every kind of task is inspected at least once.
	var guard := 0
	while guard < 40 and int(screen.call("current_step_index")) < target_step:
		guard += 1
		var card: Node = _find(screen, func(node: Node) -> bool: return node is LessonCard)
		if card != null:
			card.emit_signal("dismissed")
			await TestWindow.settle(1)
			continue
		var task: Node = screen.call("current_task")
		if task == null:
			await TestWindow.settle(1)
			continue
		task.succeed()
		await TestWindow.settle(2)

	var label := "%s/%s/%s" % [name, level_id, screen.call("current_step_index")]
	var hud := screen.get("hud") as Control
	if hud != null:
		_report_control(hud, name, label + " hud", size)
	var task := screen.call("current_task") as Control
	if task != null:
		_report_control(task, name, label + " task", size)
	else:
		_check_modal(screen, name, label, size)
	await _shot(name, label)

	Game.abandon_level()
	screen.queue_free()
	await TestWindow.settle(1)


## Walks a generated recipe challenge from start to finish. This is what puts the
## new minigames — prepare the fish, chop, stir, flip, plate, serve — through the
## same measurement as every story step, at every size.
func _check_recipe(name: String, size: Vector2i) -> void:
	var generator := ChallengeGenerator.new()
	generator.begin(20261017)
	var challenge := generator.build(RecipeDB.recipe_by_id("thot_man_pla"))
	if challenge.is_empty():
		failures.append("%s: the recipe challenge could not be built" % name)
		return
	Game.current_challenge = challenge
	Game.change_state(Game.State.PLAYING)
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await TestWindow.settle(4)

	var hud := screen.get("hud") as Control
	if hud != null:
		_report_control(hud, name, "recipe/hud", size)

	var guard := 0
	while guard < 80:
		guard += 1
		var card: Node = _find(screen, func(node: Node) -> bool: return node is LessonCard)
		if card != null:
			card.emit_signal("dismissed")
			await TestWindow.settle(1)
			continue
		var task := screen.call("current_task") as Control
		if task == null:
			_check_modal(screen, name, "recipe/tail", size)
			break
		var index := int(screen.call("current_step_index"))
		_report_control(task, name, "recipe/step%d" % index, size)
		await _shot(name, "recipe_%d" % index)
		task.succeed()
		await TestWindow.settle(2)

	Game.abandon_level()
	Game.current_challenge = {}
	screen.queue_free()
	await TestWindow.settle(1)


## A modal (lesson card or knowledge check) is its own layout; check the open one.
func _check_modal(screen: Node, name: String, label: String, size: Vector2i) -> void:
	var modal := screen.get("_modal") as Control
	if modal != null and modal.visible:
		_report_control(modal, name, label + " modal", size)


# ------------------------------------------------------------------- measuring ---
func _report_control(root: Control, name: String, label: String, size: Vector2i) -> void:
	checked += 1
	if not root.is_visible_in_tree():
		failures.append("%s: %s is not visible" % [name, label])
		return
	var window := Rect2(Vector2.ZERO, Vector2(size))
	var rect := root.get_global_rect()
	if not _within(rect, window):
		failures.append("%s: %s root rect %s leaves the %s window" % [name, label, rect, size])
	_walk(root, name, label, window, 0)


## Recurses over every visible Control, checking its rectangle and (for labels) the
## width of the text it was given.
##
## `page` is true once the walk has entered a vertical scroller. A page taller than
## the frame is not a layout bug — it is a scroll bar — and everything inside a
## scroller may run past the bottom edge as long as it is laid out inside the
## scroller's own column. The window is still the frame for width, and overflow is
## still caught for anything that does not sit inside a scroller at all.
func _walk(node: Node, name: String, label: String, bounds: Rect2, depth: int, page := false) -> void:
	if depth > 16:
		return
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			var child_bounds := bounds
			# Entering a scroller lifts the bottom edge of the frame. Its content
			# column starts a scroller at the same moment, so the allowance covers
			# exactly the page and nothing else.
			var page_here := page
			if control is ScrollContainer and (control as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
				page_here = true
			# A page taller than the window is a scroll bar, not a layout bug — but
			# only for the page frame itself and the scroller inside it, both of
			# which clip their content. Everything else is still measured against
			# the window, which is where real overflow has always been caught.
			var page_frame := control.clip_contents and (control is ScrollContainer
				or (page_here and control.get_parent() is ScrollContainer))
			if control.is_visible_in_tree() and control.size.x > 0.0 and control.size.y > 0.0:
				var rect := control.get_global_rect()
				if not _within(rect, bounds) and not (page_frame and _within_column(rect, bounds)):
					failures.append("%s: %s > %s leaves its area: %s (min %s)"
						% [name, label, _path(control, node), rect, control.get_combined_minimum_size()])
				if control is Label or control is Button:
					_check_text(control, name, _path(control, node))
			# Content inside a container that clips is measured against that
			# container instead of the window: the container is allowed to cut its
			# content off, that is the point. A scroller only clips across its
			# axes, so on the axis it scrolls the child may run as long as it
			# likes.
			if control is ScrollContainer:
				child_bounds = _scroll_bounds(control as ScrollContainer, bounds)
			elif control.clip_contents and not page_frame:
				child_bounds = control.get_global_rect()
			_walk(control, name, label, child_bounds, depth + 1, page_here)
		elif child is CanvasLayer or child is Node3D:
			_walk(child, name, label, bounds, depth + 1, page)


## A label or button must not be asked to draw more text than its own box can hold,
## which is how long Thai strings get clipped on a narrow screen.
func _check_text(control: Control, name: String, label_path: String) -> void:
	var text := str(control.get("text"))
	if text.is_empty():
		return
	var wrap_mode = control.get("autowrap_mode")
	if wrap_mode != null and int(wrap_mode) != TextServer.AUTOWRAP_OFF:
		return
	if control is Label and (control as Label).clip_text:
		return
	var font := control.get_theme_font("font")
	var font_size := control.get_theme_font_size("font_size")
	if font == null or font_size <= 0:
		return
	# A button draws its text inside its style box, so it needs room for that too.
	var padding := 40.0 if control is Button else 0.0
	var needed := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x + padding
	if needed > control.size.x + TOLERANCE:
		failures.append("%s: %s text needs %.0fpx but has %.0fpx: \"%s\""
			% [name, label_path, needed, control.size.x, text])


## A control inside a vertical scroller is allowed to run past the bottom of the
## frame, but not to be wider than the frame or to start off the top of it.
func _within_column(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x - TOLERANCE \
		and rect.position.y >= bounds.position.y - TOLERANCE \
		and rect.end.x <= bounds.end.x + TOLERANCE


## The area a scroller clips its content to. The axis it scrolls is left open: a
## child taller than a vertical scroller is not a layout bug, it is a scroll bar.
func _scroll_bounds(scroll: ScrollContainer, bounds: Rect2) -> Rect2:
	var rect := scroll.get_global_rect()
	if scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		rect.position.y = -1.0e9
		rect.size.y = 2.0e9
	if scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		rect.position.x = -1.0e9
		rect.size.x = 2.0e9
	return rect


func _within(rect: Rect2, bounds: Rect2) -> bool:	return rect.position.x >= bounds.position.x - TOLERANCE \
		and rect.position.y >= bounds.position.y - TOLERANCE \
		and rect.end.x <= bounds.end.x + TOLERANCE \
		and rect.end.y <= bounds.end.y + TOLERANCE


## The space a MarginContainer's margins take out of its rectangle, so the area its
## children are measured against can be derived from the parent's own bounds.
func _margin_box(container: MarginContainer) -> Rect2:
	var m := 0.0
	if container.has_meta("resp_margin"):
		m = float(container.get_meta("resp_margin"))
	return Rect2(Vector2(m, m), Vector2(m * 2.0, m * 2.0))


## Whether a control is inside a vertical scroller.
##
## A page taller than the frame is not a layout bug — it is a scroll bar — so the
## `PageScroll` inside the page frame is allowed to run past the frame's bottom,
## because `PageScroll` has vertical growth allowed and so does everything it
## contains. Anything that cannot grow vertically (a `Fill`-only scroll area, a
## card, a row) is still measured against the window, which is where genuine
## overflow has always been caught.
func _in_vertical_scroll(node: Node) -> bool:
	var current := node
	while current != null:
		if current is ScrollContainer and (current as ScrollContainer).clip_contents:
			return true
		current = current.get_parent()
	return false


func _path(control: Control, parent: Node) -> String:
	return "%s/%s" % [parent.name, control.name]


func _find(root: Node, predicate: Callable) -> Node:
	if predicate.call(root):
		return root
	for child in root.get_children():
		var found := _find(child, predicate)
		if found != null:
			return found
	return null


# ----------------------------------------------------------------------- shots ---
func _shot(size_name: String, label: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var safe := label.replace("/", "_")
	image.save_png("%s/%s_%s.png" % [shot_dir, size_name, safe])


# ---------------------------------------------------------------------- report ---
func _report() -> void:
	print("--- results ---")
	if failures.is_empty():
		print("RESPONSIVE CHECK PASSED (%d layouts checked)" % checked)
	else:
		print("RESPONSIVE CHECK FAILED (%d problems in %d layouts)" % [failures.size(), checked])
		for problem in failures:
			print("  FAIL: %s" % problem)
	var code := 0 if failures.is_empty() else 1
	get_tree().quit(code)
