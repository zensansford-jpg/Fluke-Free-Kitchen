extends Node
## Tests for the dish catalogue, the endless generator and save version 3.
##
## Three things are checked here that no other suite reaches:
##
##   1. every recipe in `RecipeDB` validates — its fish, ingredients, method,
##      plating, unlock rule and generated steps all resolve, and exactly one
##      cook-through step carries the safe figure from `GameConfig`;
##   2. the challenge generator is deterministic, never returns an invalid
##      challenge, never gets stuck when the pool is thin, and does not repeat a
##      recipe immediately when it has a choice;
##   3. the save file migrates from version 2, recovers from a corrupt file, keeps
##      two attempts apart in the same session, and only awards achievements for
##      conditions that were really met.
##
## It backs up `user://` on the way in and restores it on the way out, so running
## it never costs the developer their progress.
##
## Run with:
##   godot --headless --path <project> res://tests/recipe_test.tscn

var failures: Array[String] = []
var _backup := {}


func _ready() -> void:
	await _run()
	_report()


func _run() -> void:
	print("--- Fluke Free Kitchen recipe & generator test ---")
	# The save checks really do write files, so the developer's own progress is read
	# into memory at the start and written back at the end.
	_backup_saves()
	_check_catalogue()
	_check_generator()
	_check_free_cook()
	_check_generated()
	_check_custom()
	_check_browse()
	_check_save_migration()
	_check_save_recovery()
	_check_records_and_achievements()
	_restore_saves()


# ================================================================ catalogue ===
func _check_catalogue() -> void:
	var problems := RecipeDB.validate_all()
	if problems.is_empty():
		print("  catalogue: %d recipes, %d real dishes, %d fish, all valid" % [
			RecipeDB.recipe_count(), RecipeDB.real_recipe_count(), RecipeDB.fish_count()])
	else:
		for problem in problems:
			failures.append("catalogue: " + problem)

	# Real dishes and game variations must be told apart in the data itself.
	var mislabelled := 0
	for recipe in RecipeDB.recipes():
		if bool(recipe.get("real", true)):
			continue
		var note: Variant = recipe.get("note", {})
		if typeof(note) != TYPE_DICTIONARY or str((note as Dictionary).get("en", "")).is_empty():
			mislabelled += 1
	if mislabelled == 0:
		print("  catalogue: every game variation states plainly that it is not a traditional dish")
	else:
		failures.append("catalogue: %d variations do not say they are not traditional dishes" % mislabelled)

	# A fish that is a colour variety must point at the species it belongs to.
	var dishonest := 0
	for fish in RecipeDB.fish():
		var variant := str(fish.get("variant_of", ""))
		if variant.is_empty():
			continue
		if RecipeDB.fish_by_id(variant).is_empty():
			dishonest += 1
			failures.append("catalogue: '%s' is a variant of unknown fish '%s'"
				% [str(fish.get("id", "")), variant])
	if dishonest == 0:
		print("  catalogue: colour varieties are marked as the same species")

	# Every recipe must produce exactly one mandatory cook step at the safe figure.
	var checked := 0
	for recipe in RecipeDB.recipes():
		var steps := RecipeDB.build_steps(recipe)
		var cooks := 0
		for entry in steps:
			var step: Dictionary = entry
			if str(step.get("kind", "")) == "cook_through":
				cooks += 1
				if float(step.get("safe_temp", 0.0)) < GameConfig.COOK_SAFE_TEMP_C - 0.001:
					failures.append("catalogue: '%s' cooks below the safe temperature" % str(recipe.get("id", "")))
		if cooks != 1:
			failures.append("catalogue: '%s' has %d cook steps, expected 1" % [str(recipe.get("id", "")), cooks])
		checked += 1
	if checked == RecipeDB.recipe_count():
		print("  catalogue: every recipe has exactly one mandatory safe-cook step")

	# The mandatory education check must be answerable for every recipe.
	for recipe in RecipeDB.recipes():
		var quiz: Array = recipe.get("quiz", [])
		if quiz.is_empty():
			failures.append("catalogue: '%s' has no knowledge questions" % str(recipe.get("id", "")))
			continue
		for question_id in quiz:
			if QuizDB.by_id(str(question_id)).is_empty():
				failures.append("catalogue: '%s' names unknown question '%s'"
					% [str(recipe.get("id", "")), str(question_id)])
	print("  catalogue: every recipe names real knowledge questions")

	# Unlock rules must form a chain that starts somewhere open, and more than one
	# dish must be available from the very first visit so the player has a choice
	# rather than a single forced dish.
	var open := 0
	for recipe in RecipeDB.recipes():
		if str(recipe.get("unlock", "")).is_empty():
			open += 1
	if open >= 2:
		print("  catalogue: %d dishes are open from the start (a choice, no grinding gate)" % open)
	else:
		failures.append("catalogue: only %d dish is open from the start; the player has no choice" % open)

	# Every dish must be reachable from an open dish by following the unlock rules,
	# or it is content nobody can ever see.
	var reachable := {}
	for recipe in RecipeDB.recipes():
		if str(recipe.get("unlock", "")).is_empty():
			reachable[str(recipe.get("id", ""))] = true
	var grew := true
	while grew:
		grew = false
		for recipe in RecipeDB.recipes():
			var recipe_id := str(recipe.get("id", ""))
			if reachable.has(recipe_id):
				continue
			if reachable.has(str(recipe.get("unlock", ""))):
				reachable[recipe_id] = true
				grew = true
	if reachable.size() == RecipeDB.recipe_count():
		print("  catalogue: all %d dishes are reachable from the starting dishes" % reachable.size())
	else:
		for recipe in RecipeDB.recipes():
			var recipe_id := str(recipe.get("id", ""))
			if not reachable.has(recipe_id):
				failures.append("catalogue: '%s' can never be unlocked" % recipe_id)


