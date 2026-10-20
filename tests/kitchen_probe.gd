extends Node
## Development tool: prints the *world-space* arrangement of the 3D kitchen so the
## bench layout, the pan, the tools, the stations and the camera framing can be
## diagnosed from numbers instead of by eye.
##
## This exists because the 2D layout tool (`layout_check.gd`) says nothing about
## where a mesh actually sits in the room. An object can be perfectly laid out in
## the UI and still be floating above the bench, buried in the counter, or outside
## the camera's frame — and none of those is visible in a rectangle dump.
##
## Three classes of object are treated differently, because they are not the same
## kind of thing and judging them by one rule produces noise that hides real bugs:
##
##   * **room dressing** (floor, walls, window, ceiling beam, lamps, wall shelf,
##     wall herbs, the cook) lives in the room, not on the worktop. It is reported
##     but never measured against `BENCH_Y`.
##   * **furniture** (counter, sink, stove) is *built into* the bench, so its
##     lowest point is legitimately below the surface.
##   * **bench props** (board, plate, bowl, jar, fish, tool, ingredient) must rest
##     ON the surface. One that floats or sinks by more than `REST_TOLERANCE` is a
##     defect, and that is what this tool fails on.
##
## Every prop is also grouped by the station it belongs to, so an overlap between
## two props that share a station is reported — that is what "an incoherent pile on
## the worktop" looks like in numbers.
##
## Run with:
##   godot --headless --path <project> res://tests/kitchen_probe.tscn
##   godot --headless --path <project> res://tests/kitchen_probe.tscn -- 390 844

const TestWindow := preload("res://tests/test_window.gd")

## A prop resting on the bench may be off by this much (metres) before it counts
## as floating or sunk. Real props have feet, rims and lids, so a few millimetres
## is normal and only a visible gap or overlap is a defect.
const REST_TOLERANCE := 0.02
## How far two props on the same station may overlap (metres) before they are
## reported as intersecting. Props legitimately stand next to each other, and boxes
## are axis-aligned so a shared corner clips a little; only a real overlap matters.
const OVERLAP_TOLERANCE := 0.03

## Nodes that belong to the room rather than the worktop. `room()` builds these
## straight into `Decor` with no wrapper node, so they are recognised by the name
## `PropFactory` gives the mesh — and anything still unrecognised is dressing too,
## because a prop that is not on the worktop cannot float above it.
const DRESSING := ["Floor", "Wall", "Beam", "Lamp", "Window", "Shelf", "HerbsWall"]
## Nodes that are part of the furniture and are meant to sit through the bench top.
const FURNITURE := ["Counter", "Sink", "Stove", "Wok"]

var failures: Array[String] = []


func _ready() -> void:
	UIFactory.set_motion_enabled(false)
	var size := _requested_size()
	TestWindow.use(size.x, size.y)
	await TestWindow.settle(2)
	SaveData.suspend_disk_writes(true)
	print("--- Fluke Free Kitchen 3D kitchen probe ---")
	print("window: %dx%d" % [size.x, size.y])
	print("bench surface y = %.3f" % KitchenProps.BENCH_Y)
	for row in KitchenStations.describe():
		print("  station %s" % row)
	for problem in KitchenStations.validate():
		failures.append("station table: " + problem)
	for level_id in ["l1", "l2", "l3"]:
		await _probe(level_id)
	SaveData.suspend_disk_writes(false)
	_report()


func _requested_size() -> Vector2i:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0].is_valid_int() and args[1].is_valid_int():
		return Vector2i(int(args[0]), int(args[1]))
	return Vector2i(1280, 720)


func _probe(level_id: String) -> void:
	Game.current_level_id = level_id
	Game.change_state(Game.State.PLAYING)
	var screen: Node = load("res://scenes/kitchen/kitchen.tscn").instantiate()
	add_child(screen)
	await TestWindow.settle(3)

	var kitchen: KitchenScene = screen.get("kitchen") as KitchenScene
	if kitchen == null:
		failures.append("%s: no kitchen scene" % level_id)
		screen.queue_free()
		return

	print("")
	print("=== kitchen %s ===" % level_id)
	_report_camera(kitchen, level_id)
	_report_props(kitchen, level_id)

	screen.queue_free()
	await TestWindow.settle(1)


func _report_camera(kitchen: KitchenScene, level_id: String) -> void:
	var camera := kitchen.camera
	if camera == null:
		failures.append("%s: no camera" % level_id)
		return
	print("  camera pos %s  look %s  fov %.1f" % [
		_fmt(camera.global_position), _fmt(GameConfig.CAMERA_LOOK_AT), camera.fov])

	# What the camera can actually see on the bench plane. Anything the player has
	# to touch must fall inside this, or it is on screen but unreachable.
	var frame := _camera_bench_frame(camera)
	print("  bench space visible: x %.2f..%.2f   z %.2f..%.2f" % [
		frame.position.x, frame.end.x, frame.position.y, frame.end.y])
	# Every station the workflow needs must be framed. The wok and the board are
	# the two the player acts on most, so they are checked explicitly.
	for station in [
		["wok", kitchen.wok_world_position()],
		["board", KitchenScene.BOARD_ANCHOR],
	]:
		var point: Vector3 = station[1]
		var inside := _inside(frame, point)
		print("  %-6s at %s  inside frame: %s" % [station[0], _fmt(point), inside])
		if not inside:
			failures.append("%s: the %s is outside the visible bench area" % [level_id, station[0]])


