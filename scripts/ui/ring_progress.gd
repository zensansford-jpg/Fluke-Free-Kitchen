class_name RingProgress
extends Control
## A small circular progress ring, used for "press and hold" interactions.
##
## Drawn rather than assembled from nodes so it stays crisp at any size and costs
## nothing when idle. It is deliberately decorative: it shows effort, but the task
## that owns it decides when the effort is enough.

var value := 0.0:
	set(new_value):
		value = clampf(new_value, 0.0, 1.0)
		queue_redraw()

var colour := Color(0.45, 0.88, 0.60)
var track := Color(0.0, 0.0, 0.0, 0.42)
var thickness := 11.0
var cap_segments := 48


func _ready() -> void:
	custom_minimum_size = Vector2(118, 118)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - thickness
	if radius <= 0.0:
		return
	draw_arc(centre, radius, 0.0, TAU, cap_segments, track, thickness, true)
	if value <= 0.0:
		return
	draw_arc(centre, radius, -PI * 0.5, -PI * 0.5 + TAU * value, cap_segments, colour, thickness, true)
	draw_arc(centre, radius, -PI * 0.5, -PI * 0.5 + TAU * value, cap_segments, colour.lightened(0.35), thickness * 0.35, true)
