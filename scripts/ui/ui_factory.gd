class_name UIFactory
## Small helpers for building the game's UI entirely in code with the bundled
## Sarabun font. Every screen is assembled from these primitives so the look is
## consistent and no hand-authored `.tscn` control trees have to be maintained.

extends RefCounted

const TEXT_BRIGHT := Color(0.96, 0.97, 1.0)
const TEXT_DIM := Color(0.72, 0.78, 0.86)
const ACCENT := Color(1.0, 0.78, 0.32)
const GOOD := Color(0.45, 0.88, 0.60)
const BAD := Color(1.0, 0.47, 0.42)

const PANEL_COLOR := Color(0.05, 0.07, 0.11, 0.88)
const CARD_COLOR := Color(0.09, 0.12, 0.17, 0.94)

## The colour a panel is *pushed* away from the screen with: drop shadows are
## what stop the interface reading as flat stickers on glass.
const SHADOW := Color(0, 0, 0, 0.42)
const SHADOW_SOFT := Color(0, 0, 0, 0.30)


## Interface motion, on or off for the whole game.
##
## Screens fade their content in and every button answers the pointer with a
## small move. A screenshot tool captures three frames after a screen opens, so
## it would record a half-faded page; those tools switch this off and get the
## finished screen instead. Stored on `Engine` rather than as a static member
## because the factory is a plain static class.
const MOTION_KEY := &"ffk_ui_motion"


static func motion_enabled() -> bool:
	if not Engine.has_meta(MOTION_KEY):
		return true
	return bool(Engine.get_meta(MOTION_KEY))


static func set_motion_enabled(on: bool) -> void:
	Engine.set_meta(MOTION_KEY, on)

# ---------------------------------------------------------------- responsive ---
## Below this many pixels of width the interface swaps to its compact layout:
## one-column pages, smaller display type, tighter margins.
const COMPACT_WIDTH := 700.0
const MARGIN_NORMAL := 44
const MARGIN_COMPACT := 16


## The size of the game window in UI pixels.
##
## The project runs with `stretch/mode="disabled"`, so one UI unit is one screen
## pixel and this value changes with the window. That is what lets the layout
## reflow on a resize instead of being scaled down to a sliver on a phone, which
## is the whole point of the responsive layer below.
static func viewport_size() -> Vector2:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tree := loop as SceneTree
		if tree.root != null:
			return tree.root.get_visible_rect().size
	return Vector2(1280, 720)


static func is_compact() -> bool:
	return viewport_size().x < COMPACT_WIDTH


## Page margin that shrinks on a small screen.
static func ui_margin() -> int:
	return MARGIN_COMPACT if is_compact() else MARGIN_NORMAL


## Clamps a wanted width so it can never be wider than the window. Every fixed
## width in the game passes through here, which is why a 380px menu button is
## still 280px on a 320px phone instead of running off the edge.
static func fit_width(desired: float, margin: float = -1.0) -> float:
	if desired <= 0.0:
		return 0.0
	# The generous margin covers a panel's own content padding and a scrollbar, so
	# a fitted control also fits when it is nested inside a card.
	var m := margin if margin >= 0.0 else float(ui_margin()) + 24.0
	return maxf(96.0, minf(desired, viewport_size().x - m * 2.0))


## Scales a big display heading down on a narrow screen. Body text is left alone:
## 18-21px is already comfortable on a phone, only the 40-50px display type is
## wide enough to overflow.
static func heading_size(base: int) -> int:
	var scale := clampf(viewport_size().x / 780.0, 0.66, 1.0)
	return maxi(16, roundi(float(base) * scale))


## How many columns a card grid may use at the current width.
static func columns(wide: int, narrow: int = 1) -> int:
	return narrow if is_compact() else wide