# ================================================================ generator ===
func _check_generator() -> void:
	# Determinism: the same seed and the same unlocks must give the same sequence.
	var all_unlocked := RecipeDB.recipe_ids()
	var first := _sequence(4242, all_unlocked)
	var second := _sequence(4242, all_unlocked)
	if first == second:
		print("  generator: the same seed produces the same sequence (%s)" % [first])
	else:
		failures.append("generator: the same seed gave different sequences: %s vs %s" % [first, second])

	# A thin pool (only the dishes open from the start) must still be deterministic,
	# and must not spin looking for variety it does not have.
	var thin_first := _sequence(99, [])
	var thin_second := _sequence(99, [])
	if thin_first == thin_second:
		print("  generator: with only the starting dishes unlocked it is still stable (%s)" % [thin_first])
	else:
		failures.append("generator: the same seed was not stable with a thin pool")

	# Different seeds should give more than one distinct opening. Checked across
	# several seeds so the test cannot be flaky about one unlucky pair.
	var openings := {}
	for seed_value in [1, 7, 77, 404, 4243, 31337, 900001]:
		openings[JSON.stringify(_sequence(seed_value, all_unlocked))] = true
	if openings.size() > 1:
		print("  generator: seven seeds produce %d distinct opening sequences" % openings.size())
	else:
		failures.append("generator: seven different seeds all gave the same opening sequence")

	# Every challenge drawn, at every difficulty, with every unlock pool, is valid.
	var generator := ChallengeGenerator.new()
	generator.begin(31337)
	var drawn := 0
	var kinds_seen := {}
	for difficulty in [1, 2, 3]:
		for unlock_state in [[], ["tom_yum_pla"], RecipeDB.recipe_ids()]:
			for _i in 12:
				var challenge := generator.next(difficulty, unlock_state, true)
				if challenge.is_empty():
					failures.append("generator: nothing was returned for difficulty %d" % difficulty)
					continue
				drawn += 1
				var problems := generator.validate(challenge)
				for problem in problems:
					failures.append("generator: invalid challenge: " + problem)
				var steps: Array = challenge.get("steps", [])
				var cook := 0
				for entry in steps:
					var step: Dictionary = entry
					kinds_seen[str(step.get("kind", ""))] = true
					if str(step.get("kind", "")) == "cook_through":
						cook += 1
				if cook != 1:
					failures.append("generator: a challenge had %d cook steps" % cook)
	print("  generator: %d challenges drawn, all valid; kinds seen: %s"
		% [drawn, kinds_seen.keys()])

	# A fresh profile (nothing discovered) must still get a valid challenge, and a
	# pool that somehow ends up empty must fall back rather than return nothing.
	generator.begin(1)
	var fresh := generator.next(3, [], false)
	if fresh.is_empty():
		failures.append("generator: a fresh profile produced nothing at all")
	else:
		print("  generator: a fresh profile still gets a valid challenge ('%s')"
			% str(fresh.get("recipe_id", "")))

	# When there is a choice, the same recipe must not come up twice in a row.
	generator.begin(5150)
	var discovered := RecipeDB.recipe_ids()
	var consecutive := 0
	var previous := ""
	for _i in 20:
		var challenge := generator.next(3, discovered, false)
		var recipe_id := str(challenge.get("recipe_id", ""))
		if recipe_id == previous:
			consecutive += 1
		previous = recipe_id
	if consecutive == 0:
		print("  generator: never repeats the same dish back to back across 20 draws")
	else:
		failures.append("generator: repeated the same dish back to back %d times" % consecutive)

	# The generator must never return something that is not in the catalogue.
	generator.begin(9)
	for _i in 15:
		var challenge := generator.next(2, discovered, true)
		var recipe_id := str(challenge.get("recipe_id", ""))
		if RecipeDB.recipe_by_id(recipe_id).is_empty():
			failures.append("generator: invented a recipe id '%s'" % recipe_id)


