class_name PauseMenu
extends CanvasLayer
## The pause overlay for a challenge.
##
## It lives on its own layer with `PROCESS_MODE_ALWAYS` so it keeps responding
## while the rest of the tree is paused, and it handles the pause key itself,
## which means the game can be resumed from the keyboard as well as the mouse.

signal resume_requested()
signal restart_requested()
signal journal_requested()
signal levels_requested()

var _panel: PanelContainer = null
var _settings_holder: Control = null


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	visible = true
	AudioManager.play_ui("page")


func close() -> void:
	_close_settings()
	visible = false


func is_open() -> bool:
	return visible


## Re-centres the panel for the current window size. The kitchen calls this when
## the window is resized, including while the game is paused.
func apply_layout() -> void:
	if _panel != null and is_instance_valid(_panel):
		UIFactory.centre_box(_panel, 520.0, 470.0)
	UIFactory.refresh_responsive(self)


func _build() -> void:
	var backdrop := UIFactory.backdrop()
	add_child(backdrop)

	_panel = UIFactory.panel(UIFactory.PANEL_COLOR)
	UIFactory.centre_box(_panel, 520.0, 470.0)
	add_child(_panel)

	var v := UIFactory.vbox(12)
	_panel.add_child(v)
	v.add_child(UIFactory.title(Loc.t("pause.title"), 34))
	v.add_child(_button(Loc.t("pause.resume"), true, func() -> void: resume_requested.emit()))
	v.add_child(_button(Loc.t("pause.restart"), false, func() -> void: restart_requested.emit()))
	v.add_child(_button(Loc.t("pause.journal"), false, func() -> void: journal_requested.emit()))
	v.add_child(_button(Loc.t("pause.settings"), false, _open_settings))
	v.add_child(_button(Loc.t("pause.to_levels"), false, func() -> void: levels_requested.emit()))

	_settings_holder = Control.new()
	UIFactory.fill(_settings_holder)
	_settings_holder.visible = false
	add_child(_settings_holder)


func _button(text: String, primary: bool, action: Callable) -> Button:
	var button := UIFactory.button(text, 21, 400.0)
	UIFactory.style_button(button, UIFactory.ACCENT if primary else UIFactory.TEXT_BRIGHT, primary)
	button.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		action.call())
	return button


func _open_settings() -> void:
	if _settings_holder.visible:
		return
	var settings := SettingsPanel.new()
	UIFactory.responsive_min_size(settings, 720.0)
	settings.closed.connect(_close_settings)
	_settings_holder.add_child(settings)
	_settings_holder.visible = true


func _close_settings() -> void:
	if _settings_holder == null:
		return
	for child in _settings_holder.get_children():
		child.queue_free()
	_settings_holder.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _settings_holder != null and _settings_holder.visible:
		return
	if event.is_action_pressed("pause"):
		AudioManager.play_ui("ui_back")
		resume_requested.emit()
		get_viewport().set_input_as_handled()
