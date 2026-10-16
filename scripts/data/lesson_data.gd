class_name LessonDB
## The game's health-knowledge database.
##
## **This file is content, not code.** No gameplay script may state a health
## fact: gameplay asks for a lesson id and shows the text stored here. Every
## lesson therefore carries its own sources, and `Education.validate_database()`
## refuses to start quietly if a lesson cites an unknown or disallowed source.
##
## Two text tiers are stored per lesson so one build can serve primary,
## lower-secondary and upper-secondary students:
##   * `simple`  — one or two short sentences, shown first.
##   * `detail`  — the fuller explanation, revealed on request.
##
## Thai is the primary language; English is kept at the same standard.

extends RefCounted

## Date on which a human last re-read every source below against its text.
const REVIEW_DATE := "2026-10-16"


# ------------------------------------------------------------------ sources ---
## Source keys used by lessons. `status` is deliberately honest:
##   "verified" — the page was opened and the claim checked against its text.
##   "listed"   — a well-known URL for this agency; to be re-checked before the
##                competition submission (see docs/REFERENCES.md).
static func sources() -> Dictionary:
	return {
		"cdc_clinical_opisthorchis": {
			"title": "Clinical Overview of Opisthorchis (liver flukes)",
			"publisher": "US Centers for Disease Control and Prevention (CDC)",
			"url": "https://www.cdc.gov/liver-flukes/hcp/clinical-overview-opisthorchis/index.html",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "public health agency",
			"note": "Page opened 2026-10-16 (CDC, updated 24 June 2024). Confirms: cook fish to an internal temperature of at least 145 °F (about 63 °C); freezing is an additional measure; praziquantel is the treatment of choice; and people cannot get Opisthorchis from another person or from untreated drinking water. Screening nuance: CDC says routine screening is not recommended for an asymptomatic person whose only risk factor is travel. The screening the game describes is the health-worker-led screening of at-risk populations in Thailand (see ddc_thailand), not self-requested testing by travellers.",
		},
		"cdc_about_opisthorchis": {
			"title": "About Opisthorchis (liver flukes)",
			"publisher": "US Centers for Disease Control and Prevention (CDC)",
			"url": "https://www.cdc.gov/liver-flukes/opisthorchis/index.html",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "public health agency",
			"note": "Page opened 2026-10-16 (CDC, updated 6 September 2024). Confirms transmission by eating raw or undercooked freshwater fish. The URL recorded in earlier drafts (.../about/opisthorchis/) was a wrong path and has been corrected to the page that actually exists.",
		},
		"cdc_about_liver_flukes": {
			"title": "About Liver Flukes",
			"publisher": "US Centers for Disease Control and Prevention (CDC)",
			"url": "https://www.cdc.gov/liver-flukes/about/index.html",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "public health agency",
			"note": "Page opened 2026-10-16 (CDC, updated 6 September 2024). Quote read directly: 'There are two families of liver flukes that cause disease in humans: Opisthorchiidae (which includes species of Clonorchis and Opisthorchis) and Fasciolidae (which includes species of Fasciola).' Supports naming Opisthorchis and Clonorchis as liver flukes that infect people.",
		},
		"who_foodborne_trematodes": {
			"title": "Foodborne trematode infections (fact sheet)",
			"publisher": "World Health Organization (WHO)",
			"url": "https://www.who.int/news-room/fact-sheets/detail/foodborne-trematode-infections",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "public health agency",
			"note": "Prevention is by cooking fish and shellfish thoroughly, and by improved sanitation; describes the parasite life cycle.",
		},
		"who_five_keys": {
			"title": "Five keys to safer food (manual)",
			"publisher": "World Health Organization (WHO)",
			"url": "https://www.who.int/publications/i/item/9789241594639",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "public health agency",
			"note": "Page opened 2026-10-16 (WHO, 2006, ISBN 978-92-4-159463-9). The five core messages, verbatim: keep clean; separate raw and cooked; cook thoroughly; keep food at safe temperatures; use safe water and raw materials.",
		},
		"iarc_opisthorchis_group1": {
			"title": "IARC Monographs — infection with Opisthorchis viverrini is carcinogenic to humans (Group 1)",
			"publisher": "International Agency for Research on Cancer (IARC), World Health Organization",
			"url": "https://publications.iarc.who.int/Book-And-Report-Series/Iarc-Monographs-On-The-Identification-Of-Carcinogenic-Hazards-To-Humans/Biological-Agents-2012",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "cancer agency",
			"note": "Monograph text read 2026-10-16 (IARC Monographs Vol. 100B, 2012, 'Opisthorchis viverrini and Clonorchis sinensis', section 5 Evaluation). Quote: 'Chronic infection with Opisthorchis viverrini is carcinogenic to humans (Group 1).' The same section states there is sufficient evidence in humans that the chronic infection causes cholangiocarcinoma. The classified hazard is the infection, not a certainty of cancer in any one person.",
		},
		"sripa_2012_tumorigenic": {
			"title": "The tumorigenic liver fluke Opisthorchis viverrini — multiple pathways to cancer",
			"publisher": "Trends in Parasitology (peer-reviewed)",
			"url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC3682777/",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "peer-reviewed",
			"pmid": "22947297",
			"doi": "10.1016/j.pt.2012.07.006",
			"note": "Indexed record and abstract read via Europe PMC on 2026-10-16. Describes O. viverrini and Clonorchis sinensis as risk factors for cholangiocarcinoma and reviews progression from infection through chronic opisthorchiasis and advanced periductal fibrosis to cholangiocarcinogenesis.",
		},
		"sripan_2017_killing": {
			"title": "Simplified techniques for killing the carcinogenic, Opisthorchis viverrini metacercariae in cyprinid fish",
			"publisher": "Asian Pacific Journal of Cancer Prevention (peer-reviewed)",
			"url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC6373821/",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "peer-reviewed",
			"pmid": "28669159",
			"doi": "10.22034/apjcp.2017.18.6.1507",
			"note": "Abstract read and checked. Boiling or microwaving (400 or 800 W) for at least 5 minutes killed the metacercariae; freezing fish (including pickled fish) at -20 °C for 48 h killed them in all fish sizes; refrigeration at 4 °C for up to 72 h did not.",
		},
		"sornpom_2023_misconceptions": {
			"title": "Influence of misconceptions and inappropriate eating behaviors on Opisthorchis viverrini infection among at-risk populations undergoing cholangiocarcinoma screening in Northeastern Thailand",
			"publisher": "Parasitology Research (peer-reviewed)",
			"url": "https://pubmed.ncbi.nlm.nih.gov/37855971/",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "peer-reviewed",
			"pmid": "37855971",
			"doi": "10.1007/s00436-023-08003-1",
			"note": "Abstract read and checked. Among 636 respondents screened for O. viverrini in north-east Thailand, those who believed that lime or red ants in koi pla, or white whiskey, killed the parasite were more likely to be infected (ARR 1.41; 95% CI 1.03-1.94).",
		},
		"senasri_2024_pla_som": {
			"title": "Temperature and preparation time intervals on survival of Opisthorchis viverrini metacercariae in pickled fish (pla-som)",
			"publisher": "International Journal of Food Science (peer-reviewed)",
			"url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC11576085/",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "peer-reviewed",
			"pmid": "39564079",
			"doi": "10.1155/2024/4817012",
			"note": "Abstract read and checked. Fish stored at -20 °C for 48 h or longer gave zero recovery of O. viverrini metacercariae; storage at 2, 4, 8 °C or room temperature did not.",
		},
		"ddc_thailand": {
			"title": "Press release (15 July 2026): eat cooked, avoid raw freshwater fish, to prevent bile duct cancer",
			"publisher": "Department of Disease Control (DDC), Ministry of Public Health, Thailand",
			"url": "https://ddc.moph.go.th/brc/news.php?news=58817&deptcode=brc",
			"accessed": "2026-10-16",
			"status": "verified",
			"kind": "national public health agency",
			"note": "Thai press-release page opened 2026-10-16. Five prevention points: eat cooked food (especially all freshwater fish); avoid raw or undercooked freshwater fish; choose standard pla-ra and cook it before eating; at-risk people should be screened as advised by health staff; if infected, get treated, followed up and avoid returning to risk. States plainly that lime, chilli, pickling or alcohol cannot kill the larvae - only cooking with heat can. Describes health-worker-led screening of at-risk populations and that deworming medicine is given only after a positive stool test.",
		},
	}


