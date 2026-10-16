extends Node
## Behaviour test: drives the challenges through the **real pointer pipeline**.
##
## `flow_test` completes steps by calling `succeed()`, which proves the level flow is
## wired correctly but says nothing about whether a click, a drag, a swipe or a hold
## actually does what a player expects. This test pushes real `InputEventMouseButton`
## and `InputEventMouseMotion` events into the viewport instead, so the event reaches
## the same `_unhandled_input` translation and the same task callbacks that a mouse
## or a finger would.
##
## It checks four behaviours that the design promises but that no other test covers:
##
##   1. a demonstration blocks input — a click while the "watch, then try" banner is up
##      is ignored;
##   2. a wrong answer is explained and the step stays open (retry works);
##   3. the physical gestures work from real events (swipe across the board, drag an
##      item into a container, press and hold);
##   4. releasing a hold early does **not** finish the step.
##
## Every outcome is read from the task's `finished` / `mistake` signals, never from the
## task object after the fact: once a step is finished the runner frees the task, so
## touching it afterwards would crash rather than fail.
##
## Run with:
##   godot --headless --path <project> res://tests/behaviour_test.tscn

## A point over bare bench: no Control covers it, so a physical task's
## `_unhandled_input` is the only thing that can see a press there.
const FREE_POINT := Vector2(640.0, 300.0)

const TestWindow := preload("res://tests/test_window.gd")

var failures: Array[String] = []


func _ready() -> void:
	# State the window size: a headless run has no real window, so every control
	# would otherwise be laid out for a 64x64 viewport and every computed click
	# coordinate would land on empty space.
	TestWindow.use(1280, 720)
	await TestWindow.settle(3)
	await _run()
	_report()


func _run() -> void:
	print("--- Fluke Free Kitchen behaviour test ---")
	# A behaviour test must never touch the player's save file.
	SaveData.suspend_disk_writes(true)
	await _level_one_by_pointer()
	await _level_two_physical()
	SaveData.suspend_disk_writes(false)
	Game.abandon_level()
	Game.change_state(Game.State.MENU)


# =============================================================== level one ===
## Level 1 is driven end to end with real events: every option is clicked, the board
## is swiped clean, and every ingredient is dragged to a container.
func _level_one_by_pointer() -> void:
	Game.current_level_id = "l1"
	Game.change_state(Game.State.PLAYING)
	var screen: Node = await _open_kitchen("l1")
	if screen == null:
		return

	# ---- step 1: the demonstration gate and the retry path -------------------
	await _demo_gate_and_retry(screen)
	await _dismiss_lesson(screen)

	# ---- step 2: swipe the board clean ---------------------------------------
	await _swipe_board(screen, "l1", "clean_board")
	await _dismiss_lesson(screen)

	# ---- step 3: choose the clean utensils ------------------------------------
	await _tap_correct(screen, "l1", "choose_utensils")
	await _dismiss_lesson(screen)

	# ---- step 4: drag every ingredient to its container -----------------------
	await _drag_everything(screen, "l1", "separate_food")
	await _dismiss_lesson(screen)

	# ---- step 5: choose the safer response ------------------------------------
	await _tap_correct(screen, "l1", "spot_mistake")
	await _dismiss_lesson(screen)

	# ---- the knowledge check --------------------------------------------------
	await _answer_quiz_by_pointer(screen, "l1")

	# ---- result ---------------------------------------------------------------
	await _seconds(0.6)
	if not screen.call("result_visible"):
		failures.append("l1: the challenge did not reach its result after real input")
	else:
		print("  l1: finished through real clicks, drags and swipes")

	Game.abandon_level()
	screen.queue_free()
	await _frames(2)


# =============================================================== level two ===
## Level 2 adds the two hold gestures. Pressing and holding must finish them;
## letting go early must not.
func _level_two_physical() -> void:
	Game.current_level_id = "l2"
	Game.change_state(Game.State.PLAYING)
	var screen: Node = await _open_kitchen("l2")
	if screen == null:
		return

	# Reach the hold steps: step 1 (tap, demonstrated), step 2 (drag).
	await _tap_correct(screen, "l2", "identify_fish")
	await _dismiss_lesson(screen)
	await _drag_everything(screen, "l2", "prep_board")
	await _dismiss_lesson(screen)

	# ---- step 3: press and hold to heat the pan -------------------------------
	await _hold_step(screen, "l2", "heat_pan", 2.0)
	await _dismiss_lesson(screen)

	# ---- step 4: cook the fish through ----------------------------------------
	await _cook_step(screen, "l2", "cook_fish")
	await _dismiss_lesson(screen)

	# ---- step 5: choose the safer response ------------------------------------
	await _tap_correct(screen, "l2", "lime_or_cook")
	await _dismiss_lesson(screen)

	await _answer_quiz_by_pointer(screen, "l2")
	await _seconds(0.6)
	if not screen.call("result_visible"):
		failures.append("l2: the challenge did not reach its result after real input")
	else:
		print("  l2: finished through real holds and drags")

	Game.abandon_level()
	screen.queue_free()
	await _frames(2)


