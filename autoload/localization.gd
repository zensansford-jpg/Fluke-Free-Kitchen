extends Node
## Localisation (autoload name: `Loc`).
##
## Serves every user-interface string in the selected language. Thai is the
## default because the competition is Thai-language; English is kept to the same
## standard so the project can be reviewed internationally.
##
## Gameplay and UI never hard-code a sentence: they call `Loc.t("key")` so a
## wording change is a one-line edit and a missing translation is detectable.

signal language_changed(language: String)

const FALLBACK := "en"

var language: String = "th"

var _table: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_table = UIStrings.table()
	language = Settings.language
	Settings.settings_changed.connect(_on_settings_changed)
	_validate()


func _on_settings_changed() -> void:
	if Settings.language != language:
		language = Settings.language
		language_changed.emit(language)


# ------------------------------------------------------------------ public ---
## Returns the localised string for `key`. `args` are applied with `%` formatting
## when supplied, so callers can write `Loc.t("quiz.question_of", [1, 3])`.
func t(key: String, args: Array = []) -> String:
	var pair: Variant = _table.get(key)
	if pair == null:
		push_warning("Loc: missing string key '%s'." % key)
		return key
	var dict: Dictionary = pair
	var text: String = str(dict.get(language, dict.get(FALLBACK, key)))
	if not args.is_empty():
		text = text % args
	return text


func has_key(key: String) -> bool:
	return _table.has(key)


func available_languages() -> Array[String]:
	return ["th", "en"]


## Language name in its own language, for the settings dropdown.
static func language_label(code: String) -> String:
	match code:
		"th":
			return "ไทย (Thai)"
		"en":
			return "English"
		_:
			return code


# --------------------------------------------------------------- validation ---
## Every entry must carry both languages, and both must be non-empty. This runs
## at startup so a missing Thai string fails loudly during development instead of
## silently showing an English sentence to a Thai-speaking player.
func _validate() -> void:
	var problems := validate_table()
	for p in problems:
		push_warning("Loc: " + p)


func validate_table() -> Array[String]:
	var problems: Array[String] = []
	for key in _table.keys():
		var dict: Variant = _table[key]
		if typeof(dict) != TYPE_DICTIONARY:
			problems.append("string '%s' is not a dictionary." % key)
			continue
		var d: Dictionary = dict
		for lang in available_languages():
			if not d.has(lang) or str(d[lang]).strip_edges().is_empty():
				problems.append("string '%s' is missing the '%s' text." % [key, lang])
	return problems


func string_count() -> int:
	return _table.size()