# ------------------------------------------------------------------ lessons ---
static func lessons() -> Array:
	return [
		{
			"id": "clean_hands",
			"levels": ["l1"],
			"category": "hygiene",
			"title": {"en": "Wash your hands", "th": "ล้างมือให้สะอาด"},
			"simple": {
				"en": "Wash your hands with soap and clean water before you touch food, and again after touching raw fish.",
				"th": "ล้างมือด้วยสบู่และน้ำสะอาดก่อนจับอาหาร และล้างอีกครั้งหลังจับปลาดิบ",
			},
			"detail": {
				"en": "Hands move germs and parasite eggs from one surface to another. Washing with soap and running water, then drying, removes far more than a quick rinse.",
				"th": "มือสามารถนำเชื้อโรคและไข่พยาธิจากที่หนึ่งไปยังอีกที่หนึ่ง การล้างด้วยสบู่และน้ำไหลแล้วเช็ดให้แห้งช่วยกำจัดได้มากกว่าการล้างน้ำเปล่าเพียงอย่างเดียว",
			},
			"sources": ["who_five_keys", "cdc_about_liver_flukes"],
		},
		{
			"id": "clean_surfaces",
			"levels": ["l1"],
			"category": "hygiene",
			"title": {"en": "Clean the preparation area", "th": "ทำความสะอาดพื้นที่เตรียมอาหาร"},
			"simple": {
				"en": "Wipe the chopping board and the counter with soap and clean water before you start.",
				"th": "เช็ดเขียงและเคาน์เตอร์ด้วยสบู่และน้ำสะอาดก่อนเริ่มทำอาหาร",
			},
			"detail": {
				"en": "A clean surface keeps germs and parasite eggs off the food. Clean it before cooking, and again after raw fish has touched it.",
				"th": "พื้นผิวที่สะอาดช่วยไม่ให้เชื้อโรคและไข่พยาธิปนเปื้อนอาหาร ควรทำความสะอาดก่อนปรุง และเช็ดอีกครั้งหลังปลาดิบสัมผัสพื้นผิว",
			},
			"sources": ["who_five_keys"],
		},
		{
			"id": "separate_raw",
			"levels": ["l1"],
			"category": "separation",
			"title": {"en": "Separate raw fish from ready-to-eat food", "th": "แยกปลาดิบออกจากอาหารพร้อมรับประทาน"},
			"simple": {
				"en": "Keep raw fish away from food that is ready to eat. Use different boards and plates for each.",
				"th": "แยกปลาดิบออกจากอาหารที่พร้อมรับประทาน ใช้เขียงและจานคนละใบ",
			},
			"detail": {
				"en": "Juices from raw fish can carry parasite larvae onto cooked food. Separate boards, knives and plates stop that transfer. This is called preventing cross-contamination.",
				"th": "น้ำจากปลาดิบอาจมีตัวอ่อนของพยาธิปนไปกับอาหารที่ปรุงสุกแล้ว การใช้เขียง มีด และจานแยกกันจะป้องกันการปนเปื้อนข้าม",
			},
			"sources": ["who_five_keys", "cdc_about_opisthorchis"],
		},
		{
			"id": "clean_utensils",
			"levels": ["l1"],
			"category": "hygiene",
			"title": {"en": "Use clean utensils", "th": "ใช้ภาชนะและอุปกรณ์ที่สะอาด"},
			"simple": {
				"en": "Use clean knives, boards and spoons — and wash them straight away after they touch raw fish.",
				"th": "ใช้มีด เขียง และช้อนที่สะอาด และล้างทันทีหลังสัมผัสปลาดิบ",
			},
			"detail": {
				"en": "A knife that cut raw fish can carry larvae to anything it touches next. Washing it with soap and hot water before it touches other food breaks that chain.",
				"th": "มีดที่ตัดปลาดิบอาจมีตัวอ่อนพยาธิติดอยู่ และปนเปื้อนสิ่งที่สัมผัสถัดไป การล้างด้วยสบู่และน้ำอุ่นก่อนใช้กับอาหารอื่นจะตัดวงจรนี้",
			},
			"sources": ["who_five_keys"],
		},
		{
			"id": "freshwater_fish_risk",
			"levels": ["l2", "l3"],
			"category": "transmission",
			"title": {"en": "Freshwater fish can carry fluke larvae", "th": "ปลาน้ำจืดอาจมีตัวอ่อนพยาธิ"},
			"simple": {
				"en": "Some freshwater fish and shellfish carry tiny liver-fluke larvae. Not every fish is infected, but you cannot see the larvae — so cook the fish well.",
				"th": "ปลาน้ำจืดและหอยบางชนิดมีตัวอ่อนพยาธิใบไม้ตับขนาดเล็ก ไม่ใช่ปลาทุกตัวที่ติดพยาธิ แต่มองไม่เห็นตัวอ่อนด้วยตาเปล่า จึงควรปรุงให้สุกดี",
			},
			"detail": {
				"en": "People become infected by eating raw or undercooked freshwater fish that contain the parasite's larval stage (metacercariae). Marine (sea) fish are not part of this life cycle.",
				"th": "คนติดพยาธิจากการรับประทานปลาน้ำจืดดิบหรือกึ่งสุกที่ยังมีตัวอ่อนระยะติดต่อ (เมตาเซอร์คาเรีย) ปลาทะเลไม่ได้อยู่ในวงจรชีวิตนี้",
			},
			"sources": ["cdc_about_opisthorchis", "who_foodborne_trematodes"],
		},
		{
			"id": "cook_thoroughly",
			"levels": ["l2"],
			"category": "cooking",
			"title": {"en": "Cook fish all the way through", "th": "ปรุงปลาให้สุกทั่วถึง"},
			"simple": {
				"en": "Cook freshwater fish thoroughly, so the inside is fully cooked. Cooked fish flakes apart and is no longer translucent.",
				"th": "ปรุงปลาน้ำจืดให้สุกทั่วถึง เนื้อปลาที่สุกจะแยกออกเป็นชั้น ๆ และไม่โปร่งแสงอีกต่อไป",
			},
			"detail": {
				"en": "The US CDC recommends cooking fish until the inside reaches at least 145°F (about 63°C). Heat kills the parasite's larvae; laboratory tests have killed them by boiling or microwaving fish for at least five minutes. No single temperature and time suits every dish, so the point is to cook the fish through. Use a food thermometer if you have one.",
				"th": "CDC ของสหรัฐฯ แนะนำให้ปรุงปลาจนอุณหภูมิภายในอย่างน้อย 145°F (ประมาณ 63°C) ความร้อนทำลายตัวอ่อนของพยาธิ การทดลองในห้องปฏิบัติการทำลายตัวอ่อนได้โดยการต้มหรือให้ไมโครเวฟนานอย่างน้อย 5 นาที ไม่มีอุณหภูมิและเวลาค่าเดียวที่ใช้ได้กับทุกเมนู สิ่งสำคัญคือปรุงปลาให้สุกทั่วถึง หากมีเทอร์โมมิเตอร์วัดอาหารควรใช้ตรวจสอบ",
			},
			"sources": ["cdc_clinical_opisthorchis", "sripan_2017_killing"],
		},
		{
			"id": "no_substitute",
			"levels": ["l2"],
			"category": "cooking",
			"title": {"en": "Lime, salt and pickling are not enough", "th": "มะนาว เกลือ และการดอง ไม่เพียงพอ"},
			"simple": {
				"en": "Squeezing lime, salting or pickling raw fish does not make it safe. Only cooking it through, or freezing it under the conditions that studies tested, kills the larvae.",
				"th": "การบีบมะนาว หมักเกลือ หรือดองปลาดิบ ไม่ได้ทำให้ปลอดภัย มีเพียงการปรุงให้สุกทั่วถึง หรือการแช่แข็งตามเงื่อนไขที่การศึกษาใช้เท่านั้นที่ทำลายตัวอ่อนได้",
			},
			"detail": {
				"en": "A study of people at high risk in north-east Thailand found that those who believed lime, red ants or white whiskey made raw fish (koi pla) safe were more likely to be infected with the liver fluke. Laboratory experiments have also found the parasite's larvae still alive after short pickling and after refrigeration. Cooking the fish through is the reliable method.",
				"th": "การศึกษากลุ่มเสี่ยงในภาคตะวันออกเฉียงเหนือของไทยพบว่า ผู้ที่เชื่อว่าการใส่มะนาว มดแดง หรือดื่มเหล้าขาวพร้อมก้อยปลาช่วยฆ่าพยาธิ มีโอกาสติดพยาธิใบไม้ตับสูงขึ้น และการทดลองในห้องปฏิบัติการพบว่าตัวอ่อนพยาธิยังมีชีวิตหลังการดองระยะสั้นและหลังการแช่เย็น การปรุงให้สุกทั่วถึงจึงเป็นวิธีที่เชื่อถือได้",
			},
			"sources": ["sornpom_2023_misconceptions", "sripan_2017_killing", "senasri_2024_pla_som"],
		},
		{
			"id": "fluke_lifecycle",
			"levels": ["l3"],
			"category": "transmission",
			"title": {"en": "How liver flukes reach people", "th": "พยาธิใบไม้ตับมาถึงคนได้อย่างไร"},
			"simple": {
				"en": "Liver flukes are tiny worms. They live in the bile ducts after a person eats them in raw freshwater fish.",
				"th": "พยาธิใบไม้ตับเป็นหนอนขนาดเล็ก อาศัยอยู่ในท่อน้ำดี หลังจากคนรับประทานเข้าไปกับปลาน้ำจืดดิบ",
			},
			"detail": {
				"en": "Eggs leave the body in faeces and reach water. They develop inside snails, then form cysts in freshwater fish. The cycle repeats when people eat those fish raw.",
				"th": "ไข่พยาธิออกมากับอุจจาระและลงสู่แหล่งน้ำ เจริญในหอย แล้วกลายเป็นซีสต์ในปลาน้ำจืด วงจรจะซ้ำเมื่อคนรับประทานปลาเหล่านั้นแบบดิบ",
			},
			"sources": ["who_foodborne_trematodes", "cdc_about_liver_flukes"],
		},
		{
			"id": "sanitation_cycle",
			"levels": ["l3"],
			"category": "sanitation",
			"title": {"en": "Safe toilets protect the water", "th": "ส้วมที่ถูกสุขลักษณะปกป้องแหล่งน้ำ"},
			"simple": {
				"en": "Use a toilet, and keep faeces out of canals, ponds and rivers. This breaks part of the parasite's life cycle.",
				"th": "ใช้ส้วม และไม่ทิ้งอุจจาระลงในคลอง หนอง หรือแม่น้ำ ซึ่งจะตัดวงจรชีวิตของพยาธิส่วนหนึ่ง",
			},
			"detail": {
				"en": "Parasite eggs reach water through open defecation. Safe latrines and proper wastewater handling keep the eggs out of the water where snails and fish live. Improving sanitation takes time in a community, so habits matter as much as buildings.",
				"th": "ไข่พยาธิลงสู่แหล่งน้ำได้จากการถ่ายอุจจาระในที่โล่ง ส้วมที่ถูกสุขลักษณะและการจัดการน้ำเสียที่เหมาะสมจะกันไข่ไม่ให้ลงสู่แหล่งน้ำที่เป็นที่อยู่ของหอยและปลา การพัฒนาสุขอนามัยในชุมชนต้องใช้เวลา พฤติกรรมจึงสำคัญพอ ๆ กับสิ่งปลูกสร้าง",
			},
			"sources": ["who_foodborne_trematodes", "ddc_thailand"],
		},
		{
			"id": "cancer_link",
			"levels": ["l3"],
			"category": "cancer",
			"title": {"en": "Liver flukes and bile duct cancer", "th": "พยาธิใบไม้ตับกับมะเร็งท่อน้ำดี"},
			"simple": {
				"en": "Long-lasting liver fluke infection is a major risk factor for bile duct cancer. Not everyone who is infected develops cancer.",
				"th": "การติดพยาธิใบไม้ตับเป็นเวลานานเป็นปัจจัยเสี่ยงสำคัญของมะเร็งท่อน้ำดี ไม่ใช่ทุกคนที่ติดพยาธิจะป่วยเป็นมะเร็ง",
			},
			"detail": {
				"en": "The World Health Organization's cancer agency (IARC) classifies infection with Opisthorchis viverrini as 'carcinogenic to humans' (Group 1). Risk rises with repeated or long-lasting infection, so prevention and early care matter. Cancer is not an automatic outcome of infection.",
				"th": "หน่วยงานมะเร็งขององค์การอนามัยโลก (IARC) จัดให้การติดพยาธิใบไม้ตับ Opisthorchis viverrini เป็นสารก่อมะเร็งในมนุษย์ (กลุ่ม 1) ความเสี่ยงจะสูงขึ้นเมื่อติดเชื้อซ้ำหรือติดต่อกันเป็นเวลานาน การป้องกันและการดูแลตั้งแต่เนิ่น ๆ จึงสำคัญ ทั้งนี้ การติดพยาธิไม่ได้หมายความว่าจะเป็นมะเร็งเสมอไป",
			},
			"sources": ["iarc_opisthorchis_group1", "sripa_2012_tumorigenic"],
		},
		{
			"id": "screening",
			"levels": ["l3"],
			"category": "screening",
			"title": {"en": "Screening is done by health workers", "th": "การคัดกรองทำโดยเจ้าหน้าที่สาธารณสุข"},
			"simple": {
				"en": "Screening for liver flukes and liver problems is carried out by health workers, often with a stool test or an ultrasound. Ask your local health centre.",
				"th": "การตรวจคัดกรองพยาธิใบไม้ตับและปัญหาตับทำโดยเจ้าหน้าที่สาธารณสุข มักใช้การตรวจอุจจาระหรืออัลตราซาวด์ สอบถามได้ที่สถานีอนามัยหรือโรงพยาบาลใกล้บ้าน",
			},
			"detail": {
				"en": "A doctor or health worker decides which tests are suitable for you and explains the results. Screening is not a test you do or interpret by yourself at home.",
				"th": "แพทย์หรือเจ้าหน้าที่สาธารณสุขจะเป็นผู้พิจารณาว่าการตรวจใดเหมาะสมกับคุณ และอธิบายผลตรวจ การคัดกรองไม่ใช่การตรวจหรือแปลผลด้วยตนเองที่บ้าน",
			},
			"sources": ["ddc_thailand", "cdc_clinical_opisthorchis"],
		},
		{
			"id": "treatment_praziquantel",
			"levels": ["l3"],
			"category": "treatment",
			"title": {"en": "Treatment needs medical guidance", "th": "การรักษาต้องอยู่ในความดูแลของบุคลากรทางการแพทย์"},
			"simple": {
				"en": "Liver fluke infection can be treated with medicine — usually praziquantel — given by a doctor or health worker.",
				"th": "การติดพยาธิใบไม้ตับรักษาได้ด้วยยา โดยทั่วไปคือพรานซีควอนเทล ซึ่งจ่ายโดยแพทย์หรือเจ้าหน้าที่สาธารณสุข",
			},
			"detail": {
				"en": "Praziquantel is a prescription medicine. It is not a substitute for prevention: you can be infected again if you keep eating raw fish. Only a health professional should decide on and supervise treatment.",
				"th": "พรานซีควอนเทลเป็นยาที่ต้องสั่งโดยแพทย์ ไม่ใช่สิ่งทดแทนการป้องกัน เพราะคุณสามารถติดเชื้อซ้ำได้หากยังรับประทานปลาดิบ การตัดสินใจและติดตามการรักษาควรอยู่ในความดูแลของบุคลากรทางการแพทย์",
			},
			"sources": ["cdc_clinical_opisthorchis"],
		},
		{
			"id": "community_action",
			"levels": ["l3"],
			"category": "community",
			"title": {"en": "Prevention works best together", "th": "การป้องกันได้ผลดีที่สุดเมื่อทำร่วมกัน"},
			"simple": {
				"en": "Prevention works best when everyone takes part: safe cooking at home, clean water, safe toilets and health checks in the community.",
				"th": "การป้องกันได้ผลดีที่สุดเมื่อทุกคนร่วมมือ ปรุงอาหารให้สุก น้ำสะอาด ส้วมถูกสุขลักษณะ และการตรวจสุขภาพในชุมชน",
			},
			"detail": {
				"en": "Telling your family and neighbours why fish must be cooked properly, and supporting better sanitation, protects more people than any single action.",
				"th": "การเล่าให้คนในครอบครัวและเพื่อนบ้านเข้าใจว่าทำไมต้องปรุงปลาให้สุก และช่วยกันพัฒนาสุขอนามัย ช่วยปกป้องผู้คนได้มากกว่าการทำเพียงคนเดียว",
			},
			"sources": ["who_foodborne_trematodes", "ddc_thailand"],
		},
	]


