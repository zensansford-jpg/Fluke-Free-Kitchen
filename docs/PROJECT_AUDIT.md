# Project Audit — River Dash: Safe Feast Run → *Fluke Free Kitchen*

**Audit date:** 2026-10-16
**Auditor:** development team
**Purpose:** establish the factual starting point of the existing project before redesigning it,
record what is reused and what is replaced, and set the milestone plan and acceptance
criteria for the redesign.

---

## 1. Executive summary

The existing repository contains a **complete, working 3D endless runner** built in Godot
4.7.2 (GDScript). It runs, it is tested (194 automated checks pass), and it exports to
Windows. However, the endless-runner format is the wrong vehicle for the competition:

* the interactions are "reflex" interactions, not *cooking* interactions;
* health content is delivered as incidental pop-ups, which the competition's rubric
  scores poorly under *knowledge, understanding and academic accuracy*;
* a runner has no natural place for a **required knowledge question** or for recording
  **which learning activities a student completed**.

**Decision (confirmed with the project owner):** build a **new.
Cooking-Mama-inspired cooking game** as the main experience, and **delete the runner
gameplay**, while keeping the genuinely reusable infrastructure (the Godot project,
autoloads, typed-script conventions, save/settings persistence, the source-validated
education database, the Sarabun Thai font, the procedural material library and the
procedural audio synthesiser).

Nothing in this document is an estimate presented as a result. Every "verified" figure
below was produced by running the code.

---

## 2. Engine and environment

| Item | Value | How it was determined |
| --- | --- | --- |
| Engine | **Godot 4.7.2 stable** (`4.7.2.stable.official.ed1daf0bf`) | `Godot_v4.7.2-stable_win64_console.exe --version` |
| Language | GDScript, statically typed | inspection of all 43 scripts |
| Renderer | Forward+ (Vulkan 1.3.278) | real-window run on NVIDIA RTX 4060 Laptop |
| Editor binary | `C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe` | portable install, no admin rights needed |
| Export templates | installed at `%APPDATA%\Godot\export_templates\4.7.2.stable\` | `windows_debug_x86_64.exe`, `windows_release_x86_64.exe` present |
| Project root | `C:\Users\ASUS\river-dash-safe-feast-run` | — |
| VCS | none (no git repository; all work is files on disk) | `Is directory a git repo: no` |

**Decision:** stay on Godot 4.7.2. A version change is not necessary, the toolchain is
verified working end to end, and changing it would invalidate the working export
pipeline for no gain.

---

## 3. What the existing project actually does

A third-person 3D endless runner:

* the player runs forward along a 3-lane track that is generated from a recycled pool of
  8 procedural 60 m segments and cycles through three biomes (Riverbank / Night Market /
  Village Health Center);
* jump / slide / lane-change avoid three hazards (raw freshwater fish dish, chopping
  board, wastewater), each designed so exactly one verb clears it;
* pickups grant a Safe Cooking Flame, a Sanitation Shield, a Medical Treatment Boost and
  Latrine Builder Tokens;
* checkpoints every 1000 m open a hold-to-heat temperature mini-game or a clinic
  screening dialogue;
* a 3-point safety buffer ends the run; scoring is distance + pickups + clean passes with
  a combo multiplier;
* 14 source-cited health entries appear in queued pop-ups and a Health Facts screen;
* menus, settings, pause, game-over, versioned JSON save.

Health education is delivered *alongside* the running, not *through* it.

---

## 4. Baseline evidence (verified before any change)

| Check | Command | Observed result |
| --- | --- | --- |
| Engine version | `--version` | `4.7.2.stable.official.ed1daf0bf` |
| Smoke test | `--headless --path <proj> res://tests/smoke_test.tscn` | `SMOKE TEST PASSED`, exit 0 |
| Behaviour suite | `--headless --path <proj> res://tests/runner.tscn --fixed-fps 60` | `checks run: 194` / `ALL TESTS PASSED`, exit 0 |
| Scene-flow test | `--headless --path <proj> res://tests/flow_test.tscn --fixed-fps 60` | `FLOW TEST PASSED`, exit 0 |
| Real-renderer run | `<proj>\scenes\main\game.tscn --quit-after 240` | exit 0, 240 frames, no shader/script errors |
| Windows export | `--export-debug "Windows Desktop" build\RiverDash.exe` | exit 0, self-contained exe produced |

