extends Node
## Development tool: prints the on-screen rectangles of the 2D layer so layout
## problems can be diagnosed from numbers instead of by eye.
##
## Run with:
##   godot --headless --path <project> res://tests/layout_check.tscn

const TestWindow := preload("res://tests/test_window.gd")


func _ready() -> void:
	# Entrance animations only touch opacity and scale, never layout, but the
	# numbers printed here are meant to describe a settled screen — so the
	# interface's motion is off while they are read.
	UIFactory.set_motion_enabled(false)
	# Stretch mode is disabled: a headless run starts with a 64x64 viewport unless
	# it says otherwise. The size can also be given on the command line so the same
	# dump can be taken at several screen sizes:
	#   godot --headless --path <project> res://tests/layout_check.tscn -- 390 844
	TestWindow.use(_requested_size().x, _requested_size().y)
	await TestWindow.settle(2)
	SaveData.suspend_disk_writes(true)
	await _dump_screens()
	await _dump_kitchen("l1", 0)
	await _dump_kitchen("l2", 4)
	await _dump_kitchen("l3", 5)
	SaveData.suspend_disk_writes(false)
	get_tree().quit(0)


## The window size to dump at: two integers on the command line, or 1280x720.
func _requested_size() -> Vector2i:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0].is_valid_int() and args[1].is_valid_int():
		return Vector2i(int(args[0]), int(args[1]))
	return Vector2i(1280, 720)


func _dump_screens() -> void:
	for key in ["menu", "levels", "journal", "assessment"]:
		Game.change_state(Game.State.MENU)
		var screen: Control = load(str(Game.SCENES[key])).instantiate()
		add_child(screen)
		for _i in 3:
			await get_tree().process_frame
		print("=== screen %s ===" % key)
		print("  screen rect: %s" % screen.get_rect())
		_dump(screen, 1, 8)
		screen.queue_free()
		await get_tree().process_frame


func _dump_kitchen(level_id: String, target_step: int = 0) -> void:
	Game.current_level_id = level_id
	Game.change_state(Game.State.PLAYING)
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	for _i in 4:
		await get_tree().process_frame

	# Advance to the requested step so any step in a challenge can be inspected.
	var guard := 0
	while guard < 30 and screen.call("current_step_index") < target_step:
		guard += 1
		var card: Node = _find_node(screen, func(node: Node) -> bool: return node is LessonCard)
		if card != null:
			card.emit_signal("dismissed")
			await get_tree().process_frame
			continue
		var task: Node = screen.call("current_task")
		if task == null:
			await get_tree().process_frame
			continue
		task.succeed()
		for _i in 2:
			await get_tree().process_frame

	print("=== kitchen %s (step %d) ===" % [level_id, int(screen.call("current_step_index"))])
	var hud: Node = screen.get("hud")
	_dump(hud as Control, 1, 3)
	var task: Node = screen.call("current_task")
	if task != null:
		_dump(task as Control, 1, 8)
	else:
		print("  (no task)")
	screen.queue_free()
	await get_tree().process_frame


func _find_node(root: Node, predicate: Callable) -> Node:
	if predicate.call(root):
		return root
	for child in root.get_children():
		var found := _find_node(child, predicate)
		if found != null:
			return found
	return null


func _dump(node: Node, depth: int, max_depth: int) -> void:
	if depth > max_depth:
		return
	var indent := ""
	for _i in depth:
		indent += "  "
	var info := ""
	if node is Control:
		var control := node as Control
		info = " rect=%s min=%s" % [control.get_rect(), control.get_combined_minimum_size()]
	elif node is Node3D:
		info = " at=%s" % (node as Node3D).global_position
	var label := node.name
	if node is Label:
		label += " \"%s\"" % (node as Label).text
	print("%s%s [%s]%s" % [indent, label, node.get_class(), info])
	if node is Control or node is CanvasLayer:
		for child in node.get_children():
			_dump(child, depth + 1, max_depth)
