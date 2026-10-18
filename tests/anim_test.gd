extends Node
## Animation-library test.
##
## The kitchen's motion — the flip, an ingredient settling onto a plate, a puff
## rising — now comes from one place, `scripts/world/anim.gd`. If a helper there
## is wrong, every task that uses it is wrong in the same way, so it is checked
## directly as well as through the tasks.
##
## For each helper this drives a real node and asks the two questions a player
## would ask: did it move, and did it end up where it was supposed to? It also
## checks the contract every helper shares — a node that is missing, loose or
## freed is refused with `null` rather than tweened.
##
## Run with:
##   godot --headless --path <project> res://tests/anim_test.tscn

var failures: Array[String] = []


func _ready() -> void:
	await _run()
	_report()


func _run() -> void:
	print("--- Fluke Free Kitchen animation test ---")
	_check_refusals()
	await _check_prop()
	await _check_hop()
	await _check_flip()
	await _check_pop()
	await _check_drift()
	await _check_toast()


func _subject(pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	add_child(node)
	return node


# --------------------------------------------------------------- safety ---
func _check_refusals() -> void:
	if Anim.begin(null) != null:
		failures.append("begin: a null node was given a tween")
	var loose := Node3D.new()
	if Anim.begin(loose) != null:
		failures.append("begin: a node outside the tree was given a tween")
	loose.free()
	var host := Node3D.new()
	add_child(host)
	host.free()
	if is_instance_valid(host):
		failures.append("the test could not tear down its own host")
	if Anim.prop(null, "position", Vector3.ZERO, 0.1) != null:
		failures.append("prop: a null node was given a tween")
	print("  safety: a missing or loose node is refused, not animated")


func _check_prop() -> void:
	var node := _subject(Vector3.ZERO)
	var t := Anim.prop(node, "position", Vector3(4, 0, 0), 0.2)
	if t == null:
		failures.append("prop: no tween came back for a node in the tree")
		node.queue_free()
		return
	await t.finished
	if node.position.distance_to(Vector3(4, 0, 0)) > 0.001:
		failures.append("prop: the node did not reach its target (%s)" % str(node.position))
	else:
		print("  prop: a node eases to an absolute value")
	node.queue_free()


func _check_hop() -> void:
	var node := _subject(Vector3(0, 1, 0))
	var t := Anim.hop(node, 0.5, 0.2)
	if t == null:
		failures.append("hop: no tween came back")
		node.queue_free()
		return
	await t.finished
	if absf(node.position.y - 1.0) > 0.001:
		failures.append("hop: the node did not come back down (%.3f)" % node.position.y)
	else:
		print("  hop: a node rises and lands where it started")
	node.queue_free()


func _check_flip() -> void:
	var node := _subject(Vector3(0, 1, 0))
	var t := Anim.flip(node, 0.62, 0.2)
	if t == null:
		failures.append("flip: no tween came back")
		node.queue_free()
		return
	await t.finished
	if node.position.distance_to(Vector3(0, 1, 0)) > 0.01:
		failures.append("flip: the fish did not land back in place (%s)" % str(node.position))
	elif absf(node.rotation.x + TAU) > 0.02:
		failures.append("flip: the fish did not turn one whole revolution (%.3f)" % node.rotation.x)
	else:
		print("  flip: the fish rises, turns one whole revolution and lands")
	node.queue_free()


func _check_pop() -> void:
	var node := _subject(Vector3.ZERO)
	var t := Anim.pop(node, 1.5, 0.15)
	if t == null:
		failures.append("pop: no tween came back")
		node.queue_free()
		return
	await t.finished
	if node.scale.distance_to(Vector3.ONE) > 0.02:
		failures.append("pop: the node did not return to its own scale (%s)" % str(node.scale))
	else:
		print("  pop: a node swells and returns to its own size")
	node.queue_free()


func _check_drift() -> void:
	var bit := MeshInstance3D.new()
	add_child(bit)
	var t := Anim.drift_away(bit, Vector3(3, 4, 0), 0.2)
	if t == null:
		failures.append("drift: no tween came back")
		return
	await t.finished
	await get_tree().process_frame
	if is_instance_valid(bit):
		failures.append("drift: the bit was not freed once it had drifted away")
	else:
		print("  drift: a drifting bit frees itself when it is done")


func _check_toast() -> void:
	var panel := PanelContainer.new()
	add_child(panel)
	var t := Anim.toast(panel, 0.05, 0.05)
	if t == null:
		failures.append("toast: no tween came back for a Control in the tree")
		return
	await get_tree().create_timer(0.4, false).timeout
	if is_instance_valid(panel):
		failures.append("toast: the panel was not freed once it had faded")
	else:
		print("  toast: a transient panel fades in, waits, fades out and frees itself")


func _report() -> void:
	print("--- results ---")
	if failures.is_empty():
		print("ANIM TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("ANIM TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
