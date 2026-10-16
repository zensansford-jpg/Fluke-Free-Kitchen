class_name KitchenScreen
extends Node
## Runs one challenge from start to finish.
##
## The order is fixed and shared by all three levels: interactive steps, each
## followed by the health-knowledge card for what it taught, and then the
## mandatory knowledge check. Only after all of that does the result screen appear,
## which is how the design keeps education from being skippable.
##
## Everything the player's progress touches goes through the autoloads
## (`Learning`, `SaveData`, `Game`), so quitting mid-way never scores a partial
## run and never loses a completed one.

var level: Dictionary = {}
var session: KitchenSession = null
var kitchen: KitchenScene = null
var hud: KitchenHUD = null
var pause_menu: PauseMenu = null
var result_screen: KitchenResult = null

var _hud_layer: CanvasLayer = null
var _task_host: Control = null
var _modal: Control = null
var _modal_centre: CenterContainer = null
var _task: KitchenTask = null
var _step_index := 0
var _elapsed := 0.0
var _running := false
var _advancing := false
var _finishing := false
var _quiz_required: Array = []
var _resize_pending := false


func _ready() -> void:
	level = LevelDB.by_id(Game.current_level_id)
	if level.is_empty():
		push_error("KitchenScreen: no challenge named '%s'." % Game.current_level_id)
		Game.go_to_levels()
		return

	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	session = KitchenSession.new()
	session.begin(level)
	_quiz_required = QuizDB.required_ids(str(level.get("id", "")))
	Game.state_changed.connect(_on_state_changed)

	_set_step(0)
	_running = true
	set_process(true)


func _exit_tree() -> void:
	_running = false


# ------------------------------------------------------------------- resizing ---
## A live window resize re-fits the HUD, the current task's panels and the camera.
## Nothing is rebuilt and nothing is restarted: the step in progress, the score and
## the drag state all survive.
func _on_viewport_size_changed() -> void:
	if _resize_pending:
		return
	_resize_pending = true
	_reflow_soon()


func _reflow_soon() -> void:
	await get_tree().create_timer(0.18, true).timeout
	_resize_pending = false
	if not is_inside_tree():
		return
	reflow()


## Public so the layout tool can exercise it directly instead of trying to resize
## a headless window.
func reflow() -> void:
	if hud != null and is_instance_valid(hud):
		hud.apply_layout()
	if _task != null and is_instance_valid(_task):
		_task.apply_layout()
	if pause_menu != null and is_instance_valid(pause_menu):
		pause_menu.apply_layout()
	if result_screen != null and is_instance_valid(result_screen):
		result_screen.apply_layout()
	if kitchen != null and is_instance_valid(kitchen):
		kitchen.apply_layout()
	UIFactory.refresh_responsive(self)
	if _modal != null and _modal.visible:
		_fit_modal()


func _process(delta: float) -> void:
	if _running and Game.state == Game.State.PLAYING:
		_elapsed += delta


# --------------------------------------------------------------------- plumbing ---
func _build_world() -> void:
	kitchen = KitchenScene.new()
	kitchen.name = "Kitchen"
	add_child(kitchen)
	kitchen.setup(level)


func _build_ui() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HudLayer"
	_hud_layer.layer = 10
	add_child(_hud_layer)

	hud = KitchenHUD.new()
	hud.name = "Hud"
	_hud_layer.add_child(hud)
	hud.setup(level)
	hud.pause_pressed.connect(_open_pause)
	hud.hint_pressed.connect(_replay_demo)

	_task_host = Control.new()
	_task_host.name = "TaskHost"
	UIFactory.fill(_task_host)
	_task_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_task_host)

	var modal_layer := CanvasLayer.new()
	modal_layer.name = "ModalLayer"
	modal_layer.layer = 30
	add_child(modal_layer)

	_modal = UIFactory.overlay_layer(true)
	_modal.visible = false
	_modal_centre = _modal.get_meta("centre") as CenterContainer
	modal_layer.add_child(_modal)

	result_screen = KitchenResult.new()
	result_screen.name = "Result"
	result_screen.visible = false
	result_screen.retry_pressed.connect(_retry)
	result_screen.next_pressed.connect(_next_level)
	result_screen.levels_pressed.connect(_to_levels)
	result_screen.journal_pressed.connect(_to_journal)
	modal_layer.add_child(result_screen)

	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	pause_menu.resume_requested.connect(_resume)
	pause_menu.restart_requested.connect(_retry)
	pause_menu.journal_requested.connect(_to_journal)
	pause_menu.levels_requested.connect(_to_levels)
	add_child(pause_menu)