# =========================================================== the four checks ===
## 1. A click during the demonstration must be ignored; a wrong answer afterwards
##    must be explained and leave the step open; the right answer then completes it.
func _demo_gate_and_retry(screen: Node) -> void:
	var task: KitchenTask = screen.call("current_task")
	if task == null:
		failures.append("l1: the first step did not build a task")
		return
	var watch := _watch(task)
	var step: Dictionary = task.step
	var correct := _correct_label(step)
	if correct.is_empty():
		failures.append("l1: the first step has no correct option")
		return

	var button := _find_button(task, correct, false)
	if button == null:
		failures.append("l1: the correct option was not on screen")
		return
	if not button.disabled:
		failures.append("l1: the options were clickable before the demonstration ended")
	await _click(button)
	if watch["finished"] or watch["mistakes"] > 0 or task.attempts > 0:
		failures.append("l1: a click during the demonstration was accepted")
	else:
		print("  demo gate: clicks are ignored until the demonstration has played")

	# The demonstration ends on its own; wait it out, then use a wrong answer.
	await _seconds(2.6)
	if not is_instance_valid(task):
		failures.append("l1: the step ended during its own demonstration")
		return
	if button.disabled:
		failures.append("l1: the options stayed disabled after the demonstration")
		return

	var live := _find_button(task, correct, true)
	if live == null:
		failures.append("l1: the correct option was not enabled after the demonstration")
		return
	var wrong := _enabled_button_other_than(task, correct)
	if wrong == null:
		failures.append("l1: the step offers no wrong option to test a retry with")
		return

	await _click(wrong)
	if watch["finished"]:
		failures.append("l1: a wrong answer finished the step")
	if watch["mistakes"] == 0:
		failures.append("l1: a wrong answer was not recorded")
	if not _explanation_visible(task):
		failures.append("l1: a wrong answer showed no explanation")
	print("  retry: a wrong answer is explained and the step stays open")

	await _click(live)
	await _seconds(0.8)
	if not watch["finished"]:
		failures.append("l1: the correct answer did not finish the step after a retry")
	else:
		print("  retry: the correct answer then completes the step")


## 2. Swipe across the board with real motion events until it is clean.
func _swipe_board(screen: Node, level_id: String, step_id: String) -> void:
	var task: KitchenTask = screen.call("current_task")
	if task == null or task.step_id() != step_id:
		failures.append("%s: the swipe step '%s' did not build its task" % [level_id, step_id])
		return
	var watch := _watch(task)
	if bool(task.step.get("demo", false)):
		await _seconds(3.2)
	await _frames(3)

	# Scrub the same plane the task itself measures against, rather than guessing
	# where the board is. Reading it from the task keeps the test honest if the
	# board is ever moved.
	var top := float(task.get("_board_top_y"))
	var centre: Vector3 = task.kitchen.centre_slot()
	var points: Array[Vector2] = []
	for row in 3:
		var z := centre.z - 0.26 + float(row) * 0.26
		for column in 7:
			var x := centre.x - 0.42 + float(column) * 0.14
			var point := task.kitchen.world_to_screen(Vector3(x, top, z))
			if point.x > 0.0:
				points.append(point)
	if points.size() < 4:
		failures.append("%s: the board is not on screen to swipe" % level_id)
		return

	_push_button(points[0], true)
	await _frames(1)
	for point in points:
		_push_motion(point)
		await _frames(1)
	_push_button(points[points.size() - 1], false)

	await _seconds(1.0)
	if not watch["finished"]:
		failures.append("%s: swiping across the whole board did not clean it" % level_id)
	else:
		print("  swipe: real motion events wash the board clean")


## 3. Press and hold must finish; letting go early must not.
func _hold_step(screen: Node, level_id: String, step_id: String, duration: float) -> void:
	var task: KitchenTask = screen.call("current_task")
	if task == null or task.step_id() != step_id:
		failures.append("%s: the hold step '%s' did not build its task" % [level_id, step_id])
		return
	var watch := _watch(task)
	await _frames(2)

	# A short press is not a hold.
	_push_button(FREE_POINT, true)
	await _seconds(0.25)
	_push_button(FREE_POINT, false)
	await _frames(2)
	if watch["finished"]:
		failures.append("%s: a short press finished the hold step '%s'" % [level_id, step_id])
	else:
		print("  hold: letting go early does not finish the step")

	# A real press and hold does.
	_push_button(FREE_POINT, true)
	await _seconds(duration + 0.9)
	_push_button(FREE_POINT, false)
	await _seconds(0.6)
	if not watch["finished"]:
		failures.append("%s: holding for %.1fs did not finish the hold step '%s'" % [
			level_id, duration, step_id])
	else:
		print("  hold: a real press and hold finishes the step")


