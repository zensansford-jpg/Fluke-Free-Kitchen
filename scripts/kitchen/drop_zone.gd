class_name DropZone
extends Area3D
## A place in the kitchen where something can be put down: a tray, a plate, a
## board, the bin.
##
## Like `InteractiveItem` it only knows how to look and how to report itself; the
## task decides whether the thing that has just been dropped on it is the right
## thing.

signal entered(zone: DropZone)
signal exited(zone: DropZone)

var zone_id: String = ""
var display_name: Dictionary = {}

var _collision: CollisionShape3D
var _outline: MeshInstance3D
var _label: Label3D
var _highlighted := false


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = GameConfig.LAYER_INTERACTIVE
	collision_mask = 0
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func configure(id: String, hit_size: Vector3, name_pair: Dictionary = {}) -> void:
	zone_id = id
	display_name = name_pair

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = hit_size
	shape.shape = box
	shape.position = Vector3(0, hit_size.y * 0.5, 0)
	if _collision == null:
		_collision = shape
		add_child(_collision)
	else:
		_collision.shape = box


## Draws a soft plate that shows the player where things may go.
func set_visual(colour: Color = Color(0.95, 0.88, 0.62, 0.30)) -> void:
	var plate := MeshInstance3D.new()
	plate.mesh = PropFactory.unit_box()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = colour
	mat.emission_energy_multiplier = 0.4
	plate.material_override = mat
	plate.scale = Vector3(0.01, 0.01, 0.01)
	plate.name = "Plate"
	add_child(plate)

	_outline = MeshInstance3D.new()
	_outline.mesh = PropFactory.unit_box()
	_outline.material_override = GameMaterials.glow("zone_outline", Color(1.0, 0.9, 0.55), 1.2)
	_outline.scale = Vector3(0.01, 0.01, 0.01)
	_outline.visible = false
	_outline.name = "Outline"
	add_child(_outline)


## Sizes the visible plate to match the hit volume and adds a small floating name.
func fit_visual_to(hit_size: Vector3) -> void:
	var plate := get_node_or_null("Plate") as MeshInstance3D
	if plate != null:
		plate.scale = Vector3(hit_size.x * 0.94, 0.02, hit_size.z * 0.94)
		plate.position = Vector3(0, 0.01, 0)
	if _outline != null:
		_outline.scale = Vector3(hit_size.x, 0.012, hit_size.z)
		_outline.position = Vector3(0, 0.02, 0)
	if _label == null and not display_name.is_empty():
		_label = KitchenProps.floating_label(self, Vector3(0, hit_size.y + 0.22, 0), localised_name())


func set_highlighted(on: bool) -> void:
	if _highlighted == on:
		return
	_highlighted = on
	if _outline != null:
		_outline.visible = on


func localised_name() -> String:
	return LessonDB.local(display_name)


func _on_area_entered(area: Area3D) -> void:
	if area is InteractiveItem:
		entered.emit(self)


func _on_area_exited(area: Area3D) -> void:
	if area is InteractiveItem:
		exited.emit(self)
