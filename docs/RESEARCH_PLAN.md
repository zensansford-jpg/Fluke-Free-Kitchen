# Research Plan — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Version:** 1.0 · **Drafted:** 2026-10-16
**Status:** *not yet carried out.* This document is the plan for measuring the game's
educational value. No results are reported here, because none exist yet.

> **Honesty statement.** *Fluke Free Kitchen* has been built and tested as software. It has **not**
> been evaluated with students. Nothing in this project claims a measured improvement in
> knowledge or behaviour. The game tells the player this in their own language on the assessment
> screen (`assessment.not_measured`), and the report must say the same until a study is run.

---

## 1. Research questions

| # | Question | Measured by |
|---|----------|-------------|
| RQ1 | Does playing the three challenges improve students' **knowledge** of liver fluke transmission and prevention? | paired before/after scenario questions (`AssessmentDB`) |
| RQ2 | Are specific **misconceptions** (lime/salt/pickling, "infection = cancer", "one toilet fixes all", cross-contamination) reduced? | per-topic items in `AssessmentDB`, plus in-game misconception records |
| RQ3 | Do students find the game **usable and engaging**, and appropriate for their school level? | short usability and engagement questionnaire |
| RQ4 | Which **prevention behaviours** do students report intending to follow after playing? | behaviour-intention items (self-report) |

RQ4 is deliberately about *intention*, not observed behaviour. Measuring real behaviour change
needs a household or community follow-up, which is beyond a single school-based study and is
listed as a limitation.

---

## 2. Design

**Primary design: single-group before/after (repeated measures).**
Each participating class takes the six "before" questions, plays the three challenges, then
takes the six "after" questions. The two sets are **not** identical wording: `AssessmentDB`
pairs each "before" item with an "after" item on the same topic (`pair` 1–6), which allows a
before/after comparison without inviting memorisation of the exact wording.

**Optional comparison design (if a second class is available).**
One class plays the game and one continues with the usual lesson, with both classes taking the
same paired instrument before and after. This is the stronger design for showing that any change
is attributable to the game, and it is the design recommended if the school can arrange two
comparable classes. With a single class, results can only be described as before/after change,
not as a controlled effect.

**Blinding:** not possible (the students know they played a game). This is stated as a threat to
validity in §8.

---

## 3. Participants and sampling

* **Target:** students at primary, lower-secondary and upper-secondary levels, matching the three
  challenge levels (the game adapts wording, not difficulty of facts, across levels).
* **Sampling:** a convenience sample of classes from schools that agree to take part. Because it
  is a convenience sample, results cannot be generalised to all schools; this is stated in the
  report.
* **Suggested minimum for analysis:** at least one full class per level. A paired analysis needs
  a student to have both a before and an after record; students with only one record are reported
  as missing, not imputed.
* **Group size is decided by the school**, within the competition's team rules (teams of up to
  three students design and present the project; they do not have to run the study alone).

**Inclusion:** a student may take part if a parent or guardian has given consent and the student
has given assent.
**Exclusion:** any student who, or whose family, declines; any student who is absent for the
after-set; any student who asks for their data to be removed at any time.

---

## 4. Ethics, safety and data protection — **before any work begins**

The competition announcement requires that any approval needed is obtained **before** the work
is done and **not** retroactively. This plan therefore treats the following as gates:

1. **School permission** — written approval from the school director/administrator.
2. **Ethics review** — submit to the relevant institutional review board / ethics committee
   (for a school study in Thailand, the school's own process or the supervising university's
   committee). Do not collect any data before written approval is in hand.
3. **Parental consent and student assent** — a plain-language information sheet and a consent
   form for the parent/guardian, and a separate written assent for the student. Taking part is
   voluntary and can be stopped at any time with no consequence.
4. **Data protection** — no names, no student ID numbers, no school name, no device identifiers
   and no photographs of students are stored by the game. See §6 for exactly what is stored.
   Personal data, if the study needs any (e.g. a class list for matching before/after records),
   is kept **outside** the game, on paper or in a school-approved system, by the teacher, and is
   destroyed at the end of the study.
5. **Safety** — the game contains no flashing sequences, no advertising, no external links and no
   chat or multiplayer. It requires no personal account. Playing is a normal classroom computer
   activity; no physical risk is involved beyond ordinary screen use.

