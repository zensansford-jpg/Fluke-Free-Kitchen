class_name LevelDB
## The three challenges, their interactive steps, and their recipe cards.
##
## **This file is content, not code.** A step is a small dictionary that names a
## reusable interaction (`kind`), the text shown to the player, the lesson
## unlocked by doing it, and — where the step corrects a myth — the myth's id.
##
## Interaction kinds (implemented in `scripts/tasks/`):
##   tap_correct   tap the correct item out of several
##   choose_safer  pick the safer option out of two or three
##   drag_to       drag items into the right container
##   swipe_clean   swipe across a surface until it is clean
##   hold          press and hold until a progress ring fills
##   cook_through  hold to heat; reach the safe temperature and hold it there
##   order_steps   arrange steps in the correct order
##   checklist     tick every action that is correct (multi-select)

extends RefCounted


static func levels() -> Array:
	return [_level_1(), _level_2(), _level_3()]


# =============================================================== LEVEL ONE ===
static func _level_1() -> Dictionary:
	return {
		"id": "l1",
		"index": 1,
		"title": {"en": "Clean Kitchen Challenge", "th": "ภารกิจครัวสะอาด"},
		"goal": {
			"en": "Learn why clean hands, utensils and work surfaces matter, and how separating raw food from ready-to-eat food stops contamination.",
			"th": "เรียนรู้ว่าทำไมมือ อุปกรณ์ และพื้นที่ทำงานที่สะอาดจึงสำคัญ และการแยกอาหารดิบออกจากอาหารพร้อมรับประทานป้องกันการปนเปื้อนได้อย่างไร",
		},
		"objective_short": {"en": "Clean hands, clean surfaces, keep raw fish separate.", "th": "มือสะอาด พื้นผิวสะอาด แยกปลาดิบออก"},
		"unlocked_by": "",
		"lessons": ["clean_hands", "clean_surfaces", "clean_utensils", "separate_raw"],
		"quiz": ["q_l1_hands", "q_l1_separate"],
		"required_quiz": ["q_l1_separate"],
		"dish": {
			"name": {"en": "Fresh vegetable plate, prepared cleanly", "th": "ผักสดจานสะอาด"},
			"looks_like": {"en": "Cucumber, tomato and herbs, cut on a clean board.", "th": "แตงกวา มะเขือเทศ และผักสมุนไพร หั่นบนเขียงที่สะอาด"},
			"ingredients": [
				{"en": "Cucumber", "th": "แตงกวา"},
				{"en": "Tomato", "th": "มะเขือเทศ"},
				{"en": "Thai basil and mint", "th": "ใบกะเพราและใบสะระแหน่"},
				{"en": "Clean water for washing", "th": "น้ำสะอาดสำหรับล้าง"},
			],
			"method": [
				{"en": "Wash your hands with soap and clean water.", "th": "ล้างมือด้วยสบู่และน้ำสะอาด"},
				{"en": "Wash the board and knife.", "th": "ล้างเขียงและมีดให้สะอาด"},
				{"en": "Prepare raw fish on a separate board.", "th": "เตรียมปลาดิบบนเขียงอีกใบที่แยกไว้"},
				{"en": "Wash anything that touched raw fish before it touches other food.", "th": "ล้างสิ่งที่สัมผัสปลาดิบก่อนใช้กับอาหารอื่น"},
			],
		},
		"steps": [
			{
				"id": "wash_hands",
				"kind": "tap_correct",
				"prompt": {
					"en": "You are about to prepare food. What is the best way to clean your hands?",
					"th": "คุณกำลังจะเตรียมอาหาร วิธีทำความสะอาดมือที่ดีที่สุดคือข้อใด",
				},
				"demo": true,
				"lesson": "clean_hands",
				"options": [
					{"id": "soap", "label": {"en": "Soap and clean running water, then dry", "th": "สบู่และน้ำสะอาดไหล แล้วเช็ดให้แห้ง"}, "correct": true},
					{"id": "water", "label": {"en": "Rinse quickly with water only", "th": "ล้างน้ำเปล่าเร็ว ๆ"}, "why": {"en": "A quick rinse leaves many germs and parasite eggs on your hands.", "th": "การล้างน้ำเปล่าเร็ว ๆ ยังทิ้งเชื้อโรคและไข่พยาธิไว้บนมือมาก"}},
					{"id": "cloth", "label": {"en": "Wipe your hands on a cloth", "th": "เช็ดมือด้วยผ้า"}, "why": {"en": "The cloth may already be dirty, so wiping can spread germs instead of removing them.", "th": "ผ้าอาจสกปรกอยู่แล้ว การเช็ดจึงอาจแพร่เชื้อโรคแทนที่จะกำจัด"}},
				],
			},
			{
				"id": "clean_board",
				"kind": "swipe_clean",
				"prompt": {
					"en": "Swipe across the chopping board to wash it clean.",
					"th": "ลากนิ้วหรือเมาส์ไปบนเขียงเพื่อล้างให้สะอาด",
				},
				"lesson": "clean_surfaces",
				"coverage": 0.85,
			},
			{
				"id": "choose_utensils",
				"kind": "tap_correct",
				"prompt": {
					"en": "Which board and knife should you use for the fresh vegetables?",
					"th": "ควรใช้เขียงและมีดใดกับผักสด",
				},
				"lesson": "clean_utensils",
				"options": [
					{"id": "clean_pair", "label": {"en": "The freshly washed board and knife", "th": "เขียงและมีดที่เพิ่งล้างสะอาด"}, "correct": true},
					{"id": "raw_board", "label": {"en": "The board that just held raw fish", "th": "เขียงที่เพิ่งวางปลาดิบ"}, "why": {"en": "Juices from raw fish can carry parasite larvae onto food that will not be cooked.", "th": "น้ำจากปลาดิบอาจมีตัวอ่อนพยาธิปนไปกับอาหารที่จะไม่ผ่านการปรุงสุก"}},
					{"id": "cloth_wipe", "label": {"en": "The raw-fish board, wiped with a cloth", "th": "เขียงปลาดิบที่เช็ดด้วยผ้า"}, "why": {"en": "Wiping does not remove larvae. The board needs washing with soap.", "th": "การเช็ดไม่ได้กำจัดตัวอ่อน ต้องล้างด้วยสบู่"}},
				],
			},
			{
				"id": "separate_food",
				"kind": "drag_to",
				"prompt": {
					"en": "Drag each item to the correct place.",
					"th": "ลากสิ่งของแต่ละอย่างไปยังที่ที่ถูกต้อง",
				},
				"lesson": "separate_raw",
				"corrects": ["same_board_ok"],
				"targets": [
					{"id": "raw_tray", "label": {"en": "Raw fish tray", "th": "ถาดปลาดิบ"}},
					{"id": "ready_plate", "label": {"en": "Ready-to-eat plate", "th": "จานอาหารพร้อมรับประทาน"}},
				],
				"items": [
					{"id": "raw_fish", "label": {"en": "Raw freshwater fish", "th": "ปลาน้ำจืดดิบ"}, "target": "raw_tray"},
					{"id": "cooked_rice", "label": {"en": "Cooked rice", "th": "ข้าวสุก"}, "target": "ready_plate"},
					{"id": "herbs", "label": {"en": "Washed herbs", "th": "ผักสมุนไพรที่ล้างแล้ว"}, "target": "ready_plate"},
					{"id": "fish_juice", "label": {"en": "Board with fish juices", "th": "เขียงที่เปื้อนน้ำปลาดิบ"}, "target": "raw_tray"},
				],
			},
			{
				"id": "spot_mistake",
				"kind": "choose_safer",
				"prompt": {
					"en": "A neighbour used one board for raw fish and then for cooked food. What should happen next?",
					"th": "เพื่อนบ้านใช้เขียงใบเดียวกับปลาดิบ แล้วใช้กับอาหารสุกต่อ ควรทำอย่างไร",
				},
				"lesson": "separate_raw",
				"corrects": ["same_board_ok"],
				"options": [
					{"id": "wash_and_switch", "label": {"en": "Wash the board with soap and use a separate board for ready-to-eat food", "th": "ล้างเขียงด้วยสบู่ และใช้เขียงแยกอีกใบกับอาหารพร้อมรับประทาน"}, "correct": true},
					{"id": "wipe_only", "label": {"en": "Wipe it with a cloth and carry on", "th": "เช็ดด้วยผ้าแล้วใช้ต่อ"}, "why": {"en": "Wiping spreads larvae around the board instead of removing them.", "th": "การเช็ดทำให้ตัวอ่อนกระจายไปทั่วเขียงแทนที่จะถูกกำจัด"}},
					{"id": "looks_clean", "label": {"en": "Keep using it — it looks clean", "th": "ใช้ต่อได้ เพราะดูสะอาด"}, "why": {"en": "Parasite larvae are far too small to see. 'Looks clean' is not the same as clean.", "th": "ตัวอ่อนพยาธิมองไม่เห็นด้วยตาเปล่า คำว่าดูสะอาดจึงไม่เท่ากับสะอาดจริง"}},
				],
			},
		],
	}