func _sequence(seed_value: int, discovered: Array) -> Array:
	var generator := ChallengeGenerator.new()
	generator.begin(seed_value)
	var out: Array = []
	for _i in 8:
		var challenge := generator.next(3, discovered, false)
		out.append(str(challenge.get("recipe_id", "")))
	return out


# =============================================================== free cook ===
func _check_free_cook() -> void:
	var built := 0
	var generator := ChallengeGenerator.new()
	generator.begin(2026)
	for fish in RecipeDB.fish():
		for method in RecipeDB.methods():
			var challenge := RecipeDB.build_free_cook(str(fish.get("id", "")), str(method.get("id", "")))
			if challenge.is_empty():
				failures.append("free cook: %s / %s built nothing"
					% [str(fish.get("id", "")), str(method.get("id", ""))])
				continue
			built += 1
			if bool(challenge.get("real", true)):
				failures.append("free cook: %s / %s is marked as a real recipe, but it is a creation"
					% [str(fish.get("id", "")), str(method.get("id", ""))])
			var problems := generator.validate(challenge)
			for problem in problems:
				failures.append("free cook: invalid: " + problem)
			var cooks := 0
			for entry in challenge.get("steps", []):
				if str((entry as Dictionary).get("kind", "")) == "cook_through":
					cooks += 1
			if cooks != 1:
				failures.append("free cook: %s / %s has %d cook steps — safety must not be optional"
					% [str(fish.get("id", "")), str(method.get("id", "")), cooks])
	if built == RecipeDB.fish().size() * RecipeDB.methods().size():
		print("  free cook: all %d fish/method combinations build a valid, clearly-experimental challenge" % built)

	# A bad combination must fail cleanly rather than build a broken challenge.
	if not RecipeDB.build_free_cook("not_a_fish", "boil").is_empty():
		failures.append("free cook: an unknown fish produced a challenge")
	if not RecipeDB.build_free_cook("pla_nil", "not_a_method").is_empty():
		failures.append("free cook: an unknown method produced a challenge")