## The width one child of a `columns()` grid may ask for: its natural width, but
## never more than its share of the page.
##
## A grid is only as narrow as its widest column, so two 380 pixel buttons ask for
## 774 pixels and a page that holds them needs 842 — which does not fit a 768 pixel
## tablet, however much room the page itself has. Capping the request at the column
## width makes the requested number of columns actually fit.
static func grid_width(natural: float, wide: int, narrow: int = 1, separation: int = 16) -> float:
	var cols := maxi(1, columns(wide, narrow))
	# The allowance covers the vertical scrollbar of the page the grid sits on: a
	# grid that fills the window exactly still has to leave the scrollbar its room.
	var page := maxf(200.0, viewport_size().x - float(ui_margin()) * 2.0 - 12.0)
	var each := (page - float(separation) * float(cols - 1)) / float(cols)
	return maxf(120.0, minf(natural, each))


## Records a minimum size for a child of a `columns()` grid. The column count is
## recorded too, so a live resize re-fits the control to its column instead of
## letting the grid push the page off the screen.
##
## `inset` is the room the control's own surroundings take out of its column: a
## button inside a card is narrower than the card by the card's padding, so its
## minimum has to be measured against the *inner* column width. Without it a 200
## pixel button inside a 210 pixel card column still asks for 240 pixels and pushes
## the three column grid past a 768 pixel tablet.
static func responsive_grid_size(control: Control, natural: float, wide: int,
		narrow: int = 1, height: float = 0.0, separation: int = 16, inset: float = 0.0) -> void:
	control.set_meta("resp_grid_w", natural)
	control.set_meta("resp_grid_cols", Vector2i(wide, narrow))
	control.set_meta("resp_grid_sep", separation)
	control.set_meta("resp_grid_inset", inset)
	control.set_meta("resp_min_h", height)
	apply_responsive_min_size(control)


## Records a wanted minimum size and applies it. The record is what lets
## `refresh_responsive()` re-fit the control when the window is resized.
##
## `reserve` is how much vertical room the screen around the control needs for itself
## (a title, a back button, margins). A modal that reserves too little asks for more
## height than a 568 pixel phone has and ends up taller than the screen.
static func responsive_min_size(control: Control, width: float, height: float = 0.0,
		reserve: float = 150.0) -> void:
	control.set_meta("resp_min_w", width)
	control.set_meta("resp_min_h", height)
	control.set_meta("resp_min_reserve", reserve)
	apply_responsive_min_size(control)


## A demanded height, capped so a control never asks for more room than the window has
## left after the screen around it has taken its share.
static func _fitted_height(height: float, reserve: float) -> float:
	if height <= 0.0:
		return 0.0
	return minf(height, maxf(120.0, viewport_size().y - reserve))


static func apply_responsive_min_size(control: Control) -> void:
	var reserve := float(control.get_meta("resp_min_reserve", 150.0))
	if control.has_meta("resp_grid_w"):
		var wide: int = (control.get_meta("resp_grid_cols") as Vector2i).x
		var narrow: int = (control.get_meta("resp_grid_cols") as Vector2i).y
		var separation: int = int(control.get_meta("resp_grid_sep"))
		var natural := float(control.get_meta("resp_grid_w"))
		var inset := float(control.get_meta("resp_grid_inset", 0.0))
		control.custom_minimum_size = Vector2(
			maxf(0.0, grid_width(natural, wide, narrow, separation) - inset),
			_fitted_height(float(control.get_meta("resp_min_h")), reserve))
		return
	if not control.has_meta("resp_min_w"):
		return
	var w := float(control.get_meta("resp_min_w"))
	control.custom_minimum_size = Vector2(
		fit_width(w), _fitted_height(float(control.get_meta("resp_min_h")), reserve))


static func responsive_margin(container: MarginContainer, margin: int) -> void:
	container.set_meta("resp_margin", margin)
	apply_responsive_margin(container)


static func apply_responsive_margin(container: MarginContainer) -> void:
	if not container.has_meta("resp_margin"):
		return
	var m := mini(int(container.get_meta("resp_margin")), ui_margin())
	container.add_theme_constant_override("margin_left", m)
	container.add_theme_constant_override("margin_right", m)
	container.add_theme_constant_override("margin_top", m)
	container.add_theme_constant_override("margin_bottom", m)


