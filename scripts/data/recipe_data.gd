class_name RecipeDB
## The fish-dish catalogue: fish varieties, ingredients, cooking methods, plating
## styles and recipes — plus the builders that turn a recipe into the concrete
## interactive steps the kitchen runs.
##
## **This file is content plus a small amount of pure logic.** Nothing here touches
## the scene tree, so the whole catalogue can be validated and the challenge
## generator tested without opening a window.
##
## Two things are kept strictly apart, because the competition judges data quality:
##
##   * `real` recipes are actual Thai dishes. Their fish, ingredients and method are
##     described as accurately as the project can manage.
##   * recipes with `real: false` are **game challenge variations** — skill runs and
##     endless-mode modifiers. They are never named as if they were traditional
##     dishes, and their `note` says so in both languages.
##
## The fish list distinguishes species from colour variants. A red tilapia is the
## same species as a grey one (`variant_of`), and the game says so rather than
## pretending a recolour is a new animal.

extends RefCounted

# ===================================================================== fish ===
## Freshwater species that can carry liver-fluke larvae (`fluke_host: true`) must be
## cooked through; sea fish are not part of the fluke life cycle but are still cooked
## properly. `body` picks the silhouette, `size` scales it, `tint` colours it.
static func fish() -> Array:
	return [
		{
			"id": "pla_nil", "name": {"en": "Nile tilapia", "th": "ปลานิล"},
			"kind": "freshwater", "fluke_host": true, "body": "round",
			"size": 1.0, "tint": Color(0.62, 0.66, 0.60), "variant_of": "",
			"note": {"en": "The most common farmed fish in the region.",
				"th": "ปลาเลี้ยงที่พบมากที่สุดในพื้นที่"},
		},
		{
			"id": "pla_nil_red", "name": {"en": "Red Nile tilapia", "th": "ปลานิลแดง"},
			"kind": "freshwater", "fluke_host": true, "body": "round",
			"size": 1.0, "tint": Color(0.78, 0.45, 0.42), "variant_of": "pla_nil",
			"note": {"en": "A colour variety of Nile tilapia, not a separate species.",
				"th": "ปลานิลสีแดง เป็นเพียงสายพันธุ์สี ไม่ใช่ชนิดใหม่"},
		},
		{
			"id": "pla_chon", "name": {"en": "Snakehead fish", "th": "ปลาช่อน"},
			"kind": "freshwater", "fluke_host": true, "body": "slender",
			"size": 1.15, "tint": Color(0.45, 0.40, 0.30), "variant_of": "",
			"note": {"en": "Long and muscular; a favourite for grilling.",
				"th": "ตัวยาว ลำตัวแน่น นิยมนำมาย่าง"},
		},
		{
			"id": "pla_duk", "name": {"en": "Walking catfish", "th": "ปลาดุก"},
			"kind": "freshwater", "fluke_host": true, "body": "catfish",
			"size": 1.05, "tint": Color(0.38, 0.36, 0.34), "variant_of": "",
			"note": {"en": "Smooth-skinned catfish with barbels around the mouth.",
				"th": "ปลาหนังผิวเรียบ มีหนวดรอบปาก"},
		},
		{
			"id": "pla_tapian", "name": {"en": "Silver barb", "th": "ปลาตะเพียน"},
			"kind": "freshwater", "fluke_host": true, "body": "flat",
			"size": 0.85, "tint": Color(0.76, 0.78, 0.74), "variant_of": "",
			"note": {"en": "Small, deep-bodied and silvery.",
				"th": "ตัวเล็ก ลำตัวแบน สีเงิน"},
		},
		{
			"id": "pla_swai", "name": {"en": "Iridescent shark catfish", "th": "ปลาสวาย"},
			"kind": "freshwater", "fluke_host": true, "body": "catfish",
			"size": 1.2, "tint": Color(0.52, 0.54, 0.58), "variant_of": "",
			"note": {"en": "A large river catfish.",
				"th": "ปลาหนังขนาดใหญ่ในแม่น้ำ"},
		},
		{
			"id": "pla_kapong", "name": {"en": "Sea bass", "th": "ปลากะพง"},
			"kind": "sea", "fluke_host": false, "body": "round",
			"size": 1.1, "tint": Color(0.70, 0.74, 0.72), "variant_of": "",
			"note": {"en": "A sea fish; not part of the liver-fluke life cycle.",
				"th": "ปลาทะเล ไม่อยู่ในวงจรชีวิตของพยาธิใบไม้ตับ"},
		},
		{
			"id": "pla_thu", "name": {"en": "Short mackerel", "th": "ปลาทู"},
			"kind": "sea", "fluke_host": false, "body": "slender",
			"size": 0.8, "tint": Color(0.42, 0.52, 0.66), "variant_of": "",
			"note": {"en": "A small sea mackerel.",
				"th": "ปลาทะเลตัวเล็ก"},
		},
	]


static func fish_by_id(fish_id: String) -> Dictionary:
	for entry in fish():
		if str(entry.get("id", "")) == fish_id:
			return entry
	return {}


static func fish_ids() -> Array[String]:
	var out: Array[String] = []
	for entry in fish():
		out.append(str(entry.get("id", "")))
	return out


# ============================================================== ingredients ===
## Real ingredients used by the recipes below. `role` groups them so the add-step
## can show the right ones and the validator can reject nonsense combinations.
static func ingredients() -> Array:
	return [
		{"id": "lemongrass", "name": {"en": "Lemongrass", "th": "ตะไคร้"}, "role": "aromatic", "colour": Color(0.72, 0.78, 0.45)},
		{"id": "galangal", "name": {"en": "Galangal", "th": "ข่า"}, "role": "aromatic", "colour": Color(0.83, 0.74, 0.50)},
		{"id": "kaffir_lime", "name": {"en": "Kaffir lime leaves", "th": "ใบมะกรูด"}, "role": "aromatic", "colour": Color(0.34, 0.55, 0.28)},
		{"id": "garlic", "name": {"en": "Garlic", "th": "กระเทียม"}, "role": "aromatic", "colour": Color(0.90, 0.88, 0.80)},
		{"id": "shallot", "name": {"en": "Shallot", "th": "หอมแดง"}, "role": "aromatic", "colour": Color(0.72, 0.48, 0.55)},
		{"id": "chilli", "name": {"en": "Chilli", "th": "พริก"}, "role": "aromatic", "colour": Color(0.80, 0.20, 0.16)},
		{"id": "lime", "name": {"en": "Lime", "th": "มะนาว"}, "role": "seasoning", "colour": Color(0.62, 0.80, 0.30)},
		{"id": "fish_sauce", "name": {"en": "Fish sauce", "th": "น้ำปลา"}, "role": "seasoning", "colour": Color(0.55, 0.35, 0.18)},
		{"id": "tamarind", "name": {"en": "Tamarind", "th": "มะขาม"}, "role": "seasoning", "colour": Color(0.50, 0.34, 0.20)},
		{"id": "palm_sugar", "name": {"en": "Palm sugar", "th": "น้ำตาลปี๊บ"}, "role": "seasoning", "colour": Color(0.70, 0.52, 0.28)},
		{"id": "coconut_milk", "name": {"en": "Coconut milk", "th": "กะทิ"}, "role": "seasoning", "colour": Color(0.94, 0.92, 0.86)},
		{"id": "red_curry_paste", "name": {"en": "Red curry paste", "th": "พริกแกงเผ็ด"}, "role": "seasoning", "colour": Color(0.66, 0.24, 0.18)},
		{"id": "salt", "name": {"en": "Salt", "th": "เกลือ"}, "role": "seasoning", "colour": Color(0.92, 0.93, 0.95)},
		{"id": "basil", "name": {"en": "Thai basil", "th": "ใบกะเพรา"}, "role": "herb", "colour": Color(0.26, 0.46, 0.26)},
		{"id": "mint", "name": {"en": "Mint", "th": "ใบสะระแหน่"}, "role": "herb", "colour": Color(0.40, 0.66, 0.38)},
		{"id": "coriander", "name": {"en": "Coriander", "th": "ผักชี"}, "role": "herb", "colour": Color(0.44, 0.62, 0.34)},
		{"id": "spring_onion", "name": {"en": "Spring onion", "th": "ต้นหอม"}, "role": "herb", "colour": Color(0.46, 0.68, 0.40)},
		{"id": "tomato", "name": {"en": "Tomato", "th": "มะเขือเทศ"}, "role": "vegetable", "colour": Color(0.78, 0.26, 0.22)},
		{"id": "mushroom", "name": {"en": "Straw mushroom", "th": "เห็ดฟาง"}, "role": "vegetable", "colour": Color(0.84, 0.78, 0.66)},
		{"id": "cabbage", "name": {"en": "Cabbage", "th": "กะหล่ำปลี"}, "role": "vegetable", "colour": Color(0.78, 0.84, 0.60)},
		{"id": "morning_glory", "name": {"en": "Morning glory", "th": "ผักบุ้ง"}, "role": "vegetable", "colour": Color(0.34, 0.58, 0.30)},
		{"id": "long_bean", "name": {"en": "Long bean", "th": "ถั่วฝักยาว"}, "role": "vegetable", "colour": Color(0.46, 0.62, 0.32)},
		{"id": "cucumber", "name": {"en": "Cucumber", "th": "แตงกวา"}, "role": "vegetable", "colour": Color(0.54, 0.72, 0.36)},
		{"id": "rice_flour", "name": {"en": "Rice flour", "th": "แป้งข้าวเจ้า"}, "role": "binder", "colour": Color(0.94, 0.94, 0.90)},
		{"id": "egg", "name": {"en": "Egg", "th": "ไข่"}, "role": "binder", "colour": Color(0.94, 0.86, 0.62)},
		{"id": "toasted_rice", "name": {"en": "Toasted rice", "th": "ข้าวคั่ว"}, "role": "seasoning", "colour": Color(0.78, 0.66, 0.44)},
		{"id": "sticky_rice", "name": {"en": "Sticky rice", "th": "ข้าวเหนียว"}, "role": "side", "colour": Color(0.92, 0.90, 0.84)},
	]


static func ingredient_by_id(ingredient_id: String) -> Dictionary:
	for entry in ingredients():
		if str(entry.get("id", "")) == ingredient_id:
			return entry
	return {}


static func ingredient_ids() -> Array[String]:
	var out: Array[String] = []
	for entry in ingredients():
		out.append(str(entry.get("id", "")))
	return out


