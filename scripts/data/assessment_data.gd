class_name AssessmentDB
## The optional before/after knowledge check used by the research plan.
##
## Two comparable sets of six scenario questions. `pair` links a "before"
## question to its "after" counterpart, which is what allows a before/after
## comparison without reusing the identical wording (identical wording invites
## memorisation rather than understanding).
##
## Nothing here is a claim about results. This file only defines the instrument;
## whether it shows any change is a question for a real study, and the game says
## plainly that no study has been run yet.

extends RefCounted

const SET_PRE := "pre"
const SET_POST := "post"


static func questions(set_name: String) -> Array:
	var out: Array = []
	for q in all_questions():
		if str(q.get("set", "")) == set_name:
			out.append(q)
	return out


static func count(set_name: String) -> int:
	return questions(set_name).size()


static func by_id(question_id: String) -> Dictionary:
	for q in all_questions():
		if str(q.get("id", "")) == question_id:
			return q
	return {}


static func all_questions() -> Array:
	return _pre() + _post()


static func _pre() -> Array:
	return [
		{
			"id": "pre_1", "set": SET_PRE, "pair": 1,
			"question": {"en": "Can a person get liver flukes from eating raw freshwater fish?", "th": "คนติดพยาธิใบไม้ตับจากการรับประทานปลาน้ำจืดดิบได้หรือไม่"},
			"options": [
				{"id": "yes", "label": {"en": "Yes", "th": "ได้"}, "correct": true},
				{"id": "no", "label": {"en": "No", "th": "ไม่ได้"}, "correct": false},
				{"id": "unsure", "label": {"en": "Not sure", "th": "ไม่แน่ใจ"}, "correct": false},
			],
			"explain": {"en": "Eating raw or undercooked freshwater fish that carries the parasite's larvae is how people become infected.", "th": "การรับประทานปลาน้ำจืดดิบหรือกึ่งสุกที่มีตัวอ่อนพยาธิเป็นสาเหตุที่ทำให้คนติดเชื้อ"},
		},
		{
			"id": "pre_2", "set": SET_PRE, "pair": 2,
			"question": {"en": "Does squeezing lime juice over raw fish make it safe to eat?", "th": "การบีบมะนาวลงบนปลาดิบทำให้ปลอดภัยต่อการรับประทานหรือไม่"},
			"options": [
				{"id": "no", "label": {"en": "No, it still needs proper cooking", "th": "ไม่ ยังต้องปรุงให้สุกที่ถูกต้อง"}, "correct": true},
				{"id": "yes", "label": {"en": "Yes, lime kills the parasite", "th": "ใช่ มะนาวฆ่าพยาธิได้"}, "correct": false},
				{"id": "unsure", "label": {"en": "Not sure", "th": "ไม่แน่ใจ"}, "correct": false},
			],
			"explain": {"en": "Lime juice changes the taste, but it is not a proven way to kill the larvae. The fish still needs to be cooked through.", "th": "น้ำมะนาวเปลี่ยนรสชาติ แต่ไม่ใช่สิ่งที่พิสูจน์ได้ว่าฆ่าตัวอ่อน ปลายังต้องปรุงให้สุกทั่วถึง"},
		},
		{
			"id": "pre_3", "set": SET_PRE, "pair": 3,
			"question": {"en": "What is the reliable way to make freshwater fish safe to eat?", "th": "วิธีที่เชื่อถือได้ในการทำให้ปลาน้ำจืดปลอดภัยคืออะไร"},
			"options": [
				{"id": "cook", "label": {"en": "Cook it thoroughly, all the way through", "th": "ปรุงให้สุกทั่วถึงทั้งชิ้น"}, "correct": true},
				{"id": "fresh", "label": {"en": "Eat it while it is very fresh", "th": "รับประทานขณะสดมาก"}, "correct": false},
				{"id": "spice", "label": {"en": "Add a lot of chilli and lime", "th": "ใส่พริกและมะนาวเยอะ ๆ"}, "correct": false},
			],
			"explain": {"en": "Thorough cooking is the reliable method. Freshness and strong flavours do not remove the parasite.", "th": "การปรุงให้สุกทั่วถึงเป็นวิธีที่เชื่อถือได้ ความสดและรสจัดไม่ได้กำจัดพยาธิ"},
		},
		{
			"id": "pre_4", "set": SET_PRE, "pair": 4,
			"question": {"en": "Which practice helps stop parasite eggs from reaching the water?", "th": "การปฏิบัติใดช่วยไม่ให้ไข่พยาธิลงสู่แหล่งน้ำ"},
			"options": [
				{"id": "toilet", "label": {"en": "Using a safe toilet", "th": "ใช้ส้วมที่ถูกสุขลักษณะ"}, "correct": true},
				{"id": "cover", "label": {"en": "Covering drinking-water jars", "th": "ปิดภาชนะน้ำดื่ม"}, "correct": false},
				{"id": "boil", "label": {"en": "Boiling drinking water", "th": "ต้มน้ำดื่ม"}, "correct": false},
			],
			"explain": {"en": "Parasite eggs enter the water in faeces. Safe toilets keep them out.", "th": "ไข่พยาธิลงสู่แหล่งน้ำพร้อมอุจจาระ การใช้ส้วมที่ถูกสุขลักษณะจึงกันไว้ได้"},
		},
		{
			"id": "pre_5", "set": SET_PRE, "pair": 5,
			"question": {"en": "Is it true that everyone infected with liver flukes will develop bile duct cancer?", "th": "จริงหรือไม่ที่ทุกคนที่ติดพยาธิใบไม้ตับจะเป็นมะเร็งท่อน้ำดี"},
			"options": [
				{"id": "no", "label": {"en": "No — infection raises the risk, but not everyone develops cancer", "th": "ไม่จริง การติดเชื้อเพิ่มความเสี่ยง แต่ไม่ใช่ทุกคนที่เป็นมะเร็ง"}, "correct": true},
				{"id": "yes", "label": {"en": "Yes, it always leads to cancer", "th": "จริง นำไปสู่มะเร็งเสมอ"}, "correct": false},
				{"id": "unsure", "label": {"en": "Not sure", "th": "ไม่แน่ใจ"}, "correct": false},
			],
			"explain": {"en": "Long-lasting infection is a major risk factor, and IARC classifies the infection as carcinogenic to humans. It is still not an automatic outcome.", "th": "การติดเชื้อเป็นเวลานานเป็นปัจจัยเสี่ยงสำคัญ และ IARC จัดเป็นการก่อมะเร็งในมนุษย์ แต่ก็ไม่ได้หมายความว่าจะเป็นมะเร็งเสมอ"},
		},
		{
			"id": "pre_6", "set": SET_PRE, "pair": 6,
			"question": {"en": "Who should decide on treatment for a liver fluke infection?", "th": "ใครควรเป็นผู้ตัดสินใจเรื่องการรักษาการติดพยาธิใบไม้ตับ"},
			"options": [
				{"id": "worker", "label": {"en": "A doctor or health worker", "th": "แพทย์หรือเจ้าหน้าที่สาธารณสุข"}, "correct": true},
				{"id": "self", "label": {"en": "The patient, using any medicine they can buy", "th": "ผู้ป่วย โดยซื้อยาชนิดใดก็ได้มารับประทานเอง"}, "correct": false},
				{"id": "friend", "label": {"en": "A friend who has had it before", "th": "เพื่อนที่เคยเป็นมาก่อน"}, "correct": false},
			],
			"explain": {"en": "Treatment such as praziquantel is a prescription medicine given under medical supervision, with follow-up.", "th": "การรักษาเช่นพรานซีควอนเทลเป็นยาที่ต้องสั่งโดยแพทย์และต้องมีการติดตามผล"},
		},
	]