## Re-applies every recorded responsive size and margin in a subtree. Screens and
## the kitchen call this from their viewport-resize hook, which is what makes a
## live window resize safe: no scene is rebuilt, nothing is restarted.
static func refresh_responsive(root: Node) -> void:
	if root is Control:
		apply_responsive_min_size(root as Control)
	if root is MarginContainer:
		apply_responsive_margin(root as MarginContainer)
	for child in root.get_children():
		refresh_responsive(child)


## A full-rect, click-through layer that centres one child and keeps it inside the
## window at any size. Unlike `overlay_layer` it does not block input, so a task can
## show a hint over the kitchen without stealing the drag gesture underneath it.
##
## The margins update with `refresh_responsive()`, so the child stays framed after
## a resize without any extra code at the call site.
static func centre_layer(margin: int = -1) -> Control:
	var layer := Control.new()
	fill(layer)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var holder := MarginContainer.new()
	fill(holder)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	responsive_margin(holder, margin if margin >= 0 else MARGIN_NORMAL)
	layer.add_child(holder)
	var centre := CenterContainer.new()
	fill(centre)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(centre)
	layer.set_meta("centre", centre)
	layer.set_meta("holder", holder)
	return layer


## Clamps a half-width used with centred anchors (offset_left = -h, offset_right = h).
static func fit_half(half: float) -> float:
	return maxf(60.0, minf(half, (viewport_size().x - (float(ui_margin()) + 4.0) * 2.0) * 0.5))


## Centres a control with a size that never exceeds the window. Used for the
## fixed-size modals (pause, result) so they cannot spill off a phone screen.
static func centre_box(control: Control, width: float, height: float) -> void:
	var vp := viewport_size()
	var margin := float(ui_margin())
	var w := minf(width, maxf(140.0, vp.x - margin * 2.0))
	var h := minf(height, maxf(140.0, vp.y - margin * 2.0))
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = (vp.x - w) * 0.5
	control.offset_right = (vp.x + w) * 0.5
	control.offset_top = (vp.y - h) * 0.5
	control.offset_bottom = (vp.y + h) * 0.5


## Places a control as a bottom box: explicitly positioned in pixels, never wider
## or taller than the window, and never overlapping the very top of the screen.
##
## `centre_offset` shifts the box away from the middle (negative = to the left),
## which is how the cooking panels sit beside the wok on a wide screen and fall
## back to a centred, full-width box on a phone. `max_height` is the height the box
## may never exceed (the space left between the HUD and the bottom edge).
static func bottom_box(control: Control, width: float, height: float,
		centre_offset: float = 0.0, bottom_margin: float = -1.0, max_height: float = -1.0) -> void:
	var vp := viewport_size()
	var margin := float(ui_margin()) if bottom_margin < 0.0 else bottom_margin
	var w := minf(width, maxf(120.0, vp.x - margin * 2.0))
	var cap := vp.y * 0.55 if max_height < 0.0 else max_height
	var h := minf(height, maxf(140.0, cap))
	# A panel can never be shorter than its own content, so a box that asks for less
	# than the content needs would hang off the bottom edge. Growing the box to the
	# content height (never past the space between the top and bottom margins) keeps
	# the whole panel on screen instead.
	var min_h := control.get_combined_minimum_size().y
	if min_h > h:
		h = minf(min_h, maxf(140.0, vp.y - margin * 2.0))
	var cx := clampf(vp.x * 0.5 + centre_offset, margin + w * 0.5, maxf(margin + w * 0.5, vp.x - margin - w * 0.5))
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = cx - w * 0.5
	control.offset_right = cx + w * 0.5
	control.offset_bottom = vp.y - margin
	control.offset_top = control.offset_bottom - h