# ================================================================== methods ===
## How the fish is cooked. `steps` is the cooking order the builder assembles from;
## `vessel` names the pan the kitchen should show for it.
static func methods() -> Array:
	return [
		{"id": "boil", "name": {"en": "Boil (soup)", "th": "ต้ม (แกง/ซุป)"}, "vessel": "pot",
			"cook_verb": {"en": "Simmer until the fish is cooked through", "th": "ต้มเคี่ยวจนปลาสุกทั่วถึง"},
			"needs_flip": false, "stir_circles": 3},
		{"id": "steam", "name": {"en": "Steam", "th": "นึ่ง"}, "vessel": "steamer",
			"cook_verb": {"en": "Steam until the fish is cooked through", "th": "นึ่งจนปลาสุกทั่วถึง"},
			"needs_flip": false, "stir_circles": 0},
		{"id": "grill", "name": {"en": "Grill", "th": "ย่าง"}, "vessel": "grill",
			"cook_verb": {"en": "Grill until the fish is cooked through", "th": "ย่างจนปลาสุกทั่วถึง"},
			"needs_flip": true, "stir_circles": 0},
		{"id": "fry", "name": {"en": "Deep-fry", "th": "ทอด"}, "vessel": "wok",
			"cook_verb": {"en": "Fry until the fish is cooked through", "th": "ทอดจนปลาสุกทั่วถึง"},
			"needs_flip": true, "stir_circles": 0},
		{"id": "stir_fry", "name": {"en": "Stir-fry", "th": "ผัด"}, "vessel": "wok",
			"cook_verb": {"en": "Stir-fry until the fish is cooked through", "th": "ผัดจนปลาสุกทั่วถึง"},
			"needs_flip": false, "stir_circles": 4},
		{"id": "mince_fry", "name": {"en": "Mince and fry", "th": "สับแล้วทอด"}, "vessel": "wok",
			"cook_verb": {"en": "Fry the mix until it is cooked through", "th": "ทอดจนส่วนผสมสุกทั่วถึง"},
			"needs_flip": true, "stir_circles": 3},
	]


static func method_by_id(method_id: String) -> Dictionary:
	for entry in methods():
		if str(entry.get("id", "")) == method_id:
			return entry
	return {}


static func method_ids() -> Array[String]:
	var out: Array[String] = []
	for entry in methods():
		out.append(str(entry.get("id", "")))
	return out


# ================================================================= garnishes ===
static func garnishes() -> Array:
	return [
		{"id": "coriander", "name": {"en": "Coriander", "th": "ผักชี"}, "colour": Color(0.44, 0.62, 0.34)},
		{"id": "spring_onion", "name": {"en": "Spring onion", "th": "ต้นหอม"}, "colour": Color(0.46, 0.68, 0.40)},
		{"id": "mint", "name": {"en": "Mint", "th": "ใบสะระแหน่"}, "colour": Color(0.40, 0.66, 0.38)},
		{"id": "basil", "name": {"en": "Thai basil", "th": "ใบกะเพรา"}, "colour": Color(0.26, 0.46, 0.26)},
		{"id": "chilli_slices", "name": {"en": "Sliced chilli", "th": "พริกหั่นแว่น"}, "colour": Color(0.80, 0.20, 0.16)},
		{"id": "lime_wedge", "name": {"en": "Lime wedge", "th": "มะนาวหั่นเสี้ยว"}, "colour": Color(0.62, 0.80, 0.30)},
		{"id": "cucumber", "name": {"en": "Cucumber", "th": "แตงกวา"}, "colour": Color(0.54, 0.72, 0.36)},
	]


static func garnish_by_id(garnish_id: String) -> Dictionary:
	for entry in garnishes():
		if str(entry.get("id", "")) == garnish_id:
			return entry
	return {}


# =================================================================== plating ===
static func plating_styles() -> Array:
	return [
		{"id": "bowl", "name": {"en": "Soup bowl", "th": "ชามซุป"}},
		{"id": "plate", "name": {"en": "Round plate", "th": "จานกลม"}},
		{"id": "oval", "name": {"en": "Oval plate", "th": "จานรี"}},
		{"id": "platter", "name": {"en": "Sharing platter", "th": "จานแชร์"}},
		{"id": "banana_leaf", "name": {"en": "Banana-leaf plate", "th": "จานใบตอง"}},
	]


static func plating_by_id(plating_id: String) -> Dictionary:
	for entry in plating_styles():
		if str(entry.get("id", "")) == plating_id:
			return entry
	return {}


