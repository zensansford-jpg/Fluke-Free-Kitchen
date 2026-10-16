# Study Protocol — *Fluke Free Kitchen* classroom evaluation

**Status: NOT RUN.** No participant has ever played this game in a study. No data
has been collected, no ethics approval has been applied for, and no result is
reported anywhere in this project. This document is the operational kit for
running the study; it is not a report of one.

Filling that gap needs a human who can obtain approvals and stand in a room with
students. What this file removes is the *other* work — the instrument, the forms,
the data format, the extraction route and the analysis — so that the only thing
left to do is the part that requires a person.

---

## 1. What is in the kit

| File | What it is | Written? |
| --- | --- | --- |
| `docs/RESEARCH_PLAN.md` | the research design: questions, sampling, threats to validity, reporting duties | yes |
| `docs/STUDY_PROTOCOL.md` | **this file** — the step-by-step operating procedure | yes |
| `docs/study/S1_information_parent_TH.md` | parent/guardian information sheet (Thai + English) | yes |
| `docs/study/S2_consent_parent_TH.md` | parent/guardian consent form | yes |
| `docs/study/S3_assent_student_TH.md` | student information + assent form | yes |
| `docs/study/Q1_questionnaire_TH.md` | paper usability, engagement and behaviour-intention questionnaire | yes |
| `docs/study/S4_data_record_TH.md` | the paper sheet that links a case code to the collected files | yes |
| `scripts/data/assessment_data.gd` | the before/after knowledge instrument (`AssessmentDB`), 6 pairs | **already built** |
| `tools/study/analyse_export.py` | turns exported JSON files into the tables and tests the report needs | yes |
| `tools/study/README.md` | how to run the analysis | yes |

Everything marked *yes* is a draft. Every one of them is expected to be edited by
the team and by the reviewing committee. They are deliberately plain-language and
free of anything that asserts an outcome.

---

## 2. Non-negotiable gates (from the competition announcement)

The announcement requires that any needed approval is obtained **before** the
work is done, and is **not** obtained retroactively. In practice, in this order:

1. **School permission** — written approval from the school director or the
   responsible administrator, naming the classes and the dates.
2. **Ethics review** — submitted to, and approved in writing by, the relevant
   committee. For a school study in Thailand that is normally the school's own
   process together with the supervising university's committee. **The team must
   confirm which body applies to them.** Nothing in this kit substitutes for
   that decision.
3. **Parent/guardian consent** — signed form `S2` per student.
4. **Student assent** — signed form `S3` per student, in language the student
   reads at their own level.
5. **Data protection review** — the responsible teacher confirms where the export
   files will be stored, who can read them, and when they will be destroyed.

**No button in the game collects data before these exist.** The game only stores
what is listed in §7, it never touches the network, and it can be reset to empty
at any time from Settings → Reset progress.

---

## 3. Roles

| Role | Does |
| --- | --- |
| Responsible teacher | obtains the approvals, holds the paper record, runs the sessions, extracts the files |
| Class teacher | hands out and collects the forms, assigns the case codes, keeps the class list away from the data |
| Team member | sets up the devices, explains the game, does not handle the paper record |

One person — the responsible teacher — must own the key that maps a case code to
a name. Ideally **that mapping is never written down at all**: the code is
written on the student's own forms, the forms are handed back, and the code
exists in exactly two places — on paper, in the student's hands, and in the
export file.

---

## 4. Which device to use

This matters more than it looks, because the export file has to come *out* of the
device.

| Platform | Usable for the study? | Why |
| --- | --- | --- |
| **Windows desktop/laptop** | **Yes — recommended** | the export is a plain file; see §8 for the exact path |
| **Android phone/tablet** | Yes, with extra steps | the file lives in app-private storage; needs `adb` and a debug build (§8.2) |
| **Web build** | **No** | `user://` becomes browser storage (IndexedDB). The file is written, but there is no supported way for a teacher to retrieve it reliably. Use the web build for demonstration only. |
| **iOS** | No | no iOS build exists (`docs/EXPORTS.md` §6) |

If a school computer lab is used, one session per class on desktop machines is
the cleanest design: pre-set, play, post-set, export, move the files to a single
folder, done.

---

## 5. Session procedure (one class, ~30–40 minutes)

Print enough of each form plus the questionnaire and the data sheet (`S4`) before
the day.

### Before the session
- Confirm every student in the room has a signed `S2` and `S3`. A student
  without both does **not** play the game for the study. Give them the ordinary
  lesson instead. Do not make an example of anyone.
- Assign each participating student a **case code** (§6) and write it on their
  copy of `S4`. Hand the student their code on a slip of paper.

### In the session
1. **Explain (5 min).** Read the student information sheet (`S3`, first page)
   aloud or have students read it. Say plainly: this is not a test, it is not
   graded, there is no right answer that affects their marks, and they may stop
   at any time without giving a reason.
