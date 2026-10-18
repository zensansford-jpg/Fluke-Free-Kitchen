class_name AchievementDB
## The achievements a player can actually earn.
##
## Each one is tied to a real event the game can observe — a dish cooked, a recipe
## discovered, an endless streak reached. There are no achievements for simply
## opening a screen, and nothing is awarded without its condition being met (the
## conditions are checked in `SaveData._evaluate_achievements`).

extends RefCounted


static func list() -> Array:
	return [
		{"id": "first_dish", "rule": "recipes_cooked_1",
			"name": {"en": "First dish served", "th": "จานแรกที่เสิร์ฟ"},
			"hint": {"en": "Cook one dish all the way through.", "th": "ปรุงอาหารหนึ่งจานให้สำเร็จ"}},
		{"id": "three_dishes", "rule": "recipes_cooked_3",
			"name": {"en": "Getting the hang of it", "th": "เริ่มคุ้นมือ"},
			"hint": {"en": "Finish three dishes.", "th": "ทำอาหารให้สำเร็จสามจาน"}},
		{"id": "five_dishes", "rule": "recipes_discovered_5",
			"name": {"en": "Discoverer", "th": "นักค้นหาเมนู"},
			"hint": {"en": "Discover five different dishes.", "th": "ค้นพบเมนูที่แตกต่างกันห้าเมนู"}},
		{"id": "flip_master", "rule": "flip_challenge_done",
			"name": {"en": "Flip master", "th": "จอมพลิกปลา"},
			"hint": {"en": "Finish the Flip Master skill challenge.", "th": "ผ่านด่านฝึกพลิกปลา"}},
		{"id": "perfect_dish", "rule": "recipe_three_stars",
			"name": {"en": "Three stars", "th": "สามดาว"},
			"hint": {"en": "Earn three stars on any dish.", "th": "ได้สามดาวจากเมนูใดก็ได้"}},
		{"id": "endless_ten", "rule": "endless_streak_10",
			"name": {"en": "Ten in a row", "th": "สิบจานติด"},
			"hint": {"en": "Reach a streak of ten in the Endless Kitchen.", "th": "ทำสถิติต่อเนื่องสิบจานในครัวไม่รู้จบ"}},
		{"id": "collector", "rule": "all_real_dishes",
			"name": {"en": "Full menu", "th": "ครบทุกเมนู"},
			"hint": {"en": "Discover every real dish in the catalogue.", "th": "ค้นพบเมนูจริงทุกเมนูในสารบัญ"}},
		{"id": "signature_dish", "rule": "cookbook_1",
			"name": {"en": "Signature dish", "th": "เมนูประจำตัว"},
			"hint": {"en": "Save a dish you created in your own cookbook.", "th": "บันทึกจานที่คุณสร้างไว้ในสมุดสูตรของคุณ"}},
	]


static func by_id(achievement_id: String) -> Dictionary:
	for entry in list():
		if str(entry.get("id", "")) == achievement_id:
			return entry
	return {}


static func title(entry: Dictionary) -> String:
	return LessonDB.text(entry, "name", Loc.language)


static func hint(entry: Dictionary) -> String:
	return LessonDB.text(entry, "hint", Loc.language)


static func ids() -> Array[String]:
	var out: Array[String] = []
	for entry in list():
		out.append(str(entry.get("id", "")))
	return out