## Makes a control fill its parent exactly.
##
## This is deliberately explicit rather than `set_anchors_preset(...)`, because
## that helper also rewrites the offsets from the control's *minimum* size. On a
## plain `Control` the minimum size is 0x0, so calling it while the control is
## already inside the tree collapses it to nothing — which silently breaks every
## child that positions itself relative to the parent's size.
static func fill(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


static func font(bold: bool = false) -> Font:
	return PropFactory.font_bold() if bold else PropFactory.font_regular()


static func label(text: String, size: int = 20, color: Color = TEXT_BRIGHT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	var f := font(bold)
	if f != null:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_constant_override("line_spacing", 4)
	return l


static func title(text: String, size: int = 40) -> Label:
	var l := label(text, heading_size(size), TEXT_BRIGHT, true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# A wrapped label reports a one pixel minimum width, and that is the width a row
	# would hand it. Expanding makes it take the space it is given and centre its
	# text inside it, which is both what a title should look like and what stops a
	# long one from being drawn as a vertical column.
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(text: String, size: int = 22, min_width: float = 280.0) -> Button:
	var b := Button.new()
	b.text = text
	var f := font(true)
	if f != null:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_ALL
	# A button's minimum width comes from its text, and a Thai label with no spaces
	# in it is one long run: without wrapping, one long label would force every
	# container above it wider than the screen. `autowrap_mode` only exists on
	# Button in newer Godot builds, hence the guard.
	if "autowrap_mode" in b:
		b.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	# Fit the requested width to the window instead of setting it outright, so a
	# wide button reflows on a phone and is re-fitted if the window is resized.
	responsive_min_size(b, min_width, 54.0)
	# Every button answers the pointer the same way, wherever it is built.
	tap_motion(b)
	return b


static func slider(min_value: float, max_value: float, step: float, value: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_value
	s.max_value = max_value
	s.step = step
	s.value = value
	responsive_min_size(s, 240.0, 28.0)
	return s


static func check(text: String, pressed: bool) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = pressed
	if "autowrap_mode" in c:
		c.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	var f := font(false)
	if f != null:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", 20)
	return c


static func option(items: Array, selected: int) -> OptionButton:
	var o := OptionButton.new()
	for i in items.size():
		o.add_item(str(items[i]), i)
	o.selected = clampi(selected, 0, maxi(0, items.size() - 1))
	var f := font(false)
	if f != null:
		o.add_theme_font_override("font", f)
	o.add_theme_font_size_override("font_size", 20)
	responsive_min_size(o, 240.0, 44.0)
	return o


## A single-line text field, sized to reflow like every other control.
##
## Used only by the research instrument, for the anonymous case code a teacher
## hands out (see `docs/STUDY_PROTOCOL.md`). `LineEdit` does not grow to fit its
## text, so its own minimum width stays small and a long placeholder cannot force
## the page wider than a phone screen.
static func text_input(placeholder: String, value: String, max_length: int = 16) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = value
	e.max_length = max_length
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.caret_blink = true
	var f := font(false)
	if f != null:
		e.add_theme_font_override("font", f)
	e.add_theme_font_size_override("font_size", 20)
	responsive_min_size(e, 260.0, 46.0)
	return e


static func panel(color: Color = PANEL_COLOR) -> PanelContainer:
	var p := PanelContainer.new()
	style_panel(p, color)
	return p


static func style_panel(p: PanelContainer, color: Color = PANEL_COLOR, radius: int = 16) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.14)
	sb.set_content_margin_all(20)
	# Depth: the panel sits above the background instead of being printed on it.
	sb.shadow_size = 12
	sb.shadow_color = SHADOW
	sb.shadow_offset = Vector2(0, 7)
	p.add_theme_stylebox_override("panel", sb)


static func style_progress(pbar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(8)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(8)
	pbar.add_theme_stylebox_override("background", bg)
	pbar.add_theme_stylebox_override("fill", fg)


static func vbox(separation: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


## A row of tags that wraps onto a second line instead of pushing its card wider.
##
## An `HBoxContainer` never wraps, so a card holding three variable-length Thai
## capsules has a minimum width of all three laid end to end — which is what used
## to make a dish card 303 pixels wide inside a 311 pixel page and push the whole
## page off a 320 pixel phone. `FlowContainer` has no such floor: it reports the
## widest single tag and folds the rest onto following lines.
static func tag_row(separation: int = 6, alignment: int = FlowContainer.ALIGNMENT_CENTER) -> FlowContainer:
	var row := FlowContainer.new()
	row.alignment = alignment
	row.add_theme_constant_override("h_separation", separation)
	row.add_theme_constant_override("v_separation", separation)
	return row


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## A row whose single child is centred in the space available.
##
## Centring with the container's own alignment rather than with two expanding
## spacers matters on a narrow window: spacers add the row's separation on both
## sides to the minimum width, which was enough to push a small task sheet past the
## edge of a 320 pixel screen.
static func centre_row(control: Control) -> HBoxContainer:
	var row := hbox()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(control)
	return row


# --------------------------------------------------------------- extensions ---
## A label that wraps onto as many lines as it needs. Health and lesson text is
## never allowed to run off the edge of a panel.
static func wrap(text: String, size: int = 20, color: Color = TEXT_BRIGHT, bold: bool = false) -> Label:
	var l := label(text, size, color, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## Heading used at the top of a card or section.
static func heading(text: String, size: int = 26) -> Label:
	return label(text, size, ACCENT, true)


## A text block with a coloured vertical accent bar, used to frame a health tip
## without looking like an error message.
static func callout(text: String, accent: Color = ACCENT, size: int = 19) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.13, 0.92)
	sb.set_corner_radius_all(12)
	sb.border_width_left = 6
	sb.border_color = accent
	sb.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UIFactory.wrap(text, size))
	return p


## Gives a button a coloured, friendly style instead of the flat engine default.
##
## Depth and feedback are part of the style, not decoration applied later: a
## filled button sits on a small shadow, lifts when the pointer arrives, and
## carries a white ring when it has keyboard focus, so focus is never confused
## with hover.
static func style_button(b: Button, accent: Color = ACCENT, filled: bool = true) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(14)
	normal.set_content_margin_all(14)
	if filled:
		normal.bg_color = accent
		normal.border_color = accent.lightened(0.25)
	else:
		normal.bg_color = Color(1, 1, 1, 0.08)
		normal.border_color = Color(1, 1, 1, 0.2)
	normal.set_border_width_all(2)
	normal.shadow_size = 6
	normal.shadow_color = SHADOW
	normal.shadow_offset = Vector2(0, 4)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent.lightened(0.12) if filled else Color(1, 1, 1, 0.16)
	hover.shadow_size = 11
	hover.shadow_color = SHADOW

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = accent.darkened(0.18) if filled else Color(1, 1, 1, 0.24)
	pressed.shadow_size = 2
	pressed.shadow_color = SHADOW_SOFT
	pressed.shadow_offset = Vector2(0, 2)

	# Focus has to look different from hover: a reviewer navigating with the
	# keyboard must be able to tell which control will actually fire.
	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_color = Color(1, 1, 1, 0.95) if filled else accent
	focus.set_border_width_all(3)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.2, 0.22, 0.26, 0.6)
	disabled.border_color = Color(1, 1, 1, 0.08)
	disabled.shadow_size = 0

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", Color(0.08, 0.09, 0.12) if filled else TEXT_BRIGHT)
	b.add_theme_color_override("font_hover_color", Color(0.08, 0.09, 0.12) if filled else TEXT_BRIGHT)
	b.add_theme_color_override("font_pressed_color", Color(0.08, 0.09, 0.12) if filled else TEXT_BRIGHT)
	b.add_theme_color_override("font_focus_color", Color(0.08, 0.09, 0.12) if filled else TEXT_BRIGHT)
	b.add_theme_color_override("font_disabled_color", Color(0.7, 0.72, 0.75, 0.8))


## A button that stays legible over an unpredictable 3D scene: dark translucent
## background, coloured text and border.
##
## The translucent "ghost" style used elsewhere disappears against a bright wall,
## which is not acceptable for the HUD controls that must always be findable.
static func style_overlay_button(b: Button, accent: Color = ACCENT) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.11, 0.86)
	normal.set_corner_radius_all(14)
	normal.set_content_margin_all(14)
	normal.set_border_width_all(2)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.6)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.10, 0.13, 0.19, 0.94)
	hover.border_color = accent

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.03, 0.04, 0.07, 0.96)
	pressed.border_color = accent.darkened(0.2)

	# Over the 3D scene a keyboard-focused control needs a stronger outline than
	# hover, or the player cannot see where the next Enter will land.
	var focus := hover.duplicate() as StyleBoxFlat
	focus.set_border_width_all(3)
	focus.border_color = Color(1, 1, 1, 0.9)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.12, 0.13, 0.16, 0.7)
	disabled.border_color = Color(1, 1, 1, 0.12)

	# A shadow under the HUD controls lifts them off an unpredictable wall or
	# worktop behind them.
	for style: StyleBoxFlat in [normal, hover, pressed]:
		style.shadow_size = 8
		style.shadow_color = SHADOW
		style.shadow_offset = Vector2(0, 4)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent.lightened(0.25))
	b.add_theme_color_override("font_pressed_color", accent.darkened(0.15))
	b.add_theme_color_override("font_focus_color", accent.lightened(0.35))
	b.add_theme_color_override("font_disabled_color", Color(0.7, 0.72, 0.75, 0.7))