2. **Before-set (5 min).** Each student opens the game →
   **แบบทดสอบความรู้ / Knowledge Check** → *เริ่มคำถามชุดก่อนเล่น* (Start the
   'before' questions). They type their case code into the *รหัสผู้เรียน*
   (Case code) field, then answer the six questions.
   - No score is announced. If a student asks, say the score is not what is being
     looked at and they will see it at the end.
   - The game shows a short explanation after every answer. That is intentional —
     the instrument teaches as a side effect.
3. **Play (10–15 min).** Main menu → **ด่านภารกิจ / Challenges**. Three
   challenges, roughly 1–3 minutes each, a full session is about 5–10 minutes.
   Students may replay a challenge; that is fine.
4. **After-set (5 min).** Knowledge Check → *เริ่มคำถามชุดหลังเล่น* (Start the
   'after' questions). **The case code is already filled in** — ask them to check
   it is still there and correct before they start.
5. **Export (2 min per device).** On the after-set result screen, press
   **บันทึกไฟล์ผลของฉัน / Save my results file**. The game shows the full path it
   wrote to — write that path on the student's `S4` sheet and move the file to
   the study folder (§8).
6. **Questionnaire (5 min).** Paper form `Q1`. Collect it immediately, before
   students discuss their answers with each other.
7. **Collect** the `S4` sheets, the consent forms and the questionnaires.

### After the session
- Copy every export file into one folder, named with the case code, e.g.
  `A-07.json`. The game writes the same name every time, so this rename is what
  keeps the files apart.
- Count the files against the `S4` sheets **the same day**, while you still
  remember who was absent.
- Do not open the files in front of students and do not tell anyone their score.

---

## 6. The case code

The code is the only text the game stores. It exists so a before/after record can
be matched to a paper consent form without a name ever entering the game.

Rules, all of which the game enforces:

- **Alphabet:** `A–Z`, `0–9`, hyphen, underscore. Lower case is converted to upper
  case. Anything else — spaces, Thai script, punctuation, emoji — is **dropped as
  it is typed**, and dropped again when the file is read back.
- **Length:** at most 16 characters.
- **Optional:** empty is a valid and normal state. A student who types nothing
  still produces a usable record; match it by device and time instead.
- **Never a name.** Do not use initials-plus-surname, student numbers, national ID
  digits, birthdates or phone numbers. A class letter, a hyphen and a two-digit
  running number is exactly the right shape: `A-01`, `B-14`, `4A-07`.

The sanitising is not decoration. It is what makes "we store no personal data"
a property of the code rather than a promise:

```gdscript
# autoload/save_manager.gd
func sanitise_code(raw: String) -> String:
	var out := ""
	for ch in raw.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "-" or ch == "_":
			out += ch
		if out.length() >= CODE_MAX:
			break
	return out
```

Typing `สมชาย ใจดี` therefore stores `""`, and typing `john.smith@school.ac.th`
stores `JOHNSMITHSCHOOLACTH`. The last one is the failure mode worth warning
teachers about explicitly: **do not type an email address** — it survives the
filter, because it is made of letters. The filter protects the *format*, not the
*judgement*. The clear instruction is the real control, and the in-game hint says
so in both languages.

---

## 7. Exactly what the game stores

One file per installation: `save_v2.json`, plus the export copy. It holds game
progress and the fields below. Nothing else.

```json
{
  "format": "fluke-free-kitchen-learning-log",
  "format_version": 1,
  "game_version": "2.0.0",
  "exported_at": "2026-10-16 20:14:02",
  "participant_code": "A-07",
  "levels": {"l1": {"stars": 3, "best_score": 1450, "attempts": 1,
                     "completed": true, "best_accuracy": 1.0}},
  "activities_completed": ["l1.wash_hands", "l1.clean_board"],
  "lessons_covered": ["clean_hands", "clean_surfaces"],
  "misconceptions_corrected": ["same_board_ok"],
  "questions": {"q_l1_separate": {"correct": true, "attempts": 1}},
  "assessment": {
    "pre":  {"score": 3, "total": 6,
             "answers": {"pre_1": {"chosen": "yes", "correct": true}},
             "taken": true, "saved_at": "..."},
    "post": {"score": 5, "total": 6,
             "answers": {"post_1": {"chosen": "raw_fish", "correct": true}},
             "taken": true, "saved_at": "..."}
  },
  "totals": {"runs": 3, "stars": 9, "levels_completed": 3}
}
```