## 4. Cooking needs the temperature to reach the safe level and stay there.
func _cook_step(screen: Node, level_id: String, step_id: String) -> void:
	var task: KitchenTask = screen.call("current_task")
	if task == null or task.step_id() != step_id:
		failures.append("%s: the cook step '%s' did not build its task" % [level_id, step_id])
		return
	var watch := _watch(task)
	await _frames(2)

	# Letting go before the fish is safe must not finish.
	_push_button(FREE_POINT, true)
	await _seconds(1.2)
	_push_button(FREE_POINT, false)
	await _seconds(0.4)
	if watch["finished"]:
		failures.append("%s: releasing early finished the cook step '%s'" % [level_id, step_id])
	else:
		print("  cook: releasing before the fish is safe does not finish the step")

	# Hold long enough to reach the safe temperature and stay there.
	_push_button(FREE_POINT, true)
	await _seconds(13.0)
	_push_button(FREE_POINT, false)
	await _seconds(1.0)
	if not watch["finished"]:
		failures.append("%s: holding the fish at a safe temperature did not finish '%s'" % [
			level_id, step_id])
	else:
		print("  cook: holding the fish at a safe temperature finishes the step")


# ================================================================ step helpers ===
func _tap_correct(screen: Node, level_id: String, step_id: String) -> void:
	var task: KitchenTask = screen.call("current_task")
	if task == null or task.step_id() != step_id:
		failures.append("%s: step '%s' is not the current task" % [level_id, step_id])
		return
	var watch := _watch(task)
	if bool(task.step.get("demo", false)):
		await _seconds(2.6)
	var button := _find_button(task, _correct_label(task.step), true)
	if button == null:
		failures.append("%s: step '%s' never offered its correct option" % [level_id, step_id])
		return
	await _click(button)
	await _seconds(0.8)
	if not watch["finished"]:
		failures.append("%s: clicking the correct option did not finish '%s'" % [level_id, step_id])


func _drag_everything(screen: Node, level_id: String, step_id: String) -> void:
	var task: KitchenTask = screen.call("current_task")
	if task == null or task.step_id() != step_id:
		failures.append("%s: step '%s' is not the current task" % [level_id, step_id])
		return
	var watch := _watch(task)
	if bool(task.step.get("demo", false)):
		await _seconds(3.2)
	await _frames(3)

	var targets: Array = task.step.get("targets", [])
	var items: Array = task.step.get("items", [])
	var zone_index := {}
	for i in targets.size():
		zone_index[str((targets[i] as Dictionary).get("id", ""))] = i

	for i in items.size():
		var item: Dictionary = items[i]
		var target := str(item.get("target", ""))
		if not zone_index.has(target):
			failures.append("%s: item '%s' names an unknown container" % [level_id, item.get("id", "")])
			continue
		var from := task.kitchen.world_to_screen(
			task.kitchen.item_slot(i, items.size()) + Vector3(0.0, 0.16, 0.0))
		var to := task.kitchen.world_to_screen(
			task.kitchen.zone_slot(int(zone_index[target]), targets.size()) + Vector3(0.0, 0.3, 0.0))
		if from.x < 0.0 or to.x < 0.0:
			failures.append("%s: an item or container is off screen" % level_id)
			continue
		_push_button(from, true)
		await _frames(1)
		_push_motion(from.lerp(to, 0.5))
		await _frames(1)
		_push_motion(to)
		await _frames(1)
		_push_button(to, false)
		await _seconds(0.7)

	if not watch["finished"]:
		failures.append("%s: dragging every item to the right container did not finish '%s'" % [
			level_id, step_id])
	else:
		print("  drag: real drag events place every item (%s)" % step_id)


func _dismiss_lesson(screen: Node) -> void:
	var card: Node = _find(screen, func(node: Node) -> bool: return node is LessonCard)
	if card == null:
		return
	card.emit_signal("dismissed")
	await _frames(3)


