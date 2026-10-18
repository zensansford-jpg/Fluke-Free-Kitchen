class_name UIStrings
## Localised user-interface text for the whole game.
##
## Every string the interface can show lives here as a `{ "en": ..., "th": ... }`
## pair, so there is exactly one place to check translations and one place to
## edit wording. Health *content* lives in `LessonDB`, never here.
##
## Thai is the primary language for this project (the competition is Thai); the
## English tier exists so the same build can be reviewed internationally.

extends RefCounted


static func table() -> Dictionary:
	return {
		# ---------------------------------------------------------- identity --
		"app.title": {"en": GameConfig.GAME_TITLE, "th": GameConfig.GAME_TITLE_THAI},
		"app.subtitle": {"en": GameConfig.GAME_SUBTITLE, "th": GameConfig.GAME_SUBTITLE_THAI},
		"app.competition": {"en": GameConfig.COMPETITION, "th": GameConfig.COMPETITION_TH},

		# -------------------------------------------------------------- menu --
		"menu.play": {"en": "Play", "th": "เล่น"},
		"menu.continue": {"en": "Continue", "th": "เล่นต่อ"},
		"menu.levels": {"en": "Challenges", "th": "ด่านภารกิจ"},
		"menu.challenges": {"en": "Story Challenges", "th": "ด่านเรื่องราว"},
		"menu.journal": {"en": "Recipe & Knowledge Journal", "th": "สมุดสูตรอาหารและความรู้"},
		"menu.assessment": {"en": "Knowledge Check", "th": "แบบทดสอบความรู้"},
		"menu.settings": {"en": "Settings", "th": "ตั้งค่า"},
		"menu.how_to_play": {"en": "How to Play", "th": "วิธีเล่น"},
		"menu.about": {"en": "About & Sources", "th": "เกี่ยวกับและแหล่งอ้างอิง"},
		"menu.quit": {"en": "Quit", "th": "ออกจากเกม"},

		# ------------------------------------------------------ level select --
		"levels.title": {"en": "Choose a Challenge", "th": "เลือกด่านภารกิจ"},
		"levels.subtitle": {"en": "Each challenge takes about two minutes.", "th": "แต่ละด่านใช้เวลาประมาณสองนาที"},
		"levels.play": {"en": "Start", "th": "เริ่ม"},
		"levels.replay": {"en": "Play again", "th": "เล่นอีกครั้ง"},
		"levels.locked": {"en": "Locked", "th": "ยังไม่เปิด"},
		"levels.locked_hint": {"en": "Finish the previous challenge to unlock this one.", "th": "เล่นด่านก่อนหน้าให้จบเพื่อเปิดด่านนี้"},
		"levels.best": {"en": "Best", "th": "คะแนนสูงสุด"},
		"levels.best_none": {"en": "Not played yet", "th": "ยังไม่เคยเล่น"},
		"levels.total_stars": {"en": "Stars", "th": "ดาว"},

		# --------------------------------------------------------------- hud --
		"hud.challenge": {"en": "Challenge", "th": "ภารกิจ"},
		"hud.step": {"en": "Step", "th": "ขั้นที่"},
		"hud.pause": {"en": "Pause", "th": "หยุดพัก"},
		"hud.restart": {"en": "Restart", "th": "เริ่มใหม่"},
		"hud.stars_earned": {"en": "Stars", "th": "ดาว"},
		"hud.tidy": {"en": "Tidiness", "th": "ความเรียบร้อย"},

		# -------------------------------------------------------------- tasks --
		"task.watch_demo": {"en": "Watch, then try it yourself", "th": "ดูตัวอย่าง แล้วลองทำเอง"},
		"task.skip_demo": {"en": "Skip", "th": "ข้าม"},
		"task.your_turn": {"en": "Your turn!", "th": "ตาคุณแล้ว!"},
		"task.order_pool": {"en": "Tap the steps in the right order", "th": "แตะขั้นตอนตามลำดับที่ถูกต้อง"},
		"task.order_placed": {"en": "Your order so far", "th": "ลำดับที่คุณเรียงแล้ว"},
		"task.hold": {"en": "Press and hold", "th": "กดค้างไว้"},
		"task.drag": {"en": "Drag it across", "th": "ลากไปมา"},
		"task.tap": {"en": "Tap", "th": "แตะ"},
		"task.progress": {"en": "Progress", "th": "ความคืบหน้า"},
		"task.clean_all": {"en": "Wash the whole board", "th": "ล้างให้ทั่วทั้งเขียง"},
		"task.temperature": {"en": "Inside the fish", "th": "อุณหภูมิในเนื้อปลา"},
		"task.safe_zone": {"en": "Safe level", "th": "ระดับปลอดภัย"},
		"task.keep_holding": {"en": "Keep holding to stay at a safe temperature", "th": "กดค้างไว้เพื่อคงอุณหภูมิปลอดภัย"},
		"task.too_cold": {"en": "Still below the safe temperature. Hold for longer.", "th": "ยังต่ำกว่าระดับปลอดภัย กดค้างไว้นานขึ้น"},
		"task.pan_ready": {"en": "The pan is hot enough.", "th": "กระทะร้อนพอแล้ว"},
		"task.press_stove": {"en": "Press and hold on the pan to heat it", "th": "กดค้างบนกระทะเพื่อให้ความร้อน"},
		"task.drag_target": {"en": "Drag it to the right container", "th": "ลากไปยังภาชนะที่ถูกต้อง"},
		"task.not_measured_note": {
			"en": "This activity is practice, not a measurement.",
			"th": "กิจกรรมนี้คือการฝึกฝน ไม่ใช่การวัดผล",
		},

		"feedback.correct": {"en": "Correct!", "th": "ถูกต้อง!"},
		"feedback.almost": {"en": "Not quite", "th": "ยังไม่ถูก"},
		"feedback.try_again": {"en": "Try again", "th": "ลองอีกครั้ง"},
		"feedback.explanation": {"en": "Why this matters", "th": "ทำไมเรื่องนี้จึงสำคัญ"},
		"feedback.missed_correct": {
			"en": "There are still correct actions you have not ticked yet.",
			"th": "ยังมีข้อที่ถูกต้องที่คุณยังไม่ได้เลือก",
		},
		"feedback.wrong_order": {"en": "That step comes later. Start from the beginning.", "th": "ขั้นนี้มาทีหลัง เริ่มจากขั้นแรกก่อน"},
		"feedback.too_early": {"en": "Remove the fish from the heat only when it is safely cooked.", "th": "นำปลาออกจากความร้อนเมื่อสุกอย่างปลอดภัยแล้วเท่านั้น"},
		"feedback.cleaned": {"en": "Clean and ready to use.", "th": "สะอาดพร้อมใช้แล้ว"},
		"feedback.cooked": {"en": "Cooked all the way through.", "th": "สุกทั่วถึงแล้ว"},
		"feedback.continue": {"en": "Continue", "th": "ต่อไป"},
		"feedback.keep_raw_apart": {
			"en": "Raw food must stay apart from food that will be eaten without being cooked again.",
			"th": "อาหารดิบต้องแยกจากอาหารที่จะรับประทานโดยไม่ปรุงสุกอีก",
		},
		"feedback.ready_apart": {
			"en": "Ready-to-eat food must not touch raw fish or the juices from it.",
			"th": "อาหารพร้อมรับประทานต้องไม่สัมผัสปลาดิบหรือน้ำจากปลาดิบ",
		},
		"feedback.not_here": {
			"en": "That is not the right place for this one.",
			"th": "ยังไม่ใช่ที่ที่ถูกต้องสำหรับสิ่งนี้",
		},
		"feedback.board_clean": {"en": "The board is clean now.", "th": "เขียงสะอาดแล้ว"},
		"feedback.released_early": {
			"en": "Letting go stops the cooking. Keep holding until the inside is safe.",
			"th": "เมื่อปล่อยมือ การปรุงจะหยุดลง กดค้างต่อจนกว่าด้านในจะปลอดภัย",
		},
		"feedback.cleaning_done": {"en": "Washed. Time to dry it.", "th": "ล้างเสร็จแล้ว ต่อไปคือเช็ดให้แห้ง"},
		"task.colour_not_proof": {
			"en": "A golden colour is not a safety check. What makes the fish safe is the inside temperature and how long it stays there.",
			"th": "สีเหลืองทองไม่ใช่การตรวจสอบความปลอดภัย สิ่งที่ทำให้ปลาปลอดภัยคืออุณหภูมิภายในและระยะเวลาที่คงอุณหภูมินั้นไว้",
		},
		"feedback.burnt": {
			"en": "The fish has burnt. The pan stayed too hot for too long, so this fish is spoiled and cannot be served.",
			"th": "ปลาไหม้แล้ว กระทะร้อนเกินไปนานเกินไป ปลาตัวนี้จึงใช้ไม่ได้และเสิร์ฟไม่ได้",
		},
		"task.burnt_detail": {
			"en": "Burning is what too much heat does to the outside. It still says nothing about whether the inside reached a safe temperature — which is why the inside temperature is what the game measures.",
			"th": "การไหม้คือผลของความร้อนที่มากเกินไปต่อผิวนอก ยังไม่ได้บอกว่าด้านในถึงอุณหภูมิปลอดภัยหรือไม่ เกมจึงวัดที่อุณหภูมิด้านใน",
		},
		"task.retry_cook": {"en": "Start this fish again", "th": "เริ่มปรุงปลาตัวนี้ใหม่"},
		"task.serve_now": {"en": "Serve it now", "th": "เสิร์ฟเลยตอนนี้"},
		"task.keep_cooking": {"en": "Keep cooking this one", "th": "ปรุงตัวนี้ต่อ"},
		"feedback.unsafe_serve": {
			"en": "This fish is not cooked enough to serve. Served like this it may still carry living liver-fluke larvae.",
			"th": "ปลาจานนี้ยังสุกไม่พอที่จะเสิร์ฟ หากเสิร์ฟแบบนี้อาจยังมีตัวอ่อนพยาธิใบไม้ตับที่ยังมีชีวิตอยู่",
		},
		"task.unsafe_serve_detail": {
			"en": "Eating raw or undercooked freshwater fish is how people get liver flukes. Serving this plate means whoever eats it is exposed to the larvae — that is a risk of becoming infected, not an infection that has already happened, and an infection is not the same thing as cancer. Cooking the fish through until the inside is safe removes the risk.",
			"th": "การรับประทานปลาน้ำจืดดิบหรือกึ่งสุกเป็นทางที่คนติดพยาธิใบไม้ตับ การเสิร์ฟจานนี้จึงทำให้ผู้ที่รับประทานได้รับตัวอ่อนพยาธินั่นคือความเสี่ยงที่จะติดเชื้อ ไม่ใช่การติดเชื้อที่เกิดขึ้นแล้ว และการติดเชื้อก็ไม่เท่ากับการเป็นมะเร็ง การปรุงให้สุกจนด้านในปลอดภัยจะกำจัดความเสี่ยงนี้",
		},

		# ------------------------------------------------- cooking minigames --
		"task.gesture_circle": {"en": "Move in circles", "th": "ขยับเป็นวงกลม"},
		"task.gesture_swipe": {"en": "Swipe up", "th": "ปัดขึ้น"},
		"task.chop": {"en": "Chop the ingredients", "th": "หั่นส่วนผสม"},
		"task.prep_fish": {"en": "Prepare the fish", "th": "เตรียมปลา"},
		"task.stir": {"en": "Stir the pot", "th": "คนในหม้อ"},
		"task.flip": {"en": "Flip the fish", "th": "พลิกปลา"},
		"task.flip_button": {"en": "Flip", "th": "พลิก"},
		"task.plate": {"en": "Plate the dish", "th": "จัดจาน"},
		"task.serve_or_check": {"en": "Serve it, or check it first?", "th": "จะเสิร์ฟเลย หรือตรวจก่อน"},
		"task.take_it_back": {"en": "Put it back and keep cooking", "th": "เอาออกไปปรุงต่อ"},
		"feedback.prepped": {"en": "Prepared and ready.", "th": "เตรียมเสร็จแล้ว"},
		"feedback.stirred": {"en": "Mixed evenly.", "th": "คนเข้ากันดีแล้ว"},
		"feedback.flipped": {"en": "Nice flip — both sides will cook.", "th": "พลิกได้ดี ทั้งสองด้านจะสุก"},
		"feedback.plated": {"en": "Plated and ready to serve.", "th": "จัดจานพร้อมเสิร์ฟ"},
		"feedback.served_ready": {"en": "Served. It was cooked through, so this is a safe plate.", "th": "เสิร์ฟแล้ว ปรุงสุกทั่วถึง จึงเป็นจานที่ปลอดภัย"},
		"feedback.already_ready": {
			"en": "This one is already cooked through — it is safe to serve.",
			"th": "จานนี้สุกทั่วถึงแล้ว เสิร์ฟได้อย่างปลอดภัย",
		},
		"feedback.good_catch": {
			"en": "Good catch. It was not ready. Checking before serving is exactly the right habit.",
			"th": "ตรวจได้ดี จานนี้ยังไม่พร้อม การตรวจก่อนเสิร์ฟเป็นนิสัยที่ถูกต้อง",
		},
		"feedback.keep_kitchen_order": {
			"en": "Ingredients go in the pan; soap and cleaning things belong at the sink.",
			"th": "ส่วนผสมใส่ในกระทะ ส่วนสบู่และของทำความสะอาดให้วางที่อ่างล้าง",
		},

		# ------------------------------------------------------------ lessons --
		"lesson.health_tip": {"en": "Health tip", "th": "เกร็ดสุขภาพ"},
		"lesson.more_detail": {"en": "More detail", "th": "รายละเอียดเพิ่มเติม"},
		"lesson.less_detail": {"en": "Less detail", "th": "ย่อรายละเอียด"},
		"lesson.sources": {"en": "Source", "th": "แหล่งอ้างอิง"},
		"lesson.sources_plural": {"en": "Sources", "th": "แหล่งอ้างอิง"},
		"lesson.disclaimer": {
			"en": "General health information for learning only. It is not a diagnosis or medical advice. For your own health, talk to a doctor or health worker.",
			"th": "ข้อมูลนี้เป็นความรู้ทั่วไปเพื่อการเรียนรู้ ไม่ใช่การวินิจฉัยหรือคำแนะนำทางการแพทย์ หากต้องการดูแลสุขภาพของตนเอง ควรปรึกษาแพทย์หรือเจ้าหน้าที่สาธารณสุข",
		},
		"lesson.simple_label": {"en": "Simple", "th": "แบบง่าย"},
		"lesson.detail_label": {"en": "Detailed", "th": "แบบละเอียด"},

		# --------------------------------------------------------- knowledge --
		"quiz.title": {"en": "Knowledge Check", "th": "ตรวจความรู้"},
		"quiz.required_note": {
			"en": "Answer this to finish the challenge. If you are unsure, you can try again.",
			"th": "ตอบคำถามนี้เพื่อจบภารกิจ หากยังไม่แน่ใจ สามารถลองใหม่ได้",
		},
		"quiz.submit": {"en": "Answer", "th": "ตอบ"},
		"quiz.correct": {"en": "That is right.", "th": "ถูกต้อง"},
		"quiz.incorrect": {"en": "That is not right yet.", "th": "ยังไม่ถูกต้อง"},
		"quiz.explain_correct": {"en": "Here is why", "th": "เหตุผล"},
		"quiz.next": {"en": "Next", "th": "ถัดไป"},
		"quiz.question_of": {"en": "Question %d of %d", "th": "คำถามข้อ %d จาก %d"},

		# ------------------------------------------------------------- result --
		"result.title": {"en": "Challenge complete", "th": "จบภารกิจ"},
		"result.title_retry": {"en": "Almost there", "th": "เกือบแล้ว"},
		"result.stars": {"en": "Stars", "th": "ดาว"},
		"result.score": {"en": "Score", "th": "คะแนน"},
		"result.correct_actions": {"en": "Correct actions", "th": "การกระทำที่ถูกต้อง"},
		"result.safety": {"en": "Food-safety decisions", "th": "การตัดสินใจด้านความปลอดภัยอาหาร"},
		"result.knowledge": {"en": "Knowledge check", "th": "ผลการตรวจความรู้"},
		"result.understanding": {"en": "Understanding", "th": "ความเข้าใจ"},
		"result.continue": {"en": "Continue", "th": "ต่อไป"},
		"result.retry": {"en": "Try again", "th": "ลองอีกครั้ง"},
		"result.next_level": {"en": "Next challenge", "th": "ด่านถัดไป"},
		"result.to_levels": {"en": "All challenges", "th": "ด่านทั้งหมด"},
		"result.need_quiz": {
			"en": "Answer the knowledge check to complete this challenge.",
			"th": "ตอบคำถามตรวจความรู้เพื่อจบภารกิจนี้",
		},
		"result.new_best": {"en": "New best score!", "th": "คะแนนสูงสุดใหม่!"},
		"result.time": {"en": "Time taken", "th": "เวลาที่ใช้"},
		"result.accuracy": {"en": "First-try accuracy", "th": "ความแม่นยำครั้งแรก"},
		"result.first_try": {"en": "first try", "th": "ครั้งแรก"},
		"result.education_note": {
			"en": "Stars need both careful actions and correct answers. A high score alone is not proof of learning.",
			"th": "การได้ดาวต้องอาศัยทั้งการกระทำที่รอบคอบและคำตอบที่ถูกต้อง คะแนนสูงเพียงอย่างเดียวไม่ได้พิสูจน์ว่ามีการเรียนรู้",
		},

		# ------------------------------------------------------------ journal --
		"journal.title": {"en": "Journal", "th": "สมุดบันทึก"},
		"journal.tab_recipes": {"en": "Recipes", "th": "สูตรอาหาร"},
		"journal.tab_lessons": {"en": "Knowledge", "th": "ความรู้"},
		"journal.tab_progress": {"en": "Progress", "th": "ความก้าวหน้า"},
		"journal.covered": {"en": "Learned", "th": "เรียนรู้แล้ว"},
		"journal.not_covered": {"en": "Not yet", "th": "ยังไม่ได้เรียนรู้"},
		"journal.questions_correct": {"en": "Questions answered correctly", "th": "คำถามที่ตอบถูก"},
		"journal.misconceptions": {"en": "Misconceptions corrected", "th": "ความเข้าใจผิดที่แก้ไขแล้ว"},
		"journal.activities": {"en": "Activities completed", "th": "กิจกรรมที่ทำสำเร็จ"},
		"journal.myth_belief": {"en": "Some people think:", "th": "บางคนเข้าใจว่า"},
		"journal.myth_truth": {"en": "What is actually true:", "th": "ความจริงคือ"},
		"journal.empty": {"en": "Nothing here yet. Play a challenge to fill your journal.", "th": "ยังไม่มีข้อมูล เล่นด่านภารกิจเพื่อบันทึกความรู้"},
		"journal.overall": {"en": "Overall progress", "th": "ความก้าวหน้าโดยรวม"},

		# --------------------------------------------------------- assessment --
		"assessment.title": {"en": "Knowledge Check", "th": "แบบทดสอบความรู้"},
		"assessment.intro": {
			"en": "These short questions help show what you already know and what you learned after playing. They are not graded, and no personal details are stored.",
			"th": "คำถามสั้น ๆ เหล่านี้ช่วยแสดงว่าคุณรู้อะไรอยู่แล้ว และได้เรียนรู้อะไรหลังเล่นเกม ไม่มีการให้คะแนนเกรด และไม่เก็บข้อมูลส่วนตัว",
		},
		"assessment.pre": {"en": "Before playing", "th": "ก่อนเล่น"},
		"assessment.post": {"en": "After playing", "th": "หลังเล่น"},
		"assessment.start_pre": {"en": "Start the 'before' questions", "th": "เริ่มคำถามชุดก่อนเล่น"},
		"assessment.start_post": {"en": "Start the 'after' questions", "th": "เริ่มคำถามชุดหลังเล่น"},
		"assessment.result_pre": {"en": "Before-playing score", "th": "คะแนนก่อนเล่น"},
		"assessment.result_post": {"en": "After-playing score", "th": "คะแนนหลังเล่น"},
		"assessment.of": {"en": "of", "th": "จาก"},
		"assessment.pending": {"en": "Not taken yet", "th": "ยังไม่ได้ทำ"},
		"assessment.export": {"en": "Save my results file", "th": "บันทึกไฟล์ผลของฉัน"},
		"assessment.exported": {"en": "Saved to the game's user folder.", "th": "บันทึกไว้ในโฟลเดอร์ข้อมูลผู้เล่นแล้ว"},
		"assessment.not_measured": {
			"en": "This build has not yet been used in a classroom study. It does not claim any measured learning improvement.",
			"th": "เวอร์ชันนี้ยังไม่ได้รับการทดลองใช้ในห้องเรียน จึงยังไม่มีการอ้างอิงผลการเรียนที่วัดได้",
		},
		"assessment.clear": {"en": "Clear my answers", "th": "ล้างคำตอบของฉัน"},
		"assessment.code": {"en": "Case code (optional)", "th": "รหัสผู้เรียน (ไม่บังคับ)"},
		"assessment.code_placeholder": {"en": "for example A-07", "th": "ตัวอย่าง A-07"},
		"assessment.code_hint": {
			"en": "Fill this in only if your teacher gave you a code. Letters, numbers, hyphen and underscore; up to 16 characters. It is not a name — it is used only to match these answers with your paper form.",
			"th": "กรอกเฉพาะเมื่อครูมอบรหัสให้ ใช้ได้เฉพาะตัวอักษร ตัวเลข ขีดกลาง และขีดล่าง ไม่เกิน 16 ตัวอักษร ไม่ใช่ชื่อ และใช้เพียงเพื่อจับคู่คำตอบนี้กับแบบฟอร์มกระดาษของคุณ",
		},

		# ----------------------------------------------------------- settings --
		"settings.title": {"en": "Settings", "th": "ตั้งค่า"},
		"settings.audio": {"en": "Sound", "th": "เสียง"},
		"settings.master": {"en": "Master volume", "th": "ระดับเสียงรวม"},
		"settings.music": {"en": "Music", "th": "เพลง"},
		"settings.sfx": {"en": "Sound effects", "th": "เสียงประกอบ"},
		"settings.display": {"en": "Display", "th": "การแสดงผล"},
		"settings.language": {"en": "Language", "th": "ภาษา"},
		"settings.quality": {"en": "Graphics quality", "th": "คุณภาพกราฟิก"},
		"settings.fullscreen": {"en": "Fullscreen", "th": "เต็มหน้าจอ"},
		"settings.resolution": {"en": "Resolution", "th": "ความละเอียด"},
		"settings.feedback": {"en": "Feedback", "th": "การตอบสนอง"},
		"settings.shake": {"en": "Screen feedback", "th": "การสั่นของหน้าจอ"},
		"settings.detail": {"en": "Show detailed health text by default", "th": "แสดงรายละเอียดสุขภาพโดยค่าเริ่มต้น"},
		"settings.progress": {"en": "Progress", "th": "ความก้าวหน้า"},
		"settings.reset_progress": {"en": "Reset all progress", "th": "ล้างความก้าวหน้าทั้งหมด"},
		"settings.reset_confirm": {
			"en": "This erases stars, best scores and journal entries on this device. Continue?",
			"th": "การล้างจะลบดาว คะแนนสูงสุด และบันทึกความรู้ในเครื่องนี้ ดำเนินการต่อหรือไม่",
		},
		"settings.reset_done": {"en": "Progress reset.", "th": "ล้างความก้าวหน้าแล้ว"},
		"settings.back": {"en": "Back", "th": "ย้อนกลับ"},

		# -------------------------------------------------------------- pause --
		"pause.title": {"en": "Paused", "th": "หยุดพัก"},
		"pause.resume": {"en": "Resume", "th": "เล่นต่อ"},
		"pause.restart": {"en": "Restart challenge", "th": "เริ่มภารกิจใหม่"},
		"pause.settings": {"en": "Settings", "th": "ตั้งค่า"},
		"pause.journal": {"en": "Open journal", "th": "เปิดสมุดบันทึก"},
		"pause.to_levels": {"en": "Quit to challenges", "th": "ออกไปหน้าด่านภารกิจ"},

		# ---------------------------------------------------------------- how --
		"how.title": {"en": "How to Play", "th": "วิธีเล่น"},
		"how.intro": {
			"en": "You are helping in a village kitchen. Each challenge asks you to do a few small cooking and food-safety actions. A demonstration plays first, then it is your turn.",
			"th": "คุณกำลังช่วยงานในครัวของหมู่บ้าน แต่ละภารกิจจะให้ทำกิจกรรมทำอาหารและความปลอดภัยอาหารสั้น ๆ ไม่กี่อย่าง ระบบจะแสดงตัวอย่างก่อน แล้วจึงถึงตาคุณ",
		},
		"how.mouse": {"en": "Use the mouse: click, drag, and press-and-hold.", "th": "ใช้เมาส์: คลิก ลาก และกดค้าง"},
		"how.touch": {"en": "On a touchscreen, use your finger the same way.", "th": "บนจอสัมผัส ใช้นิ้วในลักษณะเดียวกัน"},
		"how.retry": {
			"en": "If you choose something unsafe, you will see a short explanation and can try again. Nothing is lost.",
			"th": "หากเลือกสิ่งที่ไม่ปลอดภัย จะมีคำอธิบายสั้น ๆ และคุณลองใหม่ได้ ไม่มีอะไรเสียหาย",
		},

		# -------------------------------------------------------------- common --
		"common.back": {"en": "Back", "th": "ย้อนกลับ"},
		"common.close": {"en": "Close", "th": "ปิด"},
		"common.yes": {"en": "Yes", "th": "ใช่"},
		"common.no": {"en": "No", "th": "ไม่"},
		"common.ok": {"en": "OK", "th": "ตกลง"},
		"common.cancel": {"en": "Cancel", "th": "ยกเลิก"},
		"common.level_n": {"en": "Challenge %d", "th": "ภารกิจที่ %d"},
		"common.loading": {"en": "Loading…", "th": "กำลังโหลด…"},

		# --------------------------------------------------------- game modes --
		"modes.title": {"en": "Choose how to cook", "th": "เลือกวิธีเล่น"},
		"modes.subtitle": {"en": "Three ways in. All of them teach the same safety rule.", "th": "สามโหมด ทุกโหมดสอนกฎความปลอดภัยเดียวกัน"},
		"modes.cook_title": {"en": "Let's Cook", "th": "มาทำอาหารกัน"},
		"modes.cook_body": {"en": "Pick a dish, cook it step by step, and discover new dishes as you go.", "th": "เลือกเมนู ทำทีละขั้น และค้นพบเมนูใหม่ไปเรื่อย ๆ"},
		"modes.cook_cta": {"en": "Choose a dish", "th": "เลือกเมนู"},
		"modes.endless_title": {"en": "Endless Kitchen", "th": "ครัวไม่รู้จบ"},
		"modes.endless_body": {"en": "One challenge after another, getting a little harder. How long a streak can you keep?", "th": "ภารกิจต่อเนื่องที่ค่อย ๆ ยากขึ้น คุณจะทำสถิติต่อเนื่องได้กี่จาน"},
		"modes.endless_cta": {"en": "Start a run", "th": "เริ่มรอบใหม่"},
		"modes.free_title": {"en": "Free Cook", "th": "ครัวอิสระ"},
		"modes.free_body": {"en": "Choose any fish and any cooking method, and experiment. Your dish is labelled as a creation, not a traditional recipe.", "th": "เลือกปลาและวิธีปรุงได้ตามใจ ทดลองได้เลย จานของคุณจะถูกระบุว่าเป็นผลงานทดลอง ไม่ใช่สูตรพื้นบ้าน"},
		"modes.free_cta": {"en": "Open Free Cook", "th": "เข้าโหมดครัวอิสระ"},
		"modes.records_title": {"en": "Your records", "th": "สถิติของคุณ"},
		"modes.record_dishes": {"en": "Dishes discovered", "th": "เมนูที่ค้นพบ"},
		"modes.record_endless": {"en": "Best endless streak", "th": "สถิติต่อเนื่องสูงสุด"},
		"modes.record_achievements": {"en": "Achievements", "th": "ความสำเร็จ"},

		# ------------------------------------------------------- dish browser --
		"dishes.title": {"en": "Let's Cook", "th": "มาทำอาหารกัน"},
		"dishes.subtitle": {"en": "Real Thai dishes and skill challenges. Get the fish cooked through and the rest is flavour.", "th": "เมนูไทยจริงและด่านฝึกฝีมือ ทำให้ปลาสุกทั่วถึง ส่วนที่เหลือคือรสชาติ"},
		"dishes.real": {"en": "Real dish", "th": "เมนูจริง"},
		"dishes.variation": {"en": "Game challenge — not a traditional dish", "th": "ด่านในเกม ไม่ใช่เมนูพื้นบ้าน"},
		"dishes.locked": {"en": "Locked", "th": "ยังไม่ปลดล็อก"},
		"dishes.locked_hint": {"en": "Finish the dish it comes from to unlock this one.", "th": "ทำเมนูต้นทางให้สำเร็จเพื่อปลดล็อกเมนูนี้"},
		"dishes.cook": {"en": "Cook this", "th": "ทำเมนูนี้"},
		"dishes.cook_again": {"en": "Cook again", "th": "ทำอีกครั้ง"},
		"dishes.best": {"en": "Best", "th": "สูงสุด"},
		"dishes.best_none": {"en": "not yet", "th": "ยังไม่มี"},
		"dishes.difficulty": {"en": "Difficulty", "th": "ระดับความยาก"},
		"dishes.favourite": {"en": "Save to favourites", "th": "บันทึกเป็นเมนูโปรด"},
		"dishes.favourited": {"en": "In favourites", "th": "อยู่ในเมนูโปรด"},
		"dishes.discovered": {"en": "Discovered", "th": "ค้นพบแล้ว"},
		"dishes.recent": {"en": "Recently cooked", "th": "ทำล่าสุด"},
		"dishes.variation_note": {"en": "This is a game challenge, not a traditional recipe.", "th": "นี่คือด่านในเกม ไม่ใช่สูตรอาหารพื้นบ้าน"},
		"dishes.none": {"en": "No dishes are available yet.", "th": "ยังไม่มีเมนูที่เล่นได้"},

		# --------------------------------------------------------- free cook --
		"free.title": {"en": "Free Cook", "th": "ครัวอิสระ"},
		"free.subtitle": {"en": "Choose a fish and a method. Cook it safely, then plate it your way.", "th": "เลือกปลาและวิธีปรุง ปรุงให้ปลอดภัย แล้วจัดจานในแบบของคุณ"},
		"free.fish": {"en": "Fish", "th": "ปลา"},
		"free.method": {"en": "Cooking method", "th": "วิธีปรุง"},
		"free.start": {"en": "Start cooking", "th": "เริ่มปรุง"},
		"free.pick_both": {"en": "Choose a fish and a method first.", "th": "เลือกปลาและวิธีปรุงก่อน"},
		"free.experimental_note": {"en": "This dish is your own creation, not a traditional recipe.", "th": "จานนี้เป็นผลงานสร้างสรรค์ของคุณ ไม่ใช่สูตรอาหารพื้นบ้าน"},
		"free.freshwater_note": {"en": "Freshwater fish can carry liver-fluke larvae, so it must be cooked through.", "th": "ปลาน้ำจืดอาจมีตัวอ่อนพยาธิใบไม้ตับ จึงต้องปรุงให้สุกทั่วถึง"},
		"free.sea_note": {"en": "Sea fish are not part of the fluke life cycle, but they are still cooked properly.", "th": "ปลาทะเลไม่อยู่ในวงจรชีวิตของพยาธิใบไม้ตับ แต่ก็ยังต้องปรุงให้สุก"},

		# ----------------------------------------------------------- endless --
		"endless.title": {"en": "Endless Kitchen", "th": "ครัวไม่รู้จบ"},
		"endless.streak_label": {"en": "Streak", "th": "ต่อเนื่อง"},
		"endless.next": {"en": "Next challenge", "th": "ภารกิจถัดไป"},
		"endless.end_run": {"en": "End run", "th": "จบรอบ"},
		"endless.run_score": {"en": "Run score", "th": "คะแนนรอบนี้"},

		# -------------------------------------------------------- achievements --
		"ach.title": {"en": "Achievements", "th": "ความสำเร็จ"},
		"ach.body": {"en": "Earned by cooking, not by clicking. Each one has a real condition.", "th": "ได้มาจากการลงมือทำจริง ไม่ใช่แค่คลิก แต่ละอย่างมีเงื่อนไขจริง"},
		"ach.locked": {"en": "Not yet", "th": "ยังไม่ได้รับ"},

		# ------------------------------------------------------------- result --
		"result.back_dishes": {"en": "Back to dishes", "th": "กลับไปเลือกเมนู"},
		"result.variation_note": {"en": "This was a game challenge, not a traditional recipe.", "th": "นี่เป็นด่านในเกม ไม่ใช่สูตรอาหารพื้นบ้าน"},

		# ------------------------------------------------------------ sources --
		"sources.title": {"en": "About & Sources", "th": "เกี่ยวกับและแหล่งอ้างอิง"},
		"sources.intro": {
			"en": "The health information in this game comes from public health agencies and peer-reviewed research. Each lesson lists where it came from.",
			"th": "ข้อมูลสุขภาพในเกมนี้มาจากหน่วยงานสาธารณสุขและงานวิจัยที่ผ่านการตรวจสอบทางวิชาการ แต่ละบทเรียนจะระบุแหล่งที่มา",
		},
		"sources.reviewed": {"en": "Reviewed", "th": "ตรวจทานเมื่อ"},
	}
