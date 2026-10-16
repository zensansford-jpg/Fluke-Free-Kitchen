class_name LessonCard
extends PanelContainer
## The health-knowledge card shown after an interactive step is completed.
##
## Every card carries its own evidence: the lesson's own source list travels with
## it, so a student (or a judge) can always see where the claim came from. The
## simpler text is shown first and the fuller explanation is one tap away, which
## is how one build serves primary and upper-secondary players.

signal dismissed()

var _detail_label: Label = null
var _toggle: Button = null
var _detail_visible := false


## `lesson_id` is a `LessonDB` id; `corrected` is a list of misconception ids the
## step addressed, which are shown as "some people think / what is actually true".
func setup(lesson_id: String, corrected: Array = []) -> void:
	UIFactory.style_panel(self, UIFactory.PANEL_COLOR)
	var lesson := Education.lesson(lesson_id)
	var v := UIFactory.vbox(10)
	add_child(v)

	if lesson.is_empty():
		# A missing lesson is a content bug, not a player-facing message: say so
		# plainly rather than inventing a health fact.
		v.add_child(UIFactory.label("Lesson data missing: %s" % lesson_id, 20, UIFactory.BAD))
		v.add_child(_centred(_continue_button()))
		return

	v.add_child(UIFactory.label(Loc.t("lesson.health_tip"), 16, UIFactory.TEXT_DIM))
	v.add_child(UIFactory.title(Education.title(lesson), 28))
	v.add_child(UIFactory.callout(Education.simple(lesson), UIFactory.GOOD, 20))

	_detail_visible = Settings.detail_default_open
	_detail_label = UIFactory.wrap(Education.detail(lesson), 18, UIFactory.TEXT_DIM)
	_detail_label.visible = _detail_visible
	v.add_child(_detail_label)

	_toggle = UIFactory.button(Loc.t("lesson.less_detail") if _detail_visible else Loc.t("lesson.more_detail"), 18, 230.0)
	UIFactory.style_button(_toggle, UIFactory.TEXT_BRIGHT, false)
	_toggle.pressed.connect(_toggle_detail)
	v.add_child(_centred(_toggle))

	for claim_id in corrected:
		var claim := Education.misconception(str(claim_id))
		if claim.is_empty():
			continue
		var truth := Education.simple(str(claim.get("lesson", "")))
		var card := UIFactory.card(
			"%s %s" % [Loc.t("journal.myth_belief"), Education.claim_text(claim)],
			"%s %s" % [Loc.t("journal.myth_truth"), truth],
			UIFactory.ACCENT)
		v.add_child(card)

	var sources := Education.sources_for(lesson)
	if not sources.is_empty():
		var box := UIFactory.vbox(3)
		box.add_child(UIFactory.label(Loc.t("lesson.sources_plural"), 16, UIFactory.ACCENT, true))
		for entry in sources:
			var source: Dictionary = entry
			box.add_child(UIFactory.wrap("%s — %s" % [
				str(source.get("publisher", "")), str(source.get("title", "")),
			], 15, UIFactory.TEXT_DIM))
			box.add_child(UIFactory.wrap(str(source.get("url", "")), 13, UIFactory.TEXT_DIM))
		v.add_child(box)

	v.add_child(UIFactory.wrap(Loc.t("lesson.disclaimer"), 15, UIFactory.TEXT_DIM))
	v.add_child(_centred(_continue_button()))


func _toggle_detail() -> void:
	_detail_visible = not _detail_visible
	if _detail_label != null:
		_detail_label.visible = _detail_visible
	if _toggle != null:
		_toggle.text = Loc.t("lesson.less_detail") if _detail_visible else Loc.t("lesson.more_detail")
	AudioManager.play_ui("ui_click")


func _continue_button() -> Button:
	var b := UIFactory.button(Loc.t("feedback.continue"), 21, 240.0)
	UIFactory.style_button(b, UIFactory.ACCENT, true)
	b.pressed.connect(func() -> void:
		AudioManager.play_ui("ui_click")
		dismissed.emit())
	return b


func _centred(control: Control) -> HBoxContainer:
	return UIFactory.centre_row(control)
