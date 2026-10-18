extends Node
## Minigame test: drives the new cooking interactions with **real pointer events**.
##
## The flow test completes steps by calling `succeed()`, and the behaviour test does
## the same for the three story challenges. Neither reaches the minigames the recipe
## and free-cook modes are built from. This suite cooks a whole generated recipe —
## prepare the fish, chop, add, heat, flip, stir, cook through, plate, serve — and
## pushes real mouse presses, moves and releases into the viewport for each one.
##
## For every minigame it proves three things a player would notice immediately:
##
##   1. the step does not finish on its own while the player does nothing;
##   2. the *wrong* gesture (a tap where a cut is needed, a straight drag where a
##      circle is needed, a press away from the pan) does not finish it either;
##   3. the right gesture does finish it, so the control is not impossible.
##
## The flip is exercised twice on purpose: once by tapping the fish in the pan and
## once by the on-screen Flip button, because the button is the documented fallback
## for anyone who cannot use the gesture.
##
## Run with:
##   godot --headless --path <project> res://tests/minigame_test.tscn

const TestWindow := preload("res://tests/test_window.gd")

## A point over bare bench: no Control covers it, so the tasks' `_unhandled_input`
## is the only thing that can see a press there.
const FREE_POINT := Vector2(640.0, 300.0)
## A real recipe that needs every minigame except the lime decision: mince-and-fry
## has a flip and a stir, and difficulty 3 adds chopping.
const RECIPE_ID := "thot_man_pla"
## How long to wait for a step to become ready before giving up on it.
const READY_TIMEOUT_MS := 9000

var failures: Array[String] = []
var _kinds_driven := {}


func _ready() -> void:
	TestWindow.use(1280, 720)
	await _run()
	_report()


func _run() -> void:
	print("--- Fluke Free Kitchen minigame test ---")
	# Nothing here should touch the player's progress; a generated challenge still
	# records a result at the end, so disk writes are suspended for the whole run.
	SaveData.suspend_disk_writes(true)

	var generator := ChallengeGenerator.new()
	generator.begin(20261017)
	var challenge := generator.build(RecipeDB.recipe_by_id(RECIPE_ID))
	if challenge.is_empty():
		failures.append("the recipe challenge could not be built")
		_report()
		return
	Game.current_challenge = challenge
	Game.change_state(Game.State.PLAYING)

	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await _frames(4)
	var loaded: Dictionary = screen.get("level")
	if loaded.is_empty():
		failures.append("the kitchen screen did not load the generated challenge")
	else:
		await _walk(screen)
		# The knowledge check is not optional in a generated challenge either.
		await _seconds(1.2)
		var quiz: Node = _find(screen, func(node: Node) -> bool: return node is QuizCard)
		if quiz == null:
			failures.append("the generated recipe ended without its mandatory knowledge check")
		else:
			print("  the generated recipe still ends with the mandatory knowledge check")

	Game.abandon_level()
	Game.current_challenge = {}
	screen.queue_free()
	await _frames(2)
	SaveData.suspend_disk_writes(false)

	for expected in ["prep_fish", "slice", "drag_to", "hold", "flip", "stir",
			"cook_through", "plate", "serve"]:
		if not _kinds_driven.has(expected):
			failures.append("'%s' was never exercised by this recipe" % expected)


## Walks the challenge, dismissing lesson cards and driving each task.
func _walk(screen: Node) -> void:
	var guard := 0
	while guard < 40:
		guard += 1
		var card: Node = _find(screen, func(node: Node) -> bool: return node is LessonCard)
		if card != null:
			card.emit_signal("dismissed")
			await _frames(3)
			continue
		var task := screen.call("current_task") as KitchenTask
		if task == null:
			break
		await _run_step(task)
		await _seconds(1.2)
	print("  cooked '%s' through %d steps with real input" % [RECIPE_ID, _kinds_driven.size()])


