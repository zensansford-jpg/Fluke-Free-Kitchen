class_name KitchenSession
extends RefCounted
## The rules of a level: what was done, what was got right, and what that is worth.
##
## Kept deliberately free of nodes and of the scene tree so it can be unit tested
## on its own and so there is exactly one place that decides how stars are earned.
##
## Scoring rewards *accuracy and understanding*, never speed: a careful player who
## corrects their own mistakes still earns every action point, but only a player who
## gets actions right on the first attempt earns the perfection bonus and the
## three-star rating. There is no timer and no penalty for taking time.

var level: Dictionary = {}
## One entry per step, pre-registered so a summary is complete even if something
## went wrong mid-level.
var steps: Array = []
var quiz: Array = []
## Whether this run required its knowledge questions. Set from the mode by the
## runner: the story challenges do, the open-ended cooking modes do not.
var quiz_gated := true
var elapsed := 0.0
var mistakes := 0


func begin(level_data: Dictionary) -> void:
	level = level_data
	steps.clear()
	quiz.clear()
	elapsed = 0.0
	mistakes = 0
	for entry in level.get("steps", []):
		var step: Dictionary = entry
		steps.append({
			"id": str(step.get("id", "")),
			"kind": str(step.get("kind", "")),
			"safety": is_safety_step(step),
			"lesson": str(step.get("lesson", "")),
			"attempts": 0,
			"mistakes": 0,
			"done": false,
		})


## A step counts as a food-safety decision when it makes the player weigh options
## or correct a myth, rather than simply carry out a movement.
static func is_safety_step(step: Dictionary) -> bool:
	if str(step.get("kind", "")) == "choose_safer":
		return true
	if str(step.get("kind", "")) == "checklist":
		return true
	return not (step.get("corrects", []) as Array).is_empty()


# ------------------------------------------------------------------- recording ---
func record_step(step_id: String, attempts: int, step_mistakes: int) -> void:
	for entry in steps:
		var record: Dictionary = entry
		if str(record.get("id", "")) == step_id:
			record["attempts"] = int(record.get("attempts", 0)) + attempts
			record["mistakes"] = int(record.get("mistakes", 0)) + step_mistakes
			record["done"] = true
	mistakes += step_mistakes


## `required` questions must end up correct before the level can be credited; the
## runner enforces that, and it is recorded here so the result screen can say so.
##
## One record per question. A question can legitimately be visited more than once
## (a wrong answer on an optional question is explained, then moved on from), and
## the latest outcome is the one that counts: appending a second record would add
## its knowledge points twice and could push the score above the level maximum.
func record_quiz(question_id: String, correct: bool, required: bool, attempts: int) -> void:
	for entry in quiz:
		var record: Dictionary = entry
		if str(record.get("id", "")) == question_id:
			record["correct"] = correct
			record["required"] = required
			record["attempts"] = int(record.get("attempts", 0)) + attempts
			return
	quiz.append({
		"id": question_id,
		"correct": correct,
		"required": required,
		"attempts": attempts,
	})


# -------------------------------------------------------------------- summaries ---
func step_count() -> int:
	return steps.size()


func steps_done() -> int:
	var count := 0
	for entry in steps:
		if bool((entry as Dictionary).get("done", false)):
			count += 1
	return count


func steps_first_try() -> int:
	var count := 0
	for entry in steps:
		var record: Dictionary = entry
		if bool(record.get("done", false)) and int(record.get("mistakes", 0)) == 0:
			count += 1
	return count


func safety_total() -> int:
	var count := 0
	for entry in steps:
		if bool((entry as Dictionary).get("safety", false)):
			count += 1
	return count


func safety_first_try() -> int:
	var count := 0
	for entry in steps:
		var record: Dictionary = entry
		if bool(record.get("safety", false)) and bool(record.get("done", false)) and int(record.get("mistakes", 0)) == 0:
			count += 1
	return count


## Fraction of steps completed without a mistake. This drives the star rating.
func accuracy() -> float:
	if steps.is_empty():
		return 0.0
	return float(steps_first_try()) / float(steps.size())


## Fraction of steps completed at all. Used to decide whether a level was finished.
func completion() -> float:
	if steps.is_empty():
		return 0.0
	return float(steps_done()) / float(steps.size())


func quiz_correct_count() -> int:
	var count := 0
	for entry in quiz:
		if bool((entry as Dictionary).get("correct", false)):
			count += 1
	return count


func required_quiz_ok() -> bool:
	var required_seen := false
	for entry in quiz:
		var record: Dictionary = entry
		if bool(record.get("required", false)):
			required_seen = true
			if not bool(record.get("correct", false)):
				return false
	# A run that required nothing cannot have failed to answer. The open-ended
	# cooking modes set it up this way on purpose, and the summary says so.
	if not required_seen:
		return not quiz_gated
	return true


func quiz_answered() -> int:
	var count := 0
	for entry in quiz:
		if int((entry as Dictionary).get("attempts", 0)) > 0:
			count += 1
	return count


# ---------------------------------------------------------------------- scoring ---
func score() -> int:
	var total := 0
	for entry in steps:
		var record: Dictionary = entry
		if not bool(record.get("done", false)):
			continue
		total += GameConfig.POINTS_ACTION
		if int(record.get("mistakes", 0)) == 0:
			total += GameConfig.POINTS_ACTION_PERFECT
	if mistakes == 0:
		total += GameConfig.POINTS_TIDY_BONUS
	total += quiz_correct_count() * GameConfig.POINTS_KNOWLEDGE
	return total


## The most this level could have been worth, used to place the score on the star
## thresholds instead of comparing raw points between levels of different lengths.
func max_score() -> int:
	var total := steps.size() * (GameConfig.POINTS_ACTION + GameConfig.POINTS_ACTION_PERFECT)
	total += GameConfig.POINTS_TIDY_BONUS
	var questions: Array = level.get("quiz", [])
	total += questions.size() * GameConfig.POINTS_KNOWLEDGE
	return maxi(total, 1)


func score_ratio() -> float:
	return float(score()) / float(max_score())


## A level is passed when every step was completed — and, when the mode gated it,
## when the mandatory knowledge question was answered correctly too.
##
## `required_quiz_ok()` returns true when *nothing was required*, which is what the
## open-ended modes set up: they ask the same questions but do not hold the run
## hostage to them. The story challenges still cannot be credited without the
## answer, which is what the competition rubric asks for.
func passed() -> bool:
	if completion() < 1.0:
		return false
	if not required_quiz_ok():
		return false
	return true


func stars() -> int:
	if not passed():
		return 0
	var ratio := score_ratio()
	if ratio >= GameConfig.STAR_THRESHOLD_3 and accuracy() >= GameConfig.STAR3_MIN_ACCURACY:
		return 3
	if ratio >= GameConfig.STAR_THRESHOLD_2:
		return 2
	return 1


# ----------------------------------------------------------------------- export ---
## A compact, honest summary. Everything here is something the player actually did
## in this level; nothing is inferred.
func summary() -> Dictionary:
	return {
		"level": str(level.get("id", "")),
		"steps_total": step_count(),
		"steps_completed": steps_done(),
		"steps_first_try": steps_first_try(),
		"safety_first_try": safety_first_try(),
		"safety_total": safety_total(),
		"quiz_correct": quiz_correct_count(),
		"quiz_answered": quiz_answered(),
		"required_quiz_ok": required_quiz_ok(),
		"quiz_gated": quiz_gated,
		"mistakes": mistakes,
		"accuracy": accuracy(),
		"score": score(),
		"max_score": max_score(),
		"stars": stars(),
		"passed": passed(),
		"seconds": elapsed,
	}