**Not collected:** name, age, sex, class, school, student number, national ID,
birthdate, photograph, voice, IP address, device identifier, location, or any
free text. Free text (the questionnaire's open questions) is collected **on
paper** and never enters the game.

**Timestamps** are the device's local clock at the moment of the action. They can
link one student's records to a session, so treat the file as confidential even
though it is anonymous.

**Tested** (see `tests/smoke_test.gd`): the exporter is asserted to carry every
one of those fields, to carry the code that was entered, to carry an empty code
when none was entered, and the serialised record is scanned for the words
`name`, `school`, `email` and `student`.

---

## 8. Getting the data out

### 8.1 Windows (recommended)

`user://` on Windows resolves to:

```
%APPDATA%\Godot\app_userdata\Fluke Free Kitchen\
```

and the export is written there as `fluke_free_kitchen_results.json`. In
PowerShell:

```powershell
$u = "$env:APPDATA\Godot\app_userdata\Fluke Free Kitchen"
Get-ChildItem $u
# rename into the study folder under the student's case code
Copy-Item "$u\fluke_free_kitchen_results.json" "D:\study\A-07.json"
```

Do not rely on the path being memorised — **the game prints the exact path in the
confirmation panel** after you press the save button. Read it off the screen.

If two students share one computer, export the **first** student's file and move
it away before the second student starts. Otherwise the second student's save
overwrites the first student's, and the first student's data is gone. This is the
single most likely way to lose a session's data.

### 8.2 Android

The export lives in the app's private storage. The build in
`build/android/FlukeFreeKitchen.apk` is a **debug** build, which is what makes
this possible without root:

```powershell
$adb = "$env:USERPROFILE\Android\Sdk\platform-tools\adb.exe"
& $adb shell run-as th.ac.kku.flukefreekitchen ls files
& $adb exec-out run-as th.ac.kku.flukefreekitchen cat files/fluke_free_kitchen_results.json > A-07.json
```

Confirm the directory name from the path shown on screen first — it is
`files/` on current Godot, but read it off the device rather than trusting this
line. Again: one device, one student, export before the next one starts.

### 8.3 Storage and destruction

- Study files and paper forms stay on a password-protected machine or a
  school-approved drive, accessible only to the responsible teacher.
- The `S4` sheet is the only place a code sits next to anything else. If the
  responsible teacher has chosen to keep a code→name mapping, that sheet is the
  sensitive document: keep it separately from the exports, and destroy it
  **first**, as soon as the analysis is complete.
- Delete the export files and the questionnaires once the report is submitted and
  the competition window has closed. State the destruction date in the report.

---

## 9. Analysis

```powershell
python tools/study/analyse_export.py --in D:\study --out D:\study\analysis
```

The script reads every export, reports how many are usable, works out each
student's paired before/after change, and writes per-topic and overall tables
plus the tests. It **refuses to produce numbers from an empty folder** and says
so, rather than printing a zero. See `tools/study/README.md`.

What to report, and what not to:

- Report the **number of students with a complete pair**, and how many were
  excluded, and why.
- Report per-topic counts, not one headline number. The topic table is the
  interesting result: a game about cooking should move the cooking items.
- Report the paired test with its sample size and its assumptions. With a class
  of 30, a Wilcoxon signed-rank test on the 0–6 score is usually the honest
  choice; a paired *t*-test is acceptable when the change scores are not wildly
  skewed, and the script reports both so the choice can be made with the data in
  front of you.
- **Never** turn "the mean went from 3.1 to 4.6" into "knowledge improved 48 %".
  Percentage change on a 6-item quiz is not a meaningful quantity and the
  competition rubric rewards people who notice that.
- The questionnaire is descriptive. Report the distribution and the counts of
  each behaviour-intention option. Behaviour intention is not behaviour; state
  that in the same sentence, not in a limitations paragraph nobody reads.

---

## 10. Pre-flight checklist

Print this and tick it.

- [ ] School director's written approval, dated, on file
- [ ] Ethics committee approval, written, **dated before the first session**
- [ ] If a two-class comparison design is used: both classes confirmed comparable
      and both sets of approvals in place
- [ ] `S1` information sheet given to every parent/guardian
- [ ] `S2` consent returned, signed, for every participating student
- [ ] `S3` information + assent read and signed by every participating student
- [ ] Case codes assigned and written on each `S4` sheet and each student's slip
- [ ] Devices ready: build installed, language correct, sound at a classroom level
- [ ] A test export performed on one device and the file retrieved successfully
- [ ] Study folder created, with a copy of `S4` blank
- [ ] Questionnaire `Q1` printed, one per student
- [ ] Plan written for what happens to a student who has *not* returned consent
- [ ] Decision recorded on when and how the data will be destroyed

---

## 11. Small print that matters

- **Absent students.** A student with a before-set but no after-set is reported
  as missing. Do not impute it and do not quietly drop it — report the number.
- **Replays.** Replaying a challenge is allowed and does not invalidate anything.
  The after-set is what is measured.
- **Retakes.** If a student retakes the after-set, the save keeps only the most
  recent one. That is deliberate; note it, and ask students not to retake.
- **Shared devices.** Covered in §8.1/§8.2 — export and move before the next
  student starts. This is the main operational risk in the whole design.
- **Wording changes.** If the team edits any question in
  `scripts/data/assessment_data.gd`, the instrument has changed and any earlier
  data was collected with a different instrument. Either freeze the instrument
  before the first session or re-collect. Never pool the two.
- **Translations.** The instrument is bilingual; a student answering in English
  and one answering in Thai are answering the same questions. Do not compare
  across languages — the classes will be single-language in practice, so simply
  record which language was used.
- **The game's own claim.** The assessment screen tells the player, in Thai and
  English, that no classroom study has been carried out. That string
  (`assessment.not_measured`) must be **removed only after** real data exists,
  and the report must match whatever the build says.