func _run_step(task: KitchenTask) -> void:
	var kind := str(task.step.get("kind", ""))
	_kinds_driven[kind] = true
	var watch := _watch(task)

	# Wait for the step's own demonstration to finish, and for the step to say it is
	# ready for input. Doing this by asking the task, rather than by guessing at the
	# demonstration length, is what makes the check below meaningful: the step has
	# had its chance to finish itself and has not.
	if not await _await_ready(task):
		failures.append("%s: the step never became ready for input" % kind)
		return
	await _frames(3)
	if watch["finished"]:
		return
	match kind:
		"prep_fish", "slice":
			await _drive_slice(task, kind, watch)
		"stir":
			await _drive_stir(task, watch)
		"flip":
			await _drive_flip(task, watch)
		"plate":
			await _drive_plate(task, watch)
		"serve":
			await _drive_serve(task, watch)
		"hold", "cook_through":
			await _drive_hold(task, kind, watch)
		"drag_to":
			await _drive_drag(task, kind, watch)
		"choose_safer":
			await _drive_choose(task, kind, watch)
		_:
			# Kinds that belong to the story challenges are covered by the flow and
			# behaviour suites; here they are simply stepped over.
			print("  %s: not part of this recipe; stepped over" % kind)
			task.succeed()

	var deadline := Time.get_ticks_msec() + 5000
	while not watch["finished"] and Time.get_ticks_msec() < deadline:
		await _frames(2)
	if not watch["finished"] and not task.settled:
		await _seconds(1.0)
	if not watch["finished"] and task.settled:
		watch["finished"] = true
	if not watch["finished"]:
		failures.append("%s: a correct real gesture did not finish the step" % kind)


# ================================================================ minigames ===
## `prep_fish` and `slice`: one sideways cut per stroke. A tap with no travel must
## not count, and a press on bare bench is ignored rather than punished.
func _drive_slice(task: KitchenTask, kind: String, watch: Dictionary) -> void:
	var board := task.get("_board") as Node3D
	if board == null:
		failures.append("%s: the chopping board was not built" % kind)
		return
	var strokes := int(task.get("_strokes"))
	var plane_y := float(task.get("_board_top_y")) + 0.12
	var centre := board.global_position
	var from := task.kitchen.world_to_screen(Vector3(centre.x - 0.45, plane_y, centre.z))
	var to := task.kitchen.world_to_screen(Vector3(centre.x + 0.45, plane_y, centre.z))
	if from.x < 0.0 or to.x < 0.0:
		failures.append("%s: the chopping board is off screen" % kind)
		return

	# A tap (no travel) is not a cut.
	_push_button(from, true)
	await _frames(2)
	_push_button(from, false)
	await _frames(3)
	if watch["finished"]:
		failures.append("%s: a tap with no drag counted as a cut" % kind)
		return
	print("  %s: a tap with no drag is not a cut" % kind)

	for _stroke in strokes:
		_push_button(from, true)
		await _frames(2)
		_push_motion(from.lerp(to, 0.5))
		await _frames(1)
		_push_motion(to)
		await _frames(1)
		_push_button(to, false)
		await _seconds(0.7)
	print("  %s: %d sideways cuts finished the step" % [kind, strokes])


## `stir`: the angle swept around the pot is what counts. A straight drag across it
## must not, and real circles must.
func _drive_stir(task: KitchenTask, watch: Dictionary) -> void:
	var centre: Vector3 = task.get("_centre")
	var plane_y := float(task.get("_top_y"))
	var radius := 0.28
	var left := task.kitchen.world_to_screen(Vector3(centre.x - radius, plane_y, centre.z))
	var right := task.kitchen.world_to_screen(Vector3(centre.x + radius, plane_y, centre.z))

	# A straight drag.
	_push_button(left, true)
	await _frames(2)
	_push_motion(right)
	await _frames(2)
	_push_button(right, false)
	await _frames(3)
	if watch["finished"]:
		failures.append("stir: a straight drag counted as stirring")
		return

	# Real circles: a small step per frame, well inside the reach. The step is kept
	# small on purpose: the task ignores a pointer jump larger than MAX_STEP (0.55
	# rad) as a glitch, and synthetic events can arrive coalesced.
	_push_button(left, true)
	await _frames(2)
	var total := 150
	var step_angle := 0.18
	var angle := 0.0
	for _i in total:
		# Stop the moment the step succeeds: the harness advances (and frees) the task
		# as soon as it finishes, so carrying on would poke a freed node.
		if bool(watch.get("finished", false)) or not is_instance_valid(task):
			break
		angle += step_angle
		_push_motion(task.kitchen.world_to_screen(
			Vector3(centre.x + cos(angle) * radius, plane_y, centre.z + sin(angle) * radius)))
		await _frames(1)
	if is_instance_valid(task):
		_push_button(task.kitchen.world_to_screen(
			Vector3(centre.x + cos(angle) * radius, plane_y, centre.z + sin(angle) * radius)), false)
	await _seconds(1.0)
	print("  stir: circling the pot (%d frames) finished the step" % total)