## A full-width dark card with a title and body.
static func card(title_text: String, body_text: String, accent: Color = ACCENT) -> PanelContainer:
	var p := panel(CARD_COLOR)
	var v := vbox(8)
	p.add_child(v)
	v.add_child(label(title_text, 22, accent, true))
	v.add_child(UIFactory.wrap(body_text, 18, TEXT_DIM))
	return p


# ------------------------------------------------------------- game feel ------
## An icon: a `UIIcon` glyph drawn in code, sized in pixels and centred in the
## space its container gives it. Decoration only — the label beside it is what
## carries the meaning.
static func icon(kind: String, px: float = 40.0, tint: Color = TEXT_BRIGHT) -> UIIcon:
	var glyph := UIIcon.new()
	glyph.kind = kind
	glyph.colour = tint
	glyph.custom_minimum_size = Vector2(px, px)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return glyph


## A row of icon + text: how a menu item announces what it opens.
static func icon_row(kind: String, text: String, tint: Color, size: int = 22) -> HBoxContainer:
	var row := hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(icon(kind, float(mini(size + 14, 40)), tint))
	row.add_child(label(text, size, TEXT_BRIGHT, true))
	return row


## A small capsule tag: a category, a filter, a status. Rounded enough to read
## as a label rather than as something with a click behind it.
static func chip(text: String, tint: Color = ACCENT, filled: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.18) if not filled else tint
	sb.set_corner_radius_all(15)
	sb.set_border_width_all(1)
	sb.border_color = Color(tint.r, tint.g, tint.b, 0.5)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 5.0
	sb.content_margin_bottom = 5.0
	p.add_theme_stylebox_override("panel", sb)
	var text_label := label(text, 15, TEXT_BRIGHT if not filled else Color(0.08, 0.09, 0.12), true)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(text_label)
	return p


