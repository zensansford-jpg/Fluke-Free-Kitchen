# Rubric Traceability — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Version:** 2.0.0 · **Compiled:** 2026-10-16

This document maps each scoring criterion of the *Fluke Free Fighters* competition to the
concrete evidence in this project — a file, a feature that runs, a test, or a document. Where a
criterion is **not** yet evidenced, that is stated next to it rather than glossed over. Honesty
is itself a scored criterion, so an accurate gap is worth more than an optimistic claim.

Legend: ✅ evidenced · ⚠️ partly evidenced · ❌ not yet done

---

## 1. Semi-final rubric (100 points)

### 1.1 Problem, importance and connection to the competition — 10 points

**Evidence:**
* `docs/SCIENTIFIC_CONTENT.md` §1–§3 — why liver fluke infection matters and how each of the six
  ideas (transmission, food safety, sanitation, screening, treatment, bile duct cancer) is kept
  distinct.
* `docs/REFERENCES.md` — every claim traced to WHO, CDC, IARC or a peer-reviewed study.
* The game's main menu and level goals state the problem in learner language
  (`LevelDB.goal`, `LevelDB.objective_short`).
* The competition itself (Fluke Free Fighters) is named in `GameConfig.COMPETITION`.

**Status:** ✅

### 1.2 Scientific / engineering design process — 20 points

**Evidence:**
* `docs/PROJECT_AUDIT.md` — M0 audit: what existed, what was reused, what was replaced, with an
  explicit reuse/replace matrix and acceptance criteria.
* `docs/MILESTONES.md` — M0–M9 plan with deliverables, acceptance and status.
* `docs/RESEARCH_PLAN.md` — instrument, procedure, analysis plan, validity threats.
* Test suite that runs: `tests/smoke_test.tscn` (autoload wiring, content validity, 8 interaction
  kinds, save schema, scoring, assessment pairing, export fields), `tests/flow_test.tscn` (drives
  all three levels end to end and asserts scoring invariants), `tests/behaviour_test.tscn` (pushes
  real mouse events into the viewport and checks the demonstration gate, the retry path, and the
  swipe/drag/hold/cook gestures), `tests/layout_check.tscn`
  (numeric UI-geometry check), `tests/visual_capture.tscn` (renders each state to PNG).
* The interaction framework is a small reusable engine (`scripts/tasks/task_base.gd` plus eight
  task kinds behind `task_factory.gd`), and the content is separated from the code
  (`scripts/data/`), which is the engineering decision that keeps health text auditable.

**Status:** ✅ (design process and software engineering). The *study* half of the scientific
process is ⚠️ until the plan in `docs/RESEARCH_PLAN.md` is executed.

### 1.3 Originality and novelty — 15 points

**Evidence — what is genuinely new here:**
* The educational game does not merely decorate a cooking game with facts: **a level cannot be
  passed until its required knowledge question is answered correctly** (`KitchenSession.passed()`
  → `required_quiz_ok()`), so the education is enforced by the game's own rules.
* **Misconceptions are first-class objects**, not feedback strings: `LessonDB.misconceptions()`
  lists nine specific beliefs (lime kills, pickling is safe, infection means cancer, one toilet
  fixes all, a dirty pipe is full of flukes, …), and steps and questions declare which belief
  they correct (`corrects`).
* **Two text tiers per lesson** (simple/detail) let one build serve primary, lower-secondary and
  upper-secondary students, satisfying the competition's "adaptive text" intent without three
  separate games.
* The **knowledge journal** separates *education coverage* from *score*, so a high score is never
  presented as proof of learning.
* A **reviewed content database with an allowlist validator** that refuses to ship a lesson citing
  an unknown or disallowed source (`Education.validate_database()`).

**Status:** ✅ (relative to the category; the report must also survey existing games to show the
gap — ❌ that survey is still to be written).

### 1.4 Data quality, analysis and discussion — 20 points

**Evidence:**
* A playable, paired before/after instrument of 6 + 6 scenario questions (`AssessmentDB`), with
  per-topic pairing so identical wording is not reused.
* An anonymised export with a fixed, documented schema (`Learning.export_anonymised()`, schema
  printed in `docs/RESEARCH_PLAN.md` §6) containing **no** name, school, or device identifier.
* A written analysis plan with named statistical approaches and an explicit list of validity
  threats (`docs/RESEARCH_PLAN.md` §8).

**Status:** ⚠️ The instrument and the analysis plan exist and run; **no data has been collected**.
Chapter 4 cannot report a result yet. This is the largest remaining gap and is stated plainly
everywhere it appears, including inside the game.

### 1.5 Knowledge and academic accuracy — 15 points

**Evidence:**
* `docs/SCIENTIFIC_CONTENT.md` records every claim with its source and a verification status.
* `docs/REFERENCES.md` gives full citations (agency pages plus four peer-reviewed studies with
  PMIDs and DOIs).
* Health text lives only in the content database; gameplay scripts contain no health facts.
* The content was corrected during review: a mis-attributed journal name was fixed, two new
  verified sources were added for the lime/salt/pickling claim, and that claim was rewritten to
  match the evidence rather than the original wording.
