extends Node
## EducationManager (autoload name: `Education`).
##
## The gatekeeper for health content. Gameplay never invents health text: it
## asks for a lesson id and receives vetted, source-backed, localised text from
## `LessonDB`.
##
## `validate_database()` is the important part: it refuses to let a lesson cite
## a missing source, or a source outside the approved agency / peer-reviewed
## allowlist. A content mistake therefore shows up as a startup warning during
## development instead of as a wrong claim in front of a student.

signal lesson_opened(lesson_id: String)

const FALLBACK_LANGUAGE := "en"

## Only these domains may be cited. Sub-domains are accepted (e.g.
## `publications.iarc.who.int` matches `who.int`).
const ALLOWED_DOMAINS: Array[String] = [
	"who.int",
	"cdc.gov",
	"ncbi.nlm.nih.gov",
	"pmc.ncbi.nlm.nih.gov",
	"ddc.moph.go.th",
]

var _by_id: Dictionary = {}
var _sources: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rebuild()
	var problems := validate_database()
	for p in problems:
		push_warning("Education: " + p)


func _rebuild() -> void:
	_by_id.clear()
	for lesson in LessonDB.lessons():
		_by_id[str(lesson.get("id", ""))] = lesson
	_sources = LessonDB.sources()


# --------------------------------------------------------------- lesson API ---
func lesson(lesson_id: String) -> Dictionary:
	var found: Variant = _by_id.get(lesson_id)
	if typeof(found) != TYPE_DICTIONARY:
		push_warning("Education: unknown lesson '%s'." % lesson_id)
		return {}
	return found


func has_lesson(lesson_id: String) -> bool:
	return _by_id.has(lesson_id)


func all_lessons() -> Array:
	return LessonDB.lessons()


func lessons_for_level(level_id: String) -> Array:
	return LessonDB.lessons_for_level(level_id)


func misconceptions_for_level(level_id: String) -> Array:
	return LessonDB.misconceptions_for_level(level_id)


func misconception(claim_id: String) -> Dictionary:
	return LessonDB.misconception(claim_id)


func review_date() -> String:
	return LessonDB.REVIEW_DATE


# ------------------------------------------------------------- localised UI ---
func language() -> String:
	return Loc.language


func title(lesson_or_id: Variant) -> String:
	var entry := _resolve(lesson_or_id)
	return LessonDB.text(entry, "title", language())


func simple(lesson_or_id: Variant) -> String:
	var entry := _resolve(lesson_or_id)
	return LessonDB.text(entry, "simple", language())


func detail(lesson_or_id: Variant) -> String:
	var entry := _resolve(lesson_or_id)
	return LessonDB.text(entry, "detail", language())


func claim_text(claim: Dictionary) -> String:
	return LessonDB.text(claim, "claim", language())


func _resolve(lesson_or_id: Variant) -> Dictionary:
	if typeof(lesson_or_id) == TYPE_DICTIONARY:
		return lesson_or_id as Dictionary
	return lesson(str(lesson_or_id))


# ------------------------------------------------------------------ sources ---
func source(source_key: String) -> Dictionary:
	var found: Variant = _sources.get(source_key)
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found


func sources_for(lesson_or_id: Variant) -> Array:
	var entry := _resolve(lesson_or_id)
	var out: Array = []
	var keys: Array = entry.get("sources", [])
	for key in keys:
		var src := source(str(key))
		if not src.is_empty():
			out.append(src)
	return out


## One short, human-readable citation line, e.g.
## "WHO — Foodborne trematode infections (fact sheet)".
func citation_line(source_key: String) -> String:
	var src := source(source_key)
	if src.is_empty():
		return source_key
	return "%s — %s" % [str(src.get("publisher", "")), str(src.get("title", ""))]


func all_sources() -> Array:
	var out: Array = []
	for key in _sources.keys():
		out.append(_sources[key])
	return out


# -------------------------------------------------------------- validation ---
## Returns a list of human-readable problems. An empty list means the database
## is safe to ship.
func validate_database() -> Array[String]:
	var problems: Array[String] = []
	var seen_ids: Dictionary = {}

	for lesson in LessonDB.lessons():
		var lesson_id := str(lesson.get("id", ""))
		if lesson_id.is_empty():
			problems.append("a lesson has no id.")
			continue
		if seen_ids.has(lesson_id):
			problems.append("duplicate lesson id '%s'." % lesson_id)
		seen_ids[lesson_id] = true

		for field in ["title", "simple", "detail"]:
			var pair: Variant = lesson.get(field)
			if typeof(pair) != TYPE_DICTIONARY:
				problems.append("lesson '%s' has no '%s' text." % [lesson_id, field])
				continue
			var dict: Dictionary = pair
			for lang in ["en", "th"]:
				if str(dict.get(lang, "")).strip_edges().is_empty():
					problems.append("lesson '%s' is missing '%s' in '%s'." % [lesson_id, field, lang])

		var categories: Array = lesson.get("categories", [])
		if categories.is_empty() and str(lesson.get("category", "")).is_empty():
			problems.append("lesson '%s' has no category." % lesson_id)

		if (lesson.get("levels", []) as Array).is_empty():
			problems.append("lesson '%s' is not attached to any challenge." % lesson_id)

		var source_keys: Array = lesson.get("sources", [])
		if source_keys.is_empty():
			problems.append("lesson '%s' cites no source." % lesson_id)
		for key in source_keys:
			var src := source(str(key))
			if src.is_empty():
				problems.append("lesson '%s' cites unknown source '%s'." % [lesson_id, key])
				continue
			var url := str(src.get("url", ""))
			if not _domain_allowed(url):
				problems.append("lesson '%s' cites '%s', which is outside the approved allowlist." % [lesson_id, url])

	for claim in LessonDB.misconceptions():
		var claim_id := str(claim.get("id", ""))
		var lesson_id := str(claim.get("lesson", ""))
		if lesson_id.is_empty() or not _by_id.has(lesson_id):
			problems.append("misconception '%s' points at unknown lesson '%s'." % [claim_id, lesson_id])
		var pair: Variant = claim.get("claim")
		if typeof(pair) != TYPE_DICTIONARY:
			problems.append("misconception '%s' has no claim text." % claim_id)
		else:
			var dict: Dictionary = pair
			for lang in ["en", "th"]:
				if str(dict.get(lang, "")).strip_edges().is_empty():
					problems.append("misconception '%s' is missing '%s' text." % [claim_id, lang])

	for key in _sources.keys():
		var src: Dictionary = _sources[key]
		if str(src.get("title", "")).is_empty() or str(src.get("publisher", "")).is_empty():
			problems.append("source '%s' is missing its title or publisher." % key)
		if not _domain_allowed(str(src.get("url", ""))):
			problems.append("source '%s' is outside the approved allowlist." % key)

	return problems


func _domain_allowed(url: String) -> bool:
	if url.is_empty():
		return false
	var host := url
	var scheme := host.find("://")
	if scheme >= 0:
		host = host.substr(scheme + 3)
	var slash := host.find("/")
	if slash >= 0:
		host = host.substr(0, slash)
	host = host.to_lower()
	for domain in ALLOWED_DOMAINS:
		if host == domain or host.ends_with("." + domain):
			return true
	return false
