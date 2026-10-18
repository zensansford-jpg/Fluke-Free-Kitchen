class_name KitchenCharacter
extends Node3D
## The cook who stands behind the bench and reacts to what the player actually
## does.
##
## The character is built from primitives, like everything else in the kitchen, and
## its reactions are short procedural animations rather than a skeleton. It has one
## personality: patient, encouraging, and quick to be pleased by a good action —
## but it only responds to real events (a step finished, a fish flipped, a dish being
## served before it is safe). It never plays a random celebration, and never
## celebrates something the player did not do.

const IDLE_BOB := 0.02

var _body: Node3D = null
var _head: Node3D = null
var _mouth: MeshInstance3D = null
var _brow_left: MeshInstance3D = null
var _brow_right: MeshInstance3D = null
var _arm_left: Node3D = null
var _arm_right: Node3D = null
var _tween: Tween = null
var _reacting := false
var _time := 0.0


func build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	PropFactory.cyl(_body, 0.26, 0.62, "shirt", Vector3(0, 0.66, 0))
	PropFactory.box(_body, Vector3(0.42, 0.30, 0.26), "shorts", Vector3(0, 0.28, 0))
	PropFactory.box(_body, Vector3(0.14, 0.06, 0.22), "shoe", Vector3(-0.10, 0.03, 0.02))
	PropFactory.box(_body, Vector3(0.14, 0.06, 0.22), "shoe", Vector3(0.10, 0.03, 0.02))

	_arm_left = Node3D.new()
	_arm_left.position = Vector3(-0.30, 0.90, 0)
	_body.add_child(_arm_left)
	PropFactory.cyl(_arm_left, 0.06, 0.40, "shirt", Vector3(0, -0.20, 0), Vector3(0, 0, 12))

	_arm_right = Node3D.new()
	_arm_right.position = Vector3(0.30, 0.90, 0)
	_body.add_child(_arm_right)
	PropFactory.cyl(_arm_right, 0.06, 0.40, "shirt", Vector3(0, -0.20, 0), Vector3(0, 0, -12))

	_head = Node3D.new()
	_head.position = Vector3(0, 1.16, 0)
	_body.add_child(_head)
	PropFactory.sphere(_head, 0.20, "skin", Vector3.ZERO)
	PropFactory.cyl(_head, 0.21, 0.06, "hair", Vector3(0, 0.15, 0))
	# A small cook's cap, so the character reads as "the one who cooks".
	PropFactory.cyl(_head, 0.17, 0.10, "sign_white", Vector3(0, 0.26, 0))
	PropFactory.box(_head, Vector3(0.30, 0.05, 0.12), "sign_white", Vector3(0, 0.20, 0.14))

	PropFactory.sphere(_head, 0.028, "hair", Vector3(-0.075, 0.03, 0.19))
	PropFactory.sphere(_head, 0.028, "hair", Vector3(0.075, 0.03, 0.19))
	_brow_left = PropFactory.box(_head, Vector3(0.08, 0.016, 0.02), "hair", Vector3(-0.075, 0.10, 0.185))
	_brow_right = PropFactory.box(_head, Vector3(0.08, 0.016, 0.02), "hair", Vector3(0.075, 0.10, 0.185))
	_mouth = PropFactory.box(_head, Vector3(0.10, 0.018, 0.02), "sign_red", Vector3(0, -0.07, 0.19))
	PropFactory.sphere(_head, 0.03, "skin", Vector3(0, -0.01, 0.20))


func _process(delta: float) -> void:
	if _reacting or _body == null:
		return
	_time += delta
	_body.position.y = sin(_time * 1.6) * IDLE_BOB


## Plays one short reaction. `kind` is one of: idle, happy, celebrate, surprised,
## worried, think, encourage, oops.
func react(kind: String) -> void:
	if _body == null:
		return
	_reset_pose()
	if kind == "idle":
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = Anim.begin(self)
	if _tween == null:
		return
	_reacting = true
	match kind:
		"happy":
			_happy()
		"celebrate":
			_celebrate()
		"surprised":
			_surprised()
		"worried":
			_worried()
		"think":
			_think()
		"encourage":
			_encourage()
		"oops":
			_oops()
		_:
			pass
	_tween.tween_interval(0.15)
	_tween.tween_callback(func() -> void:
		_reacting = false
		_reset_pose())


func _happy() -> void:
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_body, "scale", Vector3(1.06, 0.94, 1.06), 0.14)
	_tween.tween_property(_body, "scale", Vector3.ONE, 0.22)
	_tween.parallel().tween_property(_mouth, "scale", Vector3(1.5, 2.2, 1.0), 0.2)
	_tween.parallel().tween_property(_brow_left, "position:y", 0.12, 0.2)
	_tween.parallel().tween_property(_brow_right, "position:y", 0.12, 0.2)


func _celebrate() -> void:
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_body, "position:y", 0.22, 0.24)
	_tween.parallel().tween_property(_arm_left, "rotation:z", 2.4, 0.24)
	_tween.parallel().tween_property(_arm_right, "rotation:z", -2.4, 0.24)
	_tween.parallel().tween_property(_mouth, "scale", Vector3(1.6, 2.0, 1.0), 0.24)
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(_body, "position:y", 0.0, 0.22)


func _surprised() -> void:
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_head, "position:y", 1.24, 0.12)
	_tween.parallel().tween_property(_brow_left, "position:y", 0.135, 0.12)
	_tween.parallel().tween_property(_brow_right, "position:y", 0.135, 0.12)
	_tween.parallel().tween_property(_mouth, "scale", Vector3(0.7, 1.8, 1.0), 0.12)
	_tween.tween_property(_head, "position:y", 1.16, 0.22)


func _worried() -> void:
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_head, "rotation:z", 0.22, 0.2)
	_tween.parallel().tween_property(_brow_left, "rotation:z", -0.5, 0.2)
	_tween.parallel().tween_property(_brow_right, "rotation:z", 0.5, 0.2)
	_tween.parallel().tween_property(_body, "position:z", -0.10, 0.2)


func _think() -> void:
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_head, "rotation:z", -0.16, 0.24)
	_tween.tween_property(_head, "rotation:z", 0.0, 0.24)


func _encourage() -> void:
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_head, "rotation:x", 0.22, 0.16)
	_tween.tween_property(_head, "rotation:x", 0.0, 0.16)


func _oops() -> void:
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_head, "rotation:z", -0.3, 0.14)
	_tween.parallel().tween_property(_mouth, "scale", Vector3(0.8, 0.7, 1.0), 0.14)
	_tween.tween_property(_head, "rotation:z", 0.0, 0.24)


func _reset_pose() -> void:
	if _body != null:
		_body.scale = Vector3.ONE
		_body.rotation = Vector3.ZERO
		_body.position = Vector3(0, 0, 0)
	if _head != null:
		_head.position = Vector3(0, 1.16, 0)
		_head.rotation = Vector3.ZERO
	if _mouth != null:
		_mouth.scale = Vector3.ONE
	if _brow_left != null:
		_brow_left.position.y = 0.10
		_brow_left.rotation = Vector3.ZERO
	if _brow_right != null:
		_brow_right.position.y = 0.10
		_brow_right.rotation = Vector3.ZERO
	if _arm_left != null:
		_arm_left.rotation = Vector3.ZERO
	if _arm_right != null:
		_arm_right.rotation = Vector3.ZERO
