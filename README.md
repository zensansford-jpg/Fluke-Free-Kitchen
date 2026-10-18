# Fluke Free Kitchen · ครัวปลอดพยาธิ

A small, educational 3D cooking game about **preventing liver fluke infection and bile duct
cancer**, built with Godot 4.7.2 for the **Fluke Free Fighters** competition
(พิชิตพยาธิใบไม้ตับและมะเร็งท่อน้ำดี, Cholangiocarcinoma Research Institute, Khon Kaen University).

Three short story challenges — 1 to 3 minutes each, 5 to 6 actions per challenge — teach how liver
flukes reach people through raw freshwater fish, how to cook and handle fish safely, and how
sanitation, screening and treatment fit into prevention. Beyond them, the same validated cooking
engine powers an endless mode, a free-cook mode, a browser of game-composed dishes and a place to
save dishes you create yourself. Thai is the primary language; English can be toggled at any time.

> **Honesty note.** This game has been built and tested as software. It has **not** been
> evaluated with students, so no improvement in knowledge or behaviour is claimed. The game says
> the same thing on its knowledge-check screen: no classroom trial has been carried out, so
> there is no measured learning result to cite yet. See `docs/RESEARCH_PLAN.md`.

---

## Requirements

* **Godot 4.7.2** (stable). No third-party plugins, no paid assets, no network access at run time.
* Windows, macOS or Linux for development; the game is mouse- and touch-ready.

## Run it

```powershell
# Open in the editor
godot --path . --editor

# Or run directly
godot --path .
```

Headless checks (used throughout development). All eight report PASS/FAIL themselves, so they can
be run in one go:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_all_tests.ps1   # imports, runs all eight, prints a summary
```

Individually:

```powershell
godot --headless --path . res://tests/smoke_test.tscn        # content, wiring, scoring, save, sources
godot --headless --path . res://tests/anim_test.tscn         # the shared motion library and its refusal contract
godot --headless --path . res://tests/flow_test.tscn         # all three challenges end to end
godot --headless --path . res://tests/behaviour_test.tscn    # real pointer input (click/drag/swipe/hold)
godot --headless --path . res://tests/cook_test.tscn         # cooking visuals + outcomes B (unsafe serving) and C (burnt) and their retries
godot --headless --path . res://tests/recipe_test.tscn       # the catalogue, the generator and the saved cookbook
godot --headless --path . res://tests/minigame_test.tscn     # every cooking interaction, driven with real pointer events
godot --headless --path . res://tests/responsive_check.tscn  # the 12-size responsive matrix (360 layouts)

# capture tools, not pass/fail suites (the visual capture needs a real window)
godot --path . res://tests/layout_check.tscn                 # UI geometry, per step
godot --path . res://tests/visual_capture.tscn -- l1         # renders states to PNGs
```

Every suite exits non-zero on failure, so they can be wired into a check script. A new test
that uses a window must call `TestWindow.use(w, h)` first: the project runs with
`stretch/mode = "disabled"`, so a headless run otherwise gets a 64 × 64 viewport.

## How to play

The mode screen is the front door; every mode runs the same validated cooking engine.

| Mode | What it is |
|------|------------|
| **Let's Cook** | pick a real dish from the catalogue and cook it step by step |
| **Endless Kitchen** | one generated, validated challenge after another |
| **Free Cook** | your own fish and method, clearly marked as an experiment |
| **My Cookbook** | dishes you built in the creator, saved in your own save file |
| **Discover** | a paged, picture-first browser of dishes composed by the game |

| Input | Used for |
|-------|----------|
| **Click / tap** | choose the correct item; answer a question |
| **Drag** | move an ingredient to the correct container |
| **Swipe** | wash a surface clean |
| **Press and hold** | heat a pan; cook the fish to a safe inside temperature |
| **Slice** | cut the fish into pieces |
| **Stir / flip / plate** | cook evenly, turn the fish, and plate the dish |

Screens: main menu → mode select → dish or challenge → kitchen → result. Progress and best
scores are saved locally, and there is a **reset all progress** option and a **knowledge journal**
you can revisit at any time. Every new action is demonstrated before you are asked to do it, and a
wrong answer is explained and can be retried — nothing is scored on speed, and nothing is ever
blocked.

The game's rules make the education part of finishing the level: **a challenge is not passed —
and earns no stars — until its required knowledge question has been answered correctly.**

## Window sizes and languages

The interface is built to **reflow**, not to shrink: below 700 px wide, grids collapse to a
single column, labels get the full page width, and the journal's tabs become a dropdown
rather than three clipped buttons. Twelve window sizes between 320 × 568 and 3840 × 2160,
across every menu screen (plus a filled creator, a filled cookbook, the settings modal, the
three kitchens and a full recipe walk), are checked automatically by
`tests/responsive_check.tscn` (**360/360 passing**). What that does and does not prove — no
phone has run this build, safe areas and system font scaling are not handled — is written
out in `docs/RESPONSIVE.md`.

Thai is the primary language and English can be toggled at any time without restarting the
challenge. There are no motion or tilt controls in the game, so no settings toggle pretends
there are.

## Build it

```powershell
godot --headless --path . --export-release "Windows Desktop" build/FlukeFreeKitchen.exe
godot --headless --path . --export-release "Web"             build/web/index.html
godot --headless --path . --export-debug   "Android"         build/android/FlukeFreeKitchen.apk
```

The presets in `export_presets.cfg` embed the `.pck`, exclude `tests/` and `build/`, and carry the
project icon. `build/FlukeFreeKitchen.exe` opens on the main menu with no installer.

**Status of each export, with the evidence and the caveats, is in `docs/EXPORTS.md`:**

| Platform | Built | Actually run |
|---|---|---|
| Windows | yes | **yes** — launched, clean |
| Web | yes | **yes** — real Chrome, 0 console errors |
| Android | yes (signed debug APK) | **no** — no device or emulator existed |
| iOS | no — needs macOS + Xcode | **no** — blocked, reasons in `docs/EXPORTS.md` §6 |

To serve the Web build with the right `.wasm` MIME type: `python tools/serve_web.py`.

## Project layout

```
autoload/       Settings · SaveData · Loc · Learning · Education · Game ·
                AudioManager · InputManager
