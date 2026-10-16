class_name DragToTask
extends KitchenTask
## Drag each ingredient into the correct container.
##
## This is the interaction that carries the strongest food-safety message in the
## game — keeping raw fish away from food that will be eaten as it is — so it is
## also the one that must be the most forgiving. The hit volumes are large, the
## containers are labelled in 3D, and putting something in the wrong place costs
## nothing except a sentence explaining why.

var _items: Array[InteractiveItem] = []
var _zones: Dictionary = {}
## item id -> the zone id it belongs in
var _wanted: Dictionary = {}
var _placed: Array[String] = []
var _carried: InteractiveItem = null
var _hover: DropZone = null
var _ghost: GhostPointer = null
var _active := false


func begin() -> void:
	_wanted.clear()
	for entry in step.get("items", []):
		var item: Dictionary = entry
		_wanted[str(item.get("id", ""))] = str(item.get("target", ""))

	build_prompt_bar(gesture_hint_for("drag_to"))
	_spawn_containers()
	_spawn_items()

	_ghost = GhostPointer.new()
	add_child(_ghost)

	if bool(step.get("demo", false)):
		_play_demo()
		run_demo_then(_enable, 2.8)
	else:
		_enable()


func _enable() -> void:
	_active = true


## Re-plays the drag demonstration on request.
func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.6)


func abort() -> void:
	_active = false
	if _carried != null:
		_carried.release()
		_carried = null


# --------------------------------------------------------------------- the set ---
func _spawn_containers() -> void:
	var targets: Array = step.get("targets", [])
	for i in targets.size():
		var entry: Dictionary = targets[i]
		var zone_id := str(entry.get("id", ""))
		var hit := Vector3(1.3, 0.5, 1.0)

		var zone := DropZone.new()
		zone.name = "Zone_" + zone_id
		kitchen.set_root.add_child(zone)
		zone.position = kitchen.zone_slot(i, targets.size())
		zone.configure(zone_id, hit, entry.get("label", {}))
		zone.set_visual()
		zone.fit_visual_to(hit)
		var prop := KitchenProps.zone_prop(zone_id)
		if prop != null:
			zone.add_child(prop)
		_zones[zone_id] = zone


func _spawn_items() -> void:
	var items: Array = step.get("items", [])
	for i in items.size():
		var entry: Dictionary = items[i]
		var item_id := str(entry.get("id", ""))

		var item := InteractiveItem.new()
		item.name = "Item_" + item_id
		kitchen.set_root.add_child(item)
		item.position = kitchen.item_slot(i, items.size())
		item.set_visual(KitchenProps.visual_for(item_id))
		item.configure(item_id, _hit_size_for(item_id), entry.get("label", {}))
		KitchenProps.floating_label(item, Vector3(0, 0.46, 0), item.localised_name(), Color(1.0, 0.94, 0.78))
		_items.append(item)


static func _hit_size_for(item_id: String) -> Vector3:
	if item_id.contains("fish"):
		return Vector3(1.05, 0.55, 0.75)
	if item_id.contains("board") or item_id.contains("juice"):
		return Vector3(1.15, 0.5, 0.9)
	return Vector3(0.85, 0.6, 0.85)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(screen_position: Vector2) -> void:
	if not _active or settled or _carried != null:
		return
	var hit := kitchen.raycast_pointer(screen_position)
	if not hit.get("hit", false):
		return
	var collider: Variant = hit.get("collider")
	if collider is InteractiveItem and _items.has(collider):
		_carried = collider
		_carried.pick_up()
		AudioManager.play_sfx("pop")


func pointer_moved(screen_position: Vector2) -> void:
	if not _active or settled:
		return
	if _carried == null:
		_set_hover(_zone_under(screen_position))
		return
	var point := kitchen.pointer_on_plane(screen_position, _carried.home_position.y)
	_carried.move_to(point)
	_set_hover(_zone_under(screen_position))


func pointer_released(screen_position: Vector2) -> void:
	if _carried == null:
		return
	var item := _carried
	_carried = null
	var zone := _zone_under(screen_position)
	_set_hover(null)

	if zone == null:
		# Dropping on the bench is not a mistake; the item simply goes back.
		item.release()
		item.return_home()
		return

	if zone.zone_id == str(_wanted.get(item.item_id, "")):
		_accept(item, zone)
	else:
		_reject(item, zone)


func _zone_under(screen_position: Vector2) -> DropZone:
	var hit := kitchen.raycast_pointer(screen_position)
	if not hit.get("hit", false):
		return null
	var collider: Variant = hit.get("collider")
	if collider is DropZone:
		return collider
	return null


func _set_hover(zone: DropZone) -> void:
	if _hover == zone:
		return
	if _hover != null:
		_hover.set_highlighted(false)
	_hover = zone
	if _hover != null:
		_hover.set_highlighted(true)


# --------------------------------------------------------------------- outcomes ---
func _accept(item: InteractiveItem, zone: DropZone) -> void:
	item.release()
	item.set_pickable(false)
	var target := zone.position + Vector3(0, 0.14, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "position", target, 0.22)

	if not _placed.has(item.item_id):
		_placed.append(item.item_id)
	register_attempt()
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("sparkle", zone.global_position + Vector3(0, 0.25, 0))

	if _placed.size() >= _items.size():
		await get_tree().create_timer(0.5).timeout
		succeed()


func _reject(item: InteractiveItem, zone: DropZone) -> void:
	AudioManager.play_sfx("tap_bad")
	kitchen.shake(0.05)
	item.release()
	item.return_home()

	var reason_key := "keep_raw_apart" if _wanted.get(item.item_id, "") == "raw_tray" or _wanted.get(item.item_id, "") == "raw_board" else "ready_apart"
	show_reason(Loc.t("feedback.%s" % reason_key))
	register_mistake({"id": item.item_id, "why": {}}, {"key": reason_key, "text": Loc.t("feedback.%s" % reason_key)})


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	# The camera needs one frame before world_to_screen is meaningful.
	await get_tree().process_frame
	if not is_inside_tree() or _items.is_empty():
		return
	var item := _items[0]
	var zone := _zones.get(str(_wanted.get(item.item_id, ""))) as DropZone
	if zone == null:
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0 or viewport.y <= 1.0:
		return
	var from := kitchen.world_to_screen(item.global_position + Vector3(0, 0.2, 0)) / viewport
	var to := kitchen.world_to_screen(zone.global_position + Vector3(0, 0.2, 0)) / viewport
	if from.x < 0.0 or to.x < 0.0:
		from = Vector2(0.42, 0.72)
		to = Vector2(0.58, 0.40)
	_ghost.play([from, to])