# ------------------------------------------------------------------------ steps ---
func _set_step(index: int) -> void:
	_advancing = false
	_step_index = index
	var steps: Array = level.get("steps", [])
	if index >= steps.size():
		_begin_quiz()
		return

	_clear_task()
	kitchen.clear_set()
	if hud != null:
		hud.clear_prompt()

	var step: Dictionary = steps[index]
	_task = TaskFactory.create(str(step.get("kind", "")))
	if _task == null:
		# A step the factory cannot build is a content bug. Recording it as an
		# error and moving on is better than stalling a child in front of a
		# broken screen, and the mistake count makes the bug visible in the data.
		push_error("KitchenScreen: no task for kind '%s' (step '%s')." % [
			str(step.get("kind", "")), str(step.get("id", ""))])
		session.record_step(str(step.get("id", "")), 1, 1)
		_set_step(index + 1)
		return

	_task.name = "Task_" + str(step.get("id", ""))
	_task.step = step
	_task.kitchen = kitchen
	_task.hud = hud
	_task.finished.connect(_on_task_finished.bind(_task))
	_task_host.add_child(_task)
	hud.set_step(index + 1, steps.size())
	_task.begin()


func _clear_task() -> void:
	if _task == null:
		return
	_task.abort()
	if is_instance_valid(_task):
		_task_host.remove_child(_task)
		_task.queue_free()
	_task = null


func _on_task_finished(_success: bool, task: KitchenTask) -> void:
	if _advancing:
		return
	_advancing = true
	if task == null or not is_instance_valid(task):
		return

	var step: Dictionary = task.step
	var step_id := str(step.get("id", ""))
	var level_id := str(level.get("id", ""))
	session.record_step(step_id, task.attempts, task.mistakes)
	Learning.record_activity(level_id, step_id)

	var corrected: Array = task.corrects()
	for claim_id in corrected:
		Learning.record_misconception(str(claim_id))

	var lesson_id := str(step.get("lesson", ""))
	_clear_task()

	if lesson_id.is_empty() or not Education.has_lesson(lesson_id):
		_set_step(_step_index + 1)
		return

	Learning.record_lesson(lesson_id)
	AudioManager.play_ui("page")
	var card := LessonCard.new()
	card.setup(lesson_id, corrected)
	card.dismissed.connect(_on_lesson_dismissed)
	_show_modal(card)


func _on_lesson_dismissed() -> void:
	# `_advancing` is true from the moment a task finishes until the next step is
	# built, so this can only fire once per card. Without the guard a stray second
	# signal would silently skip a whole step.
	if not _advancing:
		return
	_clear_modal()
	_set_step(_step_index + 1)


func _replay_demo() -> void:
	if _task != null and is_instance_valid(_task):
		_task.replay_demo()


# ------------------------------------------------------------------------- quiz ---
func _begin_quiz() -> void:
	var level_id := str(level.get("id", ""))
	var questions := QuizDB.for_level(level_id)
	if questions.is_empty():
		# The design requires at least one knowledge question per challenge, so an
		# empty list means the content is wrong. Finish honestly rather than
		# pretending the check happened.
		push_error("KitchenScreen: challenge '%s' has no knowledge questions." % level_id)
		_finish()
		return

	AudioManager.play_ui("page")
	var card := QuizCard.new()
	card.answered.connect(_on_quiz_answered)
	card.finished.connect(_on_quiz_finished)
	_show_modal(card)
	card.run(questions, _quiz_required)


