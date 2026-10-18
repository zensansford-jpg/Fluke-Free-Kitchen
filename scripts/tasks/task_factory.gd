class_name TaskFactory
extends RefCounted
## Turns a step's `kind` into the task that runs it.
##
## All the level data needs to know is the name of an interaction; this is the one
## place that maps names to implementations, so adding an interaction means adding
## a script and one line here.

static func create(kind: String) -> KitchenTask:
	match kind:
		"tap_correct":
			return TapCorrectTask.new()
		"choose_safer":
			return TapCorrectTask.new()
		"drag_to":
			return DragToTask.new()
		"swipe_clean":
			return SwipeCleanTask.new()
		"hold":
			return HoldTask.new()
		"cook_through":
			return HoldTask.new()
		"order_steps":
			return OrderStepsTask.new()
		"checklist":
			return ChecklistTask.new()
		"slice", "prep_fish":
			return SliceTask.new()
		"stir":
			return StirTask.new()
		"flip":
			return FlipTask.new()
		"plate":
			return PlateTask.new()
		"serve":
			return ServeTask.new()
		_:
			push_error("TaskFactory: unknown step kind '%s'." % kind)
			return null


## Every kind the factory can build. The level data is validated against this list
## by `validate_data()`, so a typo in a level is caught at startup rather than in
## front of a player.
static func known_kinds() -> Array[String]:
	return [
		"tap_correct", "choose_safer", "drag_to", "swipe_clean",
		"hold", "cook_through", "order_steps", "checklist",
		"slice", "prep_fish", "stir", "flip", "plate", "serve",
	]


## Checks every level's steps against the factory and against the little schema
## each kind requires. Returns a list of human-readable problems; empty is good.
static func validate_data() -> Array[String]:
	var problems: Array[String] = []
	var kinds := known_kinds()
	for level in LevelDB.levels():
		var level_id := str(level.get("id", "?"))
		var steps: Array = level.get("steps", [])
		if steps.is_empty():
			problems.append("level '%s' has no steps." % level_id)
		for i in steps.size():
			var step: Dictionary = steps[i]
			var step_id := str(step.get("id", "?"))
			var kind := str(step.get("kind", ""))
			var where := "%s/%s" % [level_id, step_id]
			if not kinds.has(kind):
				problems.append("%s: unknown kind '%s'." % [where, kind])
			if str(step.get("prompt", "")).is_empty():
				problems.append("%s: missing prompt." % where)
			match kind:
				"tap_correct", "choose_safer":
					problems.append_array(_validate_options(where, step))
				"checklist":
					problems.append_array(_validate_options(where, step))
				"order_steps":
					var order: Array = step.get("steps", [])
					if order.size() < 2:
						problems.append("%s: needs at least two steps to order." % where)
					for entry in order:
						if str((entry as Dictionary).get("id", "")).is_empty():
							problems.append("%s: an orderable step has no id." % where)
				"drag_to":
					problems.append_array(_validate_drag(where, step))
				"swipe_clean":
					var coverage := float(step.get("coverage", 0.85))
					if coverage <= 0.0 or coverage > 1.0:
						problems.append("%s: coverage must be within (0, 1]." % where)
				"hold", "cook_through":
					if kind == "cook_through":
						var safe := float(step.get("safe_temp", GameConfig.COOK_SAFE_TEMP_C))
						if safe <= GameConfig.COOK_START_TEMP_C or safe > GameConfig.COOK_MAX_TEMP_C:
							problems.append("%s: safe_temp is outside the cookable range." % where)
	return problems


static func _validate_options(where: String, step: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var options: Array = step.get("options", [])
	if options.size() < 2:
		problems.append("%s: needs at least two options." % where)
	var correct := 0
	for entry in options:
		var option: Dictionary = entry
		if str(option.get("id", "")).is_empty():
			problems.append("%s: an option has no id." % where)
		if str(option.get("label", "")).is_empty():
			problems.append("%s: option '%s' has no label." % [where, str(option.get("id", "?"))])
		if bool(option.get("correct", false)):
			correct += 1
	if correct == 0:
		problems.append("%s: no option is marked correct." % where)
	return problems


static func _validate_drag(where: String, step: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var targets: Array = step.get("targets", [])
	var items: Array = step.get("items", [])
	if targets.is_empty():
		problems.append("%s: no containers defined." % where)
	if items.is_empty():
		problems.append("%s: no items to drag." % where)
	var target_ids: Array[String] = []
	for entry in targets:
		target_ids.append(str((entry as Dictionary).get("id", "")))
	for entry in items:
		var item: Dictionary = entry
		var wanted := str(item.get("target", ""))
		if not target_ids.has(wanted):
			problems.append("%s: item '%s' points at unknown container '%s'." % [
				where, str(item.get("id", "?")), wanted])
	return problems
