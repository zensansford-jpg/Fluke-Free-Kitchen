class_name InteractiveItem
extends Area3D
## A draggable, tappable object in the kitchen.
##
## It is an `Area3D` with a deliberately generous hit volume: the invisible box is
## `GameConfig.HIT_AREA_PADDING` times larger than the visible mesh, so a child on
## a touchscreen does not have to hit a fish exactly.
##
## The node owns only its own presentation (highlight, pick-up, put-down). All the
## decision-making — which item belongs where — lives in the tasks, so this class
## stays reusable by every interaction.

signal hovered(item: InteractiveItem, entered: bool)
signal picked_up(item: InteractiveItem)
signal dropped(item: InteractiveItem, at: Vector3)

var item_id: String = ""
## Localised display name, e.g. { "en": "Raw fish", "th": "ปลาดิบ" }.
var display_name: Dictionary = {}

var home_position: Vector3 = Vector3.ZERO
var grabbed := false

var _collision: CollisionShape3D
var _halo: MeshInstance3D
var _visual: Node3D
var _highlighted := false
var _lift := 0.0


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = GameConfig.LAYER_INTERACTIVE
	collision_mask = 0
	input_ray_pickable = false


## `hit_size` is the full size of the generously-sized click volume.
func configure(id: String, hit_size: Vector3, name_pair: Dictionary = {}) -> void:
	item_id = id
	display_name = name_pair
	home_position = position

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = hit_size
	shape.shape = box
	if _collision == null:
		_collision = shape
		add_child(_collision)
	else:
		_collision.shape = box
	_collision.position = Vector3(0, hit_size.y * 0.35, 0)


## The visible body of the item is built by the kitchen and handed in here, which
## keeps this class independent of `KitchenProps`.
func set_visual(node: Node3D) -> void:
	_visual = node
	add_child(node)
	_build_halo()


func _build_halo() -> void:
	_halo = MeshInstance3D.new()
	_halo.mesh = PropFactory.unit_cyl()
	_halo.material_override = GameMaterials.glow("pick_halo", Color(1.0, 0.86, 0.42), 1.4)
	_halo.scale = Vector3(0.5, 0.006, 0.5)
	_halo.position = Vector3(0, -0.02, 0)
	_halo.visible = false
	add_child(_halo)


# ------------------------------------------------------------------ behaviour ---
func set_highlighted(on: bool) -> void:
	if _highlighted == on:
		return
	_highlighted = on
	if _halo != null:
		_halo.visible = on or grabbed
	_tween_scale(1.07 if on else 1.0)


## Turns the hit volume on or off. It is switched off while the item is carried so
## that the drop raycast can only ever find containers, never the thing in hand.
func set_pickable(on: bool) -> void:
	if _collision == null:
		return
	_collision.set_deferred("disabled", not on)


## Lifts the item towards the camera plane while it is being carried.
func pick_up() -> void:
	grabbed = true
	set_pickable(false)
	if _halo != null:
		_halo.visible = true
	_lift = 0.16
	_apply_lift()


func release() -> void:
	grabbed = false
	set_pickable(true)
	if _halo != null:
		_halo.visible = _highlighted
	_lift = 0.0
	_apply_lift()


## Moves the carried item so it follows the pointer.
func move_to(world_position: Vector3) -> void:
	position = Vector3(world_position.x, home_position.y, world_position.z)


func return_home(animated: bool = true) -> void:
	if not animated:
		position = home_position
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home_position, 0.28)


func localised_name() -> String:
	return LessonDB.local(display_name)


func _apply_lift() -> void:
	if _visual == null:
		return
	var tween := create_tween()
	tween.tween_property(_visual, "position:y", _lift, 0.12)


func _tween_scale(target: float) -> void:
	if _visual == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "scale", Vector3.ONE * target, 0.14)
