class_name UIIcon
extends Control
## Vector icons, drawn in code.
##
## The game ships no icon font and no sprite sheet, and a menu made only of
## word buttons reads like a settings form rather than a kitchen. Each icon is
## a handful of polygons inside a 100x100 design space, so the whole set shares
## one line weight, scales to any size and costs nothing to load.
##
## Icons are decoration. The label next to a icon carries the meaning, so
## nothing here is depended on by a test or by a health message: an icon that
## fails to draw must never be able to hide the word beside it.

## Line weight, in design units (the icon is drawn in a 100x100 box).
const WEIGHT := 8.0

var kind := "star"
var colour := UIFactory.ACCENT

var _s := 1.0
var _o := Vector2.ZERO


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	_s = minf(size.x, size.y) / 100.0
	if _s <= 0.0:
		return
	_o = (size - Vector2(100.0, 100.0) * _s) * 0.5
	var c := colour
	match kind:
		"play":
			_poly([Vector2(32, 22), Vector2(84, 50), Vector2(32, 78)], c)
		"pause":
			_rect(34, 24, 12, 52, c)
			_rect(56, 24, 12, 52, c)
		"book":
			_box(14, 24, 72, 56, 7)
			_line(50, 24, 50, 80, 7)
			_line(24, 42, 42, 42, 5)
			_line(24, 56, 42, 56, 5)
			_line(58, 42, 76, 42, 5)
			_line(58, 56, 76, 56, 5)
		"clipboard":
			_box(22, 22, 56, 66, 7)
			_rect(38, 13, 24, 15, c)
			_line(34, 48, 66, 48, 6)
			_line(34, 62, 66, 62, 6)
			_line(34, 74, 56, 74, 6)
		"globe":
			_ring(50, 50, 36, 6)
			_line(14, 50, 86, 50, 5)
			_line(50, 14, 50, 86, 5)
			_line(23, 33, 77, 33, 4)
			_line(23, 67, 77, 67, 4)
		"compass":
			_ring(50, 50, 36, 6)
			_poly([Vector2(50, 24), Vector2(60, 50), Vector2(50, 50)], c.lightened(0.35))
			_poly([Vector2(60, 50), Vector2(50, 76), Vector2(40, 50), Vector2(50, 50)], c)
		"chef":
			_circle(34, 46, 17, c)
			_circle(50, 37, 19, c)
			_circle(66, 46, 17, c)
			_rect(26, 63, 48, 20, c)
		"sparkle":
			_poly(_star_points(50, 50, 44, 15, 4, -PI * 0.5), c)
		"gear":
			_ring(50, 50, 24, 9)
			for i in 8:
				var a := TAU * float(i) / 8.0
				_line(50 + cos(a) * 33, 50 + sin(a) * 33,
					50 + cos(a) * 45, 50 + sin(a) * 45, 9)
			_circle(50, 50, 7, c)
		"info":
			_ring(50, 50, 34, 6)
			_circle(50, 27, 6, c)
			_line(50, 43, 50, 74, 7)
		"question":
			_arc(50, 44, 18, PI, TAU, 7)
			_line(50, 44, 50, 64, 7)
			_circle(50, 79, 6, c)
		"check":
			_line(24, 52, 43, 71, 9, true)
			_line(43, 71, 79, 29, 9, true)
		"cross":
			_line(30, 30, 70, 70, 9, true)
			_line(70, 30, 30, 70, 9, true)
		"star":
			_poly(_star_points(50, 52, 40, 17, 5, -PI * 0.5), c)
		"flame":
			_poly([
				Vector2(50, 6), Vector2(63, 27), Vector2(71, 44), Vector2(74, 61),
				Vector2(64, 78), Vector2(50, 91), Vector2(35, 78), Vector2(26, 60),
				Vector2(31, 43), Vector2(41, 33), Vector2(43, 50), Vector2(50, 30),
			], c)
			_circle(50, 67, 11, c.lightened(0.35))
		"fish":
			_poly([
				Vector2(10, 50), Vector2(34, 28), Vector2(60, 30), Vector2(76, 44),
				Vector2(76, 56), Vector2(60, 70), Vector2(34, 72),
			], c)
			_poly([Vector2(74, 41), Vector2(95, 26), Vector2(95, 74), Vector2(74, 59)], c)
			_circle(27, 44, 5, Color(0.06, 0.07, 0.10))
		"knife":
			_poly([Vector2(28, 68), Vector2(70, 22), Vector2(79, 33), Vector2(38, 77)], c)
			_line(12, 86, 30, 67, 13, true)
		"pot":
			_box(18, 46, 64, 36, 7, true)
			_line(12, 42, 88, 42, 7, true)
			_circle(50, 34, 6, c)
			_arc(18, 62, 11, PI * 0.5, PI * 1.5, 6)
			_arc(82, 62, 11, -PI * 0.5, PI * 0.5, 6)
			_arc(36, 24, 9, PI, TAU, 5)
			_arc(63, 21, 9, PI, TAU, 5)
		"drop":
			_poly([
				Vector2(50, 7), Vector2(66, 36), Vector2(73, 55), Vector2(66, 73),
				Vector2(50, 90), Vector2(34, 73), Vector2(27, 55), Vector2(34, 36),
			], c)
			_circle(41, 56, 8, c.lightened(0.35))
		"search":
			_ring(44, 44, 25, 8)
			_line(63, 63, 87, 87, 10, true)
		"dice":
			_box(20, 20, 60, 60, 7, true)
			_circle(35, 35, 6, c)
			_circle(65, 35, 6, c)
			_circle(50, 50, 6, c)
			_circle(35, 65, 6, c)
			_circle(65, 65, 6, c)
		"heart":
			_circle(36, 40, 18, c)
			_circle(64, 40, 18, c)
			_poly([Vector2(17, 44), Vector2(83, 44), Vector2(50, 85)], c)
		"bulb":
			_circle(50, 41, 24, c)
			_rect(40, 63, 20, 11, c)
			_rect(42, 77, 16, 9, c)
		"endless":
			_ring(31, 50, 19, 8)
			_ring(69, 50, 19, 8)
		"arrow_back":
			_line(72, 50, 24, 50, 9, true)
			_line(44, 30, 24, 50, 9, true)
			_line(44, 70, 24, 50, 9, true)
		"exit":
			_box(42, 20, 44, 60, 7)
			_line(64, 50, 14, 50, 8, true)
			_line(32, 32, 14, 50, 8, true)
			_line(32, 68, 14, 50, 8, true)
		"grid":
			_rect(24, 24, 24, 24, c)
			_rect(52, 24, 24, 24, c)
			_rect(24, 52, 24, 24, c)
			_rect(52, 52, 24, 24, c)
		"lock":
			_box(26, 48, 48, 36, 7, true)
			_arc(50, 48, 16, PI, TAU, 7)
		"leaf":
			_poly([
				Vector2(20, 80), Vector2(30, 44), Vector2(52, 24), Vector2(76, 20),
				Vector2(78, 44), Vector2(64, 70), Vector2(38, 82),
			], c)
			_line(26, 78, 74, 27, 5, true)
		"hand":
			# A palm with the index finger leading: the drag.
			_circle(46, 58, 25, c)
			_poly([Vector2(36, 38), Vector2(45, 9), Vector2(55, 11), Vector2(52, 40)], c)
			_ring(14, 58, 9, 6)
			_ring(86, 58, 9, 6)
		"stir":
			# A bowl seen from above with the spoon circling it.
			_ring(50, 56, 36, 7)
			_arc(50, 56, 21, PI * 0.15, PI * 1.15, 7)
			_poly(_star_points(50, 56, 9, 4, 4, 0.0), c.lightened(0.3))
		"hold":
			# A press with a second ring closing in on it.
			_circle(50, 50, 12, c)
			_ring(50, 50, 30, 8)
		"flip":
			# An arc with an arrowhead: the toss.
			_arc(50, 62, 34, PI, TAU, 8)
			_poly([Vector2(16, 62), Vector2(6, 46), Vector2(26, 46)], c)
		"tap":
			# A fingertip with two contact marks.
			_circle(54, 66, 10, c)
			_ring(54, 46, 12, 7)
			_ring(54, 46, 22, 5)
		_:
			if kind.is_empty():
				return
			_poly(_star_points(50, 50, 34, 15, 5, -PI * 0.5), c)


