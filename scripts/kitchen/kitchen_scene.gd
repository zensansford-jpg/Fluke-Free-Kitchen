class_name KitchenScene
extends Node3D
## The 3D half of a level: room, bench, camera, and the small helpers the tasks
## use to talk to the world.
##
## The camera never moves, which is what lets the game use big, forgiving targets
## and lets a step be read at a glance. Tasks never poke at meshes directly; they
## ask this class for slots, for what is under the pointer, and for effects.

## Items being dragged are laid out along the front of the bench.
const ITEM_Z := 0.82
## Containers sit further back, so a drag has a direction and does not overlap.
const ZONE_Z := 0.16
## How big the fish in the wok starts out.
const FISH_BASE_SCALE := Vector3(0.82, 0.72, 0.82)

var camera: Camera3D
## Everything a step spawns goes here and is wiped between steps.
var set_root: Node3D
var level: Dictionary = {}

var _decor: Node3D
var _effects: Node3D
var _wok: Node3D = null
var _wok_glow: MeshInstance3D = null
var _wok_heat_material: StandardMaterial3D = null
var _sink: Node3D = null
var _board_anchor := Vector3(-0.45, KitchenProps.BENCH_Y, 0.55)
var _shake := 0.0
var _camera_home := Vector3.ZERO
var _steam_cooldown := 0.0
## The cook who reacts to the player's actions. Lives outside `set_root`, so it
## survives every `clear_set()` between steps.
var _chef: KitchenCharacter = null
## The fish being cooked, and the copies of its material that `set_fish_browning`
## paints. Empty when no fish is in the pan.
var _fish_node: Node3D = null
var _fish_meshes: Array = []


func _ready() -> void:
	_build_environment()
	_build_camera()

	set_root = Node3D.new()
	set_root.name = "SetRoot"
	add_child(set_root)

	_effects = Node3D.new()
	_effects.name = "Effects"
	add_child(_effects)

	_chef = KitchenProps.chef(self, Vector3(-2.35, 0.0, -0.95), 26.0)


## The cook reacts to a real event. `kind` is passed straight to `KitchenCharacter`.
func react(kind: String) -> void:
	if _chef != null and is_instance_valid(_chef):
		_chef.react(kind)


# ------------------------------------------------------------------- life cycle ---
## Builds the permanent dressing for a level. Called once per level, before any
## step runs.
func setup(level_data: Dictionary) -> void:
	level = level_data
	if _decor != null:
		_decor.queue_free()
	_decor = Node3D.new()
	_decor.name = "Decor"
	add_child(_decor)
	move_child(_decor, 0)

	KitchenProps.room(_decor, 1.0)
	KitchenProps.counter(_decor, 6.0, 0.55)

	var index := int(level.get("index", 1))
	match index:
		1:
			_dress_level_one()
		2:
			_dress_level_two()
		_:
			_dress_level_three()


func _dress_level_one() -> void:
	_sink = KitchenProps.sink(_decor, -2.2)
	KitchenProps.vegetable_pile(_decor, Vector3(1.45, KitchenProps.BENCH_Y, 0.35))
	KitchenProps.knife(_decor, Vector3(1.15, KitchenProps.BENCH_Y, 0.75))
	KitchenProps.basket(_decor, Vector3(2.45, KitchenProps.BENCH_Y, 0.3))
	KitchenProps.soap(_decor, Vector3(-1.55, KitchenProps.BENCH_Y, 0.85))
	KitchenProps.cloth(_decor, Vector3(2.9, KitchenProps.BENCH_Y + 0.03, 0.6), "cloth_blue")


# The cooking station. Everything is arranged around one workflow: the board in the
# middle where the fish is cut, staging and seasonings to its left, the pan on its
# own stove to the right with the handle pointing away from the board, and the cloth
# at the far right for wiping down. Nothing is scattered across the bench any more.
func _dress_level_two() -> void:
	_wok = KitchenProps.stove(_decor, 1.55)
	_wok_glow = MeshInstance3D.new()
	_wok_glow.mesh = PropFactory.unit_cyl(20)
	_wok_heat_material = GameMaterials.glow("wok_heat", Color(1.0, 0.42, 0.18), 1.0).duplicate() as StandardMaterial3D
	_wok_glow.material_override = _wok_heat_material
	# Nestled between the coals and the pan, so the glow reads as the fire under the wok.
	_wok_glow.position = Vector3(0, 0.24, 0)
	_wok_glow.scale = Vector3(0.58, 0.02, 0.58)
	_wok_glow.visible = false
	# Parented to the stove so it sits under the wok wherever the stove is.
	_wok.get_parent().add_child(_wok_glow)
	KitchenProps.water_jar(_decor, Vector3(-2.6, KitchenProps.BENCH_Y, 0.30))
	KitchenProps.herb_bunch(_decor, Vector3(-1.8, KitchenProps.BENCH_Y, 0.45))
	KitchenProps.rice_bowl(_decor, Vector3(-1.25, KitchenProps.BENCH_Y, 0.80))
	KitchenProps.cloth(_decor, Vector3(2.5, KitchenProps.BENCH_Y, 0.75), "cloth_blue")


