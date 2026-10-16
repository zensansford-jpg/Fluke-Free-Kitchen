# Fluke Free Kitchen · ครัวปลอดพยาธิ

A small, educational 3D cooking game about **preventing liver fluke infection and bile duct
cancer**, built with Godot 4.7.2 for the **Fluke Free Fighters** competition
(พิชิตพยาธิใบไม้ตับและมะเร็งท่อน้ำดี, Cholangiocarcinoma Research Institute, Khon Kaen University).

Three short challenges — 1 to 3 minutes each, 5 to 6 actions per challenge — teach how liver
flukes reach people through raw freshwater fish, how to cook and handle fish safely, and how
sanitation, screening and treatment fit into prevention. Thai is the primary language; English
can be toggled at any time.

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

Headless checks (used throughout development):

```powershell
godot --headless --path . res://tests/smoke_test.tscn        # content, wiring, scoring
godot --headless --path . res://tests/flow_test.tscn         # all three challenges end to end
godot --headless --path . res://tests/behaviour_test.tscn    # real pointer input (click/drag/swipe/hold)
godot --headless --path . res://tests/cook_test.tscn         # cooking visuals + the burnt outcome and its retry
godot --headless --path . res://tests/responsive_check.tscn  # the 12-size responsive matrix (120 layouts)
godot --headless --path . res://tests/layout_check.tscn      # UI geometry, per step
godot --path . res://tests/visual_capture.tscn -- l1         # renders states to PNGs
```

Every suite exits non-zero on failure, so they can be wired into a check script. A new test
that uses a window must call `TestWindow.use(w, h)` first: the project runs with
`stretch/mode = "disabled"`, so a headless run otherwise gets a 64 × 64 viewport.

## How to play

| Input | Used for |
|-------|----------|
| **Click / tap** | choose the correct item; answer a question |
| **Drag** | move an ingredient to the correct container |
| **Swipe** | wash a surface clean |
| **Press and hold** | heat a pan; cook the fish to a safe temperature |

Screens: main menu → challenge select → kitchen → result. Progress and best scores are saved
locally, and there is a **reset all progress** option and a **knowledge journal** you can revisit
at any time. Every new action is demonstrated before you are asked to do it, and a wrong answer
is explained and can be retried — nothing is scored on speed, and nothing is ever blocked.

The game's rules make the education part of finishing the level: **a challenge is not passed —
and earns no stars — until its required knowledge question has been answered correctly.**

## Window sizes and languages

The interface is built to **reflow**, not to shrink: below 700 px wide, grids collapse to a
single column, labels get the full page width, and the journal's tabs become a dropdown
rather than three clipped buttons. Twelve window sizes between 320 × 568 and 3840 × 2160,
across ten layouts each, are checked automatically by `tests/responsive_check.tscn`
(**132/132 passing**). What that does and does not prove — no phone has run this build, safe
areas and system font scaling are not handled — is written out in `docs/RESPONSIVE.md`.

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
                quiz_data (QuizDB) · assessment_data (AssessmentDB)
scripts/tasks/  the interaction framework: 8 task kinds behind task_factory
scripts/kitchen/ the 3D set, the flow, and the scoring rules
scripts/ui/     the design system and every screen
scripts/world/  procedural materials and props
scenes/         main_menu · level_select · kitchen · journal · assessment
tests/          smoke · flow · behaviour · cook · responsive · layout · visual capture
tools/          serve_web.py · web_smoke.mjs · study/analyse_export.py
docs/           the education and competition documents; docs/study/ holds the paper forms
build/          export output (.exe, .apk, web/) — ignored by the asset scanner
```

**Health content is data, not code.** No gameplay script states a health fact; gameplay asks for
a lesson id and receives vetted, source-backed text. `Education.validate_database()` refuses to
start quietly if a lesson cites an unknown or disallowed source.

## Documentation

| File | What it covers |
|------|----------------|
| `docs/PROJECT_AUDIT.md` | the audit, the reuse/replace decisions, the architecture, the acceptance criteria |
| `docs/MILESTONES.md` | milestone status: what is done, what is left |
| `docs/RESPONSIVE.md` | how the interface reflows, the 12 sizes it was checked at, the results, and what is still untested |
| `docs/EXPORTS.md` | what was exported to each platform, how it was verified, what was *not* verified, and how to rebuild |
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