**Ethics statement for the report:** the report must state which approvals were obtained, from
which body, and on what date. If a study has not been run, the report must say so plainly.

---

## 5. Materials

All of the paper materials that this plan refers to now exist, as drafts awaiting ethics review:
the information sheet, parental consent, student assent, the paper questionnaire and the teacher's
data record are in `docs/study/`, and the operating procedure is `docs/STUDY_PROTOCOL.md`.

### 5.1 Before/after knowledge instrument (`AssessmentDB`)

Six "before" items and six "after" items, paired by topic:

| Pair | Topic | Before | After |
|------|-------|--------|-------|
| 1 | Transmission route (raw freshwater fish, not person-to-person) | `pre_1` | `post_1` |
| 2 | Lime / salt / pickling is not a substitute for cooking | `pre_2` | `post_2` |
| 3 | The reliable cooking method and how to judge it is cooked | `pre_3` | `post_3` |
| 4 | Sanitation: keeping eggs out of the water | `pre_4` | `post_4` |
| 5 | Long-lasting infection as a risk factor, not a certainty of cancer | `pre_5` | `post_5` |
| 6 | Who decides on and supervises treatment | `pre_6` | `post_6` |

Every item is a three-option scenario question with one correct answer and a short explanation
shown after answering — so the instrument itself teaches. The instrument is available in-game
(main menu → Knowledge check) and stores only the score, the chosen option per question and
whether it was correct.

The instrument's own screen also carries the optional **case-code** field (§6.1), which is what
lets a before/after record be matched to a paper consent form.

### 5.2 Usability and engagement questionnaire (also embedded, optional)

Short, age-appropriate, 5-point items covering: whether the goals were clear, whether the
controls were easy, whether the actions were demonstrated clearly before being asked for,
whether the health messages were understandable, and whether the student would play again. Two
open questions ("What did you learn?", "What was confusing?") capture free text. **Free text is
collected on paper**, not stored by the game, so that no free text (which could identify a
student) ever enters the game's data file.

### 5.3 In-game learning log

The game records, without any personal data: which activities were completed, which lessons were
covered, which misconceptions were corrected, and each knowledge question's outcome and number
of attempts (§6).

---

## 6. Data collected and the anonymised export

The only thing the game can export is an anonymous record. Its schema is fixed in
`Learning.export_anonymised()`:

```json
{
  "format": "fluke-free-kitchen-learning-log",
  "format_version": 1,
  "game_version": "2.0.0",
  "exported_at": "YYYY-MM-DD HH:MM:SS",
  "participant_code": "A-07",
  "levels": {
    "l1": {"stars": 3, "best_score": 1450, "attempts": 1, "completed": true, "best_accuracy": 1.0}
  },
  "activities_completed": ["l1.wash_hands", "l1.clean_board", "..."],
  "lessons_covered": ["clean_hands", "clean_surfaces", "..."],
  "misconceptions_corrected": ["same_board_ok", "..."],
  "questions": {"q_l1_separate": {"correct": true, "attempts": 1}},
  "assessment": {
    "pre":  {"score": 3, "total": 6, "answers": {"pre_1": {"chosen": "yes", "correct": true}}, "taken": true, "saved_at": "..."},
    "post": {"score": 5, "total": 6, "answers": {"post_1": {"chosen": "raw_fish", "correct": true}}, "taken": true, "saved_at": "..."}
  },
  "totals": {"runs": 3, "stars": 9, "levels_completed": 3}
}
```

**What this record does *not* contain:** name, age, sex, school, class, student number, IP
address, device identifier, or any free text. One export file belongs to one device/installation.

### 6.1 The case code

`participant_code` is the only text field in the whole record. It is empty unless a teacher
types one in, and it exists so a before/after record can be matched to a paper consent form
**without a name ever entering the game**.

The game enforces the format at two points — as it is typed, and again when the file is read
back — keeping only `A–Z`, `0–9`, `-` and `_`, upper-cased, at most 16 characters
(`SaveData.sanitise_code`). The filter is a real guarantee about *format*, not about
*judgement*: it cannot tell that `JOHNSMITH` is a name. The operational rule therefore carries
the weight, and `docs/STUDY_PROTOCOL.md` §6 states it plainly — use a class letter and a running
number, never initials, an email address, a student number or a birthdate.

If a teacher prefers not to use the field at all, records can still be matched by device and
time, exactly as this plan originally described. The field removes the transcription step, not
the requirement for care.