# ========================================================== composed dishes ===
## The dishes the game composes itself. These are the "unlimited cuisine" promise:
## the catalogue is never a fixed list, so a large batch of composed dishes is
## checked here and every one is held to exactly the same standard as a written
## recipe — valid steps, exactly one mandatory safe cook, and honest labelling.
func _check_generated() -> void:
	var generator := ChallengeGenerator.new()
	generator.begin(1)

	# Determinism: the same seed must compose the same dish, or a bug cannot be
	# reproduced. Compared as text so an extra field cannot slip through.
	var first := RecipeDB.generate_dish(4242)
	var again := RecipeDB.generate_dish(4242)
	if first.is_empty() or JSON.stringify(first) != JSON.stringify(again):
		failures.append("composed: the same seed did not compose the same dish")

	var checked := 0
	var ids := {}
	for seed_value in range(1, 201):
		var dish := RecipeDB.generate_dish(seed_value)
		if dish.is_empty():
			failures.append("composed: seed %d composed nothing" % seed_value)
			continue
		checked += 1
		var recipe := RecipeDB.generate_recipe(seed_value)
		for problem in RecipeDB.validate(recipe):
			failures.append("composed: seed %d invalid recipe: %s" % [seed_value, problem])
		for problem in generator.validate(dish):
			failures.append("composed: seed %d invalid challenge: %s" % [seed_value, problem])
		if bool(dish.get("real", true)):
			failures.append("composed: seed %d claims to be a traditional dish" % seed_value)
		var title: Variant = dish.get("title", {})
		if typeof(title) != TYPE_DICTIONARY \
				or str((title as Dictionary).get("en", "")).is_empty() \
				or str((title as Dictionary).get("th", "")).is_empty():
			failures.append("composed: seed %d has no bilingual name" % seed_value)
		var difficulty := int(dish.get("difficulty", 0))
		if difficulty < 1 or difficulty > 3:
			failures.append("composed: seed %d has difficulty %d" % [seed_value, difficulty])
		var id := str(dish.get("id", ""))
		if ids.has(id):
			failures.append("composed: two seeds share the id '%s'" % id)
		ids[id] = true

		# The safety rules must survive composition: one cook step, at the safe
		# figure, and never a plating style the kitchen does not know.
		var cooks := 0
		for entry in dish.get("steps", []):
			var step: Dictionary = entry
			if str(step.get("kind", "")) != "cook_through":
				continue
			cooks += 1
			if float(step.get("safe_temp", 0.0)) < GameConfig.COOK_SAFE_TEMP_C - 0.001:
				failures.append("composed: seed %d cooks below the safe temperature" % seed_value)
		if cooks != 1:
			failures.append("composed: seed %d has %d cook steps, expected 1" % [seed_value, cooks])

	if checked == 200:
		print("  composed: 200 composed dishes are valid, honest and safely cooked")

	# The browse pool: distinct dishes, all valid, from a single base seed.
	var pool := RecipeDB.generated_pool(6, 900)
	if pool.size() == 6:
		print("  composed: the browse pool returned 6 distinct, valid dishes")
	else:
		failures.append("composed: the browse pool returned %d dishes, expected 6" % pool.size())


