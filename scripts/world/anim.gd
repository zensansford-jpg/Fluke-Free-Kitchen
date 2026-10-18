class_name Anim
extends RefCounted
## The kitchen's animation library.
##
## Every short, procedural movement in the kitchen comes from here — the fish
## turning in the pan, an ingredient settling onto a plate, the knife crossing
## the board, a puff of steam rising — so objects move with one vocabulary
## instead of each script opening its own tween.
##
## The helpers are static and take the node they act on. Each returns the
## `Tween` it started, or `null` when the node cannot be animated, so a caller
## can chain another step or await it:
##
##     var t := Anim.move_to(item, slot)
##     if t != null:
##         t.tween_callback(_on_landed)
##
## Two rules keep the motion honest:
##
##   1. a helper never animates a node that has left the tree — it returns
##      `null` rather than opening a tween on a node that is going away;
##   2. the shared durations below give the whole kitchen one rhythm, so the
##      same action is not faster in one place than another.

# --------------------------------------------------------------- one rhythm ---
## The smallest acknowledgement, a tap.
const TAP := 0.12
## A short scale pulse.
const POP := 0.14
## A nudge or a short slide.
const NUDGE := 0.22
## An item coming to rest on a surface.
const SETTLE := 0.26


## Opens a tween on `node`, or returns `null` when it cannot be animated
## (missing, freed, or not in the tree). Callers never have to reason about
## that themselves.
static func begin(node: Object) -> Tween:
	if node == null or not (node is Node) or not is_instance_valid(node):
		return null
	var n: Node = node
	if not n.is_inside_tree():
		return null
	return n.create_tween()


# -------------------------------------------------------------------- motion ---
## Eases a single property to `to`. The primitive everything else is built on.
static func prop(node: Object, property: String, to: Variant, dur: float, trans: int = Tween.TRANS_CUBIC, ease: int = Tween.EASE_OUT) -> Tween:
	var t: Tween = begin(node)
	if t == null:
		return null
	t.set_trans(trans).set_ease(ease)
	t.tween_property(node, property, to, dur)
	return t


## Eases a node to an absolute position.
static func move_to(node: Object, to: Vector3, dur: float, trans: int = Tween.TRANS_CUBIC, ease: int = Tween.EASE_OUT) -> Tween:
	return prop(node, "position", to, dur, trans, ease)


## Eases a node's scale to an absolute size.
static func scale_to(node: Object, to: Variant, dur: float, trans: int = Tween.TRANS_CUBIC, ease: int = Tween.EASE_OUT) -> Tween:
	return prop(node, "scale", to, dur, trans, ease)


## Lifts a node by an offset with a soft ease — carried objects sit a little
## closer to the camera, and this is how they get there.
static func lift(node: Object, offset: Vector3, dur: float = TAP) -> Tween:
	var n: Node3D = node as Node3D
	if n == null:
		return null
	return move_to(node, n.position + offset, dur, Tween.TRANS_SINE, Tween.EASE_IN_OUT)


## Drops a node onto `to` with a small overshoot — the landing used when an item
## is placed on a plate, in a bowl or in a pan.
static func settle(node: Object, to: Vector3, dur: float = SETTLE) -> Tween:
	return move_to(node, to, dur, Tween.TRANS_BACK, Tween.EASE_OUT)


## A short "I heard you": from the node's own scale out to `factor` and back.
static func pop(node: Object, factor: float = 1.12, dur: float = POP) -> Tween:
	var t: Tween = begin(node)
	if t == null or not (node is Node3D):
		return null
	var base: Vector3 = (node as Node3D).scale
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", base * factor, dur)
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, "scale", base, dur)
	return t


## Up and back to the starting height — a small hop, not a flip.
static func hop(node: Object, height: float, dur: float = 0.25) -> Tween:
	var t: Tween = begin(node)
	if t == null or not (node is Node3D):
		return null
	var from := (node as Node3D).position
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "position:y", from.y + height, dur)
	t.set_ease(Tween.EASE_IN)
	t.tween_property(node, "position:y", from.y, dur * 0.85)
	return t


## The signature flip: the fish rises, turns over about the axis across its body
## and lands back where it started. `peak_y` is the height it reaches.
static func flip(node: Object, peak_y: float, dur: float = 0.25) -> Tween:
	var t: Tween = begin(node)
	if t == null or not (node is Node3D):
		return null
	var n: Node3D = node
	var from := n.position
	var start_x := n.rotation.x
	t.set_trans(Tween.TRANS_SINE)
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(node, "position:y", peak_y, dur)
	t.tween_property(node, "position:z", from.z - 0.10, dur)
	t.tween_property(node, "rotation:x", start_x - PI, dur)
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_parallel(true)
	t.tween_property(node, "position:y", from.y, dur)
	t.tween_property(node, "position:z", from.z, dur)
	t.tween_property(node, "rotation:x", start_x - TAU, dur)
	t.set_parallel(false)
	return t


## Drifts a puff or bit towards `to` while shrinking into nothing, then frees
## it. The effects layer is built from this.
static func drift_away(bit: Object, to: Vector3, dur: float) -> Tween:
	var t: Tween = begin(bit)
	if t == null or not (bit is Node3D):
		return null
	var shrink: Vector3 = (bit as Node3D).scale * 0.25
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(bit, "position", to, dur)
	t.tween_property(bit, "scale", shrink, dur)
	t.set_parallel(false)
	t.tween_callback((bit as Node).queue_free)
	return t


## Fades a transient message in, holds it, fades it out and frees it. Used for
## the encouragement toasts, which are Controls.
static func toast(control: CanvasItem, hold: float = 1.7, fade: float = 0.4) -> Tween:
	var t: Tween = begin(control)
	if t == null:
		return null
	control.modulate.a = 0.0
	t.tween_property(control, "modulate:a", 1.0, 0.12)
	t.tween_interval(hold)
	t.tween_property(control, "modulate:a", 0.0, fade)
	t.tween_callback(control.queue_free)
	return t
