class_name AmbientBackground
extends Control
## Warm light drifting behind a menu.
##
## The menus were a flat two-stop gradient, which is clean but dead: nothing in
## the frame moves until the player does. This layer adds three soft pools of
## light that crawl slowly across it, so the same background feels like a room
## with a fire in it. It draws nothing sharp and nothing that could be mistaken
## for an object to tap.
##
## It is a child of the menu's own background texture, so `MenuScreen` keeps it
## when a page rebuilds, and it ignores the mouse so it can never swallow a
## click meant for the page.

const BLOBS: Array = [
	# colour, start x, start y, radius (fraction of the short side), drift per second
	{"c": Color(1.0, 0.74, 0.36, 0.13), "x": 0.22, "y": 0.28, "r": 0.46, "vx": 0.011, "vy": 0.006},
	{"c": Color(1.0, 0.45, 0.30, 0.09), "x": 0.78, "y": 0.62, "r": 0.52, "vx": -0.009, "vy": 0.008},
	{"c": Color(0.55, 0.72, 1.0, 0.06), "x": 0.52, "y": 0.85, "r": 0.40, "vx": 0.007, "vy": -0.010},
	{"c": Color(1.0, 0.86, 0.55, 0.08), "x": 0.86, "y": 0.16, "r": 0.34, "vx": -0.012, "vy": 0.005},
]

var _tex: GradientTexture2D
var _time := 0.0
var _phase := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = _make_glow()
	# One shared starting point per screen: two menus opened in the same second
	# should not look like the same screenshot, but a page rebuild inside one
	# screen must not jump the lights either.
	_phase = float(get_instance_id() % 977) * 0.017
	set_process(true)


func _process(delta: float) -> void:
	# Frozen for the screenshot tools, for the same reason the interface's
	# entrance motion is: a capture has to be a settled frame, and a pool of light
	# that is always moving would make two captures of one screen differ.
	if not UIFactory.motion_enabled():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	var short := minf(size.x, size.y)
	if short <= 1.0:
		return
	for i in BLOBS.size():
		var b: Dictionary = BLOBS[i]
		var t := _time + _phase * (1.0 + float(i))
		# Ping-pong drift: the pool eases across its range and back instead of
		# wrapping at the edge, which would pop.
		var x := float(b["x"]) + sin(t * float(b["vx"]) * TAU) * 0.16
		var y := float(b["y"]) + cos(t * float(b["vy"]) * TAU) * 0.13
		var radius := float(b["r"]) * short * (1.0 + 0.06 * sin(t * 0.6 + float(i)))
		var rect := Rect2(Vector2(x * size.x, y * size.y) - Vector2(radius, radius),
			Vector2(radius, radius) * 2.0)
		draw_texture_rect(_tex, rect, false, b["c"])


## A white radial falloff: the tint comes from the draw call, so one texture
## serves every colour in the list.
func _make_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.set_offset(0, 0.0)
	gradient.set_offset(1, 1.0)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 128
	tex.height = 128
	return tex