func _dress_level_three() -> void:
	var model := KitchenProps.village_corner(_decor, Vector3(-1.9, KitchenProps.BENCH_Y, 0.5))
	model.scale = Vector3(0.72, 0.72, 0.72)
	KitchenProps.plate(_decor, Vector3(1.0, KitchenProps.BENCH_Y, 0.45))
	KitchenProps.rice_bowl(_decor, Vector3(1.9, KitchenProps.BENCH_Y, 0.35))
	KitchenProps.water_jar(_decor, Vector3(2.6, KitchenProps.BENCH_Y, 0.30))
	KitchenProps.herb_bunch(_decor, Vector3(0.1, KitchenProps.BENCH_Y, 0.85))


## Empties the per-step content.
func clear_set() -> void:
	if set_root == null:
		return
	for child in set_root.get_children():
		child.queue_free()
	# The fish lives under the wok rather than in `set_root`, so it is forgotten
	# explicitly. Otherwise the next step would try to paint a freed mesh.
	_fish_node = null
	_fish_meshes.clear()


# ---------------------------------------------------------------------- anchors ---
## Where an item begins. Front of the bench, spread from left to right. The row is
## centred a little left of the board so the items and the pan never compete for the
## same patch of worktop.
func item_slot(index: int, total: int) -> Vector3:
	return Vector3(_spread(index, total, 1.6) - 0.45, KitchenProps.BENCH_Y, ITEM_Z)


## Where a container is placed. Back of the bench, likewise spread out — and shifted
## left of the stove, so a row of targets never grows into the pan.
func zone_slot(index: int, total: int) -> Vector3:
	return Vector3(_spread(index, total, 1.45) - 0.8, KitchenProps.BENCH_Y, ZONE_Z)


func centre_slot() -> Vector3:
	return _board_anchor


func sink_position() -> Vector3:
	if _sink == null:
		return Vector3(-2.2, KitchenProps.BENCH_Y, 0.2)
	return _sink.global_position + Vector3(0, 0.25, 0)


func wok() -> Node3D:
	return _wok


func wok_world_position() -> Vector3:
	if _wok == null:
		return Vector3(1.55, KitchenProps.BENCH_Y + 0.30, 0.30)
	return _wok.global_position


static func _spread(index: int, total: int, reach: float) -> float:
	if total <= 1:
		return 0.0
	var t := float(index) / float(total - 1)
	return lerpf(-reach, reach, t)


# -------------------------------------------------------------------- raycasting ---
## What is under the pointer. Returns `{ hit, collider, position, normal }`.
##
## `exclude_rids` matters while something is being carried. The piece in the player's
## hand must not be able to hide the container it is being dropped into: a fish is
## taller than the plate's rim, so without this the ray hits the fish and the drop
## silently fails — the player sees the piece over the plate and nothing happens.
func raycast_pointer(screen_position: Vector2, exclude_rids: Array[RID] = []) -> Dictionary:
	if camera == null:
		return {"hit": false}
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * GameConfig.RAY_LENGTH)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = GameConfig.LAYER_INTERACTIVE
	if not exclude_rids.is_empty():
		query.exclude = exclude_rids
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return {"hit": false}
	result["hit"] = true
	return result


## The point on an imaginary horizontal plane that the pointer is aiming at.
func pointer_on_plane(screen_position: Vector2, plane_y: float) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.0001:
		return origin
	var distance := (plane_y - origin.y) / direction.y
	return origin + direction * distance


## Projects a world point to screen pixels. Used to place 2D hints over 3D props.
func world_to_screen(world_position: Vector3) -> Vector2:
	if camera == null:
		return Vector2.ZERO
	if camera.is_position_behind(world_position):
		return Vector2(-1000, -1000)
	return camera.unproject_position(world_position)


