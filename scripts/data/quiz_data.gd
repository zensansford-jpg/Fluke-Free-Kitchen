class_name QuizDB
## The required knowledge questions.
##
## Every challenge ends with at least one `required` question. The kitchen will
## not issue a full-completion result until the level's required questions have
## been answered correctly, so a player cannot skip the education and still
## "finish" the game.
##
## A wrong answer is never punished: it shows `why` for the option that was
## chosen and invites another try, which is where most of the learning happens.

extends RefCounted


static func questions() -> Array:
	return [
		{
			"id": "q_l1_hands",
			"level": "l1",
			"required": false,
			"lesson": "clean_hands",
			"question": {
				"en": "Why wash your hands with soap and water before preparing food?",
				"th": "เพราะเหตุใดจึงต้องล้างมือด้วยสบู่และน้ำก่อนเตรียมอาหาร",
			},
			"options": [
				{"id": "removes", "label": {"en": "It removes germs and parasite eggs from your hands", "th": "ช่วยกำจัดเชื้อโรคและไข่พยาธิบนมือ"}, "correct": true},
				{"id": "smell", "label": {"en": "It makes your hands smell nice", "th": "ทำให้มือมีกลิ่นหอม"}, "why": {"en": "Smelling nice is not the point: soap and water physically remove germs and eggs.", "th": "กลิ่นไม่ใช่ประเด็นสำคัญ สบู่และน้ำช่วยกำจัดเชื้อโรคและไข่พยาธิออกไปจริง"}},
				{"id": "tasty", "label": {"en": "It makes the food taste better", "th": "ทำให้อาหารอร่อยขึ้น"}, "why": {"en": "Handwashing is about safety, not flavour.", "th": "การล้างมือเกี่ยวกับความปลอดภัย ไม่ใช่รสชาติ"}},
			],
		},
		{
			"id": "q_l1_separate",
			"level": "l1",
			"required": true,
			"lesson": "separate_raw",
			"corrects": ["same_board_ok"],
			"question": {
				"en": "Why should raw fish be kept away from food that is ready to eat?",
				"th": "เพราะเหตุใดจึงควรแยกปลาดิบออกจากอาหารที่พร้อมรับประทาน",
			},
			"options": [
				{"id": "juices", "label": {"en": "Juices from raw fish can carry parasite larvae onto food that will not be cooked again", "th": "น้ำจากปลาดิบอาจมีตัวอ่อนพยาธิปนไปกับอาหารที่จะไม่ผ่านการปรุงสุกอีก"}, "correct": true},
				{"id": "colour", "label": {"en": "So that the colours do not mix on the plate", "th": "เพื่อไม่ให้สีปนกันบนจาน"}, "why": {"en": "Plating is a preference; contamination is a health risk. The reason is the parasite larvae.", "th": "การจัดจานเป็นเรื่องความสวยงาม แต่การปนเปื้อนเป็นความเสี่ยงต่อสุขภาพ เหตุผลที่แท้จริงคือตัวอ่อนพยาธิ"}},
				{"id": "temperature", "label": {"en": "Because raw fish is colder than cooked food", "th": "เพราะปลาดิบเย็นกว่าอาหารสุก"}, "why": {"en": "Temperature is not the issue — the risk travels in the juices that drip from raw fish.", "th": "อุณหภูมิไม่ใช่ประเด็น ความเสี่ยงเดินทางมากับน้ำที่ไหลจากปลาดิบ"}},
			],
		},
		{
			"id": "q_l2_cook",
			"level": "l2",
			"required": true,
			"lesson": "cook_thoroughly",
			"corrects": ["temp_magic_number"],
			"question": {
				"en": "What makes freshwater fish safe to eat?",
				"th": "อะไรทำให้ปลาน้ำจืดปลอดภัยต่อการรับประทาน",
			},
			"options": [
				{"id": "cooked", "label": {"en": "Cooking it thoroughly, so the inside is fully cooked", "th": "การปรุงให้สุกทั่วถึง เนื้อด้านในสุกทั้งหมด"}, "correct": true},
				{"id": "lime", "label": {"en": "Squeezing lime juice over it", "th": "บีบมะนาวลงไป"}, "why": {"en": "Lime juice does not reliably kill the larvae. Only proper cooking does.", "th": "น้ำมะนาวไม่ได้กำจัดตัวอ่อนอย่างแน่นอน มีเพียงการปรุงสุกที่ถูกต้องเท่านั้น"}},
				{"id": "salt", "label": {"en": "Salting or pickling it for a day", "th": "หมักเกลือหรือดองหนึ่งวัน"}, "why": {"en": "Experiments show the larvae can survive short salting, pickling and refrigeration.", "th": "การทดลองพบว่าตัวอ่อนพยาธิมีชีวิตอยู่รอดได้ในปลาเค็ม ปลาดองระยะสั้น และการแช่เย็น"}},
				{"id": "fresh", "label": {"en": "Eating it while it is very fresh", "th": "รับประทานขณะยังสดมาก"}, "why": {"en": "Freshness does not remove the parasite. A very fresh fish can still carry larvae.", "th": "ความสดไม่ได้กำจัดพยาธิ ปลาที่สดมากก็ยังมีตัวอ่อนได้"}},
			],
		},
		{
			"id": "q_l2_lime",
			"level": "l2",
			"required": false,
			"lesson": "no_substitute",
			"corrects": ["lime_kills", "pickling_safe"],
			"question": {
				"en": "A friend says lime juice kills the parasite. What is correct?",
				"th": "เพื่อนบอกว่าน้ำมะนาวฆ่าพยาธิได้ ข้อใดถูกต้อง",
			},
			"options": [
				{"id": "survives", "label": {"en": "Lime juice is not a proven way to kill the larvae, so the fish still needs cooking", "th": "น้ำมะนาวไม่ใช่สิ่งที่พิสูจน์ได้ว่าฆ่าตัวอ่อนได้ ปลาจึงยังต้องปรุงให้สุก"}, "correct": true},
				{"id": "hour", "label": {"en": "Lime juice kills everything if left for an hour", "th": "แช่มะนาวหนึ่งชั่วโมงจะฆ่าได้ทั้งหมด"}, "why": {"en": "Lime changes the taste, not the risk. People who believed it made koi pla safe were found to be more likely to be infected.", "th": "มะนาวเปลี่ยนรสชาติ ไม่ได้ลดความเสี่ยง ผู้ที่เชื่อว่ามะนาวทำให้ก้อยปลาปลอดภัยกลับมีโอกาสติดเชื้อมากกว่า"}},
				{"id": "fresh_enough", "label": {"en": "Lime juice is enough if the fish is very fresh", "th": "ถ้าปลาสดมาก น้ำมะนาวก็เพียงพอ"}, "why": {"en": "Fresh fish can still carry larvae, and lime does not remove them.", "th": "ปลาสดก็ยังมีตัวอ่อนได้ และมะนาวไม่ได้กำจัดตัวอ่อน"}},
			],
		},
		{
			"id": "q_l3_cancer",
			"level": "l3",
			"required": true,
			"lesson": "cancer_link",
			"corrects": ["infection_means_cancer"],
			"question": {
				"en": "How is liver fluke infection related to bile duct cancer?",
				"th": "การติดพยาธิใบไม้ตับเกี่ยวข้องกับมะเร็งท่อน้ำดีอย่างไร",
			},
			"options": [
				{"id": "risk", "label": {"en": "Long-lasting infection is a major risk factor, but not everyone who is infected develops cancer", "th": "การติดเชื้อเป็นเวลานานเป็นปัจจัยเสี่ยงสำคัญ แต่ไม่ใช่ทุกคนที่ติดเชื้อจะเป็นมะเร็ง"}, "correct": true},
				{"id": "certain", "label": {"en": "Everyone who is infected will certainly develop cancer", "th": "ทุกคนที่ติดเชื้อจะเป็นมะเร็งแน่นอน"}, "why": {"en": "Infection raises the risk; it does not guarantee cancer. That difference matters for how we talk about it.", "th": "การติดเชื้อเพิ่มความเสี่ยง แต่ไม่ได้หมายความว่าจะเป็นมะเร็งเสมอ ความแตกต่างนี้สำคัญต่อการสื่อสาร"}},
				{"id": "unrelated", "label": {"en": "The two are not related at all", "th": "ทั้งสองเรื่องไม่เกี่ยวข้องกันเลย"}, "why": {"en": "The World Health Organization's cancer agency classifies infection with Opisthorchis viverrini as carcinogenic to humans (Group 1).", "th": "หน่วยงานมะเร็งขององค์การอนามัยโลกจัดให้การติดพยาธิ Opisthorchis viverrini เป็นสารก่อมะเร็งในมนุษย์ (กลุ่ม 1)"}},
				{"id": "elsewhere", "label": {"en": "It is only a problem in other countries", "th": "เป็นปัญหาเฉพาะในประเทศอื่น"}, "why": {"en": "Liver fluke infection and bile duct cancer are important public-health problems in parts of South-East Asia, including Thailand.", "th": "การติดพยาธิใบไม้ตับและมะเร็งท่อน้ำดีเป็นปัญหาสาธารณสุขสำคัญในพื้นที่บางส่วนของเอเชียตะวันออกเฉียงใต้ รวมถึงประเทศไทย"}},
			],
		},
		{
			"id": "q_l3_treatment",
			"level": "l3",
			"required": false,
			"lesson": "treatment_praziquantel",
			"corrects": ["medicine_replaces_prevention"],
			"question": {
				"en": "Which statement about treating liver fluke infection is correct?",
				"th": "ข้อความใดเกี่ยวกับการรักษาการติดพยาธิใบไม้ตับถูกต้อง",
			},
			"options": [
				{"id": "supervised", "label": {"en": "Medicine such as praziquantel is given under medical supervision, and it does not replace prevention", "th": "ยาต่าง ๆ เช่นพรานซีควอนเทล จ่ายภายใต้การดูแลของแพทย์ และไม่ใช่สิ่งทดแทนการป้องกัน"}, "correct": true},
				{"id": "anytime", "label": {"en": "You can take any deworming tablet whenever you like", "th": "กินยาถ่ายพยาธิชนิดใดก็ได้ตามใจ"}, "why": {"en": "Treatment needs a correct diagnosis, the right medicine and follow-up from a health professional.", "th": "การรักษาต้องมีการวินิจฉัยที่ถูกต้อง ยาที่เหมาะสม และการติดตามจากบุคลากรทางการแพทย์"}},
				{"id": "raw_again", "label": {"en": "After treatment you can eat raw fish again", "th": "หลังรักษาแล้วกลับไปกินปลาดิบได้"}, "why": {"en": "Treatment clears an existing infection. Eating raw fish again can cause a new one.", "th": "การรักษากำจัดเชื้อที่มีอยู่ หากกลับไปกินปลาดิบอีกก็ติดเชื้อใหม่ได้"}},
			],
		},
	]


# ------------------------------------------------------------------ lookups ---
static func by_id(question_id: String) -> Dictionary:
	for q in questions():
		if str(q.get("id", "")) == question_id:
			return q
	return {}


static func for_level(level_id: String) -> Array:
	var out: Array = []
	for q in questions():
		if str(q.get("level", "")) == level_id:
			out.append(q)
	return out


## Questions that must be answered correctly before a level counts as complete.
static func required_for_level(level_id: String) -> Array:
	var out: Array = []
	for q in for_level(level_id):
		if bool(q.get("required", false)):
			out.append(q)
	return out


static func required_ids(level_id: String) -> Array[String]:
	var out: Array[String] = []
	for q in required_for_level(level_id):
		out.append(str(q.get("id", "")))
	return out


static func text(entry: Dictionary, field: String) -> String:
	return LessonDB.text(entry, field, Loc.language)
