class_name KitchenProps
## Procedural builders for the village kitchen set.
##
## Like `PropFactory`, everything is generated from primitives and the shared
## `GameMaterials` palette, so the project ships no image or model files. Each
## builder adds its nodes under the parent it is given and returns the node it
## considers "the thing", which is what tasks attach to.
##
## Layout convention: the camera looks from +Z towards -Z, the bench top sits at
## y = 0.95, and items are placed on the bench at y ≈ 1.0.

extends RefCounted

## Bench top height. Tasks and props both use it so nothing floats or sinks.
const BENCH_Y := 0.95
const BENCH_DEPTH := 1.4
const WALL_Z := -1.35


# ------------------------------------------------------------------ materials ---
static var _double_sided: Dictionary = {}


## Water that reads as water without pulling in a shader we would have to tune.
static func water_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.68, 0.78, 0.62)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.06
	m.metallic = 0.15
	return m


## A fresh dirt/grime material. Never cached: the cleaning task animates its
## alpha, so each surface needs its own copy.
static func dirt_material() -> StandardMaterial3D:
	var m := GameMaterials.get_material("mud_wet").duplicate() as StandardMaterial3D
	m.albedo_color = Color(0.30, 0.24, 0.17, 0.95)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## An emissive box, used for lamplight and window light. The material is cached
## by key so repeated calls share one resource.
static func glow_box(parent: Node3D, size: Vector3, pos: Vector3, colour: Color,
		energy: float, key: String) -> MeshInstance3D:
	var mi := PropFactory.box(parent, size, "sign_white", pos)
	mi.material_override = GameMaterials.glow(key, colour, energy)
	return mi


## Double-sided variant of a shared material, used for bowls and other vessels
## whose inside must be visible.
static func double_sided(mat_name: String) -> StandardMaterial3D:
	if _double_sided.has(mat_name):
		return _double_sided[mat_name]
	var m := GameMaterials.get_material(mat_name).duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_double_sided[mat_name] = m
	return m


static func _hemisphere() -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 0.5
	m.radial_segments = 24
	m.rings = 8
	m.is_hemisphere = true
	return m


## How far a bowl's rim sits above the point it rests on: the cavity is `0.8 *
## radius` deep (see `bowl`), so a bowl standing on a surface is placed with its rim
## this much higher than its foot.
static func bowl_rim(radius: float) -> float:
	return radius * 0.8