func _answer_quiz_by_pointer(screen: Node, level_id: String) -> void:
	var quiz: Node = _find(screen, func(node: Node) -> bool: return node is QuizCard)
	if quiz == null:
		failures.append("%s: the knowledge check never appeared" % level_id)
		return
	var questions := QuizDB.for_level(level_id)
	var required: Array = QuizDB.required_ids(level_id)
	var retry_tested := false
	for index in questions.size():
		var question: Dictionary = questions[index]
		var question_id := str(question.get("id", ""))
		var correct := ""
		var wrong := ""
		for option_entry in question.get("options", []):
			var option: Dictionary = option_entry
			if bool(option.get("correct", false)):
				correct = LessonDB.local(option.get("label"))
			elif wrong.is_empty():
				wrong = LessonDB.local(option.get("label"))
		if correct.is_empty():
			failures.append("%s: question '%s' has no correct option" % [level_id, question_id])
			return

		# The retry path is a property of the *required* question: a wrong answer there
		# is explained and the step stays open. An optional question that is answered
		# wrongly is finished by design (the explanation has been read), so it must not
		# be used to test the retry.
		if not retry_tested and required.has(question_id) and not wrong.is_empty():
			retry_tested = true
			var wrong_button := _find_button(quiz, wrong, true)
			if wrong_button != null:
				await _click(wrong_button)
				if _find_button(quiz, correct, true) == null:
					failures.append("%s: a wrong answer on required '%s' left no retry" % [
						level_id, question_id])
				else:
					print("  quiz: required '%s' stays open after a wrong answer" % question_id)

		var option_button := _find_button(quiz, correct, true)
		if option_button == null:
			failures.append("%s: the correct answer was not offered for '%s'" % [level_id, question_id])
			return
		await _click(option_button)

		var advance := _find_button(quiz, Loc.t("feedback.continue"), true)
		if advance == null:
			advance = _find_button(quiz, Loc.t("quiz.next"), true)
		if advance == null:
			failures.append("%s: no way onwards after '%s'" % [level_id, question_id])
			return
		await _click(advance)
	print("  quiz: answered through real clicks (%s)" % level_id)


# ==================================================================== plumbing ===
func _open_kitchen(level_id: String) -> Node:
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await _frames(3)
	var level: Dictionary = screen.get("level")
	if level.is_empty():
		failures.append("%s: the kitchen screen did not load the challenge" % level_id)
		screen.queue_free()
		return null
	return screen


## Follows a task's outcome through its signals. Reading the task object after the
## step has finished is not safe — the runner frees it as soon as it advances.
func _watch(task: KitchenTask) -> Dictionary:
	var flags := {"finished": false, "success": false, "mistakes": 0}
	task.finished.connect(func(success: bool) -> void:
		flags["finished"] = true
		flags["success"] = success)
	task.mistake.connect(func(_payload: Dictionary) -> void:
		flags["mistakes"] += 1)
	return flags


func _explanation_visible(task: KitchenTask) -> bool:
	var label: Variant = task.get("_explain_label")
	if label is Label:
		return (label as Label).visible and not (label as Label).text.is_empty()
	return false


## Events are pushed with `in_local_coords = true` because the positions here come
## from `Control.get_global_rect()` and `world_to_screen`, which are already in
## viewport (canvas) coordinates. Pushing them as window coordinates makes the
## viewport run them back through the stretch transform, and the click then lands
## somewhere else entirely — a mistake worth recording, because it looks exactly
## like a broken button.
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


# ===================================================================== lookups ===
func _correct_label(step: Dictionary) -> String:
	for option_entry in step.get("options", []):
		var option: Dictionary = option_entry
		if bool(option.get("correct", false)):
			return LessonDB.local(option.get("label"))
	return ""


## `enabled_only` also filters out disabled buttons, which is what the player can
## actually press. It is false only for the demonstration check, which needs to see
## the disabled button to prove it is disabled.
func _find_button(root: Node, text: String, enabled_only: bool) -> Button:
	var button: Button = _find(root, func(node: Node) -> bool:
		return node is Button \
			and (node as Button).text == text \
			and (node as Button).is_visible_in_tree() \
			and (not enabled_only or not (node as Button).disabled))
	return button


func _enabled_button_other_than(root: Node, text: String) -> Button:
	var button: Button = _find(root, func(node: Node) -> bool:
		return node is Button \
			and (node as Button).text != text \
			and (node as Button).is_visible_in_tree() \
			and not (node as Button).disabled \
			and not (node as Button).text.is_empty())
	return button


func _find(root: Node, predicate: Callable) -> Node:
	if predicate.call(root):
		return root
	for child in root.get_children():
		var found := _find(child, predicate)
		if found != null:
			return found
	return null


# ====================================================================== timing ===
func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


func _report() -> void:
	print("--- results ---")
	if failures.is_empty():
		print("BEHAVIOUR TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("BEHAVIOUR TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
