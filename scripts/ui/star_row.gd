class_name StarRow
## Draws a row of stars without relying on font glyphs.
##
## A font with no star character would render as empty boxes, so the stars are
## drawn as polygons. `set_stars()` can animate the newly-earned stars, which is
## what makes finishing a challenge feel rewarding.

extends Control

signal stars_changed(stars: int)

const FILL_COLOR := Color(1.0, 0.80, 0.26)
const EMPTY_COLOR := Color(1.0, 1.0, 1.0, 0.28)
const OUTLINE_COLOR := Color(0.15, 0.11, 0.03, 0.55)

var total: int = 3
var stars: int = 0:
	set(value):
		stars = clampi(value, 0, total)
		_appear = 0.0
		queue_redraw()
		stars_changed.emit(stars)

var star_size: float = 46.0
var gap: float = 10.0
## Seconds spent on the "pop" animation of freshly awarded stars.
var pop_duration: float = 0.35

var _appear: float = 1.0
var _animating := false


func _ready() -> void:
	_apply_min_size()


func configure(star_total: int, star_size_px: float = 46.0, gap_px: float = 10.0) -> void:
	total = maxi(1, star_total)
	star_size = star_size_px
	gap = gap_px
	stars = clampi(stars, 0, total)
	_apply_min_size()


## Awards stars. When `animate` is on, the stars that filled in scale up from
## nothing, which is the visual reward for finishing a level.
func set_stars(value: int, animate: bool = true) -> void:
	var target := clampi(value, 0, total)
	var gained := target > stars
	stars = target
	if animate and gained:
		_appear = 0.0
		_animating = true
		set_process(true)
	else:
		_appear = 1.0
		_animating = false
		set_process(false)
	queue_redraw()


func _apply_min_size() -> void:
	custom_minimum_size = Vector2(total * star_size + (total - 1) * gap, star_size)


func _process(delta: float) -> void:
	if not _animating:
		return
	_appear = minf(1.0, _appear + delta / maxf(0.01, pop_duration))
	if _appear >= 1.0:
		_animating = false
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var row_width := total * star_size + (total - 1) * gap
	var start_x := (size.x - row_width) * 0.5
	var centre_y := size.y * 0.5
	for i in total:
		var centre := Vector2(start_x + i * (star_size + gap) + star_size * 0.5, centre_y)
		var filled := i < stars
		var scale := 1.0
		if filled and _animating:
			scale = 0.4 + 0.6 * _ease_out(_appear)
		var radius := star_size * 0.5 * scale
		var points := _star_points(centre, radius, radius * 0.44)
		if filled:
			draw_colored_polygon(points, FILL_COLOR)
			draw_polyline(_closed(points), OUTLINE_COLOR, 2.0)
		else:
			draw_polyline(_closed(points), EMPTY_COLOR, 2.0)


func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


func _star_points(centre: Vector2, outer: float, inner: float, points: int = 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points * 2:
		var r := outer if i % 2 == 0 else inner
		var angle := -PI * 0.5 + float(i) * PI / float(points)
		out.append(centre + Vector2(cos(angle), sin(angle)) * r)
	return out


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	if out.size() > 0:
		out.append(out[0])
	return out
