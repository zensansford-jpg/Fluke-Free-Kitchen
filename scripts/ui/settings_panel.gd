class_name SettingsPanel
## The settings screen, reused from both the main menu and the pause menu.
##
## Built entirely from `UIFactory` primitives so it matches the rest of the
## interface, and wired straight to the `Settings` autoload. When the language
## changes the panel rebuilds itself so the labels follow immediately.

extends PanelContainer

signal closed

var _built_language: String = ""
var _rows: VBoxContainer
var _confirm: ConfirmationDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.settings_changed.connect(_on_settings_changed)
	_rebuild()


func _on_settings_changed() -> void:
	# Only a language change requires new labels; rebuilding during a slider
	# drag would destroy the slider under the player's finger.
	if Settings.language != _built_language:
		_rebuild()


func _rebuild() -> void:
	_built_language = Settings.language
	for child in get_children():
		child.queue_free()
	UIFactory.style_panel(self, UIFactory.PANEL_COLOR, 20)

	var outer := UIFactory.vbox(14)
	outer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(outer)

	outer.add_child(UIFactory.title(Loc.t("settings.title"), 34))

	_rows = UIFactory.vbox(16)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	# The reserve of 260 covers the title, the back button, the margins and the gaps,
	# so on a 568 pixel phone the panel asks for about 480 and fits instead of running
	# off the bottom of the screen.
	UIFactory.responsive_min_size(scroll, 620.0, 430.0, 260.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(_rows)
	outer.add_child(scroll)

	_build_audio()
	_build_display()
	_build_feedback()
	_build_progress()

	var back := UIFactory.button(Loc.t("common.back"), 22, 220.0)
	UIFactory.style_button(back, UIFactory.ACCENT, false)
	back.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_back")
		closed.emit())
	outer.add_child(_centre(back))


# -------------------------------------------------------------------- audio ---
func _build_audio() -> void:
	_rows.add_child(UIFactory.heading(Loc.t("settings.audio"), 22))
	_rows.add_child(_volume_row("settings.master", Settings.master_volume,
		func(v: float) -> void: Settings.set_master_volume(v)))
	_rows.add_child(_volume_row("settings.music", Settings.music_volume,
		func(v: float) -> void: Settings.set_music_volume(v)))
	_rows.add_child(_volume_row("settings.sfx", Settings.sfx_volume,
		func(v: float) -> void: Settings.set_sfx_volume(v)))


## A labelled setting. The label sits above its control rather than beside it, so a
## long Thai label and a slider can share a 320px phone screen without either being
## squeezed or clipped. The readout rides in the label row, which keeps the control
## itself on a full-width line of its own.
func _volume_row(label_key: String, value: float, setter: Callable) -> VBoxContainer:
	var col := UIFactory.vbox(4)
	var head := UIFactory.hbox(12)
	var name_label := UIFactory.label(Loc.t(label_key), 19, UIFactory.TEXT_DIM)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var readout := UIFactory.label("%d%%" % int(round(value * 100.0)), 18, UIFactory.TEXT_BRIGHT)
	readout.custom_minimum_size = Vector2(56, 0)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(readout)
	col.add_child(head)

	var slider := UIFactory.slider(0.0, 1.0, 0.05, value)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void:
		readout.text = "%d%%" % int(round(v * 100.0))
		setter.call(v))
	col.add_child(slider)
	return col


# ------------------------------------------------------------------ display ---
func _build_display() -> void:
	_rows.add_child(UIFactory.heading(Loc.t("settings.display"), 22))

	var langs := Loc.available_languages()
	var lang_labels: Array = []
	var lang_index := 0
	for i in langs.size():
		lang_labels.append(Loc.language_label(str(langs[i])))
		if str(langs[i]) == Settings.language:
			lang_index = i
	var lang_option := UIFactory.option(lang_labels, lang_index)
	lang_option.item_selected.connect(func(i: int) -> void:
		Settings.set_language(str(langs[i])))
	_rows.add_child(_labelled("settings.language", lang_option))

	var quality_labels: Array = []
	var quality_index := 0
	for i in Settings.QUALITY_LEVELS.size():
		var q := str(Settings.QUALITY_LEVELS[i])
		quality_labels.append({"low": "ต่ำ / Low", "medium": "กลาง / Medium", "high": "สูง / High"}.get(q, q))
		if q == Settings.quality:
			quality_index = i
	var quality_option := UIFactory.option(quality_labels, quality_index)
	quality_option.item_selected.connect(func(i: int) -> void:
		Settings.set_quality(str(Settings.QUALITY_LEVELS[i])))
	_rows.add_child(_labelled("settings.quality", quality_option))

	var res_labels: Array = []
	for r in Settings.RESOLUTIONS:
		res_labels.append("%d × %d" % [r.x, r.y])
	var res_option := UIFactory.option(res_labels, Settings.resolution_index)
	res_option.item_selected.connect(func(i: int) -> void:
		Settings.set_resolution_index(i))
	_rows.add_child(_labelled("settings.resolution", res_option))

	var fullscreen := UIFactory.check(Loc.t("settings.fullscreen"), Settings.fullscreen)
	fullscreen.toggled.connect(func(on: bool) -> void: Settings.set_fullscreen(on))
	_rows.add_child(fullscreen)


# ----------------------------------------------------------------- feedback ---
func _build_feedback() -> void:
	_rows.add_child(UIFactory.heading(Loc.t("settings.feedback"), 22))
	var shake := UIFactory.check(Loc.t("settings.shake"), Settings.shake_enabled)
	shake.toggled.connect(func(on: bool) -> void: Settings.set_shake_enabled(on))
	_rows.add_child(shake)

	var detail := UIFactory.check(Loc.t("settings.detail"), Settings.detail_default_open)
	detail.toggled.connect(func(on: bool) -> void: Settings.set_detail_default_open(on))
	_rows.add_child(detail)


# ----------------------------------------------------------------- progress ---
func _build_progress() -> void:
	_rows.add_child(UIFactory.heading(Loc.t("settings.progress"), 22))
	var summary := UIFactory.wrap(
		"%s: %d/9    %s: %d" % [
			Loc.t("hud.stars_earned"), SaveData.total_stars(),
			Loc.t("levels.title"), SaveData.levels_completed(),
		], 18, UIFactory.TEXT_DIM)
	_rows.add_child(summary)

	var reset := UIFactory.button(Loc.t("settings.reset_progress"), 20, 320.0)
	UIFactory.style_button(reset, UIFactory.BAD, false)
	reset.pressed.connect(_ask_reset)
	_rows.add_child(reset)

	_confirm = ConfirmationDialog.new()
	_confirm.dialog_text = Loc.t("settings.reset_confirm")
	_confirm.title = Loc.t("settings.reset_progress")
	_confirm.process_mode = Node.PROCESS_MODE_ALWAYS
	_confirm.confirmed.connect(_do_reset)
	add_child(_confirm)


func _ask_reset() -> void:
	AudioManager.play_ui("ui_click")
	_confirm.dialog_text = Loc.t("settings.reset_confirm")
	_confirm.popup_centered()


func _do_reset() -> void:
	SaveData.reset_progress()
	AudioManager.play_ui("ui_back")
	_rebuild()


# ------------------------------------------------------------------ helpers ---
## A labelled setting, label above control so nothing has to be squeezed.
func _labelled(label_key: String, control: Control) -> VBoxContainer:
	var col := UIFactory.vbox(4)
	col.add_child(UIFactory.label(Loc.t(label_key), 19, UIFactory.TEXT_DIM))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(control)
	return col


func _centre(control: Control) -> HBoxContainer:
	return UIFactory.centre_row(control)