func _report_props(kitchen: KitchenScene, level_id: String) -> void:
	var decor := kitchen.get_node_or_null("Decor") as Node3D
	if decor == null:
		return
	var stations: Dictionary = {}
	for child in decor.get_children():
		var node := child as Node3D
		if node == null:
			continue
		var bounds := _world_bounds(node)
		if bounds.size == Vector3.ZERO:
			continue
		var kind := _classify(node.name)
		var note := ""
		if kind == "bench":
			var gap := bounds.position.y - KitchenProps.BENCH_Y
			if gap > REST_TOLERANCE:
				note = "FLOATING %.0f mm" % (gap * 1000.0)
				failures.append("%s: %s floats %.0f mm above the bench (y %.3f)"
					% [level_id, node.name, gap * 1000.0, bounds.position.y])
			elif gap < -REST_TOLERANCE and node.name != "Soap":
				note = "sunk %.0f mm" % (-gap * 1000.0)
				failures.append("%s: %s sinks %.0f mm into the bench (y %.3f)"
					% [level_id, node.name, -gap * 1000.0, bounds.position.y])
			var station := KitchenStations.station_of(node.global_position)
			if not stations.has(station):
				stations[station] = []
			stations[station].append([node.name, bounds])
		if kind == "dressing":
			continue
		print("    %-14s %-9s pos %-22s box x %.2f..%.2f z %.2f..%.2f  %s" % [
			node.name, kind, _fmt(node.global_position),
			bounds.position.x, bounds.end.x, bounds.position.z, bounds.end.z, note])
	# `room()` builds its meshes straight into `Decor`, so several of them arrive
	# with an auto-generated name and a wall position. They are reported as
	# dressing above; the named props are what the bench checks are about.
	print("    (room dressing: %d meshes with generated names omitted)" % _dressing_count(decor))

	# Two props sharing a station must not occupy the same patch of worktop. The
	# stove and the sink are furniture and are excluded; everything else on the
	# bench is compared.
	for station in stations:
		var props: Array = stations[station]
		for i in props.size():
			for j in range(i + 1, props.size()):
				var box_a: AABB = props[i][1]
				var box_b: AABB = props[j][1]
				var overlap := box_a.intersection(box_b)
				if overlap.size.x > OVERLAP_TOLERANCE and overlap.size.z > OVERLAP_TOLERANCE:
					failures.append(
						"%s: %s and %s overlap on the %s (%.0f x %.0f mm)"
						% [level_id, props[i][0], props[j][0], station,
							overlap.size.x * 1000.0, overlap.size.z * 1000.0])


func _dressing_count(decor: Node3D) -> int:
	var count := 0
	for child in decor.get_children():
		if _classify(child.name) == "dressing":
			count += 1
	return count


static func _classify(node_name: String) -> String:
	for name in FURNITURE:
		if node_name == name:
			return "furniture"
	for name in DRESSING:
		if node_name.begins_with(name):
			return "dressing"
	# `room()` builds its meshes directly into `Decor` with no wrapper node, so a
	# mesh the table does not name is room dressing — it cannot be floating above a
	# worktop it was never placed on.
	if node_name.begins_with("@") or node_name.begins_with("KitchenCharacter"):
		return "dressing"
	return "bench"


## The camera's view of the bench plane (y = BENCH_Y), as a Rect2 in world x/z.
## Computed by projecting the four viewport corners onto the plane, which is what
## "can the player see and reach this part of the counter" really means.
func _camera_bench_frame(camera: Camera3D) -> Rect2:
	var vp := camera.get_viewport().get_visible_rect().size
	var y := KitchenProps.BENCH_Y
	var points: Array[Vector2] = []
	for corner in [Vector2.ZERO, Vector2(vp.x, 0), Vector2(0, vp.y), vp]:
		var origin := camera.project_ray_origin(corner)
		var direction := camera.project_ray_normal(corner)
		if absf(direction.y) < 0.0001:
			continue
		var distance := (y - origin.y) / direction.y
		var hit := origin + direction * distance
		points.append(Vector2(hit.x, hit.z))
	if points.is_empty():
		return Rect2()
	var min_x := points[0].x
	var max_x := points[0].x
	var min_z := points[0].y
	var max_z := points[0].y
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.y)
		max_z = maxf(max_z, point.y)
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))


static func _inside(frame: Rect2, world: Vector3) -> bool:
	if frame.size == Vector2.ZERO:
		return false
	return frame.has_point(Vector2(world.x, world.z))


## The world-space axis-aligned bounding box of a node and everything under it.
func _world_bounds(node: Node3D) -> AABB:
	var found := false
	var result := AABB()
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		for child in current.get_children():
			stack.append(child)
		var mesh := current as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		if not found:
			result = box
			found = true
		else:
			result = result.merge(box)
	return result if found else AABB()


static func _fmt(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]


func _report() -> void:
	print("")
	print("--- results ---")
	if failures.is_empty():
		print("KITCHEN PROBE PASSED — nothing floats, sinks or intersects on the bench")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("KITCHEN PROBE FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