# =========================================================== created dishes ===
## The recipe creator's data layer. A player-made dish must be built from real
## catalogue entries, validate like any other recipe, carry exactly one safe cook
## step, and survive a save/load round-trip through the cookbook. Nothing here trusts
## the UI: this is the same validation the kitchen runs before playing the dish.
func _check_custom() -> void:
	# Every fish with every method makes a valid, safe, honest dish.
	var built := 0
	for fish in RecipeDB.fish():
		for method in RecipeDB.methods():
			var fish_id := str(fish.get("id", ""))
			var method_id := str(method.get("id", ""))
			var recipe := RecipeDB.custom_recipe("Test dish", fish_id, method_id,
				["lemongrass", "garlic", "chilli"], ["coriander"], "plate")
			if recipe.is_empty():
				failures.append("created: %s / %s built nothing" % [fish_id, method_id])
				continue
			built += 1
			for problem in RecipeDB.validate(recipe):
				failures.append("created: %s / %s invalid recipe: %s" % [fish_id, method_id, problem])
			var challenge := RecipeDB.build_custom(recipe)
			if challenge.is_empty():
				failures.append("created: %s / %s built no challenge" % [fish_id, method_id])
				continue
			var generator := ChallengeGenerator.new()
			for problem in generator.validate(challenge):
				failures.append("created: %s / %s invalid challenge: %s" % [fish_id, method_id, problem])
			if bool(challenge.get("real", true)):
				failures.append("created: %s / %s claims to be a traditional dish" % [fish_id, method_id])
			var cooks := 0
			for entry in challenge.get("steps", []):
				if str((entry as Dictionary).get("kind", "")) == "cook_through":
					cooks += 1
			if cooks != 1:
				failures.append("created: %s / %s has %d cook steps, expected 1" % [fish_id, method_id, cooks])
	if built == RecipeDB.fish().size() * RecipeDB.methods().size():
		print("  created: every fish and method makes a valid, safe, player-made dish")

	# Things the creator must refuse rather than save something broken.
	if not RecipeDB.custom_recipe("", "pla_nil", "steam", ["garlic"], [], "plate").is_empty():
		failures.append("created: an unnamed dish was built")
	if not RecipeDB.custom_recipe("X", "pla_nil", "steam", [], [], "plate").is_empty():
		failures.append("created: a dish with no ingredients was built")
	if not RecipeDB.custom_recipe("X", "no_such_fish", "steam", ["garlic"], [], "plate").is_empty():
		failures.append("created: an unknown fish was accepted")
	if not RecipeDB.custom_recipe("X", "pla_nil", "no_such_method", ["garlic"], [], "plate").is_empty():
		failures.append("created: an unknown method was accepted")
	if not RecipeDB.custom_recipe("X", "pla_nil", "steam",
			["garlic", "chilli", "lime", "lemongrass", "galangal", "shallot"], [], "plate").is_empty():
		failures.append("created: more ingredients than the cap was accepted")
	print("  created: the creator refuses a dish that cannot be cooked")

	# The id comes from what the dish is made of, order-independent, so the same dish
	# saved twice is one entry and a restored save still finds its own dish.
	var a := RecipeDB.custom_recipe("Dish", "pla_nil", "steam", ["garlic", "chilli"], [], "plate")
	var b := RecipeDB.custom_recipe("Dish", "pla_nil", "steam", ["chilli", "garlic"], [], "plate")
	var c := RecipeDB.custom_recipe("Dish", "pla_nil", "grill", ["garlic", "chilli"], [], "plate")
	if str(a.get("id", "")) != str(b.get("id", "")):
		failures.append("created: the same dish in a different order got a different id")
	if str(a.get("id", "")) == str(c.get("id", "")):
		failures.append("created: two different dishes share an id")
	print("  created: a dish's id comes from what it is made of, not the order")

	# The cookbook. Disk writes are real here (the section below backs up and restores
	# user://), because a cookbook that does not survive a restart is not a cookbook.
	SaveData.reset_progress()
	if not SaveData.save_recipe(a):
		failures.append("cookbook: saving a dish reported no change")
	if SaveData.save_recipe(a):
		failures.append("cookbook: saving the same dish twice changed the book")
	if SaveData.saved_recipe_count() != 1:
		failures.append("cookbook: expected one saved dish, got %d" % SaveData.saved_recipe_count())
	SaveData.save_recipe(c)
	if not SaveData.has_saved_recipe(str(c.get("id", ""))):
		failures.append("cookbook: a second dish was not saved")
	if SaveData.saved_recipe(str(a.get("id", ""))).is_empty():
		failures.append("cookbook: a saved dish could not be read back")
	if not SaveData.has_achievement("signature_dish"):
		failures.append("cookbook: saving a dish did not unlock 'signature dish'")

	SaveData.save()
	SaveData.load_progress()
	if SaveData.saved_recipe_count() == 2:
		print("  cookbook: saved dishes survive a save and reload")
	else:
		failures.append("cookbook: the book did not survive a save/load (%d)" % SaveData.saved_recipe_count())

	if not SaveData.remove_saved_recipe(str(a.get("id", ""))):
		failures.append("cookbook: removing a saved dish reported no change")
	if SaveData.has_saved_recipe(str(a.get("id", ""))):
		failures.append("cookbook: a removed dish is still in the book")
	if SaveData.remove_saved_recipe("not_a_dish"):
		failures.append("cookbook: removing an unknown dish reported a change")

	# A hand-edited save must not smuggle a malformed recipe into the kitchen.
	_write(SaveData.SAVE_PATH, JSON.stringify({
		"version": SaveData.VERSION,
		"cookbook": [{"id": "x"}, "not a dish", 42, {"id": "y", "method": "steam", "fish": ["pla_nil"]}],
	}))
	SaveData.load_progress()
	if SaveData.saved_recipe_count() == 1:
		print("  cookbook: a malformed saved dish is dropped, not played")
	else:
		failures.append("cookbook: a malformed save was not sanitised (%d)" % SaveData.saved_recipe_count())