* Deliberate non-claims are listed (`docs/SCIENTIFIC_CONTENT.md` §3): no invented universal
  temperature, "not every fish is infected", "infection is not cancer", "medicine does not
  replace prevention".

**Status:** ✅ for the in-game content. All eleven sources were re-opened and their claims checked
on 2026-10-16 (all now `verified` in the database and in `docs/REFERENCES.md` §6); two wrong URLs
were corrected.

### 1.6 Value, application and prevention-behaviour impact — 10 points

**Evidence:**
* Three challenges of 1–3 minutes each with 5–6 interactive steps, suitable for a classroom
  session; mouse, touch, drag, hold and swipe are all supported (`InputManager`, task kinds).
* The behaviours taught are the ones a family can act on: cook fish through; keep raw and
  ready-to-eat food apart; wash hands and utensils; keep faeces out of water; have health checks;
  do not rely on lime, salt or pickling.
* A takeaway "recipe" card per level (`LevelDB.dish`) restates the safe method as a method, so
  the lesson leaves the screen as something a player can repeat at home.

**Status:** ⚠️ The behaviours are strongly evidenced as *content*; the *impact* is not measured
(see 1.4). The report must not claim impact.

### 1.7 Report and video quality — 10 points

**Evidence:**
* In-game text in Thai with an English toggle (`Settings`, `Loc`), matching the competition's
  audience.
* A documented build/run/test path (`README.md`) and screen captures produced by
  `tests/visual_capture.tscn`.
* The written report set is drafted in `docs/report/`: chapters 1–5 in Thai, abstract/proposal/
  summary, a numbered reference list, a ≤ 7-minute video script, a display-board plan and a
  logbook template, written to the announcement's format (A4, TH SarabunPSK 16 pt, ≤ 20 pages).

**Status:** ⚠️ The text is drafted and the video/board are scripted; **typesetting, real
screenshots, the recording and the board build remain to be done**, and Chapter 4's learning
section is a marked placeholder until a study is run.

---

## 2. Final rubric (100 points)

| Criterion | Points | Evidence | Status |
|-----------|--------|----------|--------|
| Scientific / engineering process | 20 | `docs/PROJECT_AUDIT.md`, `docs/MILESTONES.md`, `docs/RESEARCH_PLAN.md`, four runnable test suites | ⚠️ software step complete; study step pending |
| Originality | 15 | Education enforced by level rules; misconceptions as data; dual text tiers; audited content database (see 1.3) | ✅ |
| Study results, analysis, discussion | 20 | Instrument and analysis plan built and playable; schema documented | ❌ no data collected yet |
| Knowledge and Q&A | 15 | `docs/SCIENTIFIC_CONTENT.md`, `docs/REFERENCES.md`, in-game knowledge journal, careful non-claims | ✅ (Q&A preparation still to do) |
| Value, application, prevention impact | 15 | Behaviours taught are directly actionable; recipe cards; classroom-length sessions | ⚠️ impact not measured |
| Presentation and exhibition | 10 | Fixed angled 3D view with 2D overlay, generous hit areas, steam/sizzle/visual feedback (see `docs/MILESTONES.md` M7) | ⚠️ board layout and oral script still to do |
| Logbook, honesty, ethics and safety | 5 | Ethical gates documented as *before-work* requirements (`docs/RESEARCH_PLAN.md` §4); the game states in-game that no study has been run; content statuses are honest | ⚠️ the **logbook** itself must be kept from the start of the work — ❌ start it now, dated, before any data collection |

---

## 3. Submission checklist (from the announcement)

| Item | Requirement | Status |
|------|-------------|--------|
| Registration form | via the competition Google Form | ❌ to do by the team |
| Abstract + proposal | — | 🟡 drafted (`docs/report/00_abstract_and_proposal.md`) |
| Project summary | — | 🟡 drafted (same file) |
| Full report, chapters 1–5 | A4, Thai SarabunPSK 16 pt, ≤ 20 pages, references/appendices within the stated limits | 🟡 drafted (`docs/report/ch1…ch5`, `references.md`); typesetting to the font/page limit and real screenshots remain |
| Presentation video | ≤ 7 minutes, YouTube/Drive, "anyone with the link can view" | 🟡 scripted (`docs/report/video_script.md`); not recorded |
| Display board | provided 150 cm foam board; logbook, model/props | 🟡 planned (`docs/report/board_layout.md`); not built |
| Oral presentation | ≤ 5 minutes + ≤ 10 minutes Q&A | ❌ to rehearse |
| Logbook | kept honestly from the start | 🟡 template started (`docs/report/logbook.md`); the team must keep it and fill in real dates |

---

## 4. What this document deliberately does not say

It does **not** claim that the game improves learning, changes behaviour, or has been tested with
students, because none of those things have happened yet. The single largest gap between the
software and a high-scoring competition entry is the study in `docs/RESEARCH_PLAN.md`, and the
honest way to close it is to run the study — not to describe it as though it had been run.