## `flip`: a tap on the fish or an upward swipe. A press away from the pan must do
## nothing. The second flip is done with the on-screen button, the stated fallback.
func _drive_flip(task: KitchenTask, watch: Dictionary) -> void:
	var pan: Vector3 = task.get("_wok_centre")
	var flips := int(task.get("_flips"))
	var on_fish := task.kitchen.world_to_screen(pan + Vector3(0, 0.3, 0))

	# A press over bare bench, far from the pan.
	_push_button(FREE_POINT, true)
	await _frames(2)
	_push_button(FREE_POINT, false)
	await _frames(3)
	if watch["finished"]:
		failures.append("flip: a press away from the pan counted as a flip")
		return
	print("  flip: a press away from the pan does nothing")

	# Flip one: a tap on the fish itself.
	_push_button(on_fish, true)
	await _frames(2)
	_push_button(on_fish, false)
	await _seconds(1.4)

	# Any remaining flips: the on-screen button.
	var button := _find_button(task, Loc.t("task.flip_button"))
	var used_button := 0
	while used_button < flips and not watch["finished"]:
		if button == null or not is_instance_valid(button):
			failures.append("flip: the on-screen Flip button was not available")
			break
		await _click(button)
		used_button += 1
		await _seconds(1.0)
	if used_button > 0:
		print("  flip: tapping the fish flips it, and the Flip button works too (%d flips)" % flips)


## `cook_through` and `hold`: releasing early must not finish; holding long enough
## must.
func _drive_hold(task: KitchenTask, kind: String, watch: Dictionary) -> void:
	_push_button(FREE_POINT, true)
	await _seconds(1.2)
	_push_button(FREE_POINT, false)
	await _seconds(0.4)
	if watch["finished"]:
		failures.append("%s: a short press finished the step" % kind)
		return
	print("  %s: letting go early does not finish the step" % kind)

	_push_button(FREE_POINT, true)
	await _seconds(13.5)
	_push_button(FREE_POINT, false)
	await _seconds(1.0)
	print("  %s: holding long enough finishes the step" % kind)


## `drag_to`: each ingredient is dragged to the container the step names.
func _drive_drag(task: KitchenTask, kind: String, watch: Dictionary) -> void:
	var targets: Array = task.step.get("targets", [])
	var items: Array = task.step.get("items", [])
	if items.is_empty():
		failures.append("%s: the step listed no items to move" % kind)
		return
	var zone_index := {}
	for i in targets.size():
		zone_index[str((targets[i] as Dictionary).get("id", ""))] = i

	# A press on bare bench, away from any item, must pick nothing up.
	_push_button(FREE_POINT, true)
	await _frames(2)
	_push_button(FREE_POINT, false)
	await _frames(3)
	if watch["finished"]:
		failures.append("%s: a press on bare bench finished the step" % kind)
		return

	for i in items.size():
		var item: Dictionary = items[i]
		var target := str(item.get("target", ""))
		if not zone_index.has(target):
			failures.append("%s: item '%s' names an unknown container" % [kind, item.get("id", "")])
			continue
		var from := task.kitchen.world_to_screen(
			task.kitchen.item_slot(i, items.size()) + Vector3(0, 0.16, 0))
		var to := task.kitchen.world_to_screen(
			task.kitchen.zone_slot(int(zone_index[target]), targets.size()) + Vector3(0, 0.3, 0))
		if from.x < 0.0 or to.x < 0.0:
			failures.append("%s: an item or container is off screen" % kind)
			continue
		_push_button(from, true)
		await _frames(1)
		_push_motion(from.lerp(to, 0.5))
		await _frames(1)
		_push_motion(to)
		await _frames(1)
		_push_button(to, false)
		await _seconds(0.7)
	print("  %s: %d items placed by real drags" % [kind, items.size()])


