class_name PlateTask
extends KitchenTask
## Plate the dish: drag the fish and the garnishes onto the plate, where they snap
## into place.
##
## Every piece snaps to a free spot rather than landing on a pixel, so the
## presentation is always tidy enough to look deliberate. Nothing is lost by
## dropping a piece on the bench — it simply goes back — and there is no way to
## "fail" plating, only to leave things off.

const PLATE_POS := Vector3(0.0, KitchenProps.BENCH_Y, 0.28)
## Radius of the little circle of spots on the plate.
const SLOT_RADIUS := 0.20

var _plate: DropZone = null
var _items: Array[InteractiveItem] = []
var _main: InteractiveItem = null
var _carried: InteractiveItem = null
var _hover: DropZone = null
var _slots: Array = []
var _placed := 0
var _counter: Label = null
var _ghost: GhostPointer = null
var _active := false


func begin() -> void:
	build_prompt_bar(gesture_hint_for("plate"))
	_spawn_plate()
	_spawn_items()
	_build_panel()

	_ghost = GhostPointer.new()
	add_child(_ghost)
	if bool(step.get("demo", true)):
		_play_demo()
		run_demo_then(_enable, 2.4)
	else:
		_enable()


func _enable() -> void:
	_active = true


## Input is only accepted once the demonstration has finished, so nothing is asked
## of the player before they have seen what to do.
func is_accepting_input() -> bool:
	return _active and not settled


func abort() -> void:
	_active = false
	if _carried != null:
		_carried.release()
		_carried = null


func replay_demo() -> void:
	_play_demo()
	run_demo_then(Callable(), 1.3)


# --------------------------------------------------------------------- the set ---
func _spawn_plate() -> void:
	_plate = DropZone.new()
	_plate.name = "Plate"
	kitchen.set_root.add_child(_plate)
	_plate.position = PLATE_POS
	var hit := Vector3(0.74, 0.36, 0.74)
	_plate.configure("plate", hit, {"en": "Plate", "th": "จาน"})
	_plate.set_visual()
	_plate.fit_visual_to(hit)
	var prop := KitchenProps.zone_prop("ready_plate")
	if prop != null:
		_plate.add_child(prop)

	var all: Array = _all_items()
	_slots.clear()
	for i in all.size():
		var a := TAU * float(i) / float(maxi(1, all.size()))
		_slots.append(PLATE_POS + Vector3(cos(a) * SLOT_RADIUS, 0.07, sin(a) * SLOT_RADIUS))


func _all_items() -> Array:
	var out: Array = []
	var main: Variant = step.get("main", {})
	if typeof(main) == TYPE_DICTIONARY and not (main as Dictionary).is_empty():
		out.append(main)
	for entry in step.get("garnish", []):
		out.append(entry)
	return out


func _spawn_items() -> void:
	var all := _all_items()
	for i in all.size():
		var entry: Dictionary = all[i]
		var item_id := str(entry.get("id", ""))
		var item := InteractiveItem.new()
		item.name = "Item_" + item_id
		kitchen.set_root.add_child(item)
		item.position = kitchen.item_slot(i, all.size())
		item.set_visual(_visual_for(item_id))
		item.configure(item_id, Vector3(0.62, 0.52, 0.62), entry.get("label", {}))
		KitchenProps.floating_label(item, Vector3(0, 0.32, 0), item.localised_name(), Color(1.0, 0.94, 0.78))
		_items.append(item)
		if i == 0:
			_main = item


func _visual_for(item_id: String) -> Node3D:
	if item_id == "fish":
		return KitchenProps.visual_for("cooked_fish")
	return _garnish_visual(item_id)