**Storage during the study:** export files are kept on a password-protected computer or a
school-approved drive, accessible only to the supervising teacher. They are deleted once the
analysis is complete and the report is submitted.

---

## 7. Procedure

1. Obtain all approvals (§4). **Do not collect data before this step is complete.**
2. Give every student a plain-language explanation; collect parental consent and student assent.
3. Students take the **before** set (`pre_*`) individually, typing their teacher-assigned case
   code first (§6.1). No score is announced; the aim is a baseline, not a test.
4. Students play the three challenges (main menu → Challenges). One level takes about 1–3 minutes;
   a full session is about 5–10 minutes of play.
5. Students take the **after** set (`post_*`).
6. Students complete the paper questionnaire and, if asked, the two open questions.
7. Export the anonymous result file per device (the game prints the exact path it wrote) and move
   it into the study folder under the student's case code. **Export and move one student's file
   before the next student starts** — otherwise the second student's save overwrites the first.
8. Analyse (§8) and report honestly.

If the optional comparison design is used, steps 3–5 are repeated in the same order for both
classes, with only the comparison class using the game between the two sets.

---

## 8. Analysis plan

The analysis is implemented, not just described: `tools/study/analyse_export.py` reads a folder of
export files and produces `report.md`, `per_student.csv`, `topics.csv` and `excluded.csv`. It
refuses to produce numbers from an empty folder, reports every rejected file with its reason, and
implements the tests below in the standard library so it runs on a school laptop with no
installation. `--selftest` pins every statistic against a published reference value.

```powershell
python tools/study/analyse_export.py --selftest
python tools/study/analyse_export.py --in D:\study --out D:\study\analysis
```

* **RQ1 / RQ2 (knowledge):** for each student with both a before and an after record, compute the
  paired change in number correct (0–6) and per topic. Report the mean change, the paired
  comparison (for example a Wilcoxon signed-rank test for the ordinal scores, or a paired t-test
  if the distribution allows), and a clear statement of the sample size. Report per-topic results
  as counts, not as a single headline number.
* **Misconceptions:** report how many students held each misconception before and after
  (for example the lime/salt/pickling item), since these are the outcomes the game is designed
  to move.
* **RQ3 (usability):** report the distribution of questionnaire responses; summarise open
  comments qualitatively with representative (anonymised) quotes.
* **RQ4 (behaviour intention):** report the intention items descriptively, and state clearly
  that these are intentions, not observed behaviour.
* **Comparison design:** if two classes are available, compare the change between groups and
  report the effect with its confidence interval.
* **What will *not* be done:** no results will be invented or estimated; no percentage
  improvement will be quoted unless it was computed from the collected data; no claim will be
  made that the game causes behaviour change.

### Threats to validity (to be stated in the report)

* **No blinding** — students know they played the game.
* **Test–retest / practice effects** — the before and after items are different wording on the
  same topic to reduce, but not eliminate, this.
* **Novelty and social-desirability effects** — students may answer as they think they should.
* **Convenience sampling** — results are not generalisable to all schools.
* **Single session** — retention over weeks is not measured.
* **Self-report for behaviour intention** — does not prove real-world behaviour change.

---

## 9. Timeline (relative, to fit the competition's 12-month window)

| Step | When | Notes |
|------|------|-------|
| Approvals, consent, assent | **before any data collection** | required by the announcement; not retroactive |
| Pilot with a small group | after approvals | checks wording and timing |
| Main before/after sessions | term time | one session per class |
| Analysis and write-up | after data collection | report chapters 4 and 5 |
| Video and display-board preparation | before the submission deadline | video ≤ 7 minutes |

The competition requires that the work be carried out within 12 months before the application;
the exact submission deadline must be confirmed from the announcement (January 2027 per the
September 2026 announcement).

---

## 10. Reporting obligations specific to this project

The competition report's **Chapter 4 must report prevention-behaviour evidence**, and
**Chapter 5 must discuss it**. Until a study is run:

* Chapter 4 reports the instrument, the procedure actually followed, and the collected data (or
  states plainly that no study has yet been run);
* Chapter 5 discusses what the data can and cannot support, using the limitations in §8;
* the video and display board must not imply an outcome that has not been measured.

The game itself already follows this rule: its assessment screen states, in Thai and English,
that no classroom trial has been carried out and that there is no measured learning result to
cite.