So the starting point is **healthy**, not broken. The redesign is a **product** decision,
not a rescue.

---

## 5. Code inventory and reuse/replace decision

43 GDScript files, 7,643 lines; 6 scenes; 1 shader.

| Area | Files | Lines | Decision | Reason |
| --- | --- | --- | --- | --- |
| `autoload/` | 6 | 1,669 | **Mostly keep, extend** | `Settings`, `SaveData`, `Education`, `AudioManager`, `InputManager` are directly reusable. `Game` (run state machine) is **rewritten** as an app/level-flow machine. |
| `scripts/world/` | 8 | 2,017 | **Mostly replace, keep 2** | Delete `world_manager`, `course_segment`, `segment_planner`, `chase_camera`, `prop_market`, `prop_clinic`. **Keep** `game_materials.gd` and `prop_factory.gd` — the procedural material library and primitive builders are the most valuable asset in the repo and are exactly what a procedural 3D kitchen needs. |
| `scripts/obstacles/` | 5 | 292 | **Delete** | Endless-runner hazards have no place in a cooking game. The single-shot-hit pattern is already captured by the new task framework. |
| `scripts/collectibles/` | 1 | 160 | **Delete** | Replaced by the cooking task framework. |
| `scripts/checkpoints/` | 2 | 123 | **Delete** | Replaced by level steps. |
| `scripts/player/` | 2 | 616 | **Delete** | Replaced by fixed-camera mouse/touch manipulation; no character controller is needed or wanted. |
| `scripts/gameplay/` | 3 | 394 | **Delete** | `difficulty_manager`, `score_manager`, `powerup_manager` are runner-specific. Stars, per-level best scores and the learning log replace them. |
| `scripts/main/game.gd` | 1 | 323 | **Replace** | Becomes the kitchen scene controller. |
| `scripts/ui/` | 12 | 1,573 | **Partly keep** | **Keep and extend** `ui_factory.gd` (the visual design system). **Keep, restyle** `main_menu.gd`, `settings_menu.gd`, `pause_menu.gd`, `educational_popup.gd`. **Delete** `hud.gd`, `biome_title.gd`, `checkpoint_panel.gd`, `game_over.gd`, `how_to_play.gd`, `health_facts.gd` (replaced by the journal), `game_ui.gd` (replaced by the kitchen UI controller). |
| `scripts/data/` | 3 | 476 | **Rewrite content, keep engine** | `game_config.gd` (runner tuning) → new cooking tuning. `difficulty_config.gd` → deleted. `education_data.gd` → **rewritten** with Thai-primary two-tier lessons and new sourcing; its `SOURCES` dictionary and the validation engine are kept. |
| `assets/fonts/` | Sarabun + OFL | — | **Keep** | OFL-licensed, correct Thai rendering, already imported. |
| `shaders/water.gdshader` | 1 | — | **Keep** | Reused for the kitchen sink basin. |
| `tests/` | 3 suites | — | **Rewrite** | The 18 runner-behaviour tests are replaced by tests for the new interaction framework, level flow, education gating, and persistence. |
| `build/` | — | — | **Keep, re-export** | Old binaries remain until the new build replaces them. |

**Reuse is 100 % of the durable engineering value** (project config, save format,
settings, source-validated content pipeline, materials, audio synthesis, font, UI design
system). **Replace is 100 % of the gameplay** plus the runner-specific content.

---

## 6. Problems identified in the current build (the case for redesign)

These are recorded as findings, not as failures of the existing work — the existing work
met its original brief.

### 6.1 Educational problems

1. **Education is incidental, not mandatory.** A player can complete a run and ignore
   every pop-up; the Health Facts screen is optional. The redesign brief explicitly
   forbids this.
2. **No assessment.** There is no knowledge question anywhere, so there is no record of
   whether the player *understood* anything — which is a scored rubric item
   (*knowledge, understanding and academic accuracy*, 15 pts) and the basis of the whole
   research plan.