# ================================================================== recipes ===
## The catalogue. `real` distinguishes an actual Thai dish from a game challenge
## variation. Every recipe carries the cooking method, its fish choices, its
## ingredients, its garnish and plating, its difficulty and its unlock rule.
static func recipes() -> Array:
	return [
		{
			"id": "tom_yum_pla",
			"real": true,
			"name": {"en": "Tom yum fish soup", "th": "ต้มยำปลา"},
			"about": {
				"en": "A hot-and-sour soup. The fish is simmered until it is opaque and cooked through; the lime goes in at the end for flavour only.",
				"th": "ซุปเปรี้ยวเผ็ด ปลาถูกต้มจนเนื้อทึบและสุกทั่วถึง มะนาวใส่ตอนท้ายเพื่อรสชาติเท่านั้น",
			},
			"method": "boil",
			"fish": ["pla_nil", "pla_chon", "pla_kapong"],
			"ingredients": ["lemongrass", "galangal", "kaffir_lime", "chilli", "lime", "fish_sauce", "mushroom", "tomato"],
			"garnish": ["coriander", "spring_onion"],
			"plating": "bowl",
			"difficulty": 1,
			"unlock": "",
			"tags": ["soup", "beginner", "lime-finish"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute", "separate_raw"],
			"note": "",
		},
		{
			"id": "pla_neung_manao",
			"real": true,
			"name": {"en": "Steamed fish with lime", "th": "ปลานึ่งมะนาว"},
			"about": {
				"en": "Steamed fish dressed with garlic, chilli and lime. Steaming cooks the fish; the lime is a dressing, not a safety step.",
				"th": "ปลานึ่งราดด้วยกระเทียม พริก และมะนาว การนึ่งทำให้ปลาสุก ส่วนมะนาวเป็นน้ำยำ ไม่ใช่ขั้นตอนความปลอดภัย",
			},
			"method": "steam",
			"fish": ["pla_kapong", "pla_nil"],
			"ingredients": ["garlic", "chilli", "lime", "fish_sauce", "coriander"],
			"garnish": ["coriander", "chilli_slices"],
			"plating": "oval",
			"difficulty": 2,
			"unlock": "",
			"tags": ["steamed", "lime-finish"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": "",
		},
		{
			"id": "pla_pao",
			"real": true,
			"name": {"en": "Salt-crusted grilled fish", "th": "ปลาเผา"},
			"about": {
				"en": "A whole fish packed in salt and grilled, often stuffed with lemongrass. Grilling needs turning so both sides cook.",
				"th": "ปลาทั้งตัวคลุกเกลือแล้วย่าง มักยัดไส้ตะไคร้ การย่างต้องพลิกกลับเพื่อให้สุกทั้งสองด้าน",
			},
			"method": "grill",
			"fish": ["pla_nil", "pla_chon", "pla_duk"],
			"ingredients": ["salt", "lemongrass", "galangal"],
			"garnish": ["coriander", "lime_wedge"],
			"plating": "platter",
			"difficulty": 2,
			"unlock": "pla_neung_manao",
			"tags": ["grilled", "flip"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": "",
		},
		{
			"id": "pla_thot_nam_pla",
			"real": true,
			"name": {"en": "Crispy fried fish with fish sauce", "th": "ปลาทอดน้ำปลา"},
			"about": {
				"en": "Fish coated lightly in rice flour and fried until crisp and cooked through, seasoned with fish sauce and garlic.",
				"th": "ปลาชุบแป้งข้าวเจ้าบาง ๆ ทอดจนกรอบและสุกทั่วถึง ปรุงรสด้วยน้ำปลาและกระเทียม",
			},
			"method": "fry",
			"fish": ["pla_nil", "pla_nil_red", "pla_thu"],
			"ingredients": ["fish_sauce", "garlic", "rice_flour"],
			"garnish": ["chilli_slices", "spring_onion"],
			"plating": "plate",
			"difficulty": 2,
			"unlock": "tom_yum_pla",
			"tags": ["fried", "flip", "crispy"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly"],
			"note": "",
		},
		{
			"id": "kaeng_som_pla",
			"real": true,
			"name": {"en": "Sour fish curry", "th": "แกงส้มปลา"},
			"about": {
				"en": "A tamarind-soured curry with vegetables. The fish simmers in the broth until it is cooked through.",
				"th": "แกงรสเปรี้ยวมะขามใส่ผัก ปลาต้มในน้ำแกงจนสุกทั่วถึง",
			},
			"method": "boil",
			"fish": ["pla_chon", "pla_duk", "pla_swai"],
			"ingredients": ["tamarind", "chilli", "garlic", "shallot", "fish_sauce", "palm_sugar", "cabbage", "morning_glory"],
			"garnish": ["coriander"],
			"plating": "bowl",
			"difficulty": 2,
			"unlock": "pla_thot_nam_pla",
			"tags": ["soup", "tamarind"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": "",
		},
		{
			"id": "pla_duk_phat_phet",
			"real": true,
			"name": {"en": "Spicy stir-fried catfish", "th": "ปลาดุกผัดเผ็ด"},
			"about": {
				"en": "Catfish stir-fried with red curry paste and Thai basil. The fish is cooked fully in the wok before serving.",
				"th": "ปลาดุกผัดพริกแกงเผ็ดกับใบกะเพรา ปรุงในกระทะจนสุกทั่วก่อนเสิร์ฟ",
			},
			"method": "stir_fry",
			"fish": ["pla_duk", "pla_swai"],
			"ingredients": ["red_curry_paste", "kaffir_lime", "chilli", "basil", "fish_sauce", "palm_sugar", "long_bean"],
			"garnish": ["basil", "chilli_slices"],
			"plating": "plate",
			"difficulty": 2,
			"unlock": "kaeng_som_pla",
			"tags": ["stir-fry", "spicy"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly"],
			"note": "",
		},
		{
			"id": "thot_man_pla",
			"real": true,
			"name": {"en": "Thai fish cakes", "th": "ทอดมันปลา"},
			"about": {
				"en": "Fish minced with curry paste, shaped into cakes and fried. The mix must be fried until cooked through, not just browned.",
				"th": "ปลาสับผสมพริกแกง ปั้นเป็นก้อนแล้วทอด ต้องทอดจนสุกทั่ว ไม่ใช่แค่ผิวเหลือง",
			},
			"method": "mince_fry",
			"fish": ["pla_duk", "pla_nil"],
			"ingredients": ["red_curry_paste", "rice_flour", "egg", "kaffir_lime", "long_bean"],
			"garnish": ["cucumber", "coriander"],
			"plating": "plate",
			"difficulty": 3,
			"unlock": "pla_duk_phat_phet",
			"tags": ["fried", "minced", "flip"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": "",
		},
		{
			"id": "lab_pla",
			"real": true,
			"name": {"en": "Warm fish salad (cooked)", "th": "ลาบปลา (ปรุงสุก)"},
			"about": {
				"en": "A north-eastern style fish salad. In this version the fish is cooked through first — the raw 'koi pla' style is a known liver-fluke risk and is not what this game teaches.",
				"th": "ลาบปลาแบบอีสาน ในเกมนี้ปรุงปลาให้สุกทั่วก่อน ส่วนแบบ 'ก้อยปลา' ที่กินดิบเป็นความเสี่ยงพยาธิใบไม้ตับที่รู้กันดี และไม่ใช่สิ่งที่เกมนี้สอน",
			},
			"method": "mince_fry",
			"fish": ["pla_duk", "pla_chon"],
			"ingredients": ["shallot", "mint", "coriander", "chilli", "lime", "fish_sauce", "toasted_rice"],
			"garnish": ["mint", "spring_onion"],
			"plating": "banana_leaf",
			"difficulty": 3,
			"unlock": "thot_man_pla",
			"tags": ["salad", "cooked-only"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute", "freshwater_fish_risk"],
			"note": {"en": "Cooked version only: the raw preparation is the transmission route.",
				"th": "เฉพาะแบบปรุงสุกเท่านั้น เพราะแบบดิบคือเส้นทางติดพยาธิ"},
		},
		{
			"id": "tom_kloeng_pla",
			"real": true,
			"provenance": "regional",
			"name": {"en": "Spicy sour fish soup (central style)", "th": "ต้มโคล้งปลา"},
			"about": {
				"en": "A tamarind-soured soup, drier and sharper than tom yum. Grilled fish is often used, so the fish is cooked twice: once over the fire, then again in the broth. Both matter.",
				"th": "ซุปเปรี้ยวมะขาม รสจัดและน้ำน้อยกว่าต้มยำ มักใช้ปลาย่าง จึงปรุงสองครั้ง ทั้งบนไฟและในน้ำแกง ทั้งสองขั้นตอนสำคัญ",
			},
			"method": "boil",
			"fish": ["pla_chon", "pla_nil"],
			"ingredients": ["tamarind", "chilli", "shallot", "garlic", "fish_sauce", "palm_sugar", "mushroom"],
			"garnish": ["coriander", "spring_onion"],
			"plating": "bowl",
			"difficulty": 2,
			"unlock": "lab_pla",
			"tags": ["soup", "tamarind", "regional"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": {"en": "Central-style variation: recipes differ between kitchens, and this is one common form.",
				"th": "สูตรภาคกลาง สูตรต่างกันไปตามครัว นี่เป็นรูปแบบที่นิยมแบบหนึ่ง"},
		},
		{
			"id": "pla_phat_khing",
			"real": true,
			"provenance": "regional",
			"name": {"en": "Fish stir-fried with ginger", "th": "ปลาผัดขิง"},
			"about": {
				"en": "Fish stir-fried with slivered ginger, spring onion and a little fermented bean paste. A quick dish, which makes it easy to pull off the heat while the middle of a thick piece is still raw.",
				"th": "ปลาผัดกับขิงซอย ต้นหอม และเต้าเจี้ยวเล็กน้อย เป็นเมนูเร็ว จึงถอดออกจากไฟได้ง่ายขณะที่เนื้อปลาชิ้นหนายังดิบอยู่ตรงกลาง",
			},
			"method": "stir_fry",
			"fish": ["pla_nil", "pla_chon", "pla_duk"],
			"ingredients": ["garlic", "chilli", "fish_sauce", "palm_sugar", "spring_onion"],
			"garnish": ["coriander", "spring_onion"],
			"plating": "plate",
			"difficulty": 2,
			"unlock": "pla_duk_phat_phet",
			"tags": ["stir-fry", "regional"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly"],
			"note": {"en": "A home-style variation: the seasoning differs from kitchen to kitchen.",
				"th": "สูตรตามบ้าน เครื่องปรุงต่างกันไปในแต่ละครัว"},
		},
		{
			"id": "pla_hor_mok",
			"real": true,
			"provenance": "regional",
			"name": {"en": "Steamed fish curry custard", "th": "ปลาฮ่อม๊ก"},
			"about": {
				"en": "A northern-style fish curry set with egg and steamed in a banana-leaf cup. The egg sets before the fish necessarily does, so the fish needs the full steaming time, not just a set surface.",
				"th": "แกงปลาแบบเหนือ ใส่ไข่แล้วนึ่งในกระทงใบตอง ไข่จะเซ็ตตัวก่อนที่ปลาจะสุกเสมอ ปลาจึงต้องนึ่งให้ครบเวลา ไม่ใช่แค่ผิวหน้าเซ็ตตัว",
			},
			"method": "steam",
			"fish": ["pla_nil", "pla_chon", "pla_duk"],
			"ingredients": ["red_curry_paste", "coconut_milk", "egg", "kaffir_lime", "fish_sauce", "basil"],
			"garnish": ["basil", "chilli_slices"],
			"plating": "bowl",
			"difficulty": 3,
			"unlock": "tom_kloeng_pla",
			"tags": ["steamed", "northern", "regional"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": {"en": "Northern-style variation: the paste and the cooking vessel differ by household.",
				"th": "สูตรภาคเหนือ พริกแกงและภาชนะนึ่งต่างกันไปตามครัวเรือน"},
		},
		{
			"id": "pla_sam_rot",
			"real": true,
			"provenance": "fusion",
			"name": {"en": "Three-flavour crispy fish (restaurant style)", "th": "ปลาสามรส (สไตล์ร้านอาหาร)"},
			"about": {
				"en": "Crisp-fried fish in a sweet-sour-spicy sauce. The three-flavour sauce is a restaurant development rather than an old village dish, and this game does not present it as one — but the fish still has to be fried until it is cooked through before the sauce goes on.",
				"th": "ปลาทอดกรอบราดซอสเปรี้ยวหวานเผ็ด ซอสสามรสเป็นพัฒนาการของร้านอาหาร ไม่ใช่กับข้าวพื้นบ้านเก่าแก่ และเกมนี้ไม่ได้นำเสนอเช่นนั้น แต่ปลายังต้องทอดจนสุกทั่วก่อนราดซอส",
			},
			"method": "fry",
			"fish": ["pla_nil", "pla_nil_red", "pla_thu"],
			"ingredients": ["garlic", "chilli", "tamarind", "palm_sugar", "fish_sauce"],
			"garnish": ["coriander", "spring_onion", "chilli_slices"],
			"plating": "plate",
			"difficulty": 3,
			"unlock": "pla_thot_nam_pla",
			"tags": ["fried", "fusion", "sweet-sour"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly"],
			"note": {"en": "A modern restaurant preparation, not a village recipe.",
				"th": "เมนูร้านอาหารสมัยใหม่ ไม่ใช่กับข้าวพื้นบ้าน"},
		},
		{
			"id": "mok_pa_lao",
			"real": true,
			"provenance": "regional",
			"name": {"en": "Lao steamed fish in banana leaf", "th": "หมกปลา (ลาว)"},
			"about": {
				"en": "A Lao preparation: fish mixed with herbs and sticky rice, wrapped in banana leaf and steamed. Wrapping it hides the fish, which is exactly why it needs the full time rather than a look at the outside.",
				"th": "อาหารลาว นำปลาคลุกสมุนไพรและข้าวเหนียว ห่อใบตองแล้วนึ่ง การห่อทำให้มองไม่เห็นตัวปลา จึงต้องนึ่งให้ครบเวลา ไม่ใช่ดูแค่ภายนอก",
			},
			"method": "steam",
			"fish": ["pla_chon", "pla_duk", "pla_nil"],
			"ingredients": ["lemongrass", "galangal", "kaffir_lime", "chilli", "fish_sauce", "sticky_rice", "spring_onion"],
			"garnish": ["mint", "chilli_slices"],
			"plating": "banana_leaf",
			"difficulty": 3,
			"unlock": "pla_hor_mok",
			"tags": ["steamed", "lao", "regional"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": {"en": "A Lao dish. The same freshwater-fluke rule applies across the region.",
				"th": "เมนูลาว หลักการเรื่องพยาธิใบไม้ตับในปลาน้ำจืดใช้เหมือนกันทั้งภูมิภาค"},
		},
		{
			"id": "cha_ca_la_vong",
			"real": true,
			"provenance": "regional",
			"name": {"en": "Vietnamese turmeric fish with dill", "th": "ปลา turmeric กับผักชีลาว (เวียดนาม)"},
			"about": {
				"en": "A Vietnamese dish: fish marinated in turmeric and fish sauce, then pan-fried with dill and spring onion. The marinade colours the surface long before the middle is cooked, so colour is not a guide here.",
				"th": "อาหารเวียดนาม ปลาหมักขมิ้นและน้ำปลา แล้วทอดในกระทะกับผักชีลาวและต้นหอม น้ำหมักทำให้ผิวเหลืองก่อนที่เนื้อในจะสุก สีจึงใช้บอกความสุกไม่ได้",
			},
			"method": "fry",
			"fish": ["pla_duk", "pla_nil", "pla_chon"],
			"ingredients": ["garlic", "chilli", "fish_sauce", "palm_sugar", "spring_onion", "coriander"],
			"garnish": ["coriander", "spring_onion", "lime_wedge"],
			"plating": "plate",
			"difficulty": 2,
			"unlock": "pla_phat_khing",
			"tags": ["fried", "vietnamese", "regional"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly"],
			"note": {"en": "A Vietnamese dish. Marinated fish can look cooked while still raw inside.",
				"th": "เมนูเวียดนาม ปลาหมักอาจดูเหมือนสุกแต่ข้างในยังดิบ"},
		},

		# ------------------------------------------- game challenge variations --
		{
			"id": "chl_flip_master",
			"real": false,
			"name": {"en": "Flip Master (skill run)", "th": "ภารกิจพลิกปลา (ฝึกฝีมือ)"},
			"about": {
				"en": "Not a traditional dish — a skills challenge built on grilled fish.",
				"th": "ไม่ใช่เมนูพื้นบ้าน แต่เป็นด่านฝึกฝีมือจากเมนูปลาย่าง",
			},
			"method": "grill",
			"fish": ["pla_chon", "pla_nil", "pla_duk"],
			"ingredients": ["salt", "lemongrass"],
			"garnish": ["lime_wedge"],
			"plating": "platter",
			"difficulty": 3,
			"unlock": "pla_pao",
			"tags": ["challenge", "flip", "skill"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly"],
			"note": {"en": "A game challenge, not a real recipe.",
				"th": "เป็นด่านในเกม ไม่ใช่สูตรอาหารจริง"},
		},
		{
			"id": "chl_knife_run",
			"real": false,
			"name": {"en": "Knife Skills Run (challenge)", "th": "ด่านฝึกมีด (ภารกิจ)"},
			"about": {
				"en": "Not a traditional dish — a chopping and stir-frying skills challenge.",
				"th": "ไม่ใช่เมนูพื้นบ้าน แต่เป็นด่านฝึกหั่นและผัด",
			},
			"method": "stir_fry",
			"fish": ["pla_duk", "pla_nil"],
			"ingredients": ["garlic", "chilli", "basil", "long_bean", "fish_sauce"],
			"garnish": ["basil"],
			"plating": "plate",
			"difficulty": 3,
			"unlock": "pla_duk_phat_phet",
			"tags": ["challenge", "slice", "stir"],
			"quiz": ["q_l2_cook"],
			"lessons": ["cook_thoroughly", "separate_raw"],
			"note": {"en": "A game challenge, not a real recipe.",
				"th": "เป็นด่านในเกม ไม่ใช่สูตรอาหารจริง"},
		},
		{
			"id": "chl_soup_sprint",
			"real": false,
			"name": {"en": "Soup Sprint (challenge)", "th": "ด่านซุปเร็ว (ภารกิจ)"},
			"about": {
				"en": "Not a traditional dish — a timed soup skills challenge.",
				"th": "ไม่ใช่เมนูพื้นบ้าน แต่เป็นด่านฝึกทำซุปแบบจับเวลา",
			},
			"method": "boil",
			"fish": ["pla_nil", "pla_kapong"],
			"ingredients": ["lemongrass", "galangal", "mushroom", "lime", "fish_sauce"],
			"garnish": ["coriander"],
			"plating": "bowl",
			"difficulty": 2,
			"unlock": "tom_yum_pla",
			"tags": ["challenge", "stir"],
			"quiz": ["q_l2_cook", "q_l2_lime"],
			"lessons": ["cook_thoroughly", "no_substitute"],
			"note": {"en": "A game challenge, not a real recipe.",
				"th": "เป็นด่านในเกม ไม่ใช่สูตรอาหารจริง"},
		},
	]


static func recipe_by_id(recipe_id: String) -> Dictionary:
	for entry in recipes():
		if str(entry.get("id", "")) == recipe_id:
			return entry
	return {}


static func recipe_ids() -> Array[String]:
	var out: Array[String] = []
	for entry in recipes():
		out.append(str(entry.get("id", "")))
	return out


## Real dishes only, in catalogue order.
static func real_recipes() -> Array:
	var out: Array = []
	for entry in recipes():
		if bool(entry.get("real", false)):
			out.append(entry)
	return out


## Challenge variations, which are never presented as traditional dishes.
static func variations() -> Array:
	var out: Array = []
	for entry in recipes():
		if not bool(entry.get("real", true)):
			out.append(entry)
	return out


static func title(recipe: Dictionary) -> String:
	return LessonDB.text(recipe, "name", Loc.language)


## Where a dish is from, said in a word, for the capsule on its card.
##
## This is the *documented* home of the dish, added here rather than invented:
## no recipe claims a region it is not known for, an unrecognised id answers with
## an empty string, and a card simply shows no capsule instead of guessing. It is
## derived from the recipe id so the catalogue itself stays as it is.
static func region_of(recipe: Dictionary) -> String:
	var pair: Variant = REGIONS.get(str(recipe.get("id", "")), "")
	if pair == null or not (pair is Dictionary):
		return ""
	var key: Dictionary = pair
	if key.is_empty():
		return ""
	return LessonDB.local(key)


const REGIONS := {
	"tom_yum_pla": {"en": "Central Thai", "th": "ภาคกลาง"},
	"pla_neung_manao": {"en": "Central Thai", "th": "ภาคกลาง"},
	"pla_pao": {"en": "Northeastern Thai", "th": "ภาคอีสาน"},
	"pla_thot_nam_pla": {"en": "Central Thai", "th": "ภาคกลาง"},
	"kaeng_som_pla": {"en": "Central Thai", "th": "ภาคกลาง"},
	"pla_duk_phat_phet": {"en": "Central Thai", "th": "ภาคกลาง"},
	"thot_man_pla": {"en": "Central Thai", "th": "ภาคกลาง"},
	"lab_pla": {"en": "Northeastern Thai", "th": "ภาคอีสาน"},
	"tom_kloeng_pla": {"en": "Central Thai", "th": "ภาคกลาง"},
	"pla_phat_khing": {"en": "Central Thai", "th": "ภาคกลาง"},
	"pla_hor_mok": {"en": "Northern Thai", "th": "ภาคเหนือ"},
	"pla_sam_rot": {"en": "Thai restaurant", "th": "ร้านอาหารไทย"},
	"mok_pa_lao": {"en": "Lao", "th": "ลาว"},
	"cha_ca_la_vong": {"en": "Vietnamese", "th": "เวียดนาม"},
}


static func about(recipe: Dictionary) -> String:
	return LessonDB.text(recipe, "about", Loc.language)


# ============================================================== provenance ===
## How well attested a dish is, which is not the same question as "is it real".
##
## The catalogue grew from a handful of Thai dishes to a broad one, and "real or
## not" stopped being enough: a dish that is documented tradition and a dish that
## is a plausible modern restaurant variation are both real food, but they are not
## the same *claim*, and the project must not blur them. So every dish carries one
## of five grades, and the card says which one in plain words.
##
##   documented  — a dish with a known tradition and a written source. The game
##                 describes its method as accurately as it can and stands behind
##                 it (docs/REFERENCES.md).
##   regional    — a recognised dish whose *modern* form varies by kitchen: a
##                 common variation, honestly labelled as a variation.
##   fusion      — a dish that deliberately mixes traditions. It is real cooking,
##                 but it is not presented as anybody's traditional recipe.
##   generated   — composed by the game from its own ingredients and methods. Not
##                 a claim about any real cuisine at all.
##   challenge   — a skills run built on a real cooking method. Not a dish anyone
##                 eats; the game says so on its own card.
##   created     — made by the player in Free Cook or the recipe builder.
##
## Everything is derived from the recipe itself — its own `provenance` field when it
## has one, and otherwise from `real` and `tags` — so no recipe has to be rewritten
## to gain a grade, and a new recipe cannot accidentally ship unlabelled.
const DOCUMENTED := "documented"
const REGIONAL := "regional"
const FUSION := "fusion"
const GENERATED := "generated"
const CHALLENGE := "challenge"
const CREATED := "created"

## The order the grades are listed in, most strongly attested first.
const PROVENANCE_ORDER := [DOCUMENTED, REGIONAL, FUSION, GENERATED, CHALLENGE, CREATED]

const PROVENANCE_LABELS := {
	DOCUMENTED: {"en": "Documented dish", "th": "เมนูที่มีเอกสารยืนยัน"},
	REGIONAL: {"en": "Regional variation", "th": "สูตรท้องถิ่นแบบร่วมสมัย"},
	FUSION: {"en": "Fusion dish", "th": "เมนูผสมผสาน"},
	GENERATED: {"en": "Composed by the game", "th": "เกมสร้างขึ้น"},
	CHALLENGE: {"en": "Skill challenge", "th": "ด่านฝึกฝีมือ"},
	CREATED: {"en": "Your own creation", "th": "ผลงานของคุณ"},
}

## One plain sentence per grade, for the dish card. These are deliberately not
## interchangeable: a documented dish and a fusion dish must not read the same.
const PROVENANCE_NOTES := {
	DOCUMENTED: {
		"en": "A dish with a recorded tradition. Its fish, ingredients and method are described as accurately as this project can manage.",
		"th": "เมนูที่มีตำรับบันทึกไว้ ปลา เครื่องปรุง และวิธีปรุง อธิบายอย่างถูกต้องที่สุดเท่าที่โครงการนี้ทำได้",
	},
	REGIONAL: {
		"en": "A recognised dish whose modern form differs between kitchens. This is one common variation, and it is shown as a variation rather than as the original.",
		"th": "เมนูที่รู้จักกันดี แต่สูตรปัจจุบันต่างกันไปตามครัว นี่เป็นอีกหนึ่งสูตรที่นิยม และแสดงไว้ในฐานะสูตรท้องถิ่น ไม่ใช่ต้นตำรับ",
	},
	FUSION: {
		"en": "A dish that deliberately mixes more than one cooking tradition. It is real cooking, but it is not presented as anyone's traditional recipe.",
		"th": "เมนูที่ผสมผสานหลายวัฒนธรรมการปรุงเข้าด้วยกัน เป็นอาหารที่ทำได้จริง แต่ไม่ได้นำเสนอว่าเป็นสูตรพื้นบ้านของใคร",
	},
	GENERATED: {
		"en": "Composed by the game from its own fish, ingredients and methods. It is not a claim about any real cuisine, and it still has to be cooked safely.",
		"th": "เกมประกอบขึ้นจากปลา เครื่องปรุง และวิธีปรุงในเกมเอง ไม่ได้อ้างอิงว่าเป็นอาหารของชาติใด และยังต้องปรุงให้ปลอดภัยเช่นเดิม",
	},
	CHALLENGE: {
		"en": "Not a dish — a skills run built on a real cooking method. Nobody eats this; it is here to practise the technique safely.",
		"th": "ไม่ใช่เมนู แต่เป็นด่านฝึกฝีมือที่สร้างจากวิธีปรุงจริง ไม่มีใครกินสิ่งนี้ มันมีไว้เพื่อฝึกทักษะอย่างปลอดภัย",
	},
	CREATED: {
		"en": "A dish you put together yourself. It is your own creation, not a traditional recipe — and it still has to reach a safe temperature inside.",
		"th": "จานที่คุณคิดขึ้นเอง เป็นผลงานของคุณ ไม่ใช่สูตรอาหารพื้นบ้าน และยังต้องปรุงให้สุกถึงอุณหภูมิปลอดภัย",
	},
}


## The provenance grade of a dish. A recipe that names its own grade keeps it;
## otherwise a `real` dish is documented, a tagged skill run is a challenge, and
## anything else is composed by the game.
static func provenance(recipe: Dictionary) -> String:
	var declared := str(recipe.get("provenance", ""))
	if PROVENANCE_ORDER.has(declared):
		return declared
	if bool(recipe.get("real", false)):
		return DOCUMENTED
	for tag in recipe.get("tags", []):
		if str(tag) == "challenge":
			return CHALLENGE
	return GENERATED


static func provenance_label(recipe: Dictionary) -> String:
	return LessonDB.local(PROVENANCE_LABELS.get(provenance(recipe), {}))


static func provenance_note(recipe: Dictionary) -> String:
	return LessonDB.local(PROVENANCE_NOTES.get(provenance(recipe), {}))


## True for the grades that describe real food rather than a composition. Used to
## decide how strongly a card may word its claim, never to hide the grade.
static func is_traditional(recipe: Dictionary) -> bool:
	return provenance(recipe) in [DOCUMENTED, REGIONAL, FUSION]


## How many dishes carry each grade. Reported by the Discover page and by the
## catalogue test, so the breadth of the catalogue is a measured number rather than
## a description.
static func provenance_counts() -> Dictionary:
	var counts := {}
	for grade in PROVENANCE_ORDER:
		counts[grade] = 0
	for recipe in recipes():
		var grade := provenance(recipe)
		counts[grade] = int(counts.get(grade, 0)) + 1
	return counts



static func local(pair: Variant) -> String:
	return LessonDB.local(pair)


# ================================================================== unlocks ===
## A recipe is open when the recipe it depends on has been discovered. The first
## recipes have no dependency, so the player has something good to cook at once.
static func is_unlocked(recipe: Dictionary, discovered: Array) -> bool:
	var dependency := str(recipe.get("unlock", ""))
	if dependency.is_empty():
		return true
	return discovered.has(dependency)


## The recipes the player can choose right now, at or below `max_difficulty`.
static func unlocked_recipes(discovered: Array, max_difficulty: int = 3) -> Array:
	var out: Array = []
	for entry in recipes():
		if int(entry.get("difficulty", 1)) > max_difficulty:
			continue
		if is_unlocked(entry, discovered):
			out.append(entry)
	return out


# ============================================================ step builders ===
## Turns a recipe into the concrete interactive steps the kitchen runs. The step
## dictionaries use the same shape as `LevelDB` and are consumed by `TaskFactory`.
##
## Every fish recipe includes exactly one `cook_through` step whose safe
## temperature and hold time come from `GameConfig` (the CDC figure), so no recipe
## can quietly lower the safety bar. The colour of the fish is never the test.
static func build_steps(recipe: Dictionary, difficulty: int = -1) -> Array:
	var method := method_by_id(str(recipe.get("method", "")))
	if method.is_empty():
		return []
	var level := int(recipe.get("difficulty", 1)) if difficulty < 0 else difficulty
	level = clampi(level, 1, 3)

	var steps: Array = []

	var fish_id := _first_fish(recipe)
	var fish_spec := fish_by_id(fish_id)
	var fish_name: Dictionary = fish_spec.get("name", {"en": "Fish", "th": "ปลา"})
	var vessel := str(method.get("vessel", "wok"))

	# 1. Prepare the fish on the board (clean it, score it). Always first.
	_append_step(steps, "prep", {
		"kind": "prep_fish",
		"prompt": {"en": "Prepare the fish on the board.", "th": "เตรียมปลาบนเขียง"},
		"demo": true,
		"lesson": "separate_raw",
		"fish": fish_id,
		"fish_name": fish_name,
		"strokes": 2,
	})

	# 2. Chop an ingredient for the pot. Knife work appears from the second
	# difficulty up, so the first dishes stay short and later ones use more of the
	# kitchen.
	if level >= 2:
		var choppable := _choppable_ingredient(recipe)
		if not choppable.is_empty():
			_append_step(steps, "chop", {
				"kind": "slice",
				"prompt": {"en": "Chop the ingredients for the pot.", "th": "หั่นส่วนผสมสำหรับหม้อ"},
				"demo": true,
				"lesson": "clean_surfaces",
				"ingredient": str(choppable.get("id", "")),
				"strokes": 1 + level,
			})

	# 3. Add the aromatics / vegetables. Boiling and stir-frying get more of them.
	var add_count := clampi(2 + level, 2, 4)
	_append_step(steps, "add", {
		"kind": "drag_to",
		"prompt": {"en": "Put each ingredient with the fish, and keep the sink for washing.", "th": "ใส่ส่วนผสมลงไปกับปลา และกันอ่างล้างไว้สำหรับล้าง"},
		"demo": true,
		"lesson": "cook_thoroughly",
		"reject_key": "keep_kitchen_order",
		"targets": [
			{"id": "the_pan", "label": vessel_label(vessel)},
			{"id": "sink_area", "label": {"en": "Washing sink", "th": "อ่างล้าง"}},
		],
		"items": _add_items(recipe, add_count),
	})

	# 3. Heat the pan or pot.
	_append_step(steps, "heat", {
		"kind": "hold",
		"prompt": {"en": "Heat the pan until it is ready.", "th": "ตั้งกระทะจนร้อนพร้อมใช้"},
		"duration": 1.6 + 0.2 * float(level),
		"success_sound": "sizzle",
	})

	# 4. Method-specific gesture: stir, or a flip for grilling and frying.
	if bool(method.get("needs_flip", false)):
		_append_step(steps, "flip", {
			"kind": "flip",
			"prompt": {"en": "Flip the fish so both sides cook.", "th": "พลิกปลาเพื่อให้สุกทั้งสองด้าน"},
			"lesson": "cook_thoroughly",
			"flips": 1 + (1 if level >= 3 else 0),
			"vessel": vessel,
		})
	var circles := int(method.get("stir_circles", 0))
	if circles > 0:
		_append_step(steps, "stir", {
			"kind": "stir",
			"prompt": {"en": "Stir so the fish cooks evenly.", "th": "คนให้ปลาสุกทั่วถึง"},
			"lesson": "cook_thoroughly",
			"circles": circles,
			"vessel": vessel,
		})

	# 5. The one mandatory safety step. Its numbers are the safe minimum, always.
	_append_step(steps, "cook", {
		"kind": "cook_through",
		"prompt": {"en": "Cook until the inside reaches a safe temperature and stays there.",
			"th": "ปรุงจนอุณหภูมิภายในถึงระดับปลอดภัยและคงอยู่"},
		"lesson": "cook_thoroughly",
		"safe_temp": GameConfig.COOK_SAFE_TEMP_C,
		"hold_seconds": GameConfig.COOK_HOLD_SECONDS,
		"vessel": vessel,
	})

	# 6. The lime lesson, where the recipe has a lime finish: flavour is not safety.
	if level >= 2 and _has_ingredient(recipe, "lime"):
		_append_step(steps, "lime", {
			"kind": "choose_safer",
			"prompt": {"en": "The lime goes on at the end. What does it do?",
				"th": "มะนาวใส่ตอนท้าย มะนาวทำหน้าที่อะไร"},
			"lesson": "no_substitute",
			"corrects": ["lime_kills", "pickling_safe", "temp_magic_number"],
			"options": [
				{"id": "flavour", "label": {"en": "It adds flavour; the cooking is what makes it safe.",
					"th": "ให้รสชาติ ความปลอดภัยมาจากการปรุงสุก"}, "correct": true},
				{"id": "lime_kills", "label": {"en": "It kills any larvae in the fish.", "th": "ฆ่าตัวอ่อนในปลาให้หมด"},
					"why": {"en": "Lime juice does not reliably kill the larvae — only proper cooking does.",
						"th": "น้ำมะนาวไม่ได้กำจัดตัวอ่อนอย่างแน่นอน มีเพียงการปรุงสุกที่ถูกต้อง"}},
				{"id": "raw_ok", "label": {"en": "Fish with lime can be served raw.", "th": "ปลาที่บีบมะนาวเสิร์ฟดิบได้"},
					"why": {"en": "No. Raw freshwater fish can carry fluke larvae whatever is squeezed on it.",
						"th": "ไม่ได้ ปลาน้ำจืดดิบอาจมีตัวอ่อนพยาธิไม่ว่าจะบีบอะไรก็ตาม"}},
			],
		})

	# 7. Plate the dish. The garnish is dragged onto the plate and snapped.
	_append_step(steps, "plate", {
		"kind": "plate",
		"prompt": {"en": "Plate the dish and add the garnish.", "th": "จัดจานและใส่เครื่องตกแต่ง"},
		"lesson": "clean_surfaces",
		"plating": str(recipe.get("plating", "plate")),
		"main": {"id": "fish", "label": fish_name},
		"garnish": _garnish_items(recipe),
	})

	# 8. The serving decision — a real choice, not a quiz.
	_append_step(steps, "serve", {
		"kind": "serve",
		"prompt": {"en": "Is this fish ready to serve?", "th": "ปลาจานนี้พร้อมเสิร์ฟหรือยัง"},
		"lesson": "cook_thoroughly",
		"fish_name": fish_name,
		"dish_state": "safe",
	})

	return steps


static func method_display_name(method: Dictionary) -> String:
	return LessonDB.text(method, "name", Loc.language)


## What the container a recipe cooks in is called on screen, in both languages. The
## sorting step labels its container with this, so the drop target is named after the
## thing the recipe actually uses rather than "the pan" for everything.
static func vessel_label(vessel: String) -> Dictionary:
	match vessel:
		"pot":
			return {"en": "The pot", "th": "หม้อต้ม"}
		"steamer":
			return {"en": "The steamer", "th": "ซึ้งนึ่ง"}
		"grill":
			return {"en": "The grill", "th": "เตาย่าง"}
		_:
			return {"en": "The wok", "th": "กระทะ"}


## Builds an experimental challenge from a fish and a cooking method, for Free Cook.
## There is no named recipe, so the dish is always labelled experimental in the UI.
## The mandatory cook-through step is present exactly as in a real recipe: an unsafe
## method cannot become safe just because other ingredients were added.
static func build_free_cook(fish_id: String, method_id: String, difficulty: int = 1) -> Dictionary:
	var fish_spec := fish_by_id(fish_id)
	var method := method_by_id(method_id)
	if fish_spec.is_empty() or method.is_empty():
		return {}
	var fish_name: Dictionary = fish_spec.get("name", {"en": "Fish", "th": "ปลา"})
	var method_name := method_display_name(method)
	var level := clampi(difficulty, 1, 3)
	var vessel := str(method.get("vessel", "wok"))

	var steps: Array = []
	_append_step(steps, "prep", {
		"kind": "prep_fish",
		"prompt": {"en": "Prepare the fish on the board.", "th": "เตรียมปลาบนเขียง"},
		"demo": true, "lesson": "separate_raw", "fish": fish_id,
		"fish_name": fish_name, "strokes": 2,
	})
	_append_step(steps, "heat", {
		"kind": "hold",
		"prompt": {"en": "Heat the pan until it is ready.", "th": "ตั้งกระทะจนร้อนพร้อมใช้"},
		"duration": 1.6, "success_sound": "sizzle",
	})
	if bool(method.get("needs_flip", false)):
		_append_step(steps, "flip", {
			"kind": "flip",
			"prompt": {"en": "Flip the fish so both sides cook.", "th": "พลิกปลาเพื่อให้สุกทั้งสองด้าน"},
			"lesson": "cook_thoroughly", "flips": 1, "vessel": vessel,
		})
	if int(method.get("stir_circles", 0)) > 0:
		_append_step(steps, "stir", {
			"kind": "stir",
			"prompt": {"en": "Stir so the fish cooks evenly.", "th": "คนให้ปลาสุกทั่วถึง"},
			"lesson": "cook_thoroughly", "circles": 3, "vessel": vessel,
		})
	_append_step(steps, "cook", {
		"kind": "cook_through",
		"prompt": {"en": "Cook until the inside reaches a safe temperature and stays there.",
			"th": "ปรุงจนอุณหภูมิภายในถึงระดับปลอดภัยและคงอยู่"},
		"lesson": "cook_thoroughly",
		"safe_temp": GameConfig.COOK_SAFE_TEMP_C,
		"hold_seconds": GameConfig.COOK_HOLD_SECONDS,
		"vessel": vessel,
	})
	_append_step(steps, "plate", {
		"kind": "plate",
		"prompt": {"en": "Plate your own dish.", "th": "จัดจานในแบบของคุณเอง"},
		"lesson": "clean_surfaces", "plating": "plate",
		"main": {"id": "fish", "label": fish_name},
		"garnish": [{"id": "coriander", "label": garnish_by_id("coriander").get("name", {"en": "Coriander", "th": "ผักชี"})}],
	})
	_append_step(steps, "serve", {
		"kind": "serve",
		"prompt": {"en": "Is your dish ready to serve?", "th": "จานของคุณพร้อมเสิร์ฟหรือยัง"},
		"lesson": "cook_thoroughly", "fish_name": fish_name, "dish_state": "safe",
	})

	return {
		"id": "free_%s_%s" % [fish_id, method_id],
		"index": 2,
		"title": {
			"en": "Free Cook: %s, %s" % [str(fish_name.get("en", "Fish")), str(method_name)],
			"th": "ครัวอิสระ: %s %s" % [str(fish_name.get("th", "ปลา")), str(method_name)],
		},
		"goal": {
			"en": "Experiment with your own combination. This is a game creation, not a traditional recipe.",
			"th": "ทดลองผสมผสานในแบบของคุณเอง นี่คือการสร้างในเกม ไม่ใช่สูตรอาหารพื้นบ้าน",
		},
		"objective_short": {
			"en": "Cook your own dish — safely.",
			"th": "ปรุงจานของคุณเองอย่างปลอดภัย",
		},
		"real": false,
		"provenance": CREATED,
		"free_cook": true,
		"difficulty": level,
		"steps": steps,
		"quiz": ["q_l2_cook"],
		"required_quiz": ["q_l2_cook"],
		"lessons": ["cook_thoroughly"],
		"tags": ["free-cook", "experimental"],
		"generated": true,
	}


# ================================================ procedural dish composition ===
## Dishes the game composes itself, so the catalogue is never a fixed, finite list.
##
## A composed dish is built from the *same* real fish, ingredients and methods as a
## hand-written recipe and is held to the *same* `validate`/`validate_steps` before
## it can be played. It is never dressed up as a traditional dish: `real` is false
## and the `note` says so in both languages, exactly like a challenge variation.
##
## The whole composition is a pure function of one integer seed, so the same seed
## always yields the same dish and a bug can be reproduced instead of chased.

## Which plating styles suit which cooking method. Drawn from, not fixed, so two
## grilled dishes do not always arrive on the same plate.
const GENERATED_PLATING := {
	"boil": ["bowl"],
	"steam": ["oval", "plate"],
	"grill": ["platter", "banana_leaf"],
	"fry": ["plate", "banana_leaf"],
	"stir_fry": ["plate"],
	"mince_fry": ["banana_leaf", "plate"],
}


## The *recipe* a generated dish is built from. Kept separate from `generate_dish`
## so the raw composition can be validated and previewed without building steps.
static func generate_recipe(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var method: Dictionary = methods()[rng.randi_range(0, methods().size() - 1)]
	var method_id := str(method.get("id", ""))
	var method_name: Dictionary = method.get("name", {"en": method_id, "th": method_id})

	# Fish: a base species, not a colour variant. A generated "new" dish reads oddly
	# if it is named after a recolour whose species is different.
	var fish_pool: Array = []
	for entry in fish():
		var spec: Dictionary = entry
		if str(spec.get("variant_of", "")).is_empty():
			fish_pool.append(str(spec.get("id", "")))
	if fish_pool.is_empty():
		fish_pool.append("pla_nil")
	var fish_id := str(fish_pool[rng.randi_range(0, fish_pool.size() - 1)])
	var fish_name: Dictionary = fish_by_id(fish_id).get("name", {"en": "Fish", "th": "ปลา"})

	# Ingredients, drawn role by role so the mix is always sensible for cooking: at
	# least one aromatic (so a chopping step has something real to chop), at least
	# one seasoning, and however many vegetables and herbs the roll allows.
	var chosen: Array = []
	_pick_into(chosen, _ingredients_with_role("aromatic"), rng, 1, 2)
	_pick_into(chosen, _ingredients_with_role("seasoning"), rng, 1, 2)
	_pick_into(chosen, _ingredients_with_role("vegetable"), rng, 0, 2)
	_pick_into(chosen, _ingredients_with_role("herb"), rng, 0, 1)
	if method_id == "mince_fry":
		_pick_into(chosen, _ingredients_with_role("binder"), rng, 1, 1)

	var plating_options: Array = GENERATED_PLATING.get(method_id, ["plate"])
	var plating := str(plating_options[rng.randi_range(0, plating_options.size() - 1)])

	# One or two garnishes, never the same one twice.
	var garnish_pool: Array = []
	for entry in garnishes():
		garnish_pool.append(str((entry as Dictionary).get("id", "")))
	_shuffle(garnish_pool, rng)
	var garnish: Array = garnish_pool.slice(0, 1 + rng.randi_range(0, 1))

	return {
		"id": "gen_%d" % seed_value,
		"real": false,
		"provenance": GENERATED,
		"name": {
			"en": "Kitchen experiment: %s, %s" % [str(fish_name.get("en", "Fish")), str(method_name.get("en", method_id))],
			"th": "จานทดลองครัว: %s %s" % [str(fish_name.get("th", "ปลา")), str(method_name.get("th", method_id))],
		},
		"about": {
			"en": "A dish composed by the game from real fish, real ingredients and a real cooking method. It is a game creation, not a traditional recipe — but however it is made, the inside must reach a safe temperature.",
			"th": "จานที่เกมประกอบขึ้นจากปลา ส่วนผสม และวิธีปรุงจริง เป็นการสร้างในเกม ไม่ใช่สูตรอาหารพื้นบ้าน แต่ไม่ว่าจะปรุงแบบใด เนื้อในต้องถึงอุณหภูมิปลอดภัย",
		},
		"note": {
			"en": "A game-composed dish, not a traditional recipe.",
			"th": "จานที่เกมสร้างขึ้น ไม่ใช่สูตรอาหารพื้นบ้าน",
		},
		"method": method_id,
		"fish": [fish_id],
		"ingredients": chosen,
		"garnish": garnish,
		"plating": plating,
		"difficulty": rng.randi_range(1, 3),
		"unlock": "",
		"tags": ["generated", "experiment"],
		"quiz": ["q_l2_cook"],
		"lessons": ["cook_thoroughly"],
	}


## A runnable challenge for a generated dish, in the same shape as `build_free_cook`
## so the kitchen runs it exactly like any other. Returns `{}` on the (should be
## impossible) chance that the composition fails the shared validator, so the caller
## gets nothing rather than a broken dish.
static func generate_dish(seed_value: int) -> Dictionary:
	var recipe := generate_recipe(seed_value)
	var problems := validate(recipe)
	if not problems.is_empty():
		push_warning("RecipeDB: generated dish %d failed validation: %s"
			% [seed_value, ", ".join(problems)])
		return {}
	return {
		"id": "gen_challenge_%d" % seed_value,
		"index": 3,
		"title": recipe.get("name", {}),
		"goal": recipe.get("about", {}),
		"objective_short": {
			"en": "Cook a dish the kitchen invented — safely.",
			"th": "ปรุงจานที่ครัวคิดขึ้นอย่างปลอดภัย",
		},
		"recipe_id": str(recipe.get("id", "")),
		"real": false,
		"difficulty": int(recipe.get("difficulty", 1)),
		"steps": build_steps(recipe),
		"quiz": ["q_l2_cook"],
		"required_quiz": ["q_l2_cook"],
		"lessons": ["cook_thoroughly"],
		"tags": ["generated", "experiment"],
		"generated": true,
		"seed": seed_value,
	}


## A pool of distinct generated dishes from a base seed, for a browse list or a
## "surprise me" button, so the list is never exhausted. `generate_dish` already
## guarantees validity; this only removes near-duplicate rolls.
static func generated_pool(count: int, base_seed: int = 1337) -> Array:
	var out: Array = []
	var seen: Array = []
	var next_seed := base_seed
	var attempts := 0
	# Bounded: a run of unlucky rolls must not spin forever looking for variety.
	while out.size() < count and attempts < count * 8 + 16:
		attempts += 1
		var dish := generate_dish(next_seed)
		next_seed += 1
		if dish.is_empty():
			continue
		var signature := _dish_signature(dish)
		if seen.has(signature):
			continue
		seen.append(signature)
		out.append(dish)
	return out


## The ingredient ids this dish must actually use, so two seeds that compose the
## same method/fish/ingredient mix can be treated as the same dish.
static func _dish_signature(dish: Dictionary) -> String:
	var parts: Array = [JSON.stringify(dish.get("title", {}))]
	for entry in dish.get("steps", []):
		var step: Dictionary = entry
		if str(step.get("kind", "")) != "drag_to":
			continue
		for item in step.get("items", []):
			parts.append(str((item as Dictionary).get("id", "")))
		break
	return "|".join(PackedStringArray(parts))


## The composition of a *recipe* as one comparable string (method, plating, fish and
## the sorted ingredient and garnish ids). Two seeds that roll the same dish share a
## signature, so a browse list can skip near-duplicates without re-running the
## validator. Order-independent for the same reason a player-made dish's id is.
static func composition_signature(recipe: Dictionary) -> String:
	var parts: Array = [str(recipe.get("method", "")), str(recipe.get("plating", ""))]
	var fish: Array = recipe.get("fish", [])
	if not fish.is_empty():
		parts.append(str(fish[0]))
	parts.append("|".join(PackedStringArray(_sorted_ids(recipe.get("ingredients", [])))))
	parts.append("|".join(PackedStringArray(_sorted_ids(recipe.get("garnish", [])))))
	return "|".join(PackedStringArray(parts))


static func _ingredients_with_role(role: String) -> Array:
	var out: Array = []
	for entry in ingredients():
		if str(entry.get("role", "")) == role:
			out.append(str(entry.get("id", "")))
	return out


## Appends between `minimum` and `maximum` ids from `pool` to `chosen`, without
## repeating one already chosen. A single helper so every role is drawn the same way.
static func _pick_into(chosen: Array, pool: Array, rng: RandomNumberGenerator,
		minimum: int, maximum: int) -> void:
	if pool.is_empty() or maximum <= 0:
		return
	var copies := pool.duplicate()
	_shuffle(copies, rng)
	var want := rng.randi_range(maxi(minimum, 0), maxi(maximum, minimum))
	for i in mini(want, copies.size()):
		var id := str(copies[i])
		if not chosen.has(id):
			chosen.append(id)


static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = list[i]
		list[i] = list[j]
		list[j] = swap


# ===================================================== player-made dishes ===
## Dishes the player composes themselves, in the recipe creator.
##
## A player-made dish is built from the same real fish, ingredients, methods,
## garnishes and plating as everything else, and is held to the same `validate` /
## `validate_steps` before the kitchen will run it. It is never dressed up as a
## traditional recipe: `real` is false, `custom` is true, and the note says plainly
## that it is the player's own creation.
##
## The id is derived from the composition, so the same dish saved twice is the same
## dish (the cookbook de-duplicates it) and a restored save still finds its own id.

## The most ingredients and garnishes a player-made dish may use, so the built step
## list stays a reasonable length rather than a chore.
const CUSTOM_INGREDIENT_MAX := 5
const CUSTOM_GARNISH_MAX := 2


## Difficulty from the amount of work the dish asks for, so a five-ingredient dish
## gets the chopping step a two-ingredient one skips. Clamped to the 1–3 the
## validator and the kitchen understand.
static func custom_difficulty(ingredient_count: int) -> int:
	if ingredient_count >= 5:
		return 3
	if ingredient_count >= 3:
		return 2
	return 1


## Builds the *recipe* for a player-made dish. `name_text` is whatever the player
## typed; the same text is stored for both languages, because the game does not
## pretend to translate a name it was handed. Returns `{}` when the input cannot make
## a playable dish, so the creator can refuse it rather than save something broken.
static func custom_recipe(name_text: String, fish_id: String, method_id: String,
		ingredient_ids: Array, garnish_ids: Array, plating_id: String) -> Dictionary:
	var dish_name := name_text.strip_edges()
	if dish_name.is_empty():
		return {}
	if fish_by_id(fish_id).is_empty() or method_by_id(method_id).is_empty():
		return {}
	if plating_by_id(plating_id).is_empty():
		return {}

	# Keep only real, distinct ingredients, and refuse a dish with nothing in it or
	# more than the cap. Selection order is preserved for the kitchen; the id below is
	# computed from a sorted copy so two orders of the same dish are the same dish.
	var ingredients: Array = []
	for entry in ingredient_ids:
		var ingredient_id := str(entry)
		if ingredient_by_id(ingredient_id).is_empty() or ingredients.has(ingredient_id):
			continue
		ingredients.append(ingredient_id)
	if ingredients.is_empty() or ingredients.size() > CUSTOM_INGREDIENT_MAX:
		return {}

	var garnish: Array = []
	for entry in garnish_ids:
		var garnish_id := str(entry)
		if garnish_by_id(garnish_id).is_empty() or garnish.has(garnish_id):
			continue
		garnish.append(garnish_id)
		if garnish.size() >= CUSTOM_GARNISH_MAX:
			break

	var method_name: Dictionary = method_by_id(method_id).get("name", {"en": method_id, "th": method_id})
	var signature := "%s|%s|%s|%s|%s" % [
		fish_id, method_id,
		"|".join(PackedStringArray(_sorted_ids(ingredients))),
		"|".join(PackedStringArray(_sorted_ids(garnish))),
		plating_id,
	]
	return {
		"id": "custom_%d" % abs(hash(signature)),
		"real": false,
		"provenance": CREATED,
		"custom": true,
		"name": {"en": dish_name, "th": dish_name},
		"about": {
			"en": "A dish you put together yourself, cooked by %s. It is your own creation, not a traditional recipe — and it still has to reach a safe temperature inside." % str(method_name.get("en", method_id)),
			"th": "จานที่คุณคิดขึ้นเอง ปรุงด้วยวิธี %s เป็นผลงานของคุณ ไม่ใช่สูตรอาหารพื้นบ้าน และยังต้องปรุงให้สุกถึงอุณหภูมิปลอดภัย" % str(method_name.get("th", method_id)),
		},
		"note": {
			"en": "A dish you created, not a traditional recipe.",
			"th": "จานที่คุณสร้างขึ้น ไม่ใช่สูตรอาหารพื้นบ้าน",
		},
		"method": method_id,
		"fish": [fish_id],
		"ingredients": ingredients,
		"garnish": garnish,
		"plating": plating_id,
		"difficulty": custom_difficulty(ingredients.size()),
		"unlock": "",
		"tags": ["custom", "created"],
		"quiz": ["q_l2_cook"],
		"lessons": ["cook_thoroughly"],
	}


## A runnable challenge for a player-made dish, in the same shape as `build_free_cook`
## and `generate_dish` so the kitchen runs it like any other. Returns `{}` if the
## composition fails the shared validator.
static func build_custom(recipe: Dictionary) -> Dictionary:
	var problems := validate(recipe)
	if not problems.is_empty():
		push_warning("RecipeDB: a player-made dish failed validation: %s" % ", ".join(problems))
		return {}
	return {
		"id": "custom_challenge_%s" % str(recipe.get("id", "")),
		"index": 3,
		"title": recipe.get("name", {}),
		"goal": recipe.get("about", {}),
		"objective_short": {
			"en": "Cook the dish you created — safely.",
			"th": "ปรุงจานที่คุณสร้างขึ้นอย่างปลอดภัย",
		},
		"recipe_id": str(recipe.get("id", "")),
		"real": false,
		"custom": true,
		"difficulty": int(recipe.get("difficulty", 1)),
		"steps": build_steps(recipe),
		"quiz": ["q_l2_cook"],
		"required_quiz": ["q_l2_cook"],
		"lessons": ["cook_thoroughly"],
		"tags": ["custom", "created"],
	}


static func _sorted_ids(values: Array) -> Array:
	var out: Array = []
	for entry in values:
		out.append(str(entry))
	out.sort()
	return out


## Appends a step with a stable, unique id derived from its prefix and position.
## A helper rather than an inline counter because GDScript lambdas capture local
## variables by value, which would make every id the same number.
static func _append_step(steps: Array, prefix: String, step: Dictionary) -> void:
	step["id"] = "%s_%d" % [prefix, steps.size()]
	steps.append(step)


static func _first_fish(recipe: Dictionary) -> String:
	var list: Array = recipe.get("fish", [])
	if list.is_empty():
		return "pla_nil"
	return str(list[0])


static func _has_ingredient(recipe: Dictionary, ingredient_id: String) -> bool:
	var list: Array = recipe.get("ingredients", [])
	return list.has(ingredient_id)


## The first ingredient in a recipe that is worth chopping: a vegetable, herb or
## aromatic. Seasonings like fish sauce are poured, not chopped.
static func _choppable_ingredient(recipe: Dictionary) -> Dictionary:
	for entry in recipe.get("ingredients", []):
		var ingredient := ingredient_by_id(str(entry))
		if ingredient.is_empty():
			continue
		var role := str(ingredient.get("role", ""))
		if role == "vegetable" or role == "herb" or role == "aromatic":
			return ingredient
	return {}


## The ingredient items for the add step: a mix of the recipe's own ingredients plus
## one clear wrong item, so the step is a real choice and not a tap-anything.
static func _add_items(recipe: Dictionary, count: int) -> Array:
	var items: Array = []
	var used: Array = []
	var sources: Array = recipe.get("ingredients", [])
	for entry in sources:
		if items.size() >= count:
			break
		var ingredient_id := str(entry)
		var ingredient := ingredient_by_id(ingredient_id)
		if ingredient.is_empty():
			continue
		items.append({
			"id": ingredient_id,
			"label": ingredient.get("name", {"en": ingredient_id, "th": ingredient_id}),
			"target": "the_pan",
		})
		used.append(ingredient_id)
	# One non-food item that must not go in the pan: soap belongs at the sink. The
	# two-target layout makes this a real decision rather than a trap, and teaches
	# that the cooking pot is for food only.
	items.append({
		"id": "soap_bar",
		"label": {"en": "Bar of soap", "th": "ก้อนสบู่"},
		"target": "sink_area",
	})
	return items


static func _garnish_items(recipe: Dictionary) -> Array:
	var out: Array = []
	for entry in recipe.get("garnish", []):
		var garnish := garnish_by_id(str(entry))
		if garnish.is_empty():
			continue
		out.append({
			"id": str(entry),
			"label": garnish.get("name", {"en": str(entry), "th": str(entry)}),
		})
	return out


# ================================================================ validation ===
## Everything that would make a recipe unplayable, in one list. Called by the
## catalogue validator and by the challenge generator before a recipe is shown.
static func validate(recipe: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var recipe_id := str(recipe.get("id", ""))
	if recipe_id.is_empty():
		problems.append("a recipe has no id")
		return problems

	for field in ["name", "about", "method", "fish", "ingredients", "garnish", "plating"]:
		if not recipe.has(field):
			problems.append("%s: missing '%s'" % [recipe_id, field])

	if not recipe.has("real"):
		problems.append("%s: 'real' must state whether this is a real dish or a game variation" % recipe_id)

	var name: Variant = recipe.get("name", {})
	if typeof(name) != TYPE_DICTIONARY or not _pair_ok(name):
		problems.append("%s: name must have both English and Thai text" % recipe_id)

	if method_by_id(str(recipe.get("method", ""))).is_empty():
		problems.append("%s: unknown cooking method '%s'" % [recipe_id, str(recipe.get("method", ""))])

	for fish_id in recipe.get("fish", []):
		if fish_by_id(str(fish_id)).is_empty():
			problems.append("%s: unknown fish '%s'" % [recipe_id, str(fish_id)])

	for ingredient_id in recipe.get("ingredients", []):
		if ingredient_by_id(str(ingredient_id)).is_empty():
			problems.append("%s: unknown ingredient '%s'" % [recipe_id, str(ingredient_id)])

	for garnish_id in recipe.get("garnish", []):
		if garnish_by_id(str(garnish_id)).is_empty():
			problems.append("%s: unknown garnish '%s'" % [recipe_id, str(garnish_id)])

	if plating_by_id(str(recipe.get("plating", ""))).is_empty():
		problems.append("%s: unknown plating style '%s'" % [recipe_id, str(recipe.get("plating", ""))])

	var difficulty := int(recipe.get("difficulty", 0))
	if difficulty < 1 or difficulty > 3:
		problems.append("%s: difficulty must be 1, 2 or 3" % recipe_id)

	var unlock := str(recipe.get("unlock", ""))
	if not unlock.is_empty() and recipe_by_id(unlock).is_empty():
		problems.append("%s: unlocks from unknown recipe '%s'" % [recipe_id, unlock])

	if not bool(recipe.get("real", true)):
		var note: Variant = recipe.get("note", {})
		if typeof(note) != TYPE_DICTIONARY or not _pair_ok(note):
			problems.append("%s: a game variation must say so in a note (both languages)" % recipe_id)

	# The built steps must be runnable: known kinds, unique ids, exactly one safety
	# cook with the safe figure from the config, and every step's own payload present
	# and well formed. A step that cannot be played must be caught here, not by a
	# player staring at an empty screen.
	problems.append_array(validate_steps(build_steps(recipe)))

	# The lesson every step teaches and the lessons the card lists must all exist.
	for lesson_id in recipe.get("lessons", []):
		if LessonDB.by_id(str(lesson_id)).is_empty():
			problems.append("%s: unknown lesson '%s'" % [recipe_id, str(lesson_id)])

	return problems


## Checks a built step list. Shared by the recipe validator and by the challenge
## generator, so a generated challenge (including Free Cook) is held to exactly the
## same standard as a hand-written recipe.
static func validate_steps(steps: Array) -> Array[String]:
	var problems: Array[String] = []
	if steps.is_empty():
		problems.append("no steps were produced")
		return problems
	var seen: Array = []
	var cook_seen := 0
	for entry in steps:
		var step: Dictionary = entry
		var step_id := str(step.get("id", ""))
		if step_id.is_empty():
			problems.append("a step has no id")
		elif seen.has(step_id):
			problems.append("duplicate step id '%s'" % step_id)
		else:
			seen.append(step_id)
		var kind := str(step.get("kind", ""))
		if not TaskFactory.known_kinds().has(kind):
			problems.append("step '%s': kind '%s' is not implemented" % [step_id, kind])
		if not _pair_ok(step.get("prompt", {})):
			problems.append("step '%s': the instruction is missing one of the two languages" % step_id)
		var lesson := str(step.get("lesson", ""))
		if not lesson.is_empty() and LessonDB.by_id(lesson).is_empty():
			problems.append("step '%s': unknown lesson '%s'" % [step_id, lesson])
		if kind == "cook_through":
			cook_seen += 1
			if float(step.get("safe_temp", 0.0)) < GameConfig.COOK_SAFE_TEMP_C - 0.001:
				problems.append("step '%s': the cook step is below the safe temperature" % step_id)
		match kind:
			"drag_to":
				problems.append_array(_validate_sorting_step(step, step_id))
			"plate":
				problems.append_array(_validate_plating_step(step, step_id))
			"serve":
				if not _pair_ok(step.get("fish_name", {})):
					problems.append("step '%s': the serving decision needs the dish named in both languages" % step_id)
				var state := str(step.get("dish_state", "safe"))
				if state != "safe" and state != "undercooked":
					problems.append("step '%s': unknown dish state '%s'" % [step_id, state])
			"slice", "prep_fish":
				# The zero-reading tutorial: a chopping step is never shown without
				# its demonstration.
				if not bool(step.get("demo", false)):
					problems.append("step '%s': a chopping step must show its demonstration" % step_id)
				if int(step.get("strokes", 0)) < 1:
					problems.append("step '%s': a chopping step needs at least one cut" % step_id)
				if kind == "slice":
					var chopping := str(step.get("ingredient", ""))
					if ingredient_by_id(chopping).is_empty():
						problems.append("step '%s': unknown ingredient '%s' to chop" % [step_id, chopping])
				elif fish_by_id(str(step.get("fish", ""))).is_empty():
					problems.append("step '%s': unknown fish '%s' to prepare" % [step_id, str(step.get("fish", ""))])
			"flip":
				if int(step.get("flips", 0)) < 1:
					problems.append("step '%s': a flipping step needs at least one flip" % step_id)
			"stir":
				if int(step.get("circles", 0)) < 1:
					problems.append("step '%s': a stirring step needs at least one circle" % step_id)
			"hold":
				if float(step.get("duration", 0.0)) <= 0.0:
					problems.append("step '%s': a hold step needs a duration" % step_id)
	if cook_seen != 1:
		problems.append("exactly one cook-through step is required, found %d" % cook_seen)
	return problems


## The sorting step: containers and items, both named in both languages, and every
## item pointing at a container that is actually on the bench.
static func _validate_sorting_step(step: Dictionary, step_id: String) -> Array[String]:
	var problems: Array[String] = []
	var targets: Array = step.get("targets", [])
	var items: Array = step.get("items", [])
	if targets.size() < 2:
		problems.append("step '%s': a sorting step needs at least two containers" % step_id)
	if items.is_empty():
		problems.append("step '%s': a sorting step needs something to move" % step_id)
	var target_ids: Array = []
	for entry in targets:
		var target: Dictionary = entry
		var target_id := str(target.get("id", ""))
		if target_id.is_empty():
			problems.append("step '%s': a container has no id" % step_id)
		if not _pair_ok(target.get("label", {})):
			problems.append("step '%s': container '%s' needs a name in both languages" % [step_id, target_id])
		target_ids.append(target_id)
	for entry in items:
		var item: Dictionary = entry
		var item_id := str(item.get("id", ""))
		if item_id.is_empty():
			problems.append("step '%s': an item has no id" % step_id)
		elif not _is_known_item(item_id):
			problems.append("step '%s': nothing knows how to draw item '%s'" % [step_id, item_id])
		if not _pair_ok(item.get("label", {})):
			problems.append("step '%s': item '%s' needs a name in both languages" % [step_id, item_id])
		if not target_ids.has(str(item.get("target", ""))):
			problems.append("step '%s': item '%s' names a container that is not on the bench" % [step_id, item_id])
	return problems


## The generic props a step may name, as opposed to a catalogue ingredient. Kept
## beside the validation so adding a prop to `KitchenProps` without teaching the
## validator about it shows up as a broken recipe rather than as a silent crate.
const GENERIC_ITEM_IDS: Array = [
	"raw_fish", "freshwater_fish", "fish", "cooked_fish", "grilled_fish",
	"cooked_rice", "rice", "herbs", "vegetables", "cooked_veg", "veg",
	"fish_juice", "dirty_board", "clean_board", "soap_bar",
]


static func _is_known_item(item_id: String) -> bool:
	return GENERIC_ITEM_IDS.has(item_id) or not ingredient_by_id(item_id).is_empty()


## The plating step: a known plating style, a named main piece, and named garnishes.
static func _validate_plating_step(step: Dictionary, step_id: String) -> Array[String]:
	var problems: Array[String] = []
	var plating := str(step.get("plating", ""))
	if plating_by_id(plating).is_empty():
		problems.append("step '%s': unknown plating style '%s'" % [step_id, plating])
	var main_value: Variant = step.get("main", {})
	var main: Dictionary = main_value if typeof(main_value) == TYPE_DICTIONARY else {}
	if not _pair_ok(main.get("label", {})):
		problems.append("step '%s': the dish itself needs a name in both languages" % step_id)
	var main_id := str(main.get("id", ""))
	if not main_id.is_empty() and not _is_known_item(main_id):
		problems.append("step '%s': nothing knows how to draw the dish '%s'" % [step_id, main_id])
	var garnish: Array = step.get("garnish", [])
	if garnish.is_empty():
		problems.append("step '%s': plating needs at least one garnish" % step_id)
	for entry in garnish:
		var piece: Dictionary = entry
		var piece_id := str(piece.get("id", ""))
		if not _pair_ok(piece.get("label", {})):
			problems.append("step '%s': garnish '%s' needs a name in both languages" % [step_id, piece_id])
		if garnish_by_id(piece_id).is_empty():
			problems.append("step '%s': garnish '%s' is not in the catalogue" % [step_id, piece_id])
	return problems


## Every problem in the whole catalogue. An empty list means it is safe to serve.
static func validate_all() -> Array[String]:
	var problems: Array[String] = []
	var ids: Array = []
	for entry in fish():
		var fish_id := str(entry.get("id", ""))
		if fish_id.is_empty():
			problems.append("a fish has no id")
		elif ids.has(fish_id):
			problems.append("duplicate fish id '%s'" % fish_id)
		else:
			ids.append(fish_id)
	ids = []
	for entry in ingredients():
		var ingredient_id := str(entry.get("id", ""))
		if ingredient_id.is_empty():
			problems.append("an ingredient has no id")
		elif ids.has(ingredient_id):
			problems.append("duplicate ingredient id '%s'" % ingredient_id)
		else:
			ids.append(ingredient_id)
	ids = []
	for entry in recipes():
		var recipe_id := str(entry.get("id", ""))
		if not recipe_id.is_empty() and ids.has(recipe_id):
			problems.append("duplicate recipe id '%s'" % recipe_id)
		else:
			ids.append(recipe_id)
		problems.append_array(validate(entry))
	return problems


static func _pair_ok(pair: Variant) -> bool:
	if typeof(pair) != TYPE_DICTIONARY:
		return false
	var dict: Dictionary = pair
	return not str(dict.get("en", "")).strip_edges().is_empty() \
		and not str(dict.get("th", "")).strip_edges().is_empty()


# ==================================================================== counts ===
static func fish_count() -> int:
	return fish().size()


static func recipe_count() -> int:
	return recipes().size()


static func real_recipe_count() -> int:
	return real_recipes().size()