# =============================================================== LEVEL TWO ===
static func _level_2() -> Dictionary:
	return {
		"id": "l2",
		"index": 2,
		"title": {"en": "Safe Cooking Challenge", "th": "ภารกิจปรุงอาหารปลอดภัย"},
		"goal": {
			"en": "Learn that eating raw or undercooked freshwater fish can pass on liver flukes, how fish should be cooked, and why lime, salt and pickling are not substitutes.",
			"th": "เรียนรู้ว่าการรับประทานปลาน้ำจืดดิบหรือกึ่งสุกอาจทำให้ติดพยาธิใบไม้ตับ ควรปรุงปลาอย่างไร และเหตุใดมะนาว เกลือ และการดองจึงใช้แทนการปรุงสุกไม่ได้",
		},
		"objective_short": {"en": "Cook freshwater fish all the way through.", "th": "ปรุงปลาน้ำจืดให้สุกทั่วถึง"},
		"unlocked_by": "l1",
		"lessons": ["freshwater_fish_risk", "cook_thoroughly", "no_substitute"],
		"quiz": ["q_l2_cook", "q_l2_lime"],
		"required_quiz": ["q_l2_cook"],
		"dish": {
			"name": {"en": "Grilled river fish, cooked through", "th": "ปลาน้ำจืดย่างสุกทั่วถึง"},
			"looks_like": {"en": "Firm, opaque flesh that comes away in flakes, served with herbs and sticky rice.", "th": "เนื้อปลาแน่น ทึบแสง แยกออกเป็นชั้น ๆ เสิร์ฟกับผักสมุนไพรและข้าวเหนียว"},
			"ingredients": [
				{"en": "Freshwater fish", "th": "ปลาน้ำจืด"},
				{"en": "Lemongrass and galangal", "th": "ตะไคร้และข่า"},
				{"en": "Salt", "th": "เกลือ"},
				{"en": "Sticky rice", "th": "ข้าวเหนียว"},
			],
			"method": [
				{"en": "Clean the fish and the work surface.", "th": "ล้างปลาและทำความสะอาดพื้นที่ทำงาน"},
				{"en": "Heat the pan or grill properly before cooking.", "th": "ให้ความร้อนกระทะหรือเตาย่างก่อนปรุง"},
				{"en": "Cook until the inside reaches a safe temperature (about 63°C / 145°F) and stays there.", "th": "ปรุงจนอุณหภูมิภายในถึงระดับปลอดภัย (ประมาณ 63°C / 145°F) และคงอยู่"},
				{"en": "Check the flesh is opaque and flakes apart.", "th": "ตรวจว่าเนื้อปลาทึบแสงและแยกออกเป็นชั้น"},
			],
		},
		"steps": [
			{
				"id": "identify_fish",
				"kind": "tap_correct",
				"prompt": {
					"en": "These are the ingredients for today's dish. Tap the one that must be cooked thoroughly.",
					"th": "นี่คือวัตถุดิบสำหรับเมนูวันนี้ แตะวัตถุดิบที่ต้องปรุงให้สุกทั่วถึง",
				},
				"demo": true,
				"lesson": "freshwater_fish_risk",
				"corrects": ["all_fish_infected", "dirty_pipe_flukes"],
				"options": [
					{"id": "freshwater_fish", "label": {"en": "Freshwater fish", "th": "ปลาน้ำจืด"}, "correct": true},
					{"id": "sea_fish", "label": {"en": "Sea fish", "th": "ปลาทะเล"}, "why": {"en": "Sea fish are not part of the liver fluke life cycle — but all fish should still be cooked properly.", "th": "ปลาทะเลไม่ได้อยู่ในวงจรชีวิตของพยาธิใบไม้ตับ แต่ปลาทุกชนิดก็ควรปรุงให้สุก"}},
					{"id": "herbs", "label": {"en": "Herbs", "th": "ผักสมุนไพร"}, "why": {"en": "Herbs should be washed, but they do not carry liver flukes.", "th": "ผักสมุนไพรควรล้างให้สะอาด แต่ไม่ได้เป็นแหล่งของพยาธิใบไม้ตับ"}},
					{"id": "rice", "label": {"en": "Rice", "th": "ข้าว"}, "why": {"en": "Rice is not part of the parasite's life cycle.", "th": "ข้าวไม่ได้อยู่ในวงจรชีวิตของพยาธิ"}},
				],
			},
			{
				"id": "prep_board",
				"kind": "drag_to",
				"prompt": {
					"en": "Drag the fish onto the board you will use for raw fish.",
					"th": "ลากปลาไปวางบนเขียงที่ใช้สำหรับปลาดิบ",
				},
				"lesson": "clean_surfaces",
				"targets": [
					{"id": "raw_board", "label": {"en": "Raw-fish board", "th": "เขียงปลาดิบ"}},
					{"id": "ready_area", "label": {"en": "Ready-to-eat area", "th": "พื้นที่อาหารพร้อมรับประทาน"}},
				],
				"items": [
					{"id": "raw_fish", "label": {"en": "Freshwater fish", "th": "ปลาน้ำจืด"}, "target": "raw_board"},
					{"id": "cooked_veg", "label": {"en": "Cooked vegetables", "th": "ผักที่ปรุงสุกแล้ว"}, "target": "ready_area"},
				],
			},
			{
				"id": "heat_pan",
				"kind": "hold",
				"prompt": {
					"en": "Press and hold to heat the pan.",
					"th": "กดค้างไว้เพื่อตั้งกระทะให้ร้อน",
				},
				"duration": 2.0,
				"success_sound": "sizzle",
			},
			{
				"id": "cook_fish",
				"kind": "cook_through",
				"prompt": {
					"en": "Hold to keep cooking. Get the fish to a safe temperature and keep it there.",
					"th": "กดค้างไว้เพื่อปรุงต่อ ทำให้ปลาถึงอุณหภูมิปลอดภัยและคงไว้",
				},
				"lesson": "cook_thoroughly",
				"safe_temp": 63.0,
				"hold_seconds": 5.0,
			},
			{
				"id": "lime_or_cook",
				"kind": "choose_safer",
				"prompt": {
					"en": "A friend says, \"Just squeeze lime over the raw fish — that makes it safe.\" What do you do?",
					"th": "เพื่อนบอกว่า \"บีบมะนาวลงบนปลาดิบก็ปลอดภัยแล้ว\" คุณจะทำอย่างไร",
				},
				"lesson": "no_substitute",
				"corrects": ["lime_kills", "pickling_safe", "temp_magic_number"],
				"options": [
					{"id": "cook", "label": {"en": "Cook the fish thoroughly before serving", "th": "ปรุงปลาให้สุกทั่วถึงก่อนเสิร์ฟ"}, "correct": true},
					{"id": "lime", "label": {"en": "Squeeze lime and serve it raw", "th": "บีบมะนาวแล้วเสิร์ฟแบบดิบ"}, "why": {"en": "Lime adds flavour, not safety. Lime juice does not reliably kill the larvae, so the fish still has to be cooked.", "th": "มะนาวให้รสชาติ ไม่ได้ให้ความปลอดภัย น้ำมะนาวไม่ได้กำจัดตัวอ่อนอย่างแน่นอน ปลาจึงยังต้องปรุงให้สุก"}},
					{"id": "spicy", "label": {"en": "Add a lot of chilli to kill the germs", "th": "ใส่พริกเยอะ ๆ เพื่อฆ่าเชื้อ"}, "why": {"en": "Chilli does not kill parasite larvae. Only proper cooking does.", "th": "พริกไม่ได้ฆ่าตัวอ่อนพยาธิ มีเพียงการปรุงสุกที่ถูกต้องเท่านั้น"}},
				],
			},
		],
	}


