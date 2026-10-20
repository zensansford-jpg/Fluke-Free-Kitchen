extends Node
## Renders each challenge to PNG files so the presentation can actually be looked
## at. Headless runs cannot show what a scene looks like, so this is run with a
## real window; it is a development tool, not part of the game.
##
## Disk writes are suspended for the whole run: a screenshot pass must never
## depend on, or leave behind, real player progress. The screen shots still show a
## finished game because the progress behind them is played for real, in memory.
##
## Run with:
##   godot --path <project> res://tests/visual_capture.tscn -- l1
##   godot --path <project> res://tests/visual_capture.tscn -- screens
##
## Images and quiz traces land in `build/screenshots/visual`.

const TestWindow := preload("res://tests/test_window.gd")
const Captures := preload("res://tests/captures.gd")

var out_dir := ""


func _ready() -> void:
	# Screens stagger their content in when they open; a capture would record
	# that as a half-faded page, so the interface's motion is off for this run.
	UIFactory.set_motion_enabled(false)
	# An explicit size: with stretch mode disabled the shots must be taken at a
	# stated pixel size, not whenever the desktop window happens to be.
	TestWindow.use(1280, 720)
	await TestWindow.settle(2)
	out_dir = Captures.open("visual")
	print("--- visual capture ---")
	SaveData.suspend_disk_writes(true)
	# The game fades in from black over the first ~0.6 s. Let that finish before
	# the first shot, or it is captured through the wash and looks dim.
	await _wait(0.9)
	# Long runs are fragile because the whole thing happens in one throwaway
	# window, so the level list can be given on the command line:
	#   godot --path <project> res://tests/visual_capture.tscn -- l1 l2
	var requested := OS.get_cmdline_user_args()
	var levels: Array = []
	var do_screens := requested.is_empty()
	for arg in requested:
		if str(arg) == "screens":
			do_screens = true
		elif LevelDB.ids().has(str(arg)):
			levels.append(str(arg))
	if requested.is_empty():
		levels = LevelDB.ids()
	for level_id in levels:
		print("  entering %s" % level_id)
		await _capture_level(str(level_id))
		print("  leaving %s" % level_id)
	if do_screens:
		await _seed_progress()
		print("  capturing screens")
		await _capture_screens()
	print("--- done ---")
	get_tree().quit(0)


# ------------------------------------------------------------------- challenges ---
func _capture_level(level_id: String) -> void:
	Game.current_level_id = level_id
	Game.change_state(Game.State.PLAYING)

	var screen := await _open_kitchen(level_id)
	if screen == null:
		return
	await _save("%s_00_demo" % level_id)

	if level_id == "l1":
		# Pause has to be captured while the challenge is still running: once the
		# result screen is up the game is no longer in the playing state.
		var hud: Node = screen.get("hud")
		var pause_menu: Node = screen.get("pause_menu")
		hud.emit_signal("pause_pressed")
		await _settle()
		await _save("l1_00_pause")
		pause_menu.emit_signal("resume_requested")
		await _settle()

	await _walk(screen, level_id, true)
	await _wait(1.2)
	await _save("%s_95_result" % level_id)

	screen.queue_free()
	await _settle()


## Plays every challenge without saving shots, so the menu, level list and journal
## that are captured afterwards reflect a real playthrough.
func _seed_progress() -> void:
	print("  seeding progress (in memory)")
	for level_id in LevelDB.ids():
		Game.current_level_id = str(level_id)
		Game.change_state(Game.State.PLAYING)
		var screen := await _open_kitchen(str(level_id))
		if screen == null:
			continue
		await _walk(screen, str(level_id), false)
		screen.queue_free()
		await _settle()


func _open_kitchen(level_id: String) -> Node:
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await _settle()
	var level: Dictionary = screen.get("level")
	if level.is_empty():
		printerr("  capture: %s did not load" % level_id)
		screen.queue_free()
		return null
	return screen


