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


static func bowl(parent: Node3D, radius: float, mat_name: String, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _hemisphere()
	mi.material_override = double_sided(mat_name)
	mi.position = pos
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
	herb_bunch(root, Vector3(-4.7, 1.95, WALL_Z + 0.2))


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

	# Top, apron and legs.
	PropFactory.box(bench, Vector3(length, 0.12, BENCH_DEPTH), "wood_light", Vector3(0, BENCH_Y, 0))
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


## A charcoal stove with a wok. Returns the wok node, which is what the cooking
## tasks heat and where the fish is placed.
static func stove(parent: Node3D, x: float) -> Node3D:
	var node := Node3D.new()
	node.name = "Stove"
	node.position = Vector3(x, BENCH_Y, 0.0)
	parent.add_child(node)

	PropFactory.cyl(node, 0.42, 0.34, "concrete", Vector3(0, -0.14, 0))
	PropFactory.torus(node, 0.34, "steel_dull", Vector3(0, 0.05, 0), Vector3.ZERO, 0.16)
	for i in 6:
		var a := TAU * float(i) / 6.0
		PropFactory.box(node, Vector3(0.10, 0.06, 0.10), "charcoal",
			Vector3(cos(a) * 0.2, 0.0, sin(a) * 0.2))

	var wok := Node3D.new()
	wok.name = "Wok"
	wok.position = Vector3(0, 0.12, 0)
	node.add_child(wok)
	bowl(wok, 0.36, "steel_dull", Vector3.ZERO)
	PropFactory.cyl(wok, 0.045, 0.34, "wood_dark", Vector3(0.5, 0.06, 0), Vector3(0, 0, 80))
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
## A whole freshwater fish: body, tail, fins and a dark eye.
##
## The body and the fins are tagged `food_surface` so the kitchen can colour them
## as they cook. The eyes are left untagged on purpose: they are already dark, and
## a fish whose eye has "burnt" would read as burnt long before it is.
static func fish(parent: Node3D, pos: Vector3, mat_name: String = "fish_raw") -> Node3D:
	var node := Node3D.new()
	node.name = "Fish"
	node.position = pos
	parent.add_child(node)
	_tag_food_surface(PropFactory.sphere(node, 0.16, mat_name, Vector3(0, 0.06, 0), Vector3(1.0, 0.62, 3.0)))
	_tag_food_surface(PropFactory.prism(node, Vector3(0.22, 0.18, 0.02), mat_name, Vector3(0, 0.06, -0.46), Vector3(0, 0, 90)))
	_tag_food_surface(PropFactory.prism(node, Vector3(0.16, 0.12, 0.02), mat_name, Vector3(0, 0.16, 0.06), Vector3(0, 0, 0)))
	PropFactory.sphere(node, 0.028, "hair", Vector3(0.09, 0.11, 0.40))
	PropFactory.sphere(node, 0.028, "hair", Vector3(-0.09, 0.11, 0.40))
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


static func herb_bunch(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Herbs"
	node.position = pos
	parent.add_child(node)
	for i in 4:
		PropFactory.box(node, Vector3(0.24, 0.03, 0.10), "leaf_dark",
			Vector3(0.02 * i, -0.04 * i, 0.03 * i), Vector3(0, 20 * i, 12))
	PropFactory.cyl(node, 0.02, 0.20, "leaf", Vector3(0, -0.10, 0))
	return node


static func rice_bowl(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "RiceBowl"
	node.position = pos
	parent.add_child(node)
	bowl(node, 0.18, "sign_white", Vector3.ZERO)
	PropFactory.sphere(node, 0.15, "rice", Vector3(0, 0.05, 0), Vector3(1.0, 0.55, 1.0))
	return node


static func plate(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "Plate"
	node.position = pos
	parent.add_child(node)
	PropFactory.cyl(node, 0.26, 0.03, "sign_white", Vector3.ZERO)
	PropFactory.cyl(node, 0.20, 0.035, "sign_white", Vector3(0, 0.005, 0))
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
	bowl(node, 0.30, "basket", Vector3.ZERO)
	PropFactory.torus(node, 0.30, "basket", Vector3(0, 0.16, 0), Vector3.ZERO, 0.08)
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
	label.font_size = 22
	label.pixel_size = 0.0045
	label.modulate = colour
	label.outline_size = 7
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
		_:
			return _release(holder, _crate(holder))


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