## A bowl: a cavity that opens upwards, not a mound.
##
## `_hemisphere()` is the *upper* half of a sphere, so leaving it as-is built an
## upside-down bowl: contents placed at the origin were swallowed by the shell and
## the pan read as a bump on the bench. The mesh is turned over (a proper 180°
## rotation, so normals stay correct) which puts `.position` on the rim plane and
## the cavity `0.8 * radius` below it. Every caller lays its contents into that
## cavity.
static func bowl(parent: Node3D, radius: float, mat_name: String, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _hemisphere()
	mi.material_override = double_sided(mat_name)
	mi.position = pos
	mi.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	mi.scale = Vector3(radius * 2.0, radius * 1.6, radius * 2.0)
	parent.add_child(mi)
	return mi


# --------------------------------------------------------------------- the room ---
## Floor, walls, window and lamps. `warmth` scales the lamp energy so a level can
## be lit a little brighter or cosier.
static func room(root: Node3D, warmth: float = 1.0) -> void:
	PropFactory.plane(root, Vector2(11.0, 7.0), "tile_floor", Vector3(0.0, 0.0, 1.8))
	# Back and side walls, low enough to be out of the camera's way.
	PropFactory.box(root, Vector3(11.0, 3.4, 0.16), "plaster_cream", Vector3(0.0, 1.7, WALL_Z))
	PropFactory.box(root, Vector3(0.16, 3.4, 7.0), "plaster_cream", Vector3(-5.5, 1.7, 1.8))
	PropFactory.box(root, Vector3(0.16, 3.4, 7.0), "plaster_cream", Vector3(5.5, 1.7, 1.8))

	# A window letting the warm late-afternoon light in.
	PropFactory.box(root, Vector3(2.6, 1.5, 0.10), "wood_dark", Vector3(-3.1, 1.9, WALL_Z + 0.12))
	glow_box(root, Vector3(1.1, 1.2, 0.06), Vector3(-3.6, 1.9, WALL_Z + 0.16), Color(1.0, 0.86, 0.62), 1.1, "window")
	glow_box(root, Vector3(1.1, 1.2, 0.06), Vector3(-2.6, 1.9, WALL_Z + 0.16), Color(1.0, 0.86, 0.62), 1.1, "window")

	# Ceiling beam and a pair of hanging lamps.
	PropFactory.box(root, Vector3(11.0, 0.18, 0.24), "wood_dark", Vector3(0.0, 3.1, 0.6))
	for x: float in [-2.4, 2.4]:
		lantern(root, Vector3(x, 2.45, 0.6), warmth)

	# Herb bundles and a shelf: pure dressing, but it stops the wall reading flat.
	PropFactory.box(root, Vector3(2.2, 0.12, 0.34), "wood_light", Vector3(3.2, 2.15, WALL_Z + 0.2))
	for i in 3:
		PropFactory.cyl(root, 0.12, 0.34, "sign_white", Vector3(2.7 + i * 0.45, 2.38, WALL_Z + 0.2))
	PropFactory.box(root, Vector3(1.6, 0.1, 0.28), "wood_light", Vector3(-4.6, 2.05, WALL_Z + 0.2))
	# A *named* node rather than the unnamed mesh every other room prop is: the
	# bench probe classifies props by name, and an unnamed mesh could not be told
	# apart from something dropped on the worktop. Standing on the wall shelf, it is
	# explicitly dressing and is not measured against `BENCH_Y`.
	var wall_herbs := herb_bunch(root, Vector3(-4.7, 1.95, WALL_Z + 0.2))
	wall_herbs.name = "HerbsWall"


static func lantern(parent: Node3D, pos: Vector3, energy: float = 1.0) -> OmniLight3D:
	PropFactory.cyl(parent, 0.02, 0.5, "hair", pos + Vector3(0, 0.3, 0))
	glow_box(parent, Vector3(0.26, 0.26, 0.26), pos, Color(1.0, 0.82, 0.52), 1.5, "lamp")
	var light := OmniLight3D.new()
	light.position = pos
	light.omni_range = 6.5
	light.light_energy = 1.6 * energy
	light.light_color = Color(1.0, 0.82, 0.58)
	parent.add_child(light)
	return light


# ------------------------------------------------------------------ work bench ---
## The main bench. Returns the Node3D that props and tasks place things on.
static func counter(root: Node3D, length: float = 6.0, z: float = 0.35) -> Node3D:
	var bench := Node3D.new()
	bench.name = "Counter"
	bench.position = Vector3(0.0, 0.0, z)
	root.add_child(bench)

	# Top, apron and legs. The slab is dropped by half its own thickness so that
	# BENCH_Y really is the *surface* props stand on. Centring the slab on BENCH_Y
	# put the surface 6 cm higher and quietly sank every plate, bowl and ingredient.
	PropFactory.box(bench, Vector3(length, 0.12, BENCH_DEPTH), "wood_light", Vector3(0, BENCH_Y - 0.06, 0))
	PropFactory.box(bench, Vector3(length, 0.16, BENCH_DEPTH - 0.1), "wood", Vector3(0, BENCH_Y - 0.14, 0))
	for x: float in [-length * 0.5 + 0.35, 0.0, length * 0.5 - 0.35]:
		PropFactory.box(bench, Vector3(0.16, BENCH_Y - 0.22, 0.16), "wood_dark", Vector3(x, (BENCH_Y - 0.22) * 0.5, -0.45))
		PropFactory.box(bench, Vector3(0.16, BENCH_Y - 0.22, 0.16), "wood_dark", Vector3(x, (BENCH_Y - 0.22) * 0.5, 0.45))
	return bench


## A washing basin set into the bench, with a tap and a shallow pool of water.
static func sink(parent: Node3D, x: float) -> Node3D:
	var node := Node3D.new()
	node.name = "Sink"
	node.position = Vector3(x, BENCH_Y, 0.0)
	parent.add_child(node)

	PropFactory.box(node, Vector3(1.5, 0.30, 1.1), "steel_dull", Vector3(0, -0.14, 0))
	PropFactory.box(node, Vector3(1.25, 0.24, 0.85), "steel", Vector3(0, -0.20, 0))
	var water := MeshInstance3D.new()
	water.mesh = PropFactory.unit_box()
	water.material_override = water_material()
	water.position = Vector3(0, -0.10, 0)
	water.scale = Vector3(1.2, 0.03, 0.8)
	node.add_child(water)

	PropFactory.cyl(node, 0.05, 0.62, "steel", Vector3(0, 0.34, -0.44))
	PropFactory.box(node, Vector3(0.24, 0.24, 0.05), "steel", Vector3(0, 0.60, -0.34))
	return node


## A charcoal stove with a wok resting in its mouth.
##
## The stove used to be extruded *downwards* from the bench surface, so its body was
## buried inside the counter with only the top edge showing and the pan floating an
## inch above the worktop — the two things that made the cooking area read as an
## unfinished prototype. Here the body stands on the bench (`BENCH_Y` is the
## surface), the pan is a genuine cavity whose rim clears the stove mouth, and the
## handle is pinned to the rim by a collar so pan and handle move as one object.
static func stove(parent: Node3D, x: float, z: float = 0.30) -> Node3D:
	var node := Node3D.new()
	node.name = "Stove"
	node.position = Vector3(x, BENCH_Y, z)
	parent.add_child(node)

	# Clay body standing on the bench, with a steel mouth and a ring of coals. Kept
	# low so the pan's cavity is what the player sees, not a tall pedestal.
	PropFactory.cyl(node, 0.42, 0.16, "concrete", Vector3(0, 0.08, 0))
	PropFactory.torus(node, 0.34, "steel_dull", Vector3(0, 0.16, 0), Vector3.ZERO, 0.16)
	for i in 6:
		var a := TAU * float(i) / 6.0
		PropFactory.box(node, Vector3(0.10, 0.06, 0.10), "charcoal",
			Vector3(cos(a) * 0.2, 0.16, sin(a) * 0.2))

	var wok := Node3D.new()
	wok.name = "Wok"
	wok.position = Vector3(0, 0.30, 0)
	node.add_child(wok)
	# Concave pan: the rim sits on the wok's origin and the cavity drops below it, so
	# food can be laid *into* the pan rather than on top of a bump. The cavity's floor
	# lands just above the bench, sitting down inside the stove's mouth.
	bowl(wok, 0.36, "steel_dull", Vector3.ZERO)
	PropFactory.torus(wok, 0.355, "steel_dull", Vector3.ZERO, Vector3.ZERO, 0.10)
	# Handle: a collar bolted through the rim, then the handle itself, both lying in
	# the rim plane. The transform lives on the prop so no task needs an offset.
	PropFactory.cyl(wok, 0.07, 0.10, "steel_dull", Vector3(0.38, 0.0, 0), Vector3(0, 0, 90))
	PropFactory.cyl(wok, 0.042, 0.40, "wood_dark", Vector3(0.60, 0.0, 0), Vector3(0, 0, 90))
	return wok


## A wooden chopping board. `dirty` adds a removable layer of grime on top.
static func chopping_board(parent: Node3D, pos: Vector3, dirty: bool = false) -> Node3D:
	var node := Node3D.new()
	node.name = "Board"
	node.position = pos
	parent.add_child(node)
	PropFactory.box(node, Vector3(0.95, 0.07, 0.62), "wood_light", Vector3(0, 0.035, 0))
	if dirty:
		var grime := MeshInstance3D.new()
		grime.name = "Grime"
		grime.mesh = PropFactory.unit_box()
		grime.material_override = dirt_material()
		grime.position = Vector3(0, 0.075, 0)
		grime.scale = Vector3(0.9, 0.012, 0.56)
		node.add_child(grime)
	return node


static func knife(parent: Node3D, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = "Knife"
	node.position = pos
	node.rotation_degrees = rot_deg
	parent.add_child(node)
	PropFactory.box(node, Vector3(0.05, 0.02, 0.44), "steel", Vector3(0, 0.01, 0.0))
	PropFactory.cyl(node, 0.024, 0.22, "wood_dark", Vector3(0, 0.01, 0.32), Vector3(90, 0, 0))
	return node


static func cloth(parent: Node3D, pos: Vector3, mat_name: String = "cloth_blue") -> MeshInstance3D:
	return PropFactory.box(parent, Vector3(0.42, 0.05, 0.34), mat_name, pos)


static func soap(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Soap"
	node.position = pos
	parent.add_child(node)
	PropFactory.box(node, Vector3(0.22, 0.07, 0.14), "sign_green", Vector3.ZERO)
	PropFactory.box(node, Vector3(0.34, 0.04, 0.24), "sign_white", Vector3(0, -0.04, 0))
	return node


# ------------------------------------------------------------------------- food ---
## A whole freshwater fish: head, tapering body, dorsal and pectoral fins, a forked
## tail, and a dark eye.
##
## Every part that reads as flesh is tagged `food_surface` so the kitchen can colour
## it as it cooks, from raw through opaque to browned. The eyes are left untagged on
## purpose: they are already dark, and a fish whose eye has "burnt" would read as
## burnt long before it is.
##
## The parts are placed so the fish's belly rests on its anchor: the anchor sits on
## the surface the fish is lying on, and everything is built above y = 0. That is
## what stops a fish half-burying itself in the chopping board or the pan, and it is
## why no caller has to nudge the fish up afterwards.
##
## The body is built from four overlapping segments rather than one stretched
## sphere: a sphere scaled 3:1 on its own reads as a balloon, while tapering
## segments give the fish a thick shoulder and a narrow tail like the real animal.
static func fish(parent: Node3D, pos: Vector3, mat_name: String = "fish_raw") -> Node3D:
	var node := Node3D.new()
	node.name = "Fish"
	node.position = pos
	parent.add_child(node)

	# Body: shoulder, middle, waist, tail root — each a little smaller and higher
	# than the last, so the back arches away from the board.
	_tag_food_surface(PropFactory.sphere(node, 0.155, mat_name, Vector3(0, 0.105, 0.16), Vector3(1.02, 0.70, 1.25)))
	_tag_food_surface(PropFactory.sphere(node, 0.145, mat_name, Vector3(0, 0.100, -0.06), Vector3(0.98, 0.66, 1.30)))
	_tag_food_surface(PropFactory.sphere(node, 0.112, mat_name, Vector3(0, 0.093, -0.30), Vector3(0.82, 0.58, 1.35)))
	_tag_food_surface(PropFactory.sphere(node, 0.070, mat_name, Vector3(0, 0.085, -0.50), Vector3(0.60, 0.44, 1.20)))
	# Head: a slightly flattened taper in front of the shoulder.
	_tag_food_surface(PropFactory.sphere(node, 0.125, mat_name, Vector3(0, 0.108, 0.44), Vector3(0.86, 0.64, 1.10)))
	_tag_food_surface(PropFactory.sphere(node, 0.078, mat_name, Vector3(0, 0.100, 0.58), Vector3(0.70, 0.52, 1.00)))

	# Dorsal fin: a raked triangle along the back, then a small second fin further
	# back, which is what a tilapia or a snakehead actually has.
	_tag_food_surface(PropFactory.prism(node, Vector3(0.20, 0.13, 0.015), mat_name,
		Vector3(0, 0.20, 0.10), Vector3(0, 0, 90)))
	_tag_food_surface(PropFactory.prism(node, Vector3(0.11, 0.07, 0.012), mat_name,
		Vector3(0, 0.16, -0.30), Vector3(0, 0, 90)))
	# Pectoral fin, angled out from the flank.
	_tag_food_surface(PropFactory.prism(node, Vector3(0.12, 0.09, 0.012), mat_name,
		Vector3(0.09, 0.07, 0.28), Vector3(0, 42, 70)))

	# Tail: a stalk and a forked fin, so the silhouette ends in a V rather than a
	# paddle.
	_tag_food_surface(PropFactory.sphere(node, 0.035, mat_name, Vector3(0, 0.085, -0.58), Vector3(0.7, 0.5, 1.6)))
	_tag_food_surface(PropFactory.prism(node, Vector3(0.20, 0.19, 0.014), mat_name,
		Vector3(0, 0.105, -0.72), Vector3(0, 90, 90)))
	_tag_food_surface(PropFactory.prism(node, Vector3(0.13, 0.15, 0.012), mat_name,
		Vector3(0.055, 0.105, -0.66), Vector3(20, 90, 64)))
	_tag_food_surface(PropFactory.prism(node, Vector3(0.13, 0.15, 0.012), mat_name,
		Vector3(-0.055, 0.105, -0.66), Vector3(20, 90, 116)))

	# Gill line and eyes: dark detail that is never recoloured by cooking.
	_tag_food_surface(PropFactory.prism(node, Vector3(0.20, 0.20, 0.010), "fish_gill",
		Vector3(0, 0.108, 0.32), Vector3(0, 0, 90)))
	PropFactory.sphere(node, 0.026, "hair", Vector3(0.072, 0.135, 0.50))
	PropFactory.sphere(node, 0.026, "hair", Vector3(-0.072, 0.135, 0.50))
	return node


static func _tag_food_surface(mesh: MeshInstance3D) -> void:
	mesh.set_meta("food_surface", true)


## A small pile of vegetables. `kinds` may include "cucumber", "tomato", "herb".
static func vegetable_pile(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Vegetables"
	node.position = pos
	parent.add_child(node)
	PropFactory.cyl(node, 0.06, 0.44, "veg_green", Vector3(-0.12, 0.06, 0), Vector3(0, 0, 90))
	PropFactory.cyl(node, 0.055, 0.40, "veg_green", Vector3(-0.05, 0.10, 0.08), Vector3(0, 20, 84))
	PropFactory.sphere(node, 0.09, "veg_red", Vector3(0.16, 0.09, -0.04))
	PropFactory.sphere(node, 0.075, "veg_red", Vector3(0.24, 0.07, 0.10))
	PropFactory.box(node, Vector3(0.26, 0.05, 0.20), "leaf_bright", Vector3(0.0, 0.03, -0.16), Vector3(0, 25, 0))
	return node


## A small pile of the actual ingredient, tinted with its own catalogue colour.
##
## `visual_for` only knows a handful of generic props, so an aromatic or a vegetable
## used to arrive as a crate — which then looked wrong when the knife cut it. This
## builds the ingredient itself, in its own colour, so the thing being chopped is
## recognisable and the pieces left behind match it.
static func ingredient_mound(parent: Node3D, pos: Vector3, colour: Color,
		radius: float = 0.14) -> Node3D:
	var node := Node3D.new()
	node.name = "Ingredient"
	node.position = pos
	parent.add_child(node)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	# Four overlapping pieces: enough to read as a small heap from the game camera,
	# cheap enough to build on every step.
	var spots := [
		Vector3(-0.06, 0.05, -0.03), Vector3(0.05, 0.06, 0.02),
		Vector3(-0.01, 0.10, -0.06), Vector3(0.07, 0.03, -0.07),
	]
	for i in spots.size():
		var piece := MeshInstance3D.new()
		piece.mesh = PropFactory.unit_sphere() if i % 2 == 0 else PropFactory.unit_box()
		piece.material_override = material
		var size := radius * 0.62
		piece.scale = Vector3(size, size * 0.72, size)
		piece.position = spots[i]
		piece.rotation_degrees = Vector3(0, 37.0 * float(i), 12.0)
		node.add_child(piece)
	return node


static func herb_bunch(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Herbs"
	node.position = pos
	parent.add_child(node)
	# Sits on its anchor: the sprigs rest on the bench and the stem stands up from it,
	# instead of the whole bunch being modelled below the point it is placed at.
	#
	# The sprigs are built in a *flat fan* in the bench plane, not stacked upwards.
	# Stacking them put the bunch about 14 cm above the point it was placed at, which
	# is what made a bunch standing on the worktop read as levitating next to it.
	#
	# The `y` lift is chosen so the *lowest corner* of a sprig stays at or above the
	# anchor even after its 12° tilt: a thinner lift sank the bunch 22 mm into the
	# worktop, which is exactly the class of defect the 3D probe now catches.
	for i in 4:
		var offset := Vector3(0.09 * (float(i) - 1.5), 0.048, 0.05 * float(i) - 0.075)
		PropFactory.box(node, Vector3(0.24, 0.03, 0.10), "leaf_dark",
			offset, Vector3(0, 28.0 * float(i) - 42.0, 12))
	PropFactory.cyl(node, 0.02, 0.16, "leaf", Vector3(0, 0.11, 0))
	return node


static func rice_bowl(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "RiceBowl"
	node.position = pos
	parent.add_child(node)
	# The bowl's foot rests on the anchor; its mouth is `bowl_rim` above it.
	var rim := bowl_rim(0.18)
	bowl(node, 0.18, "sign_white", Vector3(0, rim, 0))
	# The rice sits *in* the bowl, heaped just over the rim.
	PropFactory.sphere(node, 0.15, "rice", Vector3(0, rim - 0.03, 0), Vector3(1.0, 0.55, 1.0))
	return node


static func plate(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Plate"
	node.position = pos
	parent.add_child(node)
	# Discs are stacked upwards from the anchor so the plate rests on the surface
	# rather than sinking half its height into it.
	PropFactory.cyl(node, 0.26, 0.03, "sign_white", Vector3(0, 0.015, 0))
	PropFactory.cyl(node, 0.20, 0.035, "sign_white", Vector3(0, 0.025, 0))
	return node


static func tray(parent: Node3D, pos: Vector3, size: Vector2 = Vector2(0.9, 0.6), mat_name: String = "tray_steel") -> Node3D:
	var node := Node3D.new()
	node.name = "Tray"
	node.position = pos
	parent.add_child(node)
	PropFactory.box(node, Vector3(size.x, 0.04, size.y), mat_name, Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		PropFactory.box(node, Vector3(size.x, 0.07, 0.04), mat_name, Vector3(0, 0.04, side * size.y * 0.5))
		PropFactory.box(node, Vector3(0.04, 0.07, size.y), mat_name, Vector3(side * size.x * 0.5, 0.04, 0))
	return node


static func water_jar(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "WaterJar"
	node.position = pos
	parent.add_child(node)
	PropFactory.cyl(node, 0.22, 0.44, "plastic_blue", Vector3(0, 0.22, 0))
	PropFactory.cyl(node, 0.23, 0.06, "plastic_blue", Vector3(0, 0.45, 0))
	var lid := MeshInstance3D.new()
	lid.mesh = PropFactory.unit_cyl()
	lid.material_override = GameMaterials.get_material("plastic_red")
	lid.position = Vector3(0, 0.50, 0)
	lid.scale = Vector3(0.5, 0.05, 0.5)
	node.add_child(lid)
	return node


static func basket(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Basket"
	node.position = pos
	parent.add_child(node)
	bowl(node, 0.30, "basket", Vector3(0, bowl_rim(0.30), 0))
	# Rim hoop at the bowl's mouth rather than floating above it.
	PropFactory.torus(node, 0.30, "basket", Vector3(0, bowl_rim(0.30), 0), Vector3.ZERO, 0.08)
	return node


# ------------------------------------------------------------ little village set ---
## A miniature village corner: a pond, a latrine hut and a fish in the water. Used
## by the prevention challenge so that sanitation questions have something to look
## at rather than a bare list of words.
static func village_corner(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "VillageCorner"
	node.position = pos
	parent.add_child(node)

	# Pond.
	PropFactory.cyl(node, 0.9, 0.06, "mud_wet", Vector3(0, 0.03, 0))
	var water := MeshInstance3D.new()
	water.mesh = PropFactory.unit_cyl()
	water.material_override = water_material()
	water.position = Vector3(0, 0.07, 0)
	water.scale = Vector3(1.7, 0.02, 1.7)
	node.add_child(water)
	PropFactory.cyl(node, 0.10, 0.34, "bamboo", Vector3(-0.6, 0.2, -0.4))
	fish(node, Vector3(0.35, 0.05, 0.2), "fish_raw_dark")

	# Latrine hut.
	PropFactory.box(node, Vector3(0.8, 0.9, 0.8), "wood", Vector3(1.5, 0.45, 0.2))
	PropFactory.box(node, Vector3(1.05, 0.10, 0.26), "roof_tile", Vector3(1.5, 0.95, 0.2))
	PropFactory.box(node, Vector3(1.05, 0.10, 0.26), "roof_tile", Vector3(1.5, 0.95, 0.66))
	PropFactory.box(node, Vector3(0.3, 0.6, 0.06), "wood_dark", Vector3(1.5, 0.35, -0.22))
	return node


## Small floating label above an object, useful for naming drop zones in the 3D
## scene without a separate UI panel.
##
## The label is sized in *world* units rather than screen pixels: a fixed-screen
## label ignores perspective, so two labels a metre apart look the same size and
## the kitchen stops reading like a room. A world-sized label shrinks with
## distance the way a real card on the bench would.
static func floating_label(parent: Node3D, pos: Vector3, text: String, colour: Color = Color(1, 0.9, 0.6)) -> Label3D:
	var label := Label3D.new()
	label.text = _break_label(text)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	# Small and slightly translucent: with a whole row of containers and ingredients
	# on the bench, full-brightness labels turned the worktop into a wall of text.
	# A label that is being pointed at is brought back to full strength (see
	# `DropZone.set_highlighted`).
	label.font_size = 20
	label.pixel_size = 0.0038
	label.modulate = Color(colour, colour.a * 0.72)
	label.outline_size = 6
	label.font = PropFactory.font_bold()
	parent.add_child(label)
	return label


## Breaks a long name over a few short lines so a row of labels sitting on the
## bench does not overlap its neighbours. Thai is written without spaces between
## words, so the break is by character unless the text is already spaced.
static func _break_label(text: String, max_chars: int = 12) -> String:
	if text.length() <= max_chars:
		return text
	var lines: Array[String] = []
	var current := ""
	if text.contains(" "):
		for word in text.split(" ", false):
			if current.is_empty():
				current = word
			elif current.length() + 1 + word.length() <= max_chars:
				current += " " + word
			else:
				lines.append(current)
				current = word
		if not current.is_empty():
			lines.append(current)
	else:
		var index := 0
		while index < text.length():
			lines.append(text.substr(index, max_chars))
			index += max_chars
	return "\n".join(lines)


# ------------------------------------------------------------- content visuals ---
## The cook who watches the kitchen. Built from primitives like everything else, with
## a short procedural reaction set (see `KitchenCharacter.react`).
static func chef(parent: Node3D, pos: Vector3, facing_deg: float = 22.0) -> KitchenCharacter:
	var node := KitchenCharacter.new()
	node.name = "Chef"
	node.position = pos
	node.rotation_degrees = Vector3(0, facing_deg, 0)
	parent.add_child(node)
	node.build()
	return node


## Builds the visible body for a named ingredient. Keeping this mapping in one
## place means a level's step data can name an item and get a sensible object
## without the task knowing about meshes.
##
## The prop builders expect a parent, so they are given a throwaway holder and the
## result is handed back unparented. The caller then decides where it goes; a node
## that arrived already parented would silently refuse to be adopted.
static func visual_for(item_id: String) -> Node3D:
	var holder := Node3D.new()
	match item_id:
		"raw_fish", "freshwater_fish", "fish":
			return _release(holder, fish(holder, Vector3.ZERO, "fish_raw"))
		"cooked_fish", "grilled_fish":
			return _release(holder, fish(holder, Vector3.ZERO, "fish_cooked"))
		"cooked_rice", "rice":
			return _release(holder, rice_bowl(holder, Vector3.ZERO))
		"herbs", "vegetables", "cooked_veg", "veg":
			return _release(holder, vegetable_pile(holder, Vector3.ZERO))
		"fish_juice", "dirty_board":
			return _release(holder, chopping_board(holder, Vector3.ZERO, true))
		"clean_board":
			return _release(holder, chopping_board(holder, Vector3.ZERO, false))
		"soap_bar", "soap":
			return _release(holder, soap(holder, Vector3.ZERO))
		_:
			# A catalogue ingredient looks like itself. This is what lets a sorting
			# step show the actual ingredient named in the recipe rather than a box.
			var ingredient := ingredient_visual(item_id)
			if ingredient != null:
				return ingredient
			# Nothing recognises the id: hand back an empty crate rather than
			# nothing, so a step can never fail because of a missing prop. The crate
			# is built inside its own node — returning the holder itself used to hand
			# the caller a node that `_release` had already freed.
			var crate := Node3D.new()
			crate.name = "Crate"
			holder.add_child(crate)
			_crate(crate)
			return _release(holder, crate)


## The prop for a catalogue ingredient: a bottle for a liquid seasoning, a sprig for
## a herb, a bowl for a side, and a small mound of pieces for anything solid. Returns
## null when the id is not in the catalogue, so the caller can fall back.
static func ingredient_visual(ingredient_id: String) -> Node3D:
	var spec := RecipeDB.ingredient_by_id(ingredient_id)
	if spec.is_empty():
		return null
	var colour: Color = spec.get("colour", Color(0.6, 0.6, 0.5))
	var role := str(spec.get("role", ""))
	var holder := Node3D.new()
	match role:
		"seasoning":
			return _release(holder, _bottle(holder, colour))
		"herb":
			return _release(holder, _sprig(holder, colour))
		"side":
			return _release(holder, rice_bowl(holder, Vector3.ZERO))
		_:
			return _release(holder, ingredient_mound(holder, Vector3.ZERO, colour, 0.18))


## A sauce or paste bottle in the ingredient's own colour.
static func _bottle(parent: Node3D, colour: Color) -> Node3D:
	var node := Node3D.new()
	node.name = "Bottle"
	parent.add_child(node)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	var body := MeshInstance3D.new()
	body.mesh = PropFactory.unit_cyl()
	body.material_override = material
	body.scale = Vector3(0.15, 0.30, 0.15)
	body.position = Vector3(0, 0.15, 0)
	node.add_child(body)
	var neck := MeshInstance3D.new()
	neck.mesh = PropFactory.unit_cyl()
	neck.material_override = material
	neck.scale = Vector3(0.07, 0.10, 0.07)
	neck.position = Vector3(0, 0.34, 0)
	node.add_child(neck)
	return node


## A few leaves and a stalk, tinted with the herb's colour.
static func _sprig(parent: Node3D, colour: Color) -> Node3D:
	var node := Node3D.new()
	node.name = "Sprig"
	parent.add_child(node)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	for i in 4:
		var leaf := MeshInstance3D.new()
		leaf.mesh = PropFactory.unit_box()
		leaf.material_override = material
		leaf.scale = Vector3(0.22, 0.02, 0.09)
		leaf.position = Vector3(0.02 * float(i) - 0.03, 0.10 + 0.015 * float(i), 0.02 * float(i))
		leaf.rotation_degrees = Vector3(0, 22.0 * float(i), 10.0)
		node.add_child(leaf)
	var stalk := MeshInstance3D.new()
	stalk.mesh = PropFactory.unit_cyl()
	stalk.material_override = material
	stalk.scale = Vector3(0.02, 0.20, 0.02)
	stalk.position = Vector3(0, 0.10, 0)
	node.add_child(stalk)
	return node


## Takes a built node out of the holder it was assembled in and disposes of the
## holder, so the caller receives a node with no parent.
static func _release(holder: Node3D, node: Node3D) -> Node3D:
	if node.get_parent() == holder:
		holder.remove_child(node)
	holder.free()
	return node


static func _crate(node: Node3D) -> Node3D:
	PropFactory.box(node, Vector3(0.34, 0.26, 0.34), "basket", Vector3(0, 0.13, 0))
	return node


## The prop that makes a drop zone read as a container, or null for a plain zone.
static func zone_prop(zone_id: String) -> Node3D:
	var holder := Node3D.new()
	match zone_id:
		"raw_tray", "raw_board":
			return _release(holder, tray(holder, Vector3.ZERO, Vector2(0.95, 0.62), "tray_steel"))
		"ready_plate", "ready_area":
			return _release(holder, plate(holder, Vector3.ZERO))
		_:
			holder.free()
			return null
