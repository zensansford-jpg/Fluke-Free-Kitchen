extends Node
## Tests for the knowledge check's *gate rule*.
##
## The game asks health questions after every challenge. Whether those questions
## are a gate — "you cannot be credited until you answer" — is a property of the
## mode, not of the question:
##
##   * the story challenges gate, because the competition rubric asks for a level
##     to require the answer before it can be passed;
##   * Let's Cook, Endless Kitchen and Free Cook ask the same questions but do not
##     block: a player who came to cook finishes cooking, and the questions are
##     offered with the rest of the result.
##
## That rule lives in `KitchenSession.passed()` and `QuizCard`, so it is tested here
## against the session directly. No window is opened and nothing is clicked: the
## question is whether the *rule* is right, and the presentation of the card is
## covered by the visual capture pass.
##
## What this suite deliberately does not do is assert that a mode "feels" optional.
## It asserts the one thing that can be measured: a run that completed every step
## is credited in an open mode and is not credited in a gated mode until the
## required question is answered.
##
## Run with:
##   godot --headless --path <project> res://tests/quiz_gate_test.tscn

var failures: Array[String] = []


func _ready() -> void:
	print("--- Fluke Free Kitchen knowledge-check gate test ---")
	_test_completion_alone_credits_open_modes()
	_test_gated_mode_withholds_credit()
	_test_gated_mode_credits_after_the_answer()
	_test_optional_wrong_answer_is_recorded_but_not_fatal()
	_test_question_points_are_not_double_counted()
	_report()


# --------------------------------------------------------------------- fixtures ---
## A two-step challenge with one knowledge question, in the shape the runner builds.
func _level() -> Dictionary:
	return {
		"id": "test_gate",
		"steps": [
			{"id": "s1", "kind": "tap_correct", "lesson": "cook_thoroughly"},
			{"id": "s2", "kind": "hold", "lesson": "wash_hands"},
		],
		"quiz": ["q_gate"],
	}


## A session that has finished every step but answered nothing.
func _completed_session(gated: bool) -> KitchenSession:
	var session := KitchenSession.new()
	session.begin(_level())
	session.quiz_gated = gated
	for step in _level()["steps"]:
		session.record_step(str((step as Dictionary).get("id", "")), 1, 0)
	return session


# ------------------------------------------------------------------------ cases ---
func _test_completion_alone_credits_open_modes() -> void:
	for mode_name in ["Let's Cook", "Endless Kitchen", "Free Cook"]:
		var session := _completed_session(false)
		if not session.passed():
			failures.append("%s: a finished run was not credited with the gate open" % mode_name)
			continue
		if session.stars() < 1:
			failures.append("%s: a finished run earned no star with the gate open" % mode_name)
			continue
		var summary := session.summary()
		if bool(summary.get("quiz_gated", true)):
			failures.append("%s: the summary still reported the run as gated" % mode_name)
			continue
		print("  %-16s finished cooking alone -> passed, %d star(s)" % [mode_name, session.stars()])


func _test_gated_mode_withholds_credit() -> void:
	var session := _completed_session(true)
	# Nothing was required *because the mode did not ask*, so a gated run with no
	# required answer recorded must not be credited.
	if session.passed():
		failures.append("a gated run was credited without answering its required question")
		return
	if session.stars() != 0:
		failures.append("a gated run earned %d star(s) without answering" % session.stars())
		return
	print("  story challenge  finished cooking, no answer -> not credited")


func _test_gated_mode_credits_after_the_answer() -> void:
	var session := _completed_session(true)
	session.record_quiz("q_gate", true, true, 1)
	if not session.passed():
		failures.append("a gated run was not credited after answering correctly")
		return
	if session.stars() < 1:
		failures.append("a gated run that answered correctly earned no star")
		return
	print("  story challenge  finished cooking, answered correctly -> passed")


func _test_optional_wrong_answer_is_recorded_but_not_fatal() -> void:
	var session := _completed_session(false)
	# An open-mode question answered wrongly: recorded honestly, and the run still
	# stands, because the mode never claimed the answer was required.
	session.record_quiz("q_gate", false, false, 2)
	if not session.passed():
		failures.append("a wrong answer in an open mode blocked the run")
		return
	var summary := session.summary()
	if int(summary.get("quiz_correct", -1)) != 0:
		failures.append("a wrong answer was counted as correct")
		return
	if int(summary.get("quiz_answered", -1)) != 1:
		failures.append("the wrong answer was not recorded as answered")
		return
	print("  open mode        wrong answer recorded, run still passed")


func _test_question_points_are_not_double_counted() -> void:
	var session := _completed_session(false)
	session.record_quiz("q_gate", false, false, 1)
	var after_wrong := session.score()
	session.record_quiz("q_gate", true, false, 1)
	var after_right := session.score()
	if after_right - after_wrong != GameConfig.POINTS_KNOWLEDGE:
		failures.append("revisiting a question scored %d, expected %d"
			% [after_right - after_wrong, GameConfig.POINTS_KNOWLEDGE])
		return
	if session.quiz_correct_count() != 1:
		failures.append("revisiting a question left %d correct records, expected 1"
			% session.quiz_correct_count())
		return
	print("  revisiting a question scored it exactly once")


func _report() -> void:
	print("")
	if failures.is_empty():
		print("QUIZ GATE TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("QUIZ GATE TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