## Drives one challenge to its result. With `snap` the interesting frames are
## written out.
##
## The walk follows the runner's own state instead of a parallel counter.
## Assuming the two stay in step is what produced mislabelled shots before: the
## runner can be between steps (a lesson card up, a task already cleared) and a
## `for` loop over the level's steps cannot see that.
func _walk(screen: Node, level_id: String, snap: bool) -> void:
	var captured: Array = []
	var lesson_count := 0
	var guard := 0
	while guard < 48:
		guard += 1

		var card: Node = _find(screen, func(node: Node) -> bool: return node is LessonCard)
		if card != null:
			lesson_count += 1
			if snap:
				await _save("%s_%02d_lesson" % [level_id, lesson_count])
			card.emit_signal("dismissed")
			await _settle()
			continue

		if screen.call("result_visible"):
			return

		var quiz: Node = _find(screen, func(node: Node) -> bool: return node is QuizCard)
		if quiz != null:
			await _answer_quiz(quiz, level_id, snap)
			await _settle()
			continue

		var task: KitchenTask = screen.call("current_task")
		if task == null:
			await _settle()
			continue

		var step_id := task.step_id()
		if snap and not captured.has(step_id):
			var step_index: int = screen.call("current_step_index")
			var kind := str(task.step.get("kind", ""))
			await _wait(2.8)
			await _save("%s_%02d_%s_%s" % [level_id, step_index + 1, kind, step_id])
			captured.append(step_id)
			continue

		task.succeed()
		await _settle()

	printerr("  capture: %s did not reach its result screen" % level_id)


func _answer_quiz(quiz: Node, level_id: String, snap: bool) -> void:
	var trace: Array[String] = ["quiz %s card name=%s" % [level_id, quiz.name]]
	if snap:
		await _save("%s_90_quiz" % level_id)
	for entry in QuizDB.for_level(level_id):
		var question: Dictionary = entry
		var question_id := str(question.get("id", "?"))
		var correct_label := ""
		for option_entry in question.get("options", []):
			var option: Dictionary = option_entry
			if bool(option.get("correct", false)):
				correct_label = LessonDB.local(option.get("label"))
				break
		trace.append("-- %s expected len=%d hash=%d" % [question_id, correct_label.length(), hash(correct_label)])
		for button in _all_buttons(quiz):
			trace.append("   button len=%d hash=%d disabled=%s visible=%s match=%s" % [
				button.text.length(), hash(button.text), button.disabled,
				button.visible, button.text == correct_label])
		var option_button := _live_button_with_text(quiz, correct_label)
		if option_button == null:
			printerr("  capture: no live option for %s" % question_id)
			_write_trace(level_id, trace)
			return
		option_button.emit_signal("pressed")
		await _settle()
		var advance := _live_button_with_text(quiz, Loc.t("feedback.continue"))
		if advance == null:
			advance = _live_button_with_text(quiz, Loc.t("quiz.next"))
		if advance == null:
			printerr("  capture: no advance button after %s" % question_id)
			trace.append("   NO ADVANCE after %s" % question_id)
			_write_trace(level_id, trace)
			return
		advance.emit_signal("pressed")
		await _settle()
	_write_trace(level_id, trace)


func _all_buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	if root is Button:
		out.append(root as Button)
	for child in root.get_children():
		out.append_array(_all_buttons(child))
	return out


func _write_trace(level_id: String, lines: Array[String]) -> void:
	var file := FileAccess.open("%s/%s_quiz_trace.txt" % [out_dir, level_id], FileAccess.WRITE)
	if file == null:
		return
	file.store_string("\n".join(lines))
	file.close()


# ----------------------------------------------------------------------- menus ---
func _capture_screens() -> void:
	for key in ["menu", "levels", "journal", "assessment"]:
		Game.change_state(Game.State.MENU)
		var screen: Node = load(str(Game.SCENES[key])).instantiate()
		add_child(screen)
		await _settle()
		if key == "journal":
			screen.call("show_tab", Journal.TAB_KNOWLEDGE)
			await _settle()
			await _save("screen_%s_knowledge" % key)
			screen.call("show_tab", Journal.TAB_PROGRESS)
			await _settle()
		await _save("screen_%s" % key)
		screen.queue_free()
		await _settle()


# --------------------------------------------------------------------- helpers ---
func _settle() -> void:
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
	await _settle()


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, name]
	var err := image.save_png(path)
	if err == OK:
		print("  saved %s.png (%dx%d)" % [name, image.get_width(), image.get_height()])
	else:
		printerr("  could not save %s (error %d)" % [name, err])


func _find(root: Node, predicate: Callable) -> Node:
	if predicate.call(root):
		return root
	for child in root.get_children():
		var found := _find(child, predicate)
		if found != null:
			return found
	return null


func _live_button_with_text(root: Node, text: String) -> Button:
	# Only buttons that the player could actually press right now. `_show_current`
	# frees the previous question's buttons with `queue_free`, so for the rest of
	# that frame the retired buttons are still in the tree and would otherwise be
	# matched (and pressed) by mistake.
	var button: Button = _find(root, func(node: Node) -> bool:
		return node is Button \
			and (node as Button).text == text \
			and not (node as Button).disabled \
			and (node as Button).is_visible_in_tree())
	return button
