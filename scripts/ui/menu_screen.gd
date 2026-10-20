class_name MenuScreen
## Shared behaviour for every non-gameplay screen (menu, challenges, journal,
## knowledge check).
##
## Provides the warm background, the modal-overlay machinery, and the few widget
## helpers that every screen was otherwise going to duplicate. Subclasses call
## `super()` in `_ready()` and then build their content.

extends Control

var overlay: Control
var overlay_centre: CenterContainer
var background: TextureRect

var _resize_pending := false
var _resizing := false


func _ready() -> void:
	background = UIFactory.warm_background()
	add_child(background)
	_build_overlay()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


## Frees everything the page built but keeps the two controls every screen shares,
## the warm background and the modal overlay. Rebuilding a page on a resize must
## not lose either of them.
func clear_page() -> void:
	for child in get_children():
		if child == overlay or child == background:
			continue
		child.queue_free()


# ------------------------------------------------------------------ resizing ---
## Reflowing on a live window resize is mandatory, but a window drag fires this
## many times a second, so the work is deferred and coalesced. Nothing is
## restarted: a menu has no gameplay state to lose.
func _on_viewport_size_changed() -> void:
	if not is_node_ready() or _resize_pending:
		return
	_resize_pending = true
	_reflow_soon()


func _reflow_soon() -> void:
	await get_tree().create_timer(0.18, true).timeout
	_resize_pending = false
	if not is_inside_tree() or _resizing:
		return
	_resizing = true
	UIFactory.refresh_responsive(self)
	rebuild_for_size()
	# `clear_page()` frees the page children but leaves the overlay where it was, and
	# the rebuilt page is added after it. If a modal is open while the window is
	# resized, it has to come back to the front.
	if overlay != null and overlay.visible:
		overlay.move_to_front()
	_resizing = false


## Subclasses override this when the layout has to change shape (column counts,
## stacked cards) rather than just resize. The default only re-fits widths.
func rebuild_for_size() -> void:
	pass


# ------------------------------------------------------------------ overlay ---
func _build_overlay() -> void:
	overlay = UIFactory.overlay_layer(true)
	overlay_centre = overlay.get_meta("centre") as CenterContainer

	# Tapping the dark area closes the overlay, the same way the close button does.
	var backdrop := overlay.get_meta("backdrop") as ColorRect
	backdrop.gui_input.connect(_on_backdrop_input)

	overlay.visible = false
	add_child(overlay)


func show_overlay(content: Control) -> void:
	for child in overlay_centre.get_children():
		child.queue_free()
	overlay_centre.add_child(content)
	overlay.visible = true
	# A subclass builds its page *after* `super()` has added the overlay, so the page
	# is a later sibling and would be drawn over the modal. Raising the overlay here
	# is what keeps the settings and "how to play" panels on top of the buttons.
	overlay.move_to_front()


func hide_overlay() -> void:
	if not overlay.visible:
		return
	overlay.visible = false
	for child in overlay_centre.get_children():
		child.queue_free()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		AudioManager.play_ui("ui_back")
		hide_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if overlay != null and overlay.visible and event.is_action_pressed("pause"):
		AudioManager.play_ui("ui_back")
		hide_overlay()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ widgets ---
func make_button(text: String, primary: bool, action: Callable, width: float = 380.0) -> Button:
	var b := UIFactory.button(text, 22, width)
	UIFactory.style_button(b, UIFactory.ACCENT if primary else UIFactory.TEXT_BRIGHT, primary)
	b.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		action.call())
	return b


func back_button(action: Callable) -> Button:
	return make_button(Loc.t("common.back"), false, action, 220.0)


func close_button() -> Button:
	var b := UIFactory.button(Loc.t("common.close"), 20, 220.0)
	UIFactory.style_button(b, UIFactory.ACCENT, false)
	b.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_back")
		hide_overlay())
	return b


func content_margin(margin: int = 44) -> MarginContainer:
	var m := MarginContainer.new()
	UIFactory.fill(m)
	UIFactory.responsive_margin(m, margin)
	return m


## A full-page content column that can never be cut off. When the content is
## taller than the window the page scrolls, so no button or line of text is ever
## pushed off the bottom edge. The scrollbar only appears when it is needed, so a
## short page still looks like a plain page.
##
## This matters more than it sounds: the game ships in Thai and English, and the
## two languages do not wrap to the same number of lines.
func scroll_page(margin: int = 38, separation: int = 14) -> VBoxContainer:
	var outer := content_margin(margin)
	add_child(outer)

	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)

	var column := UIFactory.vbox(separation)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column


## Centres a control in the page.
##
## Centring is done with the container's own alignment rather than with two spacer
## Controls. Spacers share the leftover width with any child that expands, and a
## wrapped label expands — so with spacers a long Thai paragraph was given a third
## of the row and drawn as a tall, narrow column of characters. With alignment the
## wrapping label is the only expanding child and takes the full row, while a
## button or a grid keeps its natural width and is centred as before.
func centred(control: Control) -> HBoxContainer:
	var row := UIFactory.hbox()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(control)
	return row


func gap(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


func title_block(title_key: String, subtitle_key: String) -> VBoxContainer:
	var v := UIFactory.vbox(6)
	var heading := UIFactory.hero(Loc.t(title_key), 46)
	v.add_child(centred(heading))
	if not subtitle_key.is_empty():
		var sub := UIFactory.wrap(Loc.t(subtitle_key), 19, UIFactory.TEXT_DIM)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(centred(sub))
	return v