# ================================================================= explore ===
## The Discover browser composes pages lazily and de-duplicates them by composition, so
## the signature it relies on has to be stable and order-independent. This checks the
## signature directly: same seed -> same signature, ingredient order does not matter,
## and a run of seeds yields mostly-distinct dishes.
func _check_browse() -> void:
	var a := RecipeDB.generate_recipe(4242)
	if RecipeDB.composition_signature(a).is_empty():
		failures.append("browse: a signature came out empty")
	if RecipeDB.composition_signature(a) != RecipeDB.composition_signature(RecipeDB.generate_recipe(4242)):
		failures.append("browse: the same seed gave two different signatures")

	# Same fish/method/mix in a different order is the same dish.
	var reordered := RecipeDB.generate_recipe(4242)
	var ingredients: Array = (reordered.get("ingredients", []) as Array).duplicate()
	ingredients.reverse()
	reordered["ingredients"] = ingredients
	if RecipeDB.composition_signature(a) != RecipeDB.composition_signature(reordered):
		failures.append("browse: the signature depends on ingredient order")

	# A page's worth of distinct dishes from 60 consecutive seeds.
	var seen: Dictionary = {}
	for seed_value in range(20261018, 20261018 + 60):
		seen[RecipeDB.composition_signature(RecipeDB.generate_recipe(seed_value))] = true
	if seen.size() >= 40:
		print("  browse: %d distinct dishes from 60 seeds, de-duplicated by composition" % seen.size())
	else:
		failures.append("browse: only %d distinct dishes from 60 seeds" % seen.size())


# ==================================================================== saves ===
func _check_save_migration() -> void:
	# Lay down a version 2 file (and no version 3 file) and let the manager upgrade it.
	_remove_file(SaveData.SAVE_PATH)
	_write(SAVE_V2, JSON.stringify({
		"version": 2,
		"levels": {"l1": {"stars": 2, "best_score": 900, "attempts": 3, "completed": true, "best_accuracy": 0.7}},
		"learning": {"lessons": ["cook_thoroughly"]},
		"assessment": {},
		"total_runs": 4,
		"participant_code": "ab-12",
	}))
	SaveData.load_progress()
	if SaveData.stars_for("l1") == 2 and SaveData.best_score_for("l1") == 900:
		print("  save: a version 2 file is upgraded and its challenge progress kept")
	else:
		failures.append("save: version 2 progress was not carried over")
	if SaveData.participant_code == "AB-12":
		print("  save: the case code survives the upgrade (upper-cased, sanitised)")
	else:
		failures.append("save: the case code was lost in migration: '%s'" % SaveData.participant_code)
	if SaveData.discovered_count() == 0:
		print("  save: the upgrade does not invent discoveries the player never made")
	else:
		failures.append("save: the upgrade fabricated %d discoveries" % SaveData.discovered_count())

	# After the upgrade, the new fields are all writable.
	SaveData.save()
	if FileAccess.file_exists(SaveData.SAVE_PATH):
		var text := FileAccess.get_file_as_string(SaveData.SAVE_PATH)
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY and int((parsed as Dictionary).get("version", 0)) == SaveData.VERSION:
			print("  save: the upgraded file is written as version %d" % SaveData.VERSION)
		else:
			failures.append("save: the upgraded file was not written at version %d" % SaveData.VERSION)
	else:
		failures.append("save: the upgraded file was not written")


func _check_save_recovery() -> void:
	# A corrupt file must be moved aside, not crashed on, and not silently lost.
	# Writing deliberately broken JSON makes the engine print one parse error to
	# stderr; that line is expected and is not a failure of this suite.
	print("  save: (one 'Parse JSON failed' line below is expected — the file is broken on purpose)")
	_write(SaveData.SAVE_PATH, "{ this is not json")
	SaveData.load_progress()
	if FileAccess.file_exists(SaveData.BACKUP_PATH):
		print("  save: a corrupt file is quarantined rather than misinterpreted")
	else:
		failures.append("save: a corrupt file was not quarantined")
	if SaveData.levels.is_empty():
		print("  save: a corrupt file leaves a clean, empty state")
	else:
		failures.append("save: a corrupt file left stale progress behind")

	# A file from a future/unknown version must also be kept aside.
	_write(SaveData.SAVE_PATH, JSON.stringify({"version": 99, "levels": {"l9": {}}}))
	SaveData.load_progress()
	if SaveData.levels.is_empty():
		print("  save: an unknown file version is refused and kept aside")
	else:
		failures.append("save: an unknown file version was read as if it were current")


