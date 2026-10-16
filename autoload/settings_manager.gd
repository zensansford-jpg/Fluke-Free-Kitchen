extends Node
## SettingsManager (autoload name: `Settings`).
##
## Owns every user-facing preference, persists them to `user://settings_v2.json`
## and applies them to the engine (audio buses, window mode, graphics quality).
##
## Nothing here is game content: the scene tree reads these properties and
## listens to `settings_changed`.

signal settings_changed
signal graphics_changed

const SAVE_PATH := "user://settings_v2.json"
const VERSION := 2

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const QUALITY_LEVELS: Array[String] = ["low", "medium", "high"]
const LANGUAGES: Array[String] = ["th", "en"]

var master_volume: float = 1.0
var music_volume: float = 0.6
var sfx_volume: float = 0.9
## Gentle screen feedback on successful actions and mistakes.
var shake_enabled: bool = true
## Open the "more detail" tier of every health tip straight away.
var detail_default_open: bool = false
var language: String = "th"
var quality: String = "medium"
var fullscreen: bool = false
var resolution_index: int = 3

var last_load_error: String = ""

var _applying := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_audio()
	apply_graphics()


# ------------------------------------------------------------------ loading ---
func load_settings() -> void:
	last_load_error = ""
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_load_error = "could not open settings file"
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_load_error = "settings file was not valid JSON; defaults restored"
		return
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != VERSION:
		last_load_error = "settings version changed; defaults restored"
		return

	master_volume = clampf(float(data.get("master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(data.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	shake_enabled = bool(data.get("shake_enabled", shake_enabled))
	detail_default_open = bool(data.get("detail_default_open", detail_default_open))
	quality = _sanitise_quality(str(data.get("quality", quality)))
	fullscreen = bool(data.get("fullscreen", fullscreen))
	resolution_index = clampi(int(data.get("resolution_index", resolution_index)), 0, RESOLUTIONS.size() - 1)
	var lang := str(data.get("language", language))
	if LANGUAGES.has(lang):
		language = lang


func save_settings() -> void:
	var data := {
		"version": VERSION,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"shake_enabled": shake_enabled,
		"detail_default_open": detail_default_open,
		"language": language,
		"quality": quality,
		"fullscreen": fullscreen,
		"resolution_index": resolution_index,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Settings: could not write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


# ------------------------------------------------------------------- setters --
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_commit_audio()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_commit_audio()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_commit_audio()


func set_language(value: String) -> void:
	if not LANGUAGES.has(value) or value == language:
		return
	language = value
	save_settings()
	settings_changed.emit()


func set_shake_enabled(value: bool) -> void:
	shake_enabled = value
	save_settings()
	settings_changed.emit()


func set_detail_default_open(value: bool) -> void:
	detail_default_open = value
	save_settings()
	settings_changed.emit()


func set_quality(value: String) -> void:
	quality = _sanitise_quality(value)
	apply_graphics()
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_graphics()
	save_settings()


func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	apply_graphics()
	save_settings()


## Restores every preference to its shipped default and re-applies them.
func reset_defaults() -> void:
	master_volume = 1.0
	music_volume = 0.6
	sfx_volume = 0.9
	shake_enabled = true
	detail_default_open = false
	language = "th"
	quality = "medium"
	fullscreen = false
	resolution_index = 3
	apply_audio()
	apply_graphics()
	save_settings()
	settings_changed.emit()


# ------------------------------------------------------------------- engine ---
func apply_audio() -> void:
	_set_bus_volume(BUS_MASTER, master_volume)
	_set_bus_volume(BUS_MUSIC, music_volume)
	_set_bus_volume(BUS_SFX, sfx_volume)
	# The UI bus rides the effects volume so players only tune it once.
	_set_bus_volume(BUS_UI, sfx_volume)


func apply_graphics() -> void:
	_set_quality(quality)
	_apply_window()
	graphics_changed.emit()


func resolution() -> Vector2i:
	return RESOLUTIONS[resolution_index]


func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution())


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var db := -80.0 if linear <= 0.0001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(idx, db)
	AudioServer.set_bus_mute(idx, linear <= 0.0001)


func _set_quality(value: String) -> void:
	match value:
		"low":
			_apply_scaling(0.72, 1)
		"high":
			_apply_scaling(1.0, 4)
		_:
			_apply_scaling(0.9, 2)


func _apply_scaling(scale: float, msaa: int) -> void:
	var root := get_tree().root
	if root != null:
		root.scaling_3d_scale = clampf(scale, 0.5, 1.0)
		root.msaa_3d = msaa


func _sanitise_quality(value: String) -> String:
	return value if QUALITY_LEVELS.has(value) else "medium"


func _commit_audio() -> void:
	apply_audio()
	save_settings()
	settings_changed.emit()