3. **No learning record.** The game cannot answer "which lessons did this student
   complete?" — required for the learning journal and for the research data export.
4. **A high score implies nothing about learning.** Distance and combo have no relation
   to health understanding.
5. **English-first.** The competition is Thai-language and Thai-judged; the in-game
   content is English with Thai only on some entries.

### 6.2 Gameplay and product problems (for this brief)

6. **Wrong interaction vocabulary.** Reflex avoidance teaches nothing about cooking,
   washing, separating raw food or judging doneness.
7. **Completion criterion is unrelated to the learning objective.** "Ran 3 km" is not a
   proxy for "can prepare safe fish".
8. **No recipe/knowledge journal**, no stars, no level progression, no per-level best.
9. **Difficulty presets are speed presets.** Speed pressure actively works against the
   brief's instruction not to reward rushing past educational content.
10. **Long-form runs (minutes, open-ended)** do not fit 1–3-minute classroom-friendly
    sessions.

### 6.3 Engineering problems

11. **Dead constants.** `LANE_LERP_SPEED`, `SEGMENT_LOOKAHEAD_MARGIN`, `START_DISTANCE`,
    `MAX_AIRBORNE_TIME` were unused (three were removed in the previous pass; the audit
    keeps the note for traceability).
12. **`ui_factory.gd` is a single large file** (~500 lines) — acceptable as a design
    system, but it needs splitting hooks as new widgets are added (stars, progress rings,
    recipe cards, quiz cards).
13. **No touch/mouse interaction layer at all.** The runner used keyboard actions;
    the new brief is mouse-first and touch-capable. A new raycast-based interaction
    layer is required.
14. **No physics-evidence tests for the new interaction types** (hold, drag, swipe,
    timing). The existing suite cannot be adapted; it must be rewritten.
15. **The save file is runner-shaped** (`best_score`, `longest_distance`). It needs a new
    schema with a **version bump and a migration path** so an old file cannot corrupt the
    new game.

### 6.4 Content-accuracy problems to preserve and extend

16. The existing content already respects the critical nuances (not all fish are
    infected; no universal single temperature; a dirty pipe is not full of flukes; one
    toilet does not remove every egg; treatment is medically supervised). **These must
    carry over and be strengthened**, and the redesign must add the **bile duct cancer**
    relationship *without* implying every infected person develops cancer.

---

## 7. Target product (redesign summary)

**Working title:** *Fluke Free Kitchen* (ครัวปลอดพยาธิ) — an original identity, not a
copy of any commercial cooking game.

* **Format:** 3 short levels of 1–3 minutes, each a sequence of 3–5 interactive cooking /
  food-safety actions, followed by a **required** knowledge question.
* **Presentation:** a cosy north-eastern Thai village kitchen, **fixed angled camera**,
  lightweight 2.5D (3D props + 2D overlay UI), warm lighting, steam/sizzle/chop/splash
  feedback, generous click targets.
* **Controls:** mouse click, drag-and-drop, click-and-hold, swipe, and touch.
* **Levels:**
  1. **Clean Kitchen Challenge** — handwashing, cleaning surfaces, choosing utensils,
     separating raw fish from ready-to-eat food, correcting a cross-contamination mistake.
  2. **Safe Cooking Challenge** — identify freshwater fish as needing safe handling,
     prepare the area, cook through with a hold/timing interaction, recognise the
     evidence-based cooking requirement, correct the "lime/salt/pickling makes it safe"
     misconception.
  3. **Village Prevention Challenge** — review food-handling situations, choose prevention
     actions, correct a sanitation mistake, answer a cancer/screening/treatment question,
     finish with a prevention checklist.
* **Progression:** up to 3 stars per level based on *correct actions, food-safety
  decisions, completion and demonstrated understanding* — **not** speed. Wrong answers
  give a short explanation and a retry; nothing is permanently blocked.
* **Screens:** main menu, level select, cooking interface, result, recipe & knowledge
  journal, pre/post knowledge assessment, settings, pause, reset progress.