# ============================================================= LEVEL THREE ===
static func _level_3() -> Dictionary:
	return {
		"id": "l3",
		"index": 3,
		"title": {"en": "Village Prevention Challenge", "th": "ภารกิจป้องกันระดับหมู่บ้าน"},
		"goal": {
			"en": "Review food-handling situations, correct a sanitation mistake, and learn how liver fluke infection relates to bile duct cancer, screening and treatment.",
			"th": "ทบทวนสถานการณ์การจัดการอาหาร แก้ไขข้อผิดพลาดด้านสุขอนามัย และเรียนรู้ว่าการติดพยาธิใบไม้ตับเกี่ยวข้องกับมะเร็งท่อน้ำดี การคัดกรอง และการรักษาอย่างไร",
		},
		"objective_short": {"en": "Stop the parasite at its source, and know when to see a health worker.", "th": "ตัดวงจรพยาธิที่ต้นทาง และรู้ว่าควรพบเจ้าหน้าที่สาธารณสุขเมื่อใด"},
		"unlocked_by": "l2",
		"lessons": ["fluke_lifecycle", "sanitation_cycle", "cancer_link", "screening", "treatment_praziquantel", "community_action"],
		"quiz": ["q_l3_cancer", "q_l3_treatment"],
		"required_quiz": ["q_l3_cancer"],
		"dish": {
			"name": {"en": "A safe shared family meal", "th": "มื้ออาหารครอบครัวที่ปลอดภัย"},
			"looks_like": {"en": "Cooked fish, clean water, washed vegetables and clean hands — the same meal, made safe for everyone.", "th": "ปลาที่ปรุงสุก น้ำสะอาด ผักที่ล้างแล้ว และมือที่สะอาด มื้อเดิมแต่ปลอดภัยสำหรับทุกคน"},
			"ingredients": [
				{"en": "Thoroughly cooked fish", "th": "ปลาที่ปรุงสุกทั่วถึง"},
				{"en": "Clean water", "th": "น้ำสะอาด"},
				{"en": "Washed vegetables", "th": "ผักที่ล้างสะอาด"},
				{"en": "Clean hands and utensils", "th": "มือและอุปกรณ์ที่สะอาด"},
			],
			"method": [
				{"en": "Cook fish thoroughly, every time.", "th": "ปรุงปลาให้สุกทั่วถึงทุกครั้ง"},
				{"en": "Keep raw and ready-to-eat food apart.", "th": "แยกอาหารดิบออกจากอาหารพร้อมรับประทาน"},
				{"en": "Use a toilet and keep faeces out of water.", "th": "ใช้ส้วม และไม่ทิ้งอุจจาระลงในแหล่งน้ำ"},
				{"en": "Encourage family and neighbours to have health checks.", "th": "ชวนครอบครัวและเพื่อนบ้านตรวจสุขภาพ"},
			],
		},
		"steps": [
			{
				"id": "find_sanitation_problem",
				"kind": "tap_correct",
				"prompt": {
					"en": "Which of these lets parasite eggs reach the water where snails and fish live?",
					"th": "ข้อใดทำให้ไข่พยาธิลงสู่แหล่งน้ำที่เป็นที่อยู่ของหอยและปลา",
				},
				"demo": true,
				"lesson": "sanitation_cycle",
				"corrects": ["dirty_pipe_flukes", "one_toilet_fixes_all"],
				"options": [
					{"id": "open_defecation", "label": {"en": "Going to the toilet on the bank of the pond", "th": "ถ่ายอุจจาระริมตลิ่งหนองน้ำ"}, "correct": true},
					{"id": "latrine", "label": {"en": "Using a household latrine", "th": "ใช้ส้วมในบ้าน"}, "why": {"en": "Safe latrines keep eggs out of the water — this is the protective behaviour, not the problem.", "th": "ส้วมที่ถูกสุขลักษณะกันไข่ไม่ให้ลงน้ำ นี่คือพฤติกรรมที่ป้องกัน ไม่ใช่ปัญหา"}},
					{"id": "covered_water", "label": {"en": "Keeping drinking water covered", "th": "ปิดภาชนะน้ำดื่ม"}, "why": {"en": "Covering drinking water is good hygiene, and not the transmission route for liver flukes.", "th": "การปิดน้ำดื่มเป็นสุขอนามัยที่ดี และไม่ใช่วิธีที่พยาธิใบไม้ตับแพร่มาสู่คน"}},
				],
			},
			{
				"id": "wastewater_choice",
				"kind": "choose_safer",
				"prompt": {
					"en": "Where should kitchen and household wastewater go?",
					"th": "น้ำเสียจากครัวเรือนควรทิ้งที่ใด",
				},
				"lesson": "sanitation_cycle",
				"options": [
					{"id": "soak_pit", "label": {"en": "Into a proper soak pit or treatment system", "th": "ลงบ่อซึมหรือระบบบำบัดที่ถูกต้อง"}, "correct": true},
					{"id": "canal", "label": {"en": "Straight into the canal", "th": "ปล่อยลงคลองโดยตรง"}, "why": {"en": "Wastewater that reaches ponds and canals can carry parasite eggs towards the water snails and fish live in.", "th": "น้ำเสียที่ไหลลงหนองและคลองอาจนำไข่พยาธิไปสู่แหล่งน้ำที่หอยและปลาอาศัยอยู่"}},
					{"id": "pond", "label": {"en": "Into the village pond", "th": "ปล่อยลงหนองน้ำของหมู่บ้าน"}, "why": {"en": "The pond is exactly the water body the parasite's life cycle depends on.", "th": "หนองน้ำคือแหล่งน้ำที่วงจรชีวิตของพยาธิต้องพึ่งพา"}},
				],
			},
			{
				"id": "order_lifecycle",
				"kind": "order_steps",
				"prompt": {
					"en": "Put the liver fluke's journey in order, starting from the beginning.",
					"th": "เรียงลำดับการเดินทางของพยาธิใบไม้ตับ เริ่มจากขั้นแรก",
				},
				"lesson": "fluke_lifecycle",
				"steps": [
					{"id": "eggs", "label": {"en": "Eggs leave the body in faeces", "th": "ไข่พยาธิออกมากับอุจจาระ"}},
					{"id": "water", "label": {"en": "Eggs reach the water", "th": "ไข่พยาธิลงสู่แหล่งน้ำ"}},
					{"id": "snail", "label": {"en": "They develop inside a snail", "th": "เจริญภายในหอย"}},
					{"id": "fish", "label": {"en": "They form cysts in freshwater fish", "th": "กลายเป็นซีสต์ในปลาน้ำจืด"}},
					{"id": "person", "label": {"en": "A person eats the fish raw", "th": "คนรับประทานปลานั้นแบบดิบ"}},
				],
			},
			{
				"id": "screening_statement",
				"kind": "tap_correct",
				"prompt": {
					"en": "Which statement about screening and health checks is correct?",
					"th": "ข้อความใดเกี่ยวกับการคัดกรองและการตรวจสุขภาพถูกต้อง",
				},
				"lesson": "screening",
				"options": [
					{"id": "health_worker", "label": {"en": "A health worker or doctor decides on and explains the tests", "th": "เจ้าหน้าที่สาธารณสุขหรือแพทย์เป็นผู้พิจารณาและอธิบายผลการตรวจ"}, "correct": true},
					{"id": "self_check", "label": {"en": "You should work out the results yourself at home", "th": "ควรแปลผลการตรวจด้วยตนเองที่บ้าน"}, "why": {"en": "Health checks are carried out and explained by trained health professionals.", "th": "การตรวจสุขภาพดำเนินการและอธิบายโดยบุคลากรทางการแพทย์ที่ผ่านการฝึกอบรม"}},
					{"id": "only_sick", "label": {"en": "Only people who already feel ill need any check", "th": "เฉพาะคนที่รู้สึกไม่สบายแล้วเท่านั้นที่ต้องตรวจ"}, "why": {"en": "Liver fluke infection often causes no symptoms at first, which is why screening matters.", "th": "การติดพยาธิใบไม้ตับมักไม่มีอาการในระยะแรก การคัดกรองจึงสำคัญ"}},
				],
			},
			{
				"id": "treatment_statement",
				"kind": "tap_correct",
				"prompt": {
					"en": "Which statement about treatment is correct?",
					"th": "ข้อความใดเกี่ยวกับการรักษาถูกต้อง",
				},
				"lesson": "treatment_praziquantel",
				"corrects": ["medicine_replaces_prevention"],
				"options": [
					{"id": "doctor_gives", "label": {"en": "Praziquantel is given and supervised by a doctor or health worker", "th": "พรานซีควอนเทลจ่ายและดูแลโดยแพทย์หรือเจ้าหน้าที่สาธารณสุข"}, "correct": true},
					{"id": "self_medicate", "label": {"en": "Buy the medicine and take it whenever you feel like it", "th": "ซื้อยามากินเองตามใจ"}, "why": {"en": "Praziquantel is a prescription medicine. It needs the right diagnosis, dose and follow-up.", "th": "พรานซีควอนเทลเป็นยาที่ต้องสั่งโดยแพทย์ ต้องได้รับการวินิจฉัย ขนาดยา และการติดตามที่เหมาะสม"}},
					{"id": "medicine_means_raw", "label": {"en": "Once you have the medicine you can eat raw fish freely", "th": "เมื่อมียาแล้วก็กินปลาดิบได้อย่างอิสระ"}, "why": {"en": "Medicine treats an infection; it does not prevent a new one. You can be infected again the next time you eat raw fish.", "th": "ยารักษาการติดเชื้อที่มีอยู่ แต่ไม่ได้ป้องกันการติดเชื้อใหม่ หากกินปลาดิบอีกก็ติดใหม่ได้"}},
				],
			},
			{
				"id": "prevention_checklist",
				"kind": "checklist",
				"prompt": {
					"en": "Tick every action that helps prevent liver flukes and bile duct cancer.",
					"th": "เลือกทุกข้อที่ช่วยป้องกันพยาธิใบไม้ตับและมะเร็งท่อน้ำดี",
				},
				"lesson": "community_action",
				"corrects": ["infection_means_cancer"],
				"options": [
					{"id": "cook", "label": {"en": "Cook freshwater fish thoroughly", "th": "ปรุงปลาน้ำจืดให้สุกทั่วถึง"}, "correct": true},
					{"id": "separate", "label": {"en": "Keep raw and ready-to-eat food apart", "th": "แยกอาหารดิบออกจากอาหารพร้อมรับประทาน"}, "correct": true},
					{"id": "toilets", "label": {"en": "Use safe toilets and keep faeces out of water", "th": "ใช้ส้วมที่ถูกสุขลักษณะ และไม่ทิ้งอุจจาระลงน้ำ"}, "correct": true},
					{"id": "hands", "label": {"en": "Wash hands with soap", "th": "ล้างมือด้วยสบู่"}, "correct": true},
					{"id": "checks", "label": {"en": "Have health checks when they are offered", "th": "เข้ารับการตรวจสุขภาพเมื่อมีบริการ"}, "correct": true},
					{"id": "raw_tasty", "label": {"en": "Eat raw fish because it tastes better", "th": "กินปลาดิบเพราะรสชาติดีกว่า"}, "why": {"en": "This is the main way people become infected. Taste is not worth the risk.", "th": "นี่คือสาเหตุหลักที่คนติดพยาธิ รสชาติไม่คุ้มกับความเสี่ยง"}},
					{"id": "lime", "label": {"en": "Rely on lime juice instead of cooking", "th": "พึ่งมะนาวแทนการปรุงสุก"}, "why": {"en": "Lime juice does not kill the parasite's larvae.", "th": "น้ำมะนาวไม่ได้ฆ่าตัวอ่อนพยาธิ"}},
					{"id": "ignore", "label": {"en": "Ignore it — only other villages are affected", "th": "ไม่ต้องสนใจ เพราะมีแค่หมู่บ้านอื่นที่เป็น"}, "why": {"en": "Prevention only works when everyone takes part, in every village.", "th": "การป้องกันจะได้ผลเมื่อทุกคนร่วมมือกันในทุกหมู่บ้าน"}},
				],
			},
		],
	}