# ----------------------------------------------------------------------- cooking ---
## Adds the fish to the wok and returns it, so the cooking task has something to
## heat. Safe to call twice; the previous fish is removed first.
func place_fish_in_wok() -> Node3D:
	if _wok == null:
		return null
	for child in _wok.get_children():
		if child.name == "CookingFish":
			child.queue_free()
	var fish := KitchenProps.visual_for("raw_fish")
	fish.name = "CookingFish"
	# Laid into the pan's cavity (the wok's origin is its rim), so the fish rests in
	# the wok instead of standing on top of it.
	fish.position = Vector3(0, -0.10, 0)
	fish.scale = FISH_BASE_SCALE
	_wok.add_child(fish)
	_fish_node = fish
	_collect_fish_meshes(fish)
	set_fish_browning(0.0)
	return fish


## Finds the surfaces that cook, and gives each its own copy of the material.
##
## The copy matters: `GameMaterials` hands out shared instances, so tinting one
## without duplicating would repaint every raw fish in the game — including the one
## on the drying rack and the ones swimming in the pond.
func _collect_fish_meshes(fish: Node3D) -> void:
	_fish_meshes.clear()
	for child in fish.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).has_meta("food_surface"):
			var mesh := child as MeshInstance3D
			var material := mesh.material_override as StandardMaterial3D
			if material == null:
				continue
			var copy := material.duplicate() as StandardMaterial3D
			mesh.material_override = copy
			_fish_meshes.append(mesh)


## Paints the fish in the wok according to how far cooking has gone.
##
## `browning` is a pure input: calling this with the same value always produces the
## same fish, so the look never drifts. 0 is raw, ~0.85 is golden and cooked
## through, and `GameConfig.COOK_BURNT_AT` is burnt. Colour is presentation only —
## it is never read back to decide safety.
func set_fish_browning(browning: float) -> void:
	var amount := maxf(0.0, browning)
	var colour := _browning_colour(amount)
	var roughness := lerpf(0.35, 0.88, clampf(amount / GameConfig.COOK_BURNT_AT, 0.0, 1.0))
	for mesh in _fish_meshes:
		if not is_instance_valid(mesh):
			continue
		var material := (mesh as MeshInstance3D).material_override as StandardMaterial3D
		if material == null:
			continue
		material.albedo_color = colour
		material.roughness = roughness
	# Meat shrinks a little as it cooks; the fish visibly tightens in the pan.
	if _fish_node != null and is_instance_valid(_fish_node):
		var shrink := lerpf(1.0, 0.9, clampf(amount / GameConfig.COOK_BURNT_AT, 0.0, 1.0))
		_fish_node.scale = Vector3(
			FISH_BASE_SCALE.x, FISH_BASE_SCALE.y * shrink, FISH_BASE_SCALE.z)


## The five colour stops of the browning ramp: raw, opaque, golden, deep brown,
## burnt. Positions are in the same units as `browning`.
const BROWN_STOPS := [0.0, 0.30, 0.78, 1.06, 1.35]
const BROWN_COLOURS := [
	Color(0.86, 0.62, 0.58),
	Color(0.91, 0.79, 0.64),
	Color(0.80, 0.54, 0.22),
	Color(0.50, 0.29, 0.14),
	Color(0.16, 0.12, 0.10),
]


static func _browning_colour(amount: float) -> Color:
	if amount <= float(BROWN_STOPS[0]):
		return BROWN_COLOURS[0]
	for i in range(1, BROWN_STOPS.size()):
		if amount <= float(BROWN_STOPS[i]):
			var low := float(BROWN_STOPS[i - 1])
			var high := float(BROWN_STOPS[i])
			return (BROWN_COLOURS[i - 1] as Color).lerp(
				BROWN_COLOURS[i] as Color, (amount - low) / maxf(0.0001, high - low))
	return BROWN_COLOURS[BROWN_COLOURS.size() - 1]


## Glows under the wok, from 0 (cold) to 1 (raging).
func set_wok_heat(amount: float) -> void:
	if _wok_glow == null or _wok_heat_material == null:
		return
	var value := clampf(amount, 0.0, 1.0)
	_wok_glow.visible = value > 0.03
	_wok_heat_material.emission_energy_multiplier = 0.15 + value * 3.2


