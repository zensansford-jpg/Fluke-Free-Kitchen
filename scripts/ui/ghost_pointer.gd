class_name GhostPointer
## A translucent hand that mimes an interaction before the player tries it.
##
## Used by the physical tasks (drag, swipe, hold) so that "every new action is
## demonstrated first" is visibly true rather than merely stated in a sentence.
## The ghost walks a list of normalised screen positions and fades out.

extends Control

const FILL := Color(1.0, 0.90, 0.55, 0.92)
const RING := Color(1.0, 1.0, 1.0, 0.75)

var _points: Array[Vector2] = []
var _index := 0
var _t := 0.0
var _hold := 0.0
var _ring_progress := -1.0
var _running := false
var _fade := 1.0

var point_radius := 17.0
## Seconds spent travelling between two points.
var travel_time := 0.55
## Seconds paused at each point (used to mime "press and hold").
var pause_time := 0.12


func _ready() -> void:
	UIFactory.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## `points` are normalised (0..1) screen positions. `show_ring` draws a filling
## ring at the last point, which is how the hold gesture is demonstrated.
func play(points: Array, show_ring: bool = false) -> void:
	_points.clear()
	for p in points:
		_points.append(p as Vector2)
	if _points.is_empty():
		return
	_index = 0
	_t = 0.0
	_hold = 0.0
	_fade = 1.0
	_ring_progress = 0.0 if show_ring else -1.0
	_running = true
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_running = false
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not _running:
		return
	_t += delta
	if _t >= travel_time:
		_t = 0.0
		_hold += delta
		if _hold >= pause_time:
			_hold = 0.0
			_index += 1
			if _index >= _points.size():
				# Loop once more, then bow out.
				if _ring_progress >= 0.0 and _ring_progress < 1.0:
					_ring_progress = 1.0
					queue_redraw()
					return
				_fade -= delta * 1.6
				if _fade <= 0.0:
					stop()
					queue_redraw()
					return
				_index = 0
	if _ring_progress >= 0.0 and _ring_progress < 1.0:
		_ring_progress = minf(1.0, _ring_progress + delta * 0.9)
	queue_redraw()


func _draw() -> void:
	if _points.is_empty():
		return
	var from := _points[maxi(0, _index - 1)] * size
	var to := _points[mini(_index, _points.size() - 1)] * size
	var eased := _ease_in_out(clampf(_t / travel_time, 0.0, 1.0))
	var pos := from.lerp(to, eased)
	var alpha := clampf(_fade, 0.0, 1.0)

	var dot := FILL
	dot.a *= alpha
	var ring := RING
	ring.a *= alpha

	draw_circle(pos, point_radius, dot)
	draw_arc(pos, point_radius + 3.0, 0.0, TAU, 32, ring, 2.0)

	if _ring_progress >= 0.0:
		var centre := _points[_points.size() - 1] * size
		draw_arc(centre, point_radius + 11.0, -PI * 0.5, -PI * 0.5 + TAU * _ring_progress, 40, ring, 4.0)


func _ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