* **Language:** Thai primary, English toggle; **two text tiers** (simple + "more detail")
  so the same build serves primary, lower-secondary and upper-secondary students.

---

## 8. Architecture as built (keeps the codebase modular and testable)

This section started as a plan. It is now written as **built**, because the audit is a
submission document and the plan names no longer matched the files on disk.

```
autoload/            Settings · SaveData · Loc · Learning · Education · Game ·
                     AudioManager · InputManager
                     (this exact order is the autoload order in project.godot)
scripts/data/        game_config.gd (tuning + scoring) · ui_strings.gd (TH/EN catalogue) ·
                     lesson_data.gd (LessonDB) · level_data.gd (LevelDB) ·
                     quiz_data.gd (QuizDB) · assessment_data.gd (AssessmentDB)
scripts/tasks/       task_base.gd (KitchenTask) + task_tap_correct.gd (also serves
                     choose_safer) · task_drag_to.gd · task_swipe_clean.gd ·
                     task_hold.gd · task_cook_through.gd (inside task_hold) ·
                     task_order_steps.gd · task_checklist.gd · task_factory.gd
scripts/kitchen/     kitchen_scene.gd (the 3D set) · kitchen_screen.gd (flow) ·
                     kitchen_session.gd (rules and scoring) · kitchen_hud.gd ·
                     interactive_item.gd · drop_zone.gd
scripts/ui/          ui_factory.gd (design system) · menu_screen.gd · main_menu.gd ·
                     level_select.gd · journal.gd · assessment.gd · quiz_card.gd ·
                     lesson_card.gd · kitchen_result.gd · pause_menu.gd ·
                     settings_panel.gd · star_row.gd · ring_progress.gd · ghost_pointer.gd
scripts/world/       game_materials.gd · prop_factory.gd (reused and extended) ·
                     kitchen_props.gd (bench, stove, props, floating labels)
scenes/              main/main_menu · main/level_select · kitchen/kitchen ·
                     journal/journal · assessment/assessment
tests/               smoke_test · flow_test · layout_check · visual_capture
```

Rules carried over from the existing codebase because they work: typed GDScript; signals over
scene-tree lookups; one responsibility per script; data-driven content so lessons, steps and
quizzes are edited in one place; **no gameplay script states a health fact**.

Two rules were added during the build, because breaking them produced real bugs:

* A full-rect `Control` is filled with `UIFactory.fill()`, never
  `set_anchors_preset(PRESET_FULL_RECT)` — the preset uses minsize mode and collapses to 0×0 when
  applied in-tree to a plain `Control`.
* A `ScrollContainer` only stretches a child across a disabled-scroll axis when the child has
  `SIZE_EXPAND_FILL`; without it, autowrapping children collapse to a sliver and wrap into a very
  tall column.

---

## 9. Milestone plan

Each milestone ends **buildable and runnable**, and each has a gate that must pass before
the next begins. **Live status is tracked in `docs/MILESTONES.md`.**

| # | Milestone | Deliverable | Gate / evidence |
| --- | --- | --- | --- |
| **M0** | Audit & plan | this document | written and reviewed |
| **M1** | Clean slate + app shell | runner code removed; new flow state machine; main menu, level select, kitchen shell (fixed camera + kitchen set), result overlay, pause, settings; new save schema v2 + migration | launches headless with no errors; smoke test passes |
| **M2** | Interaction framework | 8 reusable task types + demo/tutorial system + generous hit areas | task test suite passes for every type |
| **M3** | **Level 1** Clean Kitchen Challenge | all steps, lesson, required question, stars | playable end-to-end; level test passes |
| **M4** | **Level 2** Safe Cooking Challenge | cook-through mechanic, misconception correction, required question | playable end-to-end; test passes |
| **M5** | **Level 3** Village Prevention Challenge | scenario cards, sanitation fix, cancer/screening/treatment question, checklist | playable end-to-end; test passes |
| **M6** | Progression & journal | stars, unlocks, per-level best, learning log, recipe/knowledge journal, reset progress | persistence tests pass across a simulated restart |
| **M7** | Presentation pass | cosy kitchen art, warm lighting, steam/sizzle/chop/splash, transitions, UI polish, final sound design | real-renderer review; no default-engine look |
| **M8** | Education & research pack | `SCIENTIFIC_CONTENT.md`, `REFERENCES.md`, `LEARNING_OBJECTIVES.md`, `RESEARCH_PLAN.md`, `RUBRIC_TRACEABILITY.md`, in-game pre/post assessment + anonymised export | every claim traced to a verified source; assessment round-trips |
| **M9** | QA & delivery | rewritten test suites, clean-directory launch, Windows exports, manual checklist, final report | all acceptance criteria below pass |