## A title with a short accent bar under it: the one piece of ornament the
## menus get, so a heading reads as a masthead instead of a line of text.
static func hero(text: String, size: int = 50, tint: Color = ACCENT) -> Control:
	var v := vbox(6)
	var heading := title(text, size)
	heading.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	v.add_child(centre_row(heading))

	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = tint
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(3)
	bar.add_theme_stylebox_override("panel", sb)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(76, 2)
	bar.add_child(spacer)
	v.add_child(centre_row(bar))
	return v


## Pointer feedback shared by every interactive control: a small lift on
## hover and a press-down when pushed, about the control's own centre.
##
## The scale is a draw transform, so it never changes a control's rectangle —
## layout, container sorting and the tests that measure rects are unaffected.
static func tap_motion(c: Control) -> void:
	if c == null:
		return
	_keep_centred_pivot(c)
	if c is BaseButton:
		var b := c as BaseButton
		b.mouse_entered.connect(func() -> void: _pulse(b, 1.035, 0.10, Tween.TRANS_BACK))
		b.mouse_exited.connect(func() -> void: _pulse(b, 1.0, 0.14, Tween.TRANS_CUBIC))
		b.button_down.connect(func() -> void: _pulse(b, 0.965, 0.07, Tween.TRANS_QUAD))
		b.button_up.connect(func() -> void: _pulse(b, 1.035, 0.12, Tween.TRANS_BACK))
		return
	c.mouse_entered.connect(func() -> void: _pulse(c, 1.03, 0.12, Tween.TRANS_BACK))
	c.mouse_exited.connect(func() -> void: _pulse(c, 1.0, 0.16, Tween.TRANS_CUBIC))