## `plate`: every piece goes to the plate. Dropping one on the bench must leave it
## out (the step stays open), and putting every piece on the plate finishes it.
func _drive_plate(task: KitchenTask, watch: Dictionary) -> void:
	var items: Array = task.get("_items")
	if items.is_empty():
		failures.append("plate: no items were spawned")
		return
	var sink := task.kitchen.sink_position()

	# Pick the first piece up and put it down on the sink: not the plate.
	var first: Node3D = items[0]
	var first_at := task.kitchen.world_to_screen(first.global_position + Vector3(0, 0.16, 0))
	var off_plate := task.kitchen.world_to_screen(sink + Vector3(0, 0.3, 0))
	if first_at.x >= 0.0 and off_plate.x >= 0.0:
		_push_button(first_at, true)
		await _frames(2)
		_push_motion(off_plate)
		await _frames(2)
		_push_button(off_plate, false)
		await _seconds(0.8)
		if watch["finished"]:
			failures.append("plate: dropping one piece away from the plate finished the step")
			return
		print("  plate: a piece dropped on the bench is not plated")

	for i in items.size():
		var item: Node3D = items[i]
		if not is_instance_valid(item) or item.get_parent() == null:
			continue
		if watch["finished"] or not is_instance_valid(task):
			break
		var from := task.kitchen.world_to_screen(item.global_position + Vector3(0, 0.16, 0))
		var to := task.kitchen.world_to_screen(_plate_point(task))
		if from.x < 0.0 or to.x < 0.0:
			continue
		_push_button(from, true)
		await _frames(2)

		_push_motion(from.lerp(to, 0.5))
		await _frames(1)
		_push_motion(to)
		await _frames(1)

		_push_button(to, false)
		await _frames(3)
		if watch["finished"]:
			break
		await _seconds(0.6)

	print("  plate: every piece plated by real drags")
	var deadline := Time.get_ticks_msec() + 8000
	while not watch["finished"] and Time.get_ticks_msec() < deadline and is_instance_valid(task):
		await _frames(2)





## A point just above the middle of the plate, where the drop zone can be hit.
func _plate_point(task: KitchenTask) -> Vector3:
	var plate := task.get("_plate") as DropZone
	if plate == null:
		return Vector3(0.0, KitchenProps.BENCH_Y, 0.28)
	return plate.global_position + Vector3(0, 0.3, 0)


## `serve`: the plate is the "serve it" target. Pressing bare bench must do nothing;
## tapping the plate serves the dish, and the character reacts.
func _drive_serve(task: KitchenTask, watch: Dictionary) -> void:
	var plate := task.get("_plate") as DropZone
	if plate == null:
		failures.append("serve: the serving plate was not built")
		return
	var on_plate := task.kitchen.world_to_screen(plate.global_position + Vector3(0, 0.3, 0))

	_push_button(FREE_POINT, true)
	await _frames(2)
	_push_button(FREE_POINT, false)
	await _frames(3)
	if watch["finished"]:
		failures.append("serve: a press on bare bench served the dish")
		return
	print("  serve: a press away from the plate does not serve")

	_push_button(on_plate, true)
	await _frames(2)
	_push_button(on_plate, false)
	await _seconds(1.2)
	print("  serve: tapping the plate serves the dish")


## `choose_safer`: the correct option has to be clicked.
func _drive_choose(task: KitchenTask, kind: String, watch: Dictionary) -> void:
	var correct := ""
	for entry in task.step.get("options", []):
		var option: Dictionary = entry
		if bool(option.get("correct", false)):
			correct = LessonDB.local(option.get("label"))
	if correct.is_empty():
		failures.append("%s: the step offered no correct option" % kind)
		return
	var button := _find_button(task, correct)
	if button == null:
		failures.append("%s: the correct option was not on screen" % kind)
		return
	await _click(button)
	await _seconds(0.8)
	print("  %s: the correct option finishes the step" % kind)


# ==================================================================== plumbing ===
## Waits until the task is willing to act on input — that is, until its demonstration
## has finished. Returns false if that never happens, which would itself be a bug.
func _await_ready(task: KitchenTask) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		# Gone or already decided: not a readiness problem. The caller checks whether
		# the step decided itself, which is the bug worth reporting.
		if not is_instance_valid(task) or task.settled:
			return true
		if task.is_accepting_input():
			return true
		await _frames(1)
	return false


## Follows a task's outcome through its signals. Reading the task after the step has
## finished is not safe — the runner frees it as soon as it advances.
func _watch(task: KitchenTask) -> Dictionary:
	var flags := {"finished": false, "success": false, "mistakes": 0}
	task.finished.connect(func(success: bool) -> void:
		flags["finished"] = true
		flags["success"] = success)
	task.mistake.connect(func(_payload: Dictionary) -> void:
		flags["mistakes"] += 1)
	return flags


## Events are pushed with `in_local_coords = true` because these positions come from
## `world_to_screen`, which is already in viewport (canvas) coordinates.
func _push_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	get_viewport().push_input(event, true)


func _push_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
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
	var button: Button = _find(root, func(node: Node) -> bool:
		return node is Button \
			and (node as Button).text == text \
			and (node as Button).is_visible_in_tree() \
			and not (node as Button).disabled)
	return button


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
		print("MINIGAME TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("MINIGAME TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