---

## 10. Acceptance criteria (for the first complete version)

1. The project launches successfully.
2. All three levels are playable from start to finish.
3. Every level contains at least one **required** knowledge question.
4. The required educational interaction cannot be skipped: a player cannot obtain a
   full-completion result (3 stars / level complete) without answering the level's
   knowledge question correctly.
5. Every wrong answer shows a short, plain-language explanation and permits a retry;
   progression is never permanently blocked and the player is never shamed.
6. Stars depend on correct actions, food-safety decisions, completion and demonstrated
   understanding — not on speed.
7. Progress, stars and best scores persist across restarts; **reset progress** returns
   the game to its initial state.
8. The learning log records which activities were completed, which questions were
   answered correctly, which misconceptions were corrected and which lessons were
   covered, and it is viewable in the journal.
9. Pause and restart work in every level.
10. Thai text renders correctly (Sarabun), and the English toggle covers all in-game text.
11. The game is fully operable with mouse only, and the same actions work with touch.
12. Every new action is demonstrated before the player is asked to perform it.
13. Every health claim in the game is traceable to an authoritative source recorded in
    `docs/REFERENCES.md`; no invented citations and no invented cooking temperature or
    duration.
14. The automated test suites pass and return a non-zero exit code on failure.
15. The project launches from a clean directory (no `.godot/`, no pre-existing save) and
    produces no script errors.
16. The Windows export builds and the exported executable runs.
17. No paid assets or plugins are used; all art and audio is original or permissively
    licensed, with attributions recorded.
18. **No fabrication:** if no student study has been run, all documents state plainly that
    educational effectiveness has not yet been measured. No participant counts, no
    improvement percentages, no research conclusions are invented.

---

## 11. Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| "Cooking-game polish" is subjective and unbounded | Could consume all effort | Lock the milestone order; polish is **M7**, deliberately after the game is complete and playable; define a concrete polish checklist rather than "make it nicer". |
| Procedural art may not read as "cosy Thai kitchen" | Weak first impression for judges | Reuse + extend the proven procedural material library; invest in warm lighting, colour grading and composition; verify on the real renderer at each milestone (headless cannot judge visuals). |
| Interaction framework could become a monolith | Unmaintainable, hard to test | One script per task type behind a common `task.gd` base with signals; each type gets its own automated test. |
| Thai text could break layout | Unreadable UI | Sarabun is already imported and proven; build UI with generous, wrapping, auto-sizing labels; add a Thai/English toggle test. |
| Competition-level research expectation vs. no data | Judges may penalise unsupported claims | `RESEARCH_PLAN.md` is written as a *plan* with a documented, ethics-gated protocol, an anonymised export format, and an explicit "not yet measured" statement. |
| Old save file from the runner conflicts with the new schema | Crash or wrong progress | Bump the save version; treat an unknown/older version as "start fresh" and keep the corrupt-file quarantine; test it. |
| Scope creep (extra levels, multiplayer, open world) | Nothing finishes | The brief forbids these; the milestone plan has no slot for them. |

---

## 12. Traceability

Milestone-by-milestone mapping to the official *Fluke Free Fighters* judging criteria
(semi-final §7 and final §9 of the announcement) is maintained in
`docs/RUBRIC_TRACEABILITY.md`, which is produced in milestone M8.

---

## 13. Repair pass — status by area (2026-10-16, updated 2026-10-17)

A later brief asked for an audit-and-repair pass over the finished game: responsive layout
across a viewport matrix, progressive cooking visuals, honest handling of the three
outcomes, real save/load, Thai/English, and a per-area verdict. Status, with the evidence
that backs it:

| Area | Verdict | Evidence / what it means |
|---|---|---|
| Responsive layout across 12 sizes (320 × 568 → 3840 × 2160) | **PASS** | `tests/responsive_check.tscn`: 132 layouts (menu, challenge picker, journal, assessment, settings modal, three kitchen states), 0 failures. 188 real faults found and fixed across the passes. Details and limits in `docs/RESPONSIVE.md` |
| Runtime resize / portrait ↔ landscape / repeated reflow | **PASS (in-run)** | The matrix resizes the window between all twelve sizes in one process, exercising rebuild and in-place reflow every time. A real device rotation event is **NOT TESTED** |
| Nulls and clipping on a physical phone/tablet | **NOT TESTED** | No phone or tablet has run this build. Every result is from window resizing on one Windows laptop |
| Safe areas (notch, rounded corners) and system font scaling | **NOT IMPLEMENTED** | Not read from the OS. Documented in `docs/RESPONSIVE.md` §7 |
| Behaviour after a language change mid-session | **PASS** | `Settings.set_language` rebuilds menus in place; the kitchen keeps its state (the language is not part of the attempt). Menu screens rebuild through `clear_page()`, which keeps the background — a bug where the warm background was lost was found and fixed |
| No auto-start, no auto score, no double scoring, no state leaking between attempts | **PASS** | `flow_test` asserts quiz records equal questions asked, correct ≤ asked, score ≤ maximum; `behaviour_test` drives the real pointer through demo gates and retries. A double-counting bug in `KitchenSession.record_quiz` was found and fixed |
| Progressive cooking visuals (raw → cooked → golden → overcooked → burnt) | **PASS** | Five-stop browning ramp in `KitchenScene.set_fish_browning()`; `cook_test.tscn` measures the colour change mid-cook and asserts the burnt look |
| Visuals separated from safety logic; never teach that golden = safe | **PASS** | Pass/fail reads only the internal temperature and the time held at it. The cooking panel prints, in both languages, that golden colour is not a safety check (`task.colour_not_proof`) |
| Outcome A (safe dish) | **PASS** | The cooking step succeeds only after the fish holds a safe internal temperature (63 °C) for the required time; `behaviour_test` and `flow_test` both drive it |
| Outcome C (burnt / overcooked) with quick retry | **PASS** | `_burn_the_fish()` / `_restart_cook()`; `cook_test.tscn` drives a real press-and-hold until the burn, checks the retry button, the fresh raw fish, the retained mistake and that the fresh fish heats again |
| Outcome B (serving an unsafe dish) — non-graphic, skippable, distinguishes exposure risk from infection | **PASS** | The cooking step now offers a deliberate "serve it now" choice (`task.serve_now`). Taking it below the safe temperature ends the step in the B outcome: the mistake is recorded, the message says the fish *may* still carry living larvae and separates exposure → risk of infection → infection → cancer in words only, and either "start this fish again" or "keep cooking this one" leaves the message in one tap. `cook_test.tscn` drives it and asserts the ending, the recorded mistake, the exposure/infection wording and the way out; screenshot `cook_4_unsafe_serve.png` |
| Bottom sheets fitted to their real content (all tasks) | **PASS** | A wrapped label answers `get_combined_minimum_size()` with a fantasy height until it knows its width, and a container's child `size` just echoes the rect it was given. `_fit_sheet`/`_refit_measured` now fit sheets to the post-layout minimum, and `KitchenHUD.content_top()` measures the visible bottom of the instruction area instead of its claimed minimum. Before this, a tall sheet (the new B message) was clamped to ~160 px and clipped. All five sheets re-checked in a windowed run; the 132-layout matrix still passes |
| Motion / tilt controls with fallbacks | **NOT APPLICABLE, NOT FAKED** | No sensor interaction exists anywhere in the game; every task is pointer-driven. No settings toggle pretends otherwise. Rationale in `docs/RESPONSIVE.md` §8 |
| Save/load: versioned, validated, atomic, corrupt-safe, no silent overwrite | **PASS** | `SaveData` schema v2, temp swap, `save_v2.corrupt.json` quarantine, legacy `save_v1.json` kept as a backup; `smoke_test` plants a file of every kind, resets, and proves none survive |
| Settings persistence and reset | **PASS** | `settings_v2.json`; "reset all progress" clears disk and memory, including half-written and quarantined files |
| Graphics quality settings that affect only real features | **PASS (limited scope)** | `low/medium/high` change 3D render scale and MSAA only, leaving the UI at native resolution so text stays readable. No claimed setting does nothing |
| Thai/English coverage, tone marks, no clipped text | **PASS (current strings)** | The responsive checker fails a label asked to draw more text than its box; the full matrix passes in Thai. A native-speaker review of both languages is still **NOT DONE** |
| Menus: no traps, consistent back button, pause stops processes, settings do not start gameplay | **PASS** | Verified by `flow_test`, `behaviour_test` and the captured screenshots. A real z-order bug was found here: modals were drawn behind the page, because a screen adds its content after `super()` has added the overlay. `show_overlay()` now raises the overlay |
| Offline only, no unnecessary online features | **PASS** | No network calls anywhere in the project |
| Windows export builds and runs | **PASS** | `build/FlukeFreeKitchen.exe` (104.6 MB) exported and launched headless for 8 s: engine banner on stdout, empty stderr |
| Web export builds and runs in a browser | **PASS** | `build/web/` exported single-threaded; driven in real Chrome over the DevTools protocol — canvas 1254 × 564, `Engine` global present, 0 console errors, Thai menu rendered. Details in `docs/EXPORTS.md` §4 |
| Android export builds, signs and validates | **PASS (build) / NOT TESTED (runtime)** | `build/android/FlukeFreeKitchen.apk` (55.34 MB): `apksigner verify` PASS (v2 + v3), manifest inspected (`th.ac.kku.flukefreekitchen`, minSdk 24 / targetSdk 36, **no `<uses-permission>` at all**), both ABIs present, 25 launcher icons. **Never installed or launched** — no device or emulator existed. `docs/EXPORTS.md` §5.3 |
| Android runtime on hardware (touch, back button, notches, thermals) | **NOT TESTED** | No Android device or emulator was available in this environment |
| iOS export | **BLOCKED** | Requires macOS + Xcode; no cross-compiler exists on Windows. A preset is committed, marked untested. `docs/EXPORTS.md` §6 |
| Learning-outcome study — data | **NOT DONE** | No participants, no consent, no ethics approval, no data, no results. The game says so on the assessment screen. This remains not-done and cannot be done by software |
| Learning-outcome study — runnable kit | **PASS** | Protocol (`docs/STUDY_PROTOCOL.md`), five bilingual paper forms (`docs/study/`), the optional in-game case code (`SaveData.sanitise_code`, asserted in `smoke_test`), and `tools/study/analyse_export.py`, whose `--selftest` pins every statistic against a reference value and runs the full pipeline on clearly-labelled synthetic records |
| Source verification (11 sources) | **PASS** | All eleven are now `verified` (2026-10-16). The seven that were `listed` were re-opened and their claims checked against the source's own words: the CDC pages, the WHO Five Keys manual, the Thai DDC press release of 15 July 2026, the IARC Monographs Volume 100B PDF, and the Sripa 2012 abstract via Europe PMC. Two wrong URLs (CDC About Opisthorchis; the DDC home page) were corrected. Log in `docs/REFERENCES.md` §6 |
| Competition deliverables (report ch. 1–5, video, board, logbook) | **IN PROGRESS** | The written set is drafted in `docs/report/`: chapters 1–5 in Thai, abstract/proposal/summary, a numbered reference list, a ≤ 7-minute video script, a display-board plan and a logbook template. Chapter 4 reports the real software results and states plainly that no learning/behaviour data was collected. Still to do: typeset to A4 / TH SarabunPSK 16 pt, insert real screenshots, record the video, build the board, and fill the logbook with real dates |

Nothing in this table is marked PASS because it "should work". Every PASS is tied to a test
that runs and reports, or to a screenshot that was looked at. Everything else is marked
NOT TESTED, NOT IMPLEMENTED or NOT DONE on purpose.