static func _post() -> Array:
	return [
		{
			"id": "post_1", "set": SET_POST, "pair": 1,
			"question": {"en": "How do people usually become infected with liver flukes?", "th": "โดยทั่วไปคนติดพยาธิใบไม้ตับได้อย่างไร"},
			"options": [
				{"id": "raw_fish", "label": {"en": "By eating raw or undercooked freshwater fish", "th": "จากการรับประทานปลาน้ำจืดดิบหรือกึ่งสุก"}, "correct": true},
				{"id": "water", "label": {"en": "By drinking dirty-looking water", "th": "จากการดื่มน้ำที่ดูสกปรก"}, "correct": false},
				{"id": "touch", "label": {"en": "By touching an infected person", "th": "จากการสัมผัสผู้ป่วย"}, "correct": false},
			],
			"explain": {"en": "The infection comes from eating the parasite's larval stage in raw freshwater fish — not from person to person.", "th": "การติดเชื้อเกิดจากการรับประทานตัวอ่อนพยาธิในปลาน้ำจืดดิบ ไม่ได้ติดจากคนสู่คน"},
		},
		{
			"id": "post_2", "set": SET_POST, "pair": 2,
			"question": {"en": "A neighbour salts and pickles raw fish for one day before serving it. Is it safe?", "th": "เพื่อนบ้านหมักเกลือและดองปลาดิบหนึ่งวันก่อนเสิร์ฟ ปลอดภัยหรือไม่"},
			"options": [
				{"id": "no_cook", "label": {"en": "No — it still needs to be cooked thoroughly", "th": "ไม่ ยังต้องปรุงให้สุกทั่วถึง"}, "correct": true},
				{"id": "yes_salt", "label": {"en": "Yes — the salt kills the parasite", "th": "ใช่ เกลือฆ่าพยาธิได้"}, "correct": false},
				{"id": "yes_pickle", "label": {"en": "Yes — pickling is the same as cooking", "th": "ใช่ การดองเทียบเท่าการปรุงสุก"}, "correct": false},
			],
			"explain": {"en": "Salting and pickling change flavour and texture, but fluke larvae can survive them.", "th": "การหมักเกลือและการดองเปลี่ยนรสชาติและเนื้อสัมผัส แต่ตัวอ่อนพยาธิยังมีชีวิตอยู่ได้"},
		},
		{
			"id": "post_3", "set": SET_POST, "pair": 3,
			"question": {"en": "Which result shows that freshwater fish is safely cooked?", "th": "ผลลัพธ์ใดแสดงว่าปลาน้ำจืดปรุงสุกอย่างปลอดภัย"},
			"options": [
				{"id": "opaque", "label": {"en": "The inside is fully cooked and the flesh flakes apart", "th": "เนื้อด้านในสุกทั้งหมดและแยกออกเป็นชั้น"}, "correct": true},
				{"id": "warm", "label": {"en": "The outside feels warm to the touch", "th": "ด้านนอกอุ่นเมื่อสัมผัส"}, "correct": false},
				{"id": "golden", "label": {"en": "The skin has turned golden", "th": "หนังปลาเปลี่ยนเป็นสีเหลืองทอง"}, "correct": false},
			],
			"explain": {"en": "Brown skin and a warm surface do not prove the inside is cooked. The CDC recommends an internal temperature of at least 145°F (about 63°C).", "th": "ผิวเหลืองทองและด้านนอกอุ่นไม่ได้ยืนยันว่าด้านในสุก CDC แนะนำให้อุณหภูมิภายในอย่างน้อย 145°F (ประมาณ 63°C)"},
		},
		{
			"id": "post_4", "set": SET_POST, "pair": 4,
			"question": {"en": "Why do safe toilets help prevent liver fluke infection?", "th": "เพราะเหตุใดส้วมที่ถูกสุขลักษณะจึงช่วยป้องกันการติดพยาธิใบไม้ตับ"},
			"options": [
				{"id": "eggs", "label": {"en": "They keep parasite eggs out of the water where snails and fish live", "th": "ช่วยกันไข่พยาธิไม่ให้ลงสู่แหล่งน้ำที่เป็นที่อยู่ของหอยและปลา"}, "correct": true},
				{"id": "smell", "label": {"en": "They keep the village tidy and smelling fresh", "th": "ทำให้หมู่บ้านสะอาดและไม่มีกลิ่น"}, "correct": false},
				{"id": "instant", "label": {"en": "One toilet removes every egg immediately", "th": "ส้วมหนึ่งที่กำจัดไข่พยาธิได้ทันทีทั้งหมด"}, "correct": false},
			],
			"explain": {"en": "Safe sanitation breaks the parasite's life cycle at the point where eggs would reach the water. It takes consistent effort across a community, not a single building.", "th": "สุขอนามัยที่ถูกต้องตัดวงจรชีวิตของพยาธิตรงจุดที่ไข่จะลงสู่แหล่งน้ำ ต้องอาศัยความร่วมมือต่อเนื่องของชุมชน ไม่ใช่สิ่งปลูกสร้างเพียงหลังเดียว"},
		},
		{
			"id": "post_5", "set": SET_POST, "pair": 5,
			"question": {"en": "How does long-lasting liver fluke infection relate to bile duct cancer?", "th": "การติดพยาธิใบไม้ตับเป็นเวลานานเกี่ยวข้องกับมะเร็งท่อน้ำดีอย่างไร"},
			"options": [
				{"id": "risk", "label": {"en": "It is a major risk factor, but most risks can be reduced by prevention and early care", "th": "เป็นปัจจัยเสี่ยงสำคัญ แต่ความเสี่ยงส่วนใหญ่ลดได้ด้วยการป้องกันและการดูแลตั้งแต่เนิ่น ๆ"}, "correct": true},
				{"id": "certain", "label": {"en": "Every infected person will develop cancer", "th": "ทุกคนที่ติดเชื้อจะเป็นมะเร็ง"}, "correct": false},
				{"id": "none", "label": {"en": "There is no connection between them", "th": "ไม่มีความเกี่ยวข้องกันเลย"}, "correct": false},
			],
			"explain": {"en": "IARC classifies infection with Opisthorchis viverrini as carcinogenic to humans (Group 1), while stressing that infection does not automatically mean cancer.", "th": "IARC จัดการติดพยาธิ Opisthorchis viverrini เป็นสารก่อมะเร็งในมนุษย์ (กลุ่ม 1) แต่ย้ำว่าการติดเชื้อไม่ได้หมายความว่าจะเป็นมะเร็งเสมอ"},
		},
		{
			"id": "post_6", "set": SET_POST, "pair": 6,
			"question": {"en": "What is the correct role of praziquantel?", "th": "บทบาทที่ถูกต้องของพรานซีควอนเทลคืออะไร"},
			"options": [
				{"id": "supervised", "label": {"en": "It treats an infection under medical supervision, and does not replace prevention", "th": "รักษาการติดเชื้อภายใต้การดูแลของแพทย์ และไม่ใช่สิ่งทดแทนการป้องกัน"}, "correct": true},
				{"id": "prevent", "label": {"en": "It prevents infection, so raw fish becomes safe", "th": "ป้องกันการติดเชื้อ ปลาดิบจึงปลอดภัย"}, "correct": false},
				{"id": "replace", "label": {"en": "It replaces the need to cook fish properly", "th": "ใช้แทนการปรุงปลาให้สุกได้"}, "correct": false},
			],
			"explain": {"en": "Praziquantel is prescribed and supervised by a health professional. It clears an existing infection; it does not stop a new one.", "th": "พรานซีควอนเทลต้องสั่งและดูแลโดยบุคลากรทางการแพทย์ ช่วยกำจัดเชื้อที่มีอยู่ แต่ไม่ได้ป้องกันการติดเชื้อใหม่"},
		},
	]


static func text(entry: Dictionary, field: String) -> String:
	return LessonDB.local(entry.get(field))
