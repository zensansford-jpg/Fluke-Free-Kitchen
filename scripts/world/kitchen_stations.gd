class_name KitchenStations
## Where everything on the worktop lives.
##
## The kitchen is arranged around one workflow, left to right, the way a cook
## actually stands at a bench: prep and washing on the left, the cooking fire in
## the middle, resting and plating on the right. Every prop and every task anchor
## is looked up here rather than written as a loose coordinate at the call site, so
##
##   * two props can never be given the same patch of worktop by accident,
##   * moving a station moves everything that belongs to it, and
##   * the 3D probe (`tests/kitchen_probe.gd`) can check the real arrangement
##     against the same table the kitchen was built from.
##
## Coordinates are world-space metres on the bench plane (`KitchenProps.BENCH_Y`).
## `z` runs from the back of the bench (`-`) to the front edge (`+`), because the
## camera looks along `-Z`. `radius` is how much worktop the station claims; the
## probe uses it to decide whether two props are fighting over the same spot.
##
## This file is pure data and pure logic — it never touches the scene tree, so it
## can be validated without opening a window.

extends RefCounted

## How far apart two stations must be before they count as separate. A little
## under half of the narrowest station, so neighbouring stations may touch but not
## share worktop.
const SEPARATION := 0.05


## Stations that are allowed to be close enough to touch. The village model is an
## *illustration* of a village rather than a piece of cooking equipment, so it is
## placed on the far left and may lean into the washing area without either of them
## being wrong.
const INDEPENDENT := ["village"]


## Checks the table against itself: every station has the fields the kitchen reads,
## its footprint fits on the bench, and no two *cooking* stations overlap.
##
## Returns one plain-language line per problem, so the message can be printed by a
## test or shown in a debug dump without translation.
static func validate(bench_half_width: float = 3.0) -> Array:
	var problems: Array = []
	var stations := table()
	for station_id in ids():
		if not stations.has(station_id):
			problems.append("%s: missing from the table" % station_id)
			continue
		var spec: Dictionary = stations[station_id]
		for field in ["x", "z", "radius", "en", "th"]:
			if not spec.has(field):
				problems.append("%s: no '%s'" % [station_id, field])
		var radius := float(spec.get("radius", 0.0))
		if radius <= 0.0:
			problems.append("%s: radius must be positive" % station_id)
		# A station whose worktop hangs off the end of the bench cannot be used.
		var x := float(spec.get("x", 0.0))
		if absf(x) - radius < -bench_half_width:
			problems.append("%s: its worktop runs off the end of the bench" % station_id)

	for i in ids().size():
		for j in range(i + 1, ids().size()):
			var a: String = ids()[i]
			var b: String = ids()[j]
			if a in INDEPENDENT or b in INDEPENDENT:
				continue
			var overlap := footprint(a).intersection(footprint(b))
			if overlap.size.x > SEPARATION and overlap.size.y > SEPARATION:
				problems.append("%s and %s claim the same worktop (%.0f x %.0f mm)"
					% [a, b, overlap.size.x * 1000.0, overlap.size.y * 1000.0])
	return problems


## The station table. `x` is the centre, `z` the depth, `radius` the footprint.
##
## The x order is the workflow order, and it is the whole point of the layout:
##
##   wash   -2.60  sink and the water jar      (before you touch food)
##   prep   -0.90  board, knife, raw tray      (where the fish is opened up)
##   heat    1.55  stove and pan               (the only place food is cooked)
##   rest    2.95  plate, tray, cloth          (off the heat, and wiped down)
##
## The cook stands behind `prep`, looking along the bench, so the step the player
## is doing is always in the middle of the frame.
static func table() -> Dictionary:
	return {
		"wash": {
			"x": -2.20, "z": 0.00, "radius": 0.62,
			"th": "ล้าง", "en": "Wash",
		},
		"prep": {
			"x": -0.75, "z": 0.40, "radius": 0.58,
			"th": "เตรียม", "en": "Prep",
		},
		"heat": {
			"x": 1.55, "z": 0.30, "radius": 0.55,
			"th": "ตั้งไฟ", "en": "Heat",
		},
		"rest": {
			"x": 3.00, "z": 0.45, "radius": 0.62,
			"th": "พักและจัดจาน", "en": "Rest and plate",
		},
		"village": {
			"x": -3.60, "z": 0.00, "radius": 0.70,
			"th": "หมู่บ้าน", "en": "Village corner",
		},
	}


static func ids() -> Array:
	return ["wash", "prep", "heat", "rest", "village"]


static func has(station_id: String) -> bool:
	return table().has(station_id)


## The centre of a station, on the bench surface.
static func at(station_id: String, y: float = KitchenProps.BENCH_Y) -> Vector3:
	var spec: Dictionary = table().get(station_id, {})
	if spec.is_empty():
		return Vector3(0.0, y, 0.0)
	return Vector3(float(spec["x"]), y, float(spec["z"]))


## A point on a station, offset from its centre in the bench plane. Used to place
## the several props that share a station (the sink and the jar in `wash`, the
## board and the knife in `prep`) without anyone writing a raw coordinate twice.
static func spot(station_id: String, dx: float, dz: float, y: float = KitchenProps.BENCH_Y) -> Vector3:
	var centre := at(station_id, y)
	return centre + Vector3(dx, 0.0, dz)


## The worktop a station claims, as a Rect2 in world x/z.
static func footprint(station_id: String) -> Rect2:
	var spec: Dictionary = table().get(station_id, {})
	if spec.is_empty():
		return Rect2()
	var radius := float(spec["radius"])
	var centre := Vector2(float(spec["x"]), float(spec["z"]))
	return Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0)


## Which station a world position belongs to. Nearest centre wins, so a prop is
## always attributed to exactly one station and the probe can group props without
## the kitchen having to tag them.
static func station_of(world: Vector3) -> String:
	var best := ""
	var best_distance := INF
	for station_id in ids():
		var spec: Dictionary = table()[station_id]
		var centre := Vector2(float(spec["x"]), float(spec["z"]))
		var distance := centre.distance_to(Vector2(world.x, world.z))
		if distance < best_distance:
			best_distance = distance
			best = station_id
	return best


## The station table as rows for a menu or a debug dump.
static func describe() -> Array:
	var rows: Array = []
	for station_id in ids():
		var spec: Dictionary = table()[station_id]
		rows.append("%-5s x %6.2f  z %5.2f  r %.2f  %s" % [
			station_id, float(spec["x"]), float(spec["z"]), float(spec["radius"]),
			str(spec["en"])])
	return rows
