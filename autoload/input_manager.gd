extends Node
## InputManager (autoload name: `InputManager`).
##
## The game is mouse-first and touch-capable. Named actions are registered at
## runtime (so the mapping is reviewed in one place), a touchscreen tap
## synthesises the same `primary` action as a mouse click, and quick finger
## swipes are reported as a direction for gesture-based interactions.
##
## Cooking tasks read pointer state directly (`pointer_position`,
## `Input.is_action_pressed("primary")`), which keeps click, drag, hold and
## swipe implementations identical on desktop and mobile.

signal virtual_action(action: String, pressed: bool)
signal swipe(direction: String, distance: float)

const BINDINGS := {
	"primary": {
		"keys": [KEY_SPACE, KEY_ENTER],
		"buttons": [JOY_BUTTON_A],
		"label": "Confirm / act",
	},
	"pause": {
		"keys": [KEY_ESCAPE],
		"buttons": [JOY_BUTTON_START],
		"label": "Pause",
	},
	"debug": {
		"keys": [KEY_F3],
		"buttons": [],
		"label": "Toggle debug overlay",
	},
}

var touch_enabled := false

var _touch_active := false
var _touch_start := Vector2.ZERO
var _touch_start_time := 0.0
var _touch_index := -1
var _registered := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	register_actions()
	touch_enabled = DisplayServer.is_touchscreen_available()


func register_actions() -> void:
	if _registered:
		return
	for action_name in BINDINGS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)
		var binding: Dictionary = BINDINGS[action_name]
		for keycode in binding.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action_name, ev)
		for button in binding.get("buttons", []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = button
			InputMap.action_add_event(action_name, jb)
	# A left mouse click is "primary" everywhere.
	if InputMap.has_action("primary"):
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("primary", click)
	_registered = true


# ------------------------------------------------------------------ queries ---
## Where the pointer is, in viewport pixels, whichever device produced it.
func pointer_position() -> Vector2:
	if _touch_active:
		return _touch_start
	return get_viewport().get_mouse_position()


func is_primary_pressed() -> bool:
	return Input.is_action_pressed("primary")


static func binding_label(action_name: String) -> String:
	var binding: Dictionary = BINDINGS.get(action_name, {})
	return str(binding.get("label", action_name))


static func primary_keys_text() -> String:
	var binding: Dictionary = BINDINGS.get("primary", {})
	var parts: Array[String] = []
	for keycode in binding.get("keys", []):
		parts.append(OS.get_keycode_string(keycode))
	return " / ".join(parts)


# -------------------------------------------------------------------- touch ---
func _input(event: InputEvent) -> void:
	if not touch_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_active:
				return
			_touch_active = true
			_touch_index = touch.index
			_touch_start = touch.position
			_touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			if touch.index != _touch_index:
				return
			_resolve_gesture(touch.position, true)
			_touch_active = false
			_touch_index = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _touch_active or drag.index != _touch_index:
			return
		_touch_start = drag.position


## A short movement is a tap (which becomes `primary`); a fast, long movement is
## a swipe, reported to whoever is listening.
func _resolve_gesture(end_position: Vector2, released: bool) -> void:
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _touch_start_time
	var delta := end_position - _touch_start
	var distance := delta.length()
	if distance < GameConfig.SWIPE_MIN_PIXELS or elapsed > GameConfig.SWIPE_MAX_TIME:
		if released:
			synthesize_action("primary")
		return
	var direction := "right"
	if absf(delta.x) > absf(delta.y):
		direction = "right" if delta.x > 0.0 else "left"
	else:
		direction = "down" if delta.y > 0.0 else "up"
	swipe.emit(direction, distance)


## Fires a named action for one short pulse. Used by touch taps and by on-screen
## buttons that appear on mobile layouts.
func synthesize_action(action_name: String, hold_seconds: float = 0.12) -> void:
	if not InputMap.has_action(action_name):
		push_warning("InputManager: unknown action '%s'." % action_name)
		return
	var press := InputEventAction.new()
	press.action = action_name
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	virtual_action.emit(action_name, true)
	_release_later(action_name, hold_seconds)


func _release_later(action_name: String, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var release := InputEventAction.new()
	release.action = action_name
	release.pressed = false
	Input.parse_input_event(release)
	virtual_action.emit(action_name, false)
