class_name DishPreview
extends Control
## The little picture on a dish card: a plate with the recipe's fish on it.
##
## It is drawn from the same catalogue the kitchen uses (`RecipeDB`), so the
## silhouette, proportion and tint really do come from the fish the recipe names.
## A slender snakehead and a deep-bodied silver barb look different because they
## are different — a recolour is never used to pretend a fish is a new species.
##
## Locked dishes are drawn dimmed with a padlock, so the content can be seen and
## recognised before it is unlocked.

const PLATE := Color(0.87, 0.85, 0.79)
const PLATE_RIM := Color(0.72, 0.70, 0.65)
const LOCK_COLOR := Color(0.10, 0.12, 0.16, 0.72)
## The ring inside the rim, the way a real serving plate steps down to its well.
const PLATE_WELL := Color(0.79, 0.77, 0.71)

var _recipe: Dictionary = {}
var _unlocked := true


func configure(recipe: Dictionary, unlocked: bool) -> void:
	_recipe = recipe
	_unlocked = unlocked
	queue_redraw()


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return

	var cx := size.x * 0.5
	var cy := size.y * 0.60
	var rx := minf(size.x * 0.42, 170.0)
	var ry := size.y * 0.19
	if ry < 8.0:
		ry = 8.0

	# The plate sits on the card instead of being printed on it: a soft shadow
	# underneath, a drop under the near rim, then the rim and its well.
	var shadow := _ellipse(cx, cy + maxf(3.0, ry * 0.22), rx * 1.02, ry * 1.02)
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.30))
	var body := _ellipse(cx, cy, rx, ry)
	draw_colored_polygon(body, PLATE.darkened(0.10))
	draw_colored_polygon(_ellipse(cx, cy - maxf(1.0, ry * 0.04), rx * 0.99, ry * 0.95), PLATE)
	draw_arc(Vector2(cx, cy), maxf(rx, ry), 0.0, TAU, 48, PLATE_RIM, 2.0)
	draw_arc(Vector2(cx, cy - ry * 0.04), maxf(rx * 0.82, ry * 0.82), 0.0, TAU, 48,
		PLATE_WELL, 1.5)

	var spec := RecipeDB.fish_by_id(_first_fish())
	var tint: Color = spec.get("tint", Color(0.62, 0.66, 0.60))
	if not _unlocked:
		tint = tint.darkened(0.5).lerp(Color(0.2, 0.22, 0.26), 0.45)
	var body_kind := str(spec.get("body", "round"))

	var length := rx * 0.78
	var height := ry * 0.86
	match body_kind:
		"slender":
			length *= 1.12
			height *= 0.66
		"flat":
			length *= 0.9
			height *= 1.35
		"catfish":
			length *= 1.05
			height *= 0.9
		_:
			pass

	var mid := Vector2(cx - length * 0.05, cy - ry * 0.16)
	# A contact shadow under the food, so it rests in the plate's well.
	if _unlocked:
		draw_colored_polygon(_ellipse(mid.x, mid.y + height * 0.85, length * 0.98, height * 0.34),
			Color(0.0, 0.0, 0.0, 0.22))
	draw_colored_polygon(_ellipse(mid.x, mid.y, length, height), tint)
	# A single soft highlight along the back, which reads as a wet, cooked surface.
	draw_colored_polygon(_ellipse(mid.x - length * 0.10, mid.y - height * 0.42,
		length * 0.62, height * 0.22), tint.lightened(0.28))
	# Tail fin.
	draw_colored_polygon(PackedVector2Array([
		Vector2(mid.x + length * 0.92, mid.y),
		Vector2(mid.x + length * 1.36, mid.y - height * 1.25),
		Vector2(mid.x + length * 1.36, mid.y + height * 1.25),
	]), tint.darkened(0.18))
	# Eye.
	var eye_radius := maxf(1.6, height * 0.14)
	draw_circle(Vector2(mid.x - length * 0.66, mid.y - height * 0.24), eye_radius, Color(0.10, 0.10, 0.13))

	# A couple of garnish slivers, in the colours of the recipe's own garnish.
	var garnish: Array = _recipe.get("garnish", [])
	for i in garnish.size():
		var spec_g := RecipeDB.garnish_by_id(str(garnish[i]))
		if spec_g.is_empty():
			continue
		var colour: Color = spec_g.get("colour", Color(0.5, 0.7, 0.4))
		if not _unlocked:
			colour = colour.darkened(0.5)
		var gx := cx + rx * (0.42 - 0.20 * float(i))
		var gy := cy - ry * 0.55 - ry * 0.35 * float(i)
		draw_colored_polygon(PackedVector2Array([
			Vector2(gx - 5.0, gy + 3.0), Vector2(gx, gy - 6.0), Vector2(gx + 5.0, gy + 3.0),
		]), colour)

	if not _unlocked:
		_draw_lock(Vector2(cx, cy - ry * 0.1))


func _draw_lock(centre: Vector2) -> void:
	var body := Rect2(centre - Vector2(13.0, 2.0), Vector2(26.0, 20.0))
	draw_rect(body, LOCK_COLOR)
	draw_arc(centre - Vector2(0.0, 2.0), 8.0, PI, TAU, 20, LOCK_COLOR, 3.0)


func _first_fish() -> String:
	var list: Array = _recipe.get("fish", [])
	if list.is_empty():
		return "pla_nil"
	return str(list[0])


## An ellipse as a polygon, because `draw_circle` only draws a circle.
static func _ellipse(cx: float, cy: float, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 28
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cx + cos(angle) * rx, cy + sin(angle) * ry))
	return points