func _on_quiz_answered(question_id: String, correct: bool, attempts: int) -> void:
	session.record_quiz(question_id, correct, _quiz_required.has(question_id), attempts)


func _on_quiz_finished() -> void:
	_clear_modal()
	_finish()


# ----------------------------------------------------------------------- result ---
func _finish() -> void:
	# The result is written once. A second call would re-record the score after the
	# first call had already stored it as the best, which would report "new best"
	# wrongly.
	if _finishing:
		return
	_finishing = true
	_running = false
	var level_id := str(level.get("id", ""))
	var result := session.summary()
	result["seconds"] = _elapsed

	var save_info := SaveData.record_level_result(
		level_id,
		int(result.get("stars", 0)),
		int(result.get("score", 0)),
		float(result.get("accuracy", 0.0)),
		bool(result.get("passed", false)))

	Game.finish_level(result)
	result_screen.show_result(level, result, save_info)
	result_screen.visible = true


func _retry() -> void:
	Game.resume()
	if pause_menu != null:
		pause_menu.close()
	Game.restart_level()


func _next_level() -> void:
	var next := LevelDB.next_level_id(str(level.get("id", "")))
	if next.is_empty():
		_to_levels()
		return
	Game.resume()
	if pause_menu != null:
		pause_menu.close()
	Game.start_level(next)


func _to_levels() -> void:
	Game.resume()
	Game.abandon_level()
	Game.go_to_levels()


func _to_journal() -> void:
	Game.resume()
	Game.abandon_level()
	Game.navigate("journal")


# ------------------------------------------------------------------------ pause ---
func _open_pause() -> void:
	if _modal != null and _modal.visible:
		return
	if Game.state != Game.State.PLAYING:
		return
	Game.pause()
	pause_menu.open()


func _resume() -> void:
	if pause_menu != null:
		pause_menu.close()
	Game.resume()


func _on_state_changed(state: int, _previous: int) -> void:
	if state != Game.State.PAUSED and pause_menu != null and pause_menu.is_open():
		pause_menu.close()


# --------------------------------------------------------------------- queries ---
## The task currently on screen, or `null` between steps.
func current_task() -> KitchenTask:
	return _task


func current_step_index() -> int:
	return _step_index


func is_modal_open() -> bool:
	return _modal != null and _modal.visible


func result_visible() -> bool:
	return result_screen != null and result_screen.visible


# --------------------------------------------------------------------- modality ---
func _show_modal(content: Control) -> void:
	_clear_modal()
	var scroll := ScrollContainer.new()
	scroll.name = "ModalScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(content)
	_modal_centre.add_child(scroll)
	_modal.visible = true
	_fit_modal()


## Sizes the open modal to the window. Called again on a resize, so a lesson card
## or a knowledge check opened on a desktop still fits when the window shrinks.
func _fit_modal() -> void:
	if _modal_centre == null:
		return
	var scroll := _modal_centre.get_node_or_null("ModalScroll") as ScrollContainer
	if scroll == null:
		return
	var vp := UIFactory.viewport_size()
	var w := UIFactory.fit_width(900.0)
	var h := minf(790.0, maxf(200.0, vp.y - 90.0))
	scroll.custom_minimum_size = Vector2(w, h)
	var content := scroll.get_child(0) as Control
	if content != null:
		content.custom_minimum_size = Vector2(w - 12.0, content.custom_minimum_size.y)


func _clear_modal() -> void:
	if _modal_centre == null:
		return
	for child in _modal_centre.get_children():
		_modal_centre.remove_child(child)
		child.queue_free()
	_modal.visible = false


# ------------------------------------------------------------------------ input ---
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if result_screen != null and result_screen.visible:
		return
	if _modal != null and _modal.visible:
		return
	if Game.state != Game.State.PLAYING:
		return
	_open_pause()
	get_viewport().set_input_as_handled()