# ------------------------------------------------------------------ drawing ---
func _pt(x: float, y: float) -> Vector2:
	return _o + Vector2(x, y) * _s


func _px(value: float) -> float:
	return value * _s


func _poly(points: Array, c: Color) -> void:
	var packed := PackedVector2Array()
	for p in points:
		packed.append(_pt(p.x, p.y))
	draw_colored_polygon(packed, c)


func _line(x1: float, y1: float, x2: float, y2: float, width: float, aa: bool = false) -> void:
	draw_line(_pt(x1, y1), _pt(x2, y2), c_of(), _px(width), aa)


func _ring(x: float, y: float, radius: float, width: float) -> void:
	draw_arc(_pt(x, y), _px(radius), 0.0, TAU, 40, c_of(), _px(width), true)


func _arc(x: float, y: float, radius: float, from: float, to: float, width: float) -> void:
	draw_arc(_pt(x, y), _px(radius), from, to, 24, c_of(), _px(width), true)


func _circle(x: float, y: float, radius: float, c: Color) -> void:
	draw_circle(_pt(x, y), _px(radius), c, true)


func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(_pt(x, y), Vector2(_px(w), _px(h))), c, true)


func _box(x: float, y: float, w: float, h: float, width: float, aa: bool = false) -> void:
	var col := c_of()
	var lw := _px(width)
	var tl := _pt(x, y)
	var tr := _pt(x + w, y)
	var br := _pt(x + w, y + h)
	var bl := _pt(x, y + h)
	draw_line(tl, tr, col, lw, aa)
	draw_line(tr, br, col, lw, aa)
	draw_line(br, bl, col, lw, aa)
	draw_line(bl, tl, col, lw, aa)


func c_of() -> Color:
	return colour


## A star with `points` tips, alternating between the outer and inner radius.
func _star_points(cx: float, cy: float, outer: float, inner: float, points: int,
		rotation: float) -> Array:
	var out: Array = []
	for i in points * 2:
		var radius := outer if i % 2 == 0 else inner
		var a := rotation + TAU * float(i) / float(points * 2)
		out.append(Vector2(cx + cos(a) * radius, cy + sin(a) * radius))
	return out