# ----------------------------------------------------------- misconceptions ---
## The nine ideas the game explicitly corrects. Each one names the lesson that
## explains the truth, so a correction always shows real content rather than a
## bare "wrong".
static func misconceptions() -> Array:
	return [
		{
			"id": "same_board_ok",
			"levels": ["l1"],
			"claim": {"en": "One board is fine for raw fish and for cooked food.", "th": "ใช้เขียงใบเดียวกับปลาดิบและอาหารสุกก็ได้"},
			"lesson": "separate_raw",
		},
		{
			"id": "lime_kills",
			"levels": ["l2"],
			"claim": {"en": "Squeezing lime juice over raw fish makes it safe to eat.", "th": "บีบมะนาวลงบนปลาดิบแล้วกินได้อย่างปลอดภัย"},
			"lesson": "no_substitute",
		},
		{
			"id": "pickling_safe",
			"levels": ["l2"],
			"claim": {"en": "Salting or pickling the fish kills the parasite.", "th": "การหมักเกลือหรือดองปลาช่วยฆ่าพยาธิ"},
			"lesson": "no_substitute",
		},
		{
			"id": "all_fish_infected",
			"levels": ["l2", "l3"],
			"claim": {"en": "Every freshwater fish is full of liver flukes.", "th": "ปลาน้ำจืดทุกตัวเต็มไปด้วยพยาธิใบไม้ตับ"},
			"lesson": "freshwater_fish_risk",
		},
		{
			"id": "temp_magic_number",
			"levels": ["l2"],
			"claim": {"en": "There is one exact temperature that works for every dish.", "th": "มีอุณหภูมิที่แน่นอนเพียงค่าเดียวที่ใช้ได้กับทุกเมนู"},
			"lesson": "cook_thoroughly",
		},
		{
			"id": "dirty_pipe_flukes",
			"levels": ["l3"],
			"claim": {"en": "A dirty pipe means the water is full of liver flukes.", "th": "ท่อที่ดูสกปรกหมายความว่าน้ำเต็มไปด้วยพยาธิใบไม้ตับ"},
			"lesson": "fluke_lifecycle",
		},
		{
			"id": "one_toilet_fixes_all",
			"levels": ["l3"],
			"claim": {"en": "Building one toilet removes every parasite egg straight away.", "th": "สร้างส้วมหนึ่งที่แล้วไข่พยาธิจะหมดไปทันที"},
			"lesson": "sanitation_cycle",
		},
		{
			"id": "infection_means_cancer",
			"levels": ["l3"],
			"claim": {"en": "If you are infected with liver flukes, you will certainly get bile duct cancer.", "th": "ถ้าติดพยาธิใบไม้ตับ จะเป็นมะเร็งท่อน้ำดีแน่นอน"},
			"lesson": "cancer_link",
		},
		{
			"id": "medicine_replaces_prevention",
			"levels": ["l3"],
			"claim": {"en": "Taking the medicine means I can eat raw fish whenever I like.", "th": "กินยาแล้วก็กินปลาดิบได้ทุกเมื่อ"},
			"lesson": "treatment_praziquantel",
		},
	]