# ------------------------------------------------------------------ lookups ---
static func by_id(level_id: String) -> Dictionary:
	for level in levels():
		if str(level.get("id", "")) == level_id:
			return level
	return {}


static func ids() -> Array[String]:
	var out: Array[String] = []
	for level in levels():
		out.append(str(level.get("id", "")))
	return out


## All lesson ids the game teaches, in play order.
static func all_lesson_ids() -> Array[String]:
	var out: Array[String] = []
	for level in levels():
		for lesson_id in level.get("lessons", []):
			var key := str(lesson_id)
			if not out.has(key):
				out.append(key)
	return out


static func all_question_ids() -> Array[String]:
	var out: Array[String] = []
	for level in levels():
		for qid in level.get("quiz", []):
			var key := str(qid)
			if not out.has(key):
				out.append(key)
	return out


## The level after `level_id`, or an empty string at the end.
static func next_level_id(level_id: String) -> String:
	var found := false
	for level in levels():
		if found:
			return str(level.get("id", ""))
		if str(level.get("id", "")) == level_id:
			found = true
	return ""


static func title(level: Dictionary) -> String:
	return LessonDB.text(level, "title", Loc.language)


static func goal(level: Dictionary) -> String:
	return LessonDB.text(level, "goal", Loc.language)


static func objective_short(level: Dictionary) -> String:
	return LessonDB.text(level, "objective_short", Loc.language)


## A level is unlocked when the level it depends on has been completed.
static func is_unlocked(level: Dictionary) -> bool:
	var dependency := str(level.get("unlocked_by", ""))
	if dependency.is_empty():
		return true
	return SaveData.is_completed(dependency)