## A small, recognisable garnish made from a few tinted slivers. Built here rather
## than in `KitchenProps` because the colour comes from the catalogue.
func _garnish_visual(item_id: String) -> Node3D:
	var spec := RecipeDB.garnish_by_id(item_id)
	var node := Node3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.7, 0.4)
	if not spec.is_empty():
		material.albedo_color = spec.get("colour", material.albedo_color)
	for i in 3:
		var sliver := MeshInstance3D.new()
		sliver.mesh = PropFactory.unit_box()
		sliver.material_override = material
		sliver.scale = Vector3(0.11, 0.03, 0.05)
		sliver.position = Vector3(0.06 * float(i) - 0.06, 0.02 * float(i), 0.02 * float(i))
		sliver.rotation_degrees = Vector3(0, 24.0 * float(i), 12.0)
		node.add_child(sliver)
	return node


func _build_panel() -> void:
	var panel := UIFactory.panel(UIFactory.CARD_COLOR)
	UIFactory.bottom_box(panel, 420.0, 120.0, -330.0)
	remember_box(panel, 420.0, 120.0, -330.0)
	var v := UIFactory.vbox(8)
	panel.add_child(v)
	v.add_child(UIFactory.label(Loc.t("task.plate"), 19, UIFactory.ACCENT, true))
	_counter = UIFactory.label("%d/%d" % [0, _items.size()], 24, UIFactory.TEXT_BRIGHT, true)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_counter)
	add_child(panel)


# ------------------------------------------------------------------ interaction ---
func pointer_pressed(screen_position: Vector2) -> void:
	if not _active or settled or _carried != null:
		return
	var hit := kitchen.raycast_pointer(screen_position)
	if not bool(hit.get("hit", false)):
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
	_set_hover(_zone_under(screen_position, _carried))


func pointer_released(screen_position: Vector2) -> void:
	if _carried == null:
		return
	var item := _carried
	_carried = null
	var zone := _zone_under(screen_position, item)
	_set_hover(null)
	if zone == _plate:
		_snap(item)
	else:
		item.release()
		item.return_home()


## Which container is under the pointer. The piece being carried is excluded, so a
## big fish can never sit between the camera and the plate and swallow its own drop.
func _zone_under(screen_position: Vector2, ignore: Node3D = null) -> DropZone:
	var exclude: Array[RID] = []
	if ignore != null and is_instance_valid(ignore) and ignore is Area3D:
		exclude.append((ignore as Area3D).get_rid())
	var hit := kitchen.raycast_pointer(screen_position, exclude)
	if not bool(hit.get("hit", false)):
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


func _snap(item: InteractiveItem) -> void:
	item.release()
	item.set_pickable(false)
	var slot: Vector3 = _slots[mini(_placed, _slots.size() - 1)] if not _slots.is_empty() else _plate.position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "position", slot, 0.26)

	_placed += 1
	register_attempt()
	AudioManager.play_sfx("tap_ok")
	kitchen.play_effect("sparkle", slot + Vector3(0, 0.12, 0))
	if _counter != null:
		_counter.text = "%d/%d" % [_placed, _items.size()]

	if _placed >= _items.size():
		_finish()


func _finish() -> void:
	if settled:
		return
	_active = false
	AudioManager.play_sfx("star_full")
	kitchen.play_effect("sparkle", PLATE_POS + Vector3(0, 0.4, 0))
	flash_message(Loc.t("feedback.plated"), UIFactory.GOOD)
	await get_tree().create_timer(0.55, false).timeout
	succeed()


# ------------------------------------------------------------------------ demo ---
func _play_demo() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or _items.is_empty():
		return
	var viewport := get_viewport_rect().size
	if viewport.x <= 1.0:
		return
	var item := _items[0]
	var from := kitchen.world_to_screen(item.global_position + Vector3(0, 0.2, 0)) / viewport
	var to := kitchen.world_to_screen(PLATE_POS + Vector3(0, 0.2, 0)) / viewport
	if from.x < 0.0 or to.x < 0.0:
		from = Vector2(0.42, 0.74)
		to = Vector2(0.5, 0.52)
	_ghost.play([from, to])
