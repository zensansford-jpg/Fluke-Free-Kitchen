class_name PropFactory
## Procedural prop library — primitives, nature and village architecture.
##
## Every 3D object in the game is assembled here from Godot primitive meshes and
## the code-generated materials in `GameMaterials`. No external models are
## required, which keeps the project runnable from a clean checkout.
##
## Conventions
##   * every `add_*` builds the prop as a child of `parent` and returns the
##     created root Node3D (or null when a prop is skipped),
##   * helpers use *unit* meshes plus node scale, so one BoxMesh/MeshInstance
##     material pair is reused across the whole world (very few resources),
##   * props that stand next to the running lane and must be solid call
##     `add_static_box()` so the player can never clip through them.
##
## Related files: `prop_market.gd`, `prop_clinic.gd`, `prop_obstacles.gd`.

extends RefCounted

# ------------------------------------------------------------- unit meshes ---
static var _unit_box: BoxMesh
static var _unit_cyl: CylinderMesh
static var _unit_sphere: SphereMesh
static var _unit_prism: PrismMesh
static var _unit_plane: PlaneMesh
static var _unit_torus: TorusMesh
static var _cross_quads: Dictionary = {}
static var _font_regular: FontFile
static var _font_bold: FontFile


static func unit_box() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box


static func unit_cyl(sides: int = 12) -> CylinderMesh:
	# Cache a couple of resolutions; low sides for background clutter.
	if _unit_cyl == null:
		_unit_cyl = CylinderMesh.new()
		_unit_cyl.top_radius = 0.5
		_unit_cyl.bottom_radius = 0.5
		_unit_cyl.height = 1.0
		_unit_cyl.radial_segments = sides
	return _unit_cyl


static func unit_sphere() -> SphereMesh:
	if _unit_sphere == null:
		_unit_sphere = SphereMesh.new()
		_unit_sphere.radius = 0.5
		_unit_sphere.height = 1.0
		_unit_sphere.radial_segments = 12
		_unit_sphere.rings = 6
	return _unit_sphere


static func unit_prism() -> PrismMesh:
	if _unit_prism == null:
		_unit_prism = PrismMesh.new()
		_unit_prism.size = Vector3.ONE
	return _unit_prism


static func unit_plane() -> PlaneMesh:
	if _unit_plane == null:
		_unit_plane = PlaneMesh.new()
		_unit_plane.size = Vector2.ONE
		_unit_plane.subdivide_width = 8
		_unit_plane.subdivide_depth = 8
	return _unit_plane


static func unit_torus() -> TorusMesh:
	if _unit_torus == null:
		_unit_torus = TorusMesh.new()
		_unit_torus.inner_radius = 0.35
		_unit_torus.outer_radius = 0.5
		_unit_torus.rings = 16
		_unit_torus.ring_segments = 8
	return _unit_torus


static func font_regular() -> Font:
	if _font_regular == null:
		_font_regular = _load_font("res://assets/fonts/Sarabun-Regular.ttf")
	return _font_regular


static func font_bold() -> Font:
	if _font_bold == null:
		_font_bold = _load_font("res://assets/fonts/Sarabun-Bold.ttf")
	return _font_bold


static func _load_font(path: String) -> FontFile:
	if not ResourceLoader.exists(path):
		push_warning("PropFactory: font %s missing; falling back to the default font (Thai text may not render)." % path)
		return null
	return load(path) as FontFile