scripts/data/   game_config · ui_strings · lesson_data (LessonDB) · level_data (LevelDB) ·
                quiz_data (QuizDB) · assessment_data (AssessmentDB) · recipe_data (RecipeDB) ·
                achievement_data · challenge_generator (validated procedural dishes)
scripts/tasks/  the interaction framework: 14 interaction kinds behind task_factory
scripts/kitchen/ the 3D set, the flow, and the scoring rules
scripts/ui/     the design system and every screen
scripts/world/  procedural materials, props, and the shared motion library
scenes/         main_menu · mode_select · dish_select · free_cook · custom_cook ·
                cookbook · explore · kitchen · journal · assessment
tests/          eight pass/fail suites (smoke · anim · flow · behaviour · cook ·
                recipe · minigame · responsive) plus layout_check and visual_capture
tools/          serve_web.py · web_smoke.mjs · run_all_tests.ps1 · study/analyse_export.py
docs/           the education and competition documents; docs/study/ holds the paper forms
build/          export output (.exe, .apk, web/) — ignored by the asset scanner
```

**Health content is data, not code.** No gameplay script states a health fact; gameplay asks for
a lesson id and receives vetted, source-backed text. `Education.validate_database()` refuses to
start quietly if a lesson cites an unknown or disallowed source.

## Documentation

| File | What it covers |
|------|----------------|
| `docs/FINAL_STATUS.md` | the one-page status sheet: the suite results, what is verified, and what is left |
| `docs/PROJECT_AUDIT.md` | the audit, the reuse/replace decisions, the architecture, the acceptance criteria |
| `docs/ROADMAP.md` | the consolidated plan: every requirement, its status, its evidence, and what is human-only or blocked |
| `docs/QA_CHECKLIST.md` | the practical pre-demo / pre-submission checklist, condensed from the roadmap |
| `docs/MILESTONES.md` | milestone status: what is done, what is left |
| `docs/RESPONSIVE.md` | how the interface reflows, the 12 sizes it was checked at, the results, and what is still untested |
| `docs/EXPORTS.md` | what was exported to each platform, how it was verified, what was *not* verified, and how to rebuild |
| `docs/PLACEHOLDER_ASSETS.md` | what is generated rather than shipped, and the exact hook to replace each asset |
| `docs/SCIENTIFIC_CONTENT.md` | every health claim, its lesson, its source, and what the game deliberately does *not* claim |
| `docs/REFERENCES.md` | full citations, each with its verification status and the log of when and how it was checked |
| `docs/LEARNING_OBJECTIVES.md` | what each challenge teaches and how the game records it |
| `docs/RESEARCH_PLAN.md` | the (not yet run) plan to measure the game's educational value |
| `docs/STUDY_PROTOCOL.md` | how to actually run that study, step by step, and what the ethics gates are |
| `docs/study/` | the paper materials: information sheet, parental consent, student assent, questionnaire, data record |
| `tools/study/README.md` | how to turn exported results into the report's tables, and what the statistics are pinned against |
| `docs/RUBRIC_TRACEABILITY.md` | each competition scoring criterion mapped to evidence, including the gaps |
| `docs/report/` | the competition report set: chapters 1–5 (Thai), abstract/proposal/summary, references, video script, display-board plan, logbook |
| `docs/archive/` | the superseded endless-runner prototype's documents, kept for history |

## The health rules the game follows

* Transmission is by eating **raw or undercooked freshwater fish** — the game never says water,
  air or sea fish transmit it.
* **No universal safe temperature or duration is invented.** The game repeats CDC's 145 °F
  (about 63 °C) internal guideline and reports the laboratory regimes actually tested, labelled
  as such.
* **Not every fish is infected**, and the larvae cannot be seen.
* **Infection is a risk factor, not a diagnosis of cancer**; most infected people do not develop
  cancer.
* Praziquantel is a prescription medicine that treats an existing infection; it does not replace
  prevention and does not stop a new infection.
* Screening is carried out and explained by health workers.
* Medicine is not a licence to eat raw fish, and one toilet does not end transmission overnight.

Every claim traces to a source in `docs/REFERENCES.md`. If a source says something different from
the game text, the game text changes — the source wins.