# ------------------------------------------------------------------ lookups ---
static func by_id(lesson_id: String) -> Dictionary:
	for lesson in lessons():
		if str(lesson.get("id", "")) == lesson_id:
			return lesson
	return {}


static func lessons_for_level(level_id: String) -> Array:
	var out: Array = []
	for lesson in lessons():
		var levels: Array = lesson.get("levels", [])
		if levels.has(level_id):
			out.append(lesson)
	return out


static func misconceptions_for_level(level_id: String) -> Array:
	var out: Array = []
	for item in misconceptions():
		var levels: Array = item.get("levels", [])
		if levels.has(level_id):
			out.append(item)
	return out


static func misconception(claim_id: String) -> Dictionary:
	for item in misconceptions():
		if str(item.get("id", "")) == claim_id:
			return item
	return {}


## Localised field helper: `text(lesson, "simple")`.
static func text(entry: Dictionary, field: String, language: String) -> String:
	var pair: Variant = entry.get(field)
	if typeof(pair) != TYPE_DICTIONARY:
		return ""
	var dict: Dictionary = pair
	return str(dict.get(language, dict.get("en", "")))


## Localised value of a `{ "en": ..., "th": ... }` dictionary, in the language
## the player has currently selected.
static func local(pair: Variant) -> String:
	if typeof(pair) != TYPE_DICTIONARY:
		return str(pair)
	var dict: Dictionary = pair
	return str(dict.get(Loc.language, dict.get("en", "")))