# ---------------------------------------------------------------- primitives ---
static func mesh_instance(mesh: Mesh, mat_name: String, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = GameMaterials.get_material(mat_name)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


static func box(parent: Node3D, size: Vector3, mat_name: String, pos: Vector3,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := mesh_instance(unit_box(), mat_name, pos, rot_deg, size)
	parent.add_child(mi)
	return mi


static func cyl(parent: Node3D, radius: float, height: float, mat_name: String, pos: Vector3,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := mesh_instance(unit_cyl(), mat_name, pos, rot_deg, Vector3(radius * 2.0, height, radius * 2.0))
	parent.add_child(mi)
	return mi


static func sphere(parent: Node3D, radius: float, mat_name: String, pos: Vector3,
		squash: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var s := Vector3(radius * 2.0, radius * 2.0, radius * 2.0) * squash
	var mi := mesh_instance(unit_sphere(), mat_name, pos, Vector3.ZERO, s)
	parent.add_child(mi)
	return mi


static func prism(parent: Node3D, size: Vector3, mat_name: String, pos: Vector3,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := mesh_instance(unit_prism(), mat_name, pos, rot_deg, size)
	parent.add_child(mi)
	return mi


static func plane(parent: Node3D, size: Vector2, mat_name: String, pos: Vector3,
		rot_deg: Vector3 = Vector3(-90, 0, 0)) -> MeshInstance3D:
	var mi := mesh_instance(unit_plane(), mat_name, pos, rot_deg, Vector3(size.x, 1.0, size.y))
	parent.add_child(mi)
	return mi


static func torus(parent: Node3D, radius: float, mat_name: String, pos: Vector3,
		rot_deg: Vector3 = Vector3.ZERO, thickness: float = 1.0) -> MeshInstance3D:
	var mi := mesh_instance(unit_torus(), mat_name, pos, rot_deg, Vector3(radius * 2.0, radius * 2.0 * thickness, radius * 2.0))
	parent.add_child(mi)
	return mi


## Builds a mesh consisting of `count` vertical quads arranged around the Y axis.
## Used for grass tufts, leaves, netting and other "flat card" foliage which
## reads far better than boxes at this polygon budget.
static func cross_quad_mesh(count: int, width: float, height: float) -> ArrayMesh:
	var key := "cq_%d_%.2f_%.2f" % [count, width, height]
	if _cross_quads.has(key):
		return _cross_quads[key]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for i in count:
		var angle := PI * float(i) / float(count)
		var dx := cos(angle) * width * 0.5
		var dz := sin(angle) * width * 0.5
		var n := Vector3(-sin(angle), 0.0, cos(angle))
		var bl := Vector3(-dx, 0.0, -dz)
		var br := Vector3(dx, 0.0, dz)
		var tr := Vector3(dx, height, dz)
		var tl := Vector3(-dx, height, -dz)
		for tri in [[bl, br, tr], [bl, tr, tl]]:
			verts.append(tri[0])
			verts.append(tri[1])
			verts.append(tri[2])
			for _k in 3:
				normals.append(n)
		uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])
		uvs.append_array([Vector2(0, 1), Vector2(1, 0), Vector2(0, 0)])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_cross_quads[key] = mesh
	return mesh


# ------------------------------------------------------------------ physics ---
## Adds an invisible (or visible) solid collider. Scenery the player can bump
## into must always use this so collision matches the visual silhouette.
static func add_static_box(parent: Node3D, size: Vector3, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	return body


static func add_label(parent: Node3D, text: String, pos: Vector3, size: float = 0.35,
		color: Color = Color(0.1, 0.1, 0.12), rot_deg: Vector3 = Vector3.ZERO, bold: bool = false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	var f: Font = font_bold() if bold else font_regular()
	if f != null:
		label.font = f
	label.font_size = 96
	label.pixel_size = size / 96.0
	label.position = pos
	label.rotation_degrees = rot_deg
	label.modulate = color
	label.outline_size = 12
	label.outline_modulate = Color(1, 1, 1, 0.85) if color.v < 0.5 else Color(0, 0, 0, 0.6)
	label.double_sided = true
	label.no_depth_test = false
	label.shaded = true
	parent.add_child(label)
	return label


# -------------------------------------------------------------------- water ---
static func add_water(parent: Node3D, size: Vector2, pos: Vector3, flow_speed: float = 0.18) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = unit_plane()
	mi.material_override = water_material(flow_speed)
	mi.position = pos
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.scale = Vector3(size.x, 1.0, size.y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static var _water_mats: Dictionary = {}


static func water_material(flow_speed: float) -> ShaderMaterial:
	var key := "%.2f" % flow_speed
	if _water_mats.has(key):
		return _water_mats[key]
	var shader: Shader = load("res://shaders/water.gdshader")
	if shader == null:
		push_warning("PropFactory: water shader missing; using a flat material.")
		var fallback := ShaderMaterial.new()
		_water_mats[key] = fallback
		return fallback
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("flow_speed", flow_speed)
	_water_mats[key] = m
	return m


# ------------------------------------------------------------------- nature ---
static func add_grass_tuft(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator) -> MeshInstance3D:
	var mesh := cross_quad_mesh(3, 0.5, 0.45)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = GameMaterials.get_material("grass" if rng.randf() < 0.7 else "grass_dry")
	mi.position = pos
	mi.rotation_degrees = Vector3(0, rng.randf_range(0, 360), 0)
	mi.scale = Vector3.ONE * scale
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Scatters many grass tufts with one MultiMesh draw call.
static func add_grass_field(parent: Node3D, count: int, area: Rect2, y: float,
		rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var mesh := cross_quad_mesh(3, 0.5, 0.45)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	for i in count:
		var t := Transform3D()
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t = t.scaled(Vector3.ONE * rng.randf_range(0.7, 1.5))
		t.origin = Vector3(rng.randf_range(area.position.x, area.end.x), y, rng.randf_range(area.position.y, area.end.y))
		mm.set_instance_transform(i, t)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = GameMaterials.get_material("grass")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


## Scatters pebbles/stones with a single MultiMesh.
static func add_pebble_field(parent: Node3D, count: int, area: Rect2, y: float,
		rng: RandomNumberGenerator, mat_name: String = "gravel") -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = unit_sphere()
	mm.instance_count = count
	for i in count:
		var t := Transform3D()
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		var s := rng.randf_range(0.08, 0.22)
		t = t.scaled(Vector3(s, s * 0.6, s))
		t.origin = Vector3(rng.randf_range(area.position.x, area.end.x), y, rng.randf_range(area.position.y, area.end.y))
		mm.set_instance_transform(i, t)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = GameMaterials.get_material(mat_name)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


static func add_banana_tree(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "BananaTree"
	root.position = pos
	root.scale = Vector3.ONE * scale
	parent.add_child(root)
	cyl(root, 0.18, 2.4, "trunk", Vector3(0, 1.2, 0))
	# Fronds: flat cards fanning outward and drooping.
	var fronds := rng.randi_range(7, 10)
	for i in fronds:
		var a := TAU * float(i) / float(fronds) + rng.randf_range(-0.2, 0.2)
		var tilt := rng.randf_range(-45.0, -18.0)
		var len_scale := rng.randf_range(0.85, 1.25)
		var frond := MeshInstance3D.new()
		frond.mesh = cross_quad_mesh(1, 0.55, 2.0)
		frond.material_override = GameMaterials.get_material("leaf_banana")
		frond.position = Vector3(cos(a) * 0.35, 2.3, sin(a) * 0.35)
		frond.rotation_degrees = Vector3(tilt, rad_to_deg(-a), 0)
		frond.scale = Vector3(len_scale, len_scale, 1.0)
		frond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(frond)
	# A small bunch of bananas for a recognisable silhouette.
	sphere(root, 0.16, "roof_tile_blue", Vector3(0.28, 1.55, 0.1), Vector3(1.0, 1.6, 1.0))
	return root


static func add_palm(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Palm"
	root.position = pos
	root.scale = Vector3.ONE * scale
	parent.add_child(root)
	cyl(root, 0.16, 4.5, "trunk_palm", Vector3(0, 2.25, 0))
	for i in 7:
		var a := TAU * float(i) / 7.0
		var frond := MeshInstance3D.new()
		frond.mesh = cross_quad_mesh(1, 0.7, 2.6)
		frond.material_override = GameMaterials.get_material("leaf")
		frond.position = Vector3(cos(a) * 0.4, 4.4, sin(a) * 0.4)
		frond.rotation_degrees = Vector3(rng.randf_range(-55.0, -30.0), rad_to_deg(-a), 0)
		root.add_child(frond)
	return root


static func add_bush(parent: Node3D, pos: Vector3, scale: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Bush"
	root.position = pos
	parent.add_child(root)
	var blobs := rng.randi_range(2, 4)
	for i in blobs:
		var r := rng.randf_range(0.35, 0.7) * scale
		sphere(root, r, "leaf_dark" if i % 2 == 0 else "leaf",
			Vector3(rng.randf_range(-0.4, 0.4) * scale, r * 0.85, rng.randf_range(-0.4, 0.4) * scale))
	if rng.randf() < 0.5:
		sphere(root, 0.12 * scale, "flower_pink", Vector3(0, scale * 0.8, 0))
	return root


static func add_potted_plant(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "PottedPlant"
	root.position = pos
	parent.add_child(root)
	# Terracotta pot: slightly tapered cylinder look via two cylinders.
	cyl(root, 0.26, 0.36, "roof_tile", Vector3(0, 0.18, 0))
	cyl(root, 0.28, 0.05, "wood_light", Vector3(0, 0.37, 0))
	cylinder_leaves(root, 0.0, 0.38, 1.0, rng)
	return root


static func cylinder_leaves(root: Node3D, x: float, y: float, scale: float, rng: RandomNumberGenerator) -> void:
	var blades := 9
	for i in blades:
		var a := TAU * float(i) / float(blades) + rng.randf_range(-0.15, 0.15)
		var leaf := MeshInstance3D.new()
		leaf.mesh = cross_quad_mesh(1, 0.22, 1.0)
		leaf.material_override = GameMaterials.get_material("leaf_bright" if i % 2 == 0 else "leaf")
		leaf.position = Vector3(x + cos(a) * 0.12, y + 0.32 * scale, sin(a) * 0.12)
		leaf.rotation_degrees = Vector3(rng.randf_range(-38.0, -12.0), rad_to_deg(-a), 0)
		leaf.scale = Vector3.ONE * scale
		root.add_child(leaf)


static func add_hay_stack(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "HayStack"
	root.position = pos
	parent.add_child(root)
	cyl(root, 0.9, 1.2, "thatch", Vector3(0, 0.6, 0))
	prism(root, Vector3(1.7, 0.7, 1.7), "thatch", Vector3(0, 1.5, 0))
	cyl(root, 0.08, 2.4, "bamboo", Vector3(0, 2.2, 0))
	return root


static func add_rice_field(parent: Node3D, size: Vector2, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "RiceField"
	root.position = pos
	parent.add_child(root)
	var rows := int(size.y / 1.2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cross_quad_mesh(2, 0.4, 0.6)
	mm.instance_count = maxi(1, rows * 6)
	var idx := 0
	for r in rows:
		for c in 6:
			var t := Transform3D()
			t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			t.origin = Vector3(-size.x * 0.5 + size.x * (float(c) + 0.5) / 6.0,
				0.3, -size.y * 0.5 + 1.2 * float(r))
			if idx < mm.instance_count:
				mm.set_instance_transform(idx, t)
			idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = GameMaterials.get_material("rice_field")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	# Water between the rows.
	plane(root, size, "puddle", Vector3(0, 0.06, 0))
	return root


static func add_distant_hills(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Hills"
	root.position = pos
	parent.add_child(root)
	for i in 5:
		var h := rng.randf_range(9.0, 22.0)
		var r := rng.randf_range(16.0, 34.0)
		var mi := sphere(root, r, "leaf_dark", Vector3(rng.randf_range(-70.0, 70.0), -r * 0.55 + h * 0.15, rng.randf_range(-30.0, 30.0)),
			Vector3(1.0, h / r, 1.0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


static func add_rock_cluster(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Rocks"
	root.position = pos
	parent.add_child(root)
	for i in rng.randi_range(3, 6):
		var r := rng.randf_range(0.2, 0.6)
		var mi := sphere(root, r, "gravel", Vector3(rng.randf_range(-0.8, 0.8), r * 0.5, rng.randf_range(-0.8, 0.8)),
			Vector3(1.0, rng.randf_range(0.5, 0.8), 1.0))
		mi.rotation_degrees = Vector3(0, rng.randf_range(0, 360), 0)
	return root


# ------------------------------------------------------------------ village ---
## Traditional Thai stilt house: raised floor, pitched roof, front veranda.
static func add_stilt_house(parent: Node3D, pos: Vector3, rotation_y: float, scale: float,
		rng: RandomNumberGenerator, with_collision: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "StiltHouse"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	root.scale = Vector3.ONE * scale
	parent.add_child(root)

	var w := 5.0
	var d := 4.0
	var floor_y := 1.2
	# Stilts.
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			cyl(root, 0.12, floor_y, "wood_dark",
				Vector3(sx * (w * 0.5 - 0.3), floor_y * 0.5, sz * (d * 0.5 - 0.3)))
	# Floor and walls.
	box(root, Vector3(w, 0.18, d), "wood", Vector3(0, floor_y, 0))
	box(root, Vector3(w, 1.9, 0.14), "wood_painted", Vector3(0, floor_y + 1.05, -d * 0.5))
	box(root, Vector3(0.14, 1.9, d), "wood_painted", Vector3(-w * 0.5, floor_y + 1.05, 0))
	box(root, Vector3(0.14, 1.9, d), "wood_painted", Vector3(w * 0.5, floor_y + 1.05, 0))
	box(root, Vector3(w * 0.35, 1.9, 0.14), "wood_painted", Vector3(w * 0.28, floor_y + 1.05, -d * 0.5))
	# Windows on the side wall.
	for i in 2:
		box(root, Vector3(0.9, 0.7, 0.06), "glass", Vector3(w * 0.5 + 0.08, floor_y + 1.3, -0.9 + i * 1.8))
	# Pitched roof (two prisms leaning against each other).
	prism(root, Vector3(w + 1.2, 0.9, d * 0.62), "roof_tile", Vector3(0, floor_y + 2.45, -d * 0.25), Vector3(0, 0, 0))
	prism(root, Vector3(w + 1.2, 0.9, d * 0.62), "roof_tile", Vector3(0, floor_y + 2.45, d * 0.25), Vector3(0, 180, 0))
	# Veranda + stairs.
	box(root, Vector3(w, 0.14, 1.6), "wood_light", Vector3(0, floor_y, d * 0.5 + 0.8))
	box(root, Vector3(1.0, 0.2, 1.2), "wood_dark", Vector3(0, floor_y - 0.4, d * 0.5 + 0.9))
	if with_collision:
		add_static_box(root, Vector3(w, 2.4, d), Vector3(0, floor_y + 0.9, 0))
	return root


static func add_pier(parent: Node3D, length: float, pos: Vector3, rotation_y: float,
		rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Pier"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	var planks := int(length / 0.6)
	for i in planks:
		var z := -length * 0.5 + 0.3 + float(i) * 0.6
		var worn: float = rng.randf_range(0.94, 1.06)
		box(root, Vector3(2.0 * worn, 0.12, 0.5), "wood" if i % 3 else "wood_dark", Vector3(0, 1.0, z),
			Vector3(0, rng.randf_range(-2.0, 2.0), 0))
	for i in int(length / 3.0) + 1:
		var z := -length * 0.5 + float(i) * 3.0
		cyl(root, 0.14, 1.1, "wood_dark", Vector3(-0.85, 0.5, z))
		cyl(root, 0.14, 1.1, "wood_dark", Vector3(0.85, 0.5, z))
	# Railings.
	box(root, Vector3(0.1, 0.7, length), "wood_light", Vector3(-0.95, 1.45, 0))
	return root


static func add_fishing_boat(parent: Node3D, pos: Vector3, rotation_y: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Boat"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	# Hull: a prism gives a convincing narrow bow cheaply.
	prism(root, Vector3(1.3, 0.7, 4.2), "wood_light", Vector3(0, 0.25, 0))
	box(root, Vector3(1.5, 0.18, 4.4), "wood_dark", Vector3(0, 0.62, 0))
	box(root, Vector3(1.1, 0.1, 0.5), "wood", Vector3(0, 0.78, -1.6))
	box(root, Vector3(1.1, 0.1, 0.5), "wood", Vector3(0, 0.78, 1.4))
	# Outboard motor.
	box(root, Vector3(0.3, 0.7, 0.3), "painted_metal_green", Vector3(0, 1.0, 2.1))
	cyl(root, 0.05, 0.6, "steel_dull", Vector3(0, 0.5, 2.2))
	# Nets and baskets.
	torus(root, 0.35, "basket", Vector3(0.35, 0.75, 0.6), Vector3(90, 0, 0))
	if rng.randf() < 0.6:
		cyl(root, 0.22, 0.32, "basket", Vector3(-0.35, 0.8, -0.6))
	return root


static func add_fish_basket_tower(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "FishBaskets"
	root.position = pos
	parent.add_child(root)
	var stack := rng.randi_range(2, 4)
	for i in stack:
		var r := 0.4 - float(i) * 0.04
		cyl(root, r, 0.28, "basket", Vector3(rng.randf_range(-0.1, 0.1), 0.14 + float(i) * 0.28, rng.randf_range(-0.1, 0.1)))
	return root


static func add_fish_trap(parent: Node3D, pos: Vector3, rotation_y: float) -> Node3D:
	# A woven cylindrical trap — instantly readable as fishing gear.
	var root := Node3D.new()
	root.name = "FishTrap"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	cyl(root, 0.28, 0.9, "bamboo", Vector3(0, 0.45, 0))
	cyl(root, 0.2, 0.3, "bamboo", Vector3(0, 1.0, 0))
	for i in 6:
		box(root, Vector3(0.02, 0.9, 0.02), "wood_dark", Vector3(cos(TAU * i / 6.0) * 0.28, 0.45, sin(TAU * i / 6.0) * 0.28))
	return root


static func add_net_pole(parent: Node3D, pos: Vector3, rotation_y: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "NetPole"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	cyl(root, 0.07, 3.2, "bamboo", Vector3(0, 1.6, 0))
	var net := MeshInstance3D.new()
	net.mesh = cross_quad_mesh(2, 1.6, 1.4)
	net.material_override = GameMaterials.get_material("basket")
	net.position = Vector3(0.8, 1.5, 0)
	net.rotation_degrees = Vector3(0, 20, 8)
	root.add_child(net)
	return root


static func add_sign_post(parent: Node3D, text: String, pos: Vector3, rotation_y: float,
		board_mat: String = "sign_blue", text_color: Color = Color(1, 1, 1)) -> Node3D:
	var root := Node3D.new()
	root.name = "SignPost"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	cyl(root, 0.06, 2.0, "steel_dull", Vector3(0, 1.0, 0))
	box(root, Vector3(1.5, 0.7, 0.06), board_mat, Vector3(0, 1.9, 0))
	add_label(root, text, Vector3(0, 1.9, 0.05), 0.22, text_color)
	return root


static func add_road_barrier(parent: Node3D, pos: Vector3, rotation_y: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Barrier"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	box(root, Vector3(1.6, 0.18, 0.18), "sign_yellow", Vector3(0, 0.9, 0))
	box(root, Vector3(1.6, 0.18, 0.18), "sign_red", Vector3(0, 0.62, 0))
	cyl(root, 0.05, 1.0, "steel_dull", Vector3(-0.7, 0.5, 0))
	cyl(root, 0.05, 1.0, "steel_dull", Vector3(0.7, 0.5, 0))
	return root


static func add_paper_lantern_string(parent: Node3D, length: float, pos: Vector3, rotation_y: float,
		count: int, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LanternString"
	root.position = pos
	root.rotation_degrees = Vector3(0, rotation_y, 0)
	parent.add_child(root)
	box(root, Vector3(length, 0.03, 0.03), "wood_dark", Vector3(0, 0, 0))
	for i in count:
		var x := -length * 0.5 + length * (float(i) + 0.5) / float(count)
		var sag := sin(PI * (float(i) + 0.5) / float(count)) * 0.35
		var lantern := sphere(root, 0.16, "glow_warm", Vector3(x, -0.35 - sag, 0))
		lantern.material_override = GameMaterials.glow("lantern", Color(1.0, 0.78, 0.42), 2.4)
		var l := OmniLight3D.new()
		l.position = Vector3(x, -0.35 - sag, 0)
		l.light_color = Color(1.0, 0.78, 0.45)
		l.light_energy = 0.9
		l.omni_range = 5.0
		l.shadow_enabled = false
		root.add_child(l)
	return root