# ----------------------------------------------------------------------- effects ---
## Short, readable feedback. Nothing here changes state; it is pure presentation.
func play_effect(kind: String, at: Vector3 = Vector3.ZERO) -> void:
	match kind:
		"steam":
			_puff(6, at, Color(0.92, 0.94, 0.96, 0.42), 0.16, 0.55, true)
		"splash":
			_puff(12, at, Color(0.55, 0.78, 0.90, 0.80), 0.30, 0.34, false)
		"clean":
			_puff(10, at, Color(1.0, 1.0, 1.0, 0.68), 0.34, 0.30, false)
		"sparkle":
			_puff(14, at, Color(1.0, 0.88, 0.42, 0.95), 0.44, 0.75, false)
		"poof":
			_puff(9, at, Color(0.78, 0.70, 0.58, 0.55), 0.30, 0.36, false)
		"smoke":
			_puff(16, at, Color(0.22, 0.20, 0.19, 0.62), 0.34, 0.85, true)
		_:
			_puff(6, at, Color(1.0, 1.0, 1.0, 0.6), 0.25, 0.35, false)


func _puff(count: int, at: Vector3, colour: Color, spread: float, rise: float, soft: bool) -> void:
	if _effects == null:
		return
	var material: StandardMaterial3D
	if soft:
		material = StandardMaterial3D.new()
		material.albedo_color = colour
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		material = StandardMaterial3D.new()
		material.albedo_color = colour
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = 1.6

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var bit := MeshInstance3D.new()
		bit.mesh = PropFactory.unit_sphere()
		bit.material_override = material
		var size := rng.randf_range(0.018, 0.05)
		bit.scale = Vector3.ONE * size
		bit.position = at + Vector3(rng.randf_range(-spread, spread) * 0.3, 0.0, rng.randf_range(-spread, spread) * 0.3)
		_effects.add_child(bit)
		var target := bit.position + Vector3(
			rng.randf_range(-spread, spread),
			rise * rng.randf_range(0.6, 1.4),
			rng.randf_range(-spread, spread) * 0.5)
		Anim.drift_away(bit, target, rng.randf_range(0.45, 0.85))


## A small camera nudge, used when something goes wrong. Never motion-sickness
## sized, and it decays on its own.
func shake(amount: float = 0.06) -> void:
	_shake = maxf(_shake, amount)


# ------------------------------------------------------------------------ camera ---
## The world-space box the camera must keep on screen. The counter is six metres
## wide, so on a tall portrait window a fixed camera would crop the wok and the
## sink away; these are the half-extents that must stay visible at any aspect.
const FRAME_HALF_WIDTH := 2.6
const FRAME_HALF_HEIGHT := 1.6


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "KitchenCamera"
	camera.fov = GameConfig.CAMERA_FOV
	camera.current = true
	add_child(camera)
	apply_layout()


## Frames the bench for the current window shape.
##
## The camera keeps its fixed angle but moves straight back along its own view
## direction until the required world box fits. On a 16:9 window that distance is
## the authored one, so the desktop framing is unchanged; on a portrait phone it
## pulls back so the whole working area stays visible instead of being cropped.
func apply_layout() -> void:
	if camera == null:
		return
	var vp := UIFactory.viewport_size()
	var aspect := vp.x / maxf(1.0, vp.y)
	var half_tan := maxf(0.05, tan(deg_to_rad(camera.fov * 0.5)))
	var look := GameConfig.CAMERA_LOOK_AT
	var base := GameConfig.CAMERA_POSITION
	var base_distance := base.distance_to(look)
	var need_width := FRAME_HALF_WIDTH / maxf(0.05, half_tan * aspect)
	var need_height := FRAME_HALF_HEIGHT / half_tan
	var distance := maxf(base_distance, maxf(need_width, need_height))
	_camera_home = look + (base - look).normalized() * distance
	camera.position = _camera_home
	camera.look_at(look, Vector3.UP)


func _process(delta: float) -> void:
	_steam_cooldown = maxf(0.0, _steam_cooldown - delta)
	if _shake > 0.001 and camera != null:
		_shake = maxf(0.0, _shake - delta * 0.35)
		camera.position = _camera_home + Vector3(
			randf_range(-_shake, _shake),
			randf_range(-_shake, _shake) * 0.6,
			randf_range(-_shake, _shake))
	elif camera != null and camera.position != _camera_home:
		camera.position = _camera_home


## Throttled steam, so a cooking step can call it every frame without spawning a
## particle system per frame.
func puff_steam(at: Vector3, interval: float = 0.22) -> void:
	if _steam_cooldown > 0.0:
		return
	_steam_cooldown = interval
	play_effect("steam", at)


# ------------------------------------------------------------------- environment ---
func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.10, 0.09, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.56, 0.48)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.08
	environment.ssao_enabled = false
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "WarmSun"
	sun.light_color = Color(1.0, 0.90, 0.74)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-46.0, -38.0, 0.0)
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.62, 0.72, 0.85)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-24.0, 132.0, 0.0)
	add_child(fill)