static func _pulse(c: Control, factor: float, dur: float, trans: int) -> void:
	if not motion_enabled() or not is_instance_valid(c) or not c.is_inside_tree():
		return
	var previous: Variant = c.get_meta("ffk_pulse", null)
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	var t := Anim.begin(c)
	if t == null:
		return
	c.pivot_offset = c.size * 0.5
	c.set_meta("ffk_pulse", t)
	t.set_trans(trans).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2.ONE * factor, dur)


## Keeps a control's scale pivot on its own centre as it is laid out, so a
## pulse grows the control in place instead of from its top-left corner.
static func _keep_centred_pivot(c: Control) -> void:
	if c.has_meta("ffk_pivot"):
		return
	c.set_meta("ffk_pivot", true)
	c.resized.connect(func() -> void:
		if is_instance_valid(c):
			c.pivot_offset = c.size * 0.5)


## The way a screen introduces itself: content fades and eases into place with a
## short stagger, instead of the whole page snapping in behind the black wipe.
##
## `delay` is the wait before this particular block starts; pass an increasing
## value per sibling to cascade them. Nothing here changes layout — only
## opacity and scale — so measurement, focus and clicks are unaffected, and
## `set_motion_enabled(false)` (used by the screenshot tools) turns it off.
static func entrance(c: Control, delay: float = 0.0) -> void:
	if c == null or not motion_enabled():
		return
	if c.is_inside_tree():
		_start_entrance(c, delay)
	else:
		c.tree_entered.connect(func() -> void: _start_entrance(c, delay), CONNECT_ONE_SHOT)


static func _start_entrance(c: Control, delay: float) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or not motion_enabled():
		return
	_keep_centred_pivot(c)
	var t := Anim.begin(c)
	if t == null:
		return
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	c.scale = Vector2(0.96, 0.96)
	# The interval comes first, then both properties run in parallel: the block
	# arrives as one movement rather than a fade that pops afterwards.
	t.tween_interval(maxf(delay, 0.0))
	t.set_parallel(true)
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, 0.26)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2.ONE, 0.34)
	t.set_parallel(false)



# ---------------------------------------------------------------- background ---
## A full-rect warm gradient, used behind every menu so the game has a
## consistent cosy village-evening look without shipping any image files.
##
## The drifting light layer rides inside the gradient rather than beside it, so a
## page rebuild (`clear_page`) that replaces the menu's content never disturbs the
## background, and every screen that shows the gradient also gets the movement.
static func warm_background() -> TextureRect:
	var rect := warm_gradient(Color(0.14, 0.10, 0.07), Color(0.30, 0.17, 0.10))
	rect.add_child(AmbientBackground.new())
	return rect


static func warm_gradient(top: Color, bottom: Color) -> TextureRect:
	var rect := TextureRect.new()
	fill(rect)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	rect.texture = tex
	return rect


## Dark, click-blocking backdrop used behind modal panels.
static func backdrop() -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0.55)
	fill(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	return rect


## A full-screen click-blocking layer holding a centred child. The centre is
## stored in metadata so callers can add content without another lookup.
##
## With `dim` the layer also carries a dark backdrop behind its content, which is
## what makes a modal read as a modal instead of as a panel floating over a live
## scene. The backdrop is exposed as metadata so a caller can also listen to it.
static func overlay_layer(dim: bool = false) -> Control:
	var layer := Control.new()
	fill(layer)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	if dim:
		var backdrop := backdrop()
		layer.add_child(backdrop)
		layer.set_meta("backdrop", backdrop)
	var centre := CenterContainer.new()
	fill(centre)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(centre)
	layer.set_meta("centre", centre)
	return layer