func _check_records_and_achievements() -> void:
	SaveData.reset_progress()

	var first := SaveData.record_recipe_result("tom_yum_pla", 1, 500, 0.5, true)
	if bool(first.get("new_best_score", false)) and bool(first.get("new_discovery", false)):
		print("  save: the first cook of a dish is a discovery and a personal best")
	else:
		failures.append("save: the first cook was not reported as a discovery/best")
	if not SaveData.is_discovered("tom_yum_pla"):
		failures.append("save: a cooked dish was not marked as discovered")
	if not SaveData.has_achievement("first_dish"):
		failures.append("save: cooking one dish did not unlock 'first dish'")
	else:
		print("  save: achievements unlock from real cooking, not from opening a screen")

	# A second, worse attempt must not overwrite the best.
	var second := SaveData.record_recipe_result("tom_yum_pla", 0, 200, 0.2, false)
	if int(SaveData.recipe_stats("tom_yum_pla").get("best_score", 0)) == 500:
		print("  save: a worse second attempt leaves the personal best alone")
	else:
		failures.append("save: a worse attempt overwrote the best score")
	if bool(second.get("new_best_score", false)):
		failures.append("save: a worse attempt was reported as a new best")
	if int(SaveData.recipe_stats("tom_yum_pla").get("attempts", 0)) == 2:
		print("  save: two attempts are counted as two attempts")
	else:
		failures.append("save: attempts were miscounted")

	# Discovery counts must not double-count the same dish.
	var before := SaveData.discovered_count()
	SaveData.discover_recipe("tom_yum_pla")
	if SaveData.discovered_count() == before:
		print("  save: re-cooking a discovered dish does not inflate the count")
	else:
		failures.append("save: discovery count grew without a new dish")

	# Achievements that need a real endless streak must not unlock early.
	if SaveData.has_achievement("endless_ten"):
		failures.append("save: the endless-10 achievement unlocked without a streak")
	SaveData.record_endless(5000, 10, false)
	if SaveData.has_achievement("endless_ten"):
		print("  save: the endless streak achievement unlocks at a streak of 10")
	else:
		failures.append("save: a streak of 10 did not unlock its achievement")

	# Favourites and recents.
	SaveData.toggle_favourite("tom_yum_pla")
	if SaveData.is_favourite("tom_yum_pla"):
		print("  save: favourites round-trip through the manager")
	else:
		failures.append("save: a favourite did not stick")
	SaveData.toggle_favourite("tom_yum_pla")
	if SaveData.is_favourite("tom_yum_pla"):
		failures.append("save: un-favouriting did nothing")
	if not SaveData.recent_ids().has("tom_yum_pla"):
		failures.append("save: a cooked dish did not reach the recent list")

	# Reset must clear the new fields too.
	SaveData.reset_progress()
	if SaveData.discovered_count() == 0 and SaveData.endless_stats().get("best_streak", 0) == 0 \
			and SaveData.unlocked_achievements().is_empty() and SaveData.favourite_ids().is_empty():
		print("  save: reset clears dishes, records, achievements and favourites")
	else:
		failures.append("save: reset left progress behind")
	if FileAccess.file_exists(SaveData.SAVE_PATH):
		failures.append("save: reset left the save file on disk")


# ==================================================================== helpers ===
const SAVE_V2 := "user://save_v2.json"


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("save: could not write a test file at %s" % path)
		return
	file.store_string(text)
	file.close()


## Keeps the developer's real progress safe: every file this test may touch is read
## first and written back afterwards.
func _backup_saves() -> void:
	for path in [SaveData.SAVE_PATH, SAVE_V2, SaveData.LEGACY_V1_PATH]:
		if FileAccess.file_exists(path):
			_backup[path] = FileAccess.get_file_as_string(path)


func _restore_saves() -> void:
	for path in [SaveData.SAVE_PATH, SAVE_V2, SaveData.LEGACY_V1_PATH, SaveData.BACKUP_PATH,
			SaveData.TEMP_PATH, SaveData.LEGACY_V2_BACKUP, SaveData.LEGACY_V1_BACKUP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in _backup.keys():
		_write(str(path), str(_backup[path]))
	SaveData.load_progress()


func _report() -> void:
	print("--- results ---")
	if failures.is_empty():
		print("RECIPE TEST PASSED")
		get_tree().quit(0)
		return
	for failure in failures:
		printerr("  FAIL: " + failure)
	print("RECIPE TEST FAILED (%d problems)" % failures.size())
	get_tree().quit(1)
