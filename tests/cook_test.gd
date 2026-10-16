extends Node
## Focused test for the cooking visuals and for the burnt outcome.
##
## The behaviour test proves that a correct cook finishes the step. This one covers
## the two things that test cannot reach in reasonable time:
##
##   1. the fish *changes as it cooks* — the surface walks a browning ramp from raw
##      towards burnt instead of snapping from one look to another, and
##   2. a fish that burns before its inside is safe ends the step with the burnt
##      outcome and an immediate retry, and the retry really does start a fresh
##      fish rather than wiping the record.
##
## To reach the burnt outcome deterministically the step's safe hold is set longer
## than the test is willing to sit here: burning is what happens when heat keeps
## going in while the inside still is not proven safe, and that is exactly the case
## being reproduced. It cannot happen by accident on the normal path — the safe hold
## finishes first, which the behaviour test covers.
##
## Run with:
##   godot --headless --path <project> res://tests/cook_test.tscn

const TestWindow := preload("res://tests/test_window.gd")

## Where `-- shots` writes its images. A real window is needed to render one, so the
## capture only happens on a windowed run; the checks run either way.
const SHOT_DIR := "C:/Users/ASUS/AppData/Local/Temp/opencode/captures"

## A point over bare bench: no Control covers it, so the cooking task's
## `_unhandled_input` is the only thing that can see a press there.
const FREE_POINT := Vector2(640.0, 300.0)
const STEP_INDEX := 3
const HOLD_LONG_ENOUGH := 16.0

var failures: Array[String] = []
var shots := false


func _ready() -> void:
	shots = OS.get_cmdline_user_args().has("shots")
	if shots:
		DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	TestWindow.use(1280, 720)
	await TestWindow.settle(3)
	await _run()
	_report()


func _run() -> void:
	print("--- Fluke Free Kitchen cooking test ---")
	SaveData.suspend_disk_writes(true)

	Game.current_level_id = "l2"
	Game.change_state(Game.State.PLAYING)
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await _frames(3)

	var level: Dictionary = screen.get("level")
	if level.is_empty():
		failures.append("the kitchen did not load challenge l2")
		_finish(screen)
		return

	# Reach the cooking step directly: the earlier steps are covered by the
	# behaviour test, and sitting through them here would only add seconds.
	var steps: Array = level.get("steps", [])
	if steps.size() <= STEP_INDEX:
		failures.append("l2 has no cooking step at index %d" % STEP_INDEX)
		_finish(screen)
		return
	var cook_step: Dictionary = steps[STEP_INDEX]
	var original_hold := float(cook_step.get("hold_seconds", 5.0))
	cook_step["hold_seconds"] = 999.0

	screen.call("_set_step", STEP_INDEX)
	await _frames(3)

	var task = screen.call("current_task")
	if task == null or str(task.get("step").get("kind", "")) != "cook_through":
		failures.append("the cooking step did not build a cook_through task")
		cook_step["hold_seconds"] = original_hold
		_finish(screen)
		return

	var kitchen: Node = screen.get("kitchen")
	var raw_colour: Variant = _fish_colour(kitchen)
	if raw_colour == null:
		failures.append("no cooking fish was placed in the pan")

	# ---- a real press and hold, held long past a sensible cook ----------------
	await _shot("cook_1_raw")
	_push_button(FREE_POINT, true)
	await _seconds(5.0)
	var early := float(task.get("_browning"))
	var mid_colour: Variant = _fish_colour(kitchen)
	await _shot("cook_2_browning")
	await _seconds(HOLD_LONG_ENOUGH)
	_push_button(FREE_POINT, false)
	await _frames(2)
	await _shot("cook_3_burnt")

	if early <= 0.0:
		failures.append("the fish did not start browning while it was cooking")
	elif raw_colour != null and mid_colour == raw_colour:
		failures.append("the fish changed its measured browning but not its colour")
	else:
		print("  visuals: the fish browned as it cooked (browning %.2f, colour %s -> %s)"
			% [early, str(raw_colour), str(mid_colour)])

	if not bool(task.get("_burnt")):
		failures.append("holding that long did not burn the fish")
	else:
		print("  outcome C: the burnt fish ended the step")

	# ---- the burnt outcome offers a retry, and the retry resets -----------------
	var retry := _find_button(task, Loc.t("task.retry_cook"))
	if retry == null:
		failures.append("the burnt outcome offered no retry button")
	else:
		await _click(retry)
		await _frames(3)
		if bool(task.get("_burnt")):
			failures.append("the retry button did not clear the burnt state")
		elif float(task.get("_browning")) > 0.01:
			failures.append("the retry did not reset the browning (%.2f)"
				% float(task.get("_browning")))
		else:
			var fresh: Variant = _fish_colour(kitchen)
			if raw_colour != null and fresh != raw_colour:
				failures.append("the retry did not put a raw fish back (colour %s)" % str(fresh))
			else:
				print("  outcome C: the retry started a fresh raw fish")

	# The mistake has to survive the retry, or a retry would be a way to erase it.
	if int(task.get("mistakes")) < 1:
		failures.append("the burnt fish was not recorded as a mistake")
	else:
		print("  outcome C: the burn was recorded as a mistake before the retry")

	# ---- and the retry really is playable --------------------------------------
	var before := float(task.get("_temperature"))
	_push_button(FREE_POINT, true)
	await _seconds(2.0)
	_push_button(FREE_POINT, false)
	await _frames(2)
	if float(task.get("_temperature")) <= before:
		failures.append("the fish could not be heated again after the retry")
	else:
		print("  outcome C: the retried fish heats up again")

	cook_step["hold_seconds"] = original_hold
	_finish(screen)


func _finish(screen: Node) -> void:
	SaveData.suspend_disk_writes(false)
	Game.abandon_level()
	Game.change_state(Game.State.MENU)
	if is_instance_valid(screen):
		screen.queue_free()


# ------------------------------------------------------------------- measuring ---
## Saves what is on screen, when the run was asked for shots.
func _shot(name: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [SHOT_DIR, name])


## The colour of the fish surface in the pan, or null when there is no fish.
func _fish_colour(kitchen: Node) -> Variant:
	if kitchen == null:
		return null
	var meshes: Array = kitchen.get("_fish_meshes")
	for entry in meshes:
		var mesh := entry as MeshInstance3D
		if mesh != null and is_instance_valid(mesh):
			var material := mesh.material_override as StandardMaterial3D
			if material != null:
				return material.albedo_color
	return null


# -------------------------------------------------------------------- plumbing ---
func _push_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	get_viewport().push_input(event, true)


func _click(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	_push_button(position, true)
	await _frames(1)
	_push_button(position, false)
	await _frames(2)


func _find_button(root: Node, text: String) -> Button:
	return _find(root, func(node: Node) -> bool:
		return node is Button \
			and (node as Button).text == text \
			and (node as Button).is_visible_in_tree() \
			and not (node as Button).disabled)


func _find(root: Node, predicate: Callable) -> Node:
	if predicate.call(root):
		return root
	for child in root.get_children():
		var found := _find(child, predicate)
		if found != null:
			return found
	return null


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


func _report() -> void:
	print("--- results ---")
	if failures.is_empty():
		print("COOKING TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("COOKING TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
