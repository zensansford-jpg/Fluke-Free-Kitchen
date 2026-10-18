# Milestones — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Version:** 2.0.0 · **Updated:** 2026-10-18
This is the live status tracker. The milestone plan itself (gates and deliverables) is in
`docs/PROJECT_AUDIT.md` §9; the acceptance criteria are in §10 of the same file.

Legend: ✅ complete · 🔄 in progress · ⬜ not started

---

## Status at a glance

| # | Milestone | Status | Evidence |
|---|-----------|--------|----------|
| **M0** | Audit & plan | ✅ | `docs/PROJECT_AUDIT.md`, `docs/MILESTONES.md` |
| **M1** | Clean slate + app shell | ✅ | runner code removed; 8 autoloads; 5 screens; save schema v2; `smoke_test.tscn` passes |
| **M2** | Interaction framework | ✅ | 8 task kinds behind `task_factory.gd`; demo-before-action; generous hit areas; built by `smoke_test` |
| **M3** | Level 1 — Clean Kitchen | ✅ | `flow_test.tscn`: 5 steps, 3 stars, 1450/1450, 2 questions |
| **M4** | Level 2 — Safe Cooking | ✅ | `flow_test.tscn`: 5 steps, 3 stars, 1450/1450, 2 questions |
| **M5** | Level 3 — Village Prevention | ✅ | `flow_test.tscn`: 6 steps, 3 stars, 1610/1610, 2 questions |
| **M6** | Progression & journal | ✅ | stars, unlocks, per-level best, learning log, knowledge journal, reset progress; journal shows 12 recorded lessons |
| **M7** | Presentation pass | ✅ | fixed angled camera, cosy kitchen set, feedback, UI polish, screen transitions; **progressive cooking visuals** (raw → cooked → golden → burnt), the burnt outcome with quick retry **and the unsafe-serving outcome (B)** all verified by `cook_test.tscn`; in-game screens verified by `layout_check` and `visual_capture` |
| **M8** | Education & research pack | 🔄 | in-game pre/post assessment + anonymised export (running); the five documents written; source re-verification and any real study remain |
| **M9** | QA & delivery | 🔄 | cold-start launch verified with a clean user directory (no errors); Windows build exported (`build/FlukeFreeKitchen.exe`); **responsive matrix passed: 360/360 layouts** (`responsive_check.tscn`, see `docs/RESPONSIVE.md`); eight suites green (smoke, anim, flow, behaviour, cook, recipe, minigame, responsive) and runnable in one command (`tools\run_all_tests.ps1`); remaining: manual play-through checklist on a physical device and a final Thai/English string review |

---

## What is finished and verified

* **All three challenges play end to end** on Godot 4.7.2, headless and with a real window.
* **Scoring invariants are asserted, not assumed:** `flow_test` checks that the number of quiz
  records equals the number of questions for the level, that correct answers never exceed
  questions asked, that the score never exceeds the level maximum, and that every step is
  completed. (This caught a real double-counting bug, now fixed in `KitchenSession.record_quiz`
  and in the quiz card's button locking.)
* **Education cannot be skipped for credit.** `KitchenSession.passed()` requires every step to be
  completed *and* the level's required knowledge question to be answered correctly; the runner
  keeps asking until it is right, showing `why` after each wrong option.
* **Every new action is demonstrated before it is asked for** (`KitchenTask.run_demo_then`, plus a
  ghost pointer for physical tasks).
* **Eight test suites, one command:** smoke (content, wiring, scoring, assessment pairing, export
  fields), anim (the shared kitchen motion library, including its refusal contract for missing or
  loose nodes), flow (all three levels), behaviour (what each interaction asks for), cooking
  (progressive browning and the burnt outcome with its retry), recipe (catalogue, generator and v3
  save migration with quarantine), minigame (a full generated recipe driven with real pointer
  events) and responsive (the 360-layout matrix). `tools\run_all_tests.ps1` runs them all and prints
  a per-suite verdict.
* **The interface survives a 360-layout responsive matrix.** `tests/responsive_check.tscn` walks
  every menu screen (the main menu, the mode picker, the challenge picker, the dish browser,
  Free Cook, the recipe creator, the cookbook, the Discover browser, the journal and the
  assessment screen), a filled creator and a filled cookbook, the settings modal, three
  kitchen states and a full recipe walk across twelve window sizes from 320 × 568 to
  3840 × 2160 and fails on any control that leaves the window or any label that is asked to
  draw more text than its box holds. It reports **360/360 passing**. The whole story —
  approach, the faults it found and the honest list of what is still untested (no physical
  device, no safe-area handling, no system font scaling) — is in `docs/RESPONSIVE.md`.
* **Cooking looks like cooking.** The fish in the pan walks a five-stop browning ramp as heat goes
  in (raw → opaque → golden → deep brown → burnt), and holds its look between frames because the
  ramp is a pure function of accumulated heat rather than a per-frame nudge. `cook_test.tscn`
  measures the colour change, drives a real press-and-hold until the fish burns, checks that the
  burnt outcome appears with a retry, that the retry puts a **raw** fish back, that the mistake
  survives the retry, and that the fresh fish heats up again. Colour is presentation only: the
  panel says on screen that golden is not a safety check, and no pass/fail rule reads the colour.
* **All three outcomes are real and each is covered by a test.**
  *A* — the dish is safe: the step succeeds only after the inside holds a safe temperature.
  *C* — burnt: too much heat spoils the fish, shown with an explanation and a quick retry.
  *B* — unsafe serving: the player may deliberately "serve it now" below the safe temperature;
  the step stops, records a mistake, says in words — with nothing depicted — that the fish may
  still carry living larvae, that the eater would be *exposed* (a risk of infection, not an
  infection, and not the same as cancer), and offers either a fresh fish or "keep cooking this
  one" so the message is one tap to skip. Added 2026-10-17; driven by `cook_test.tscn`.
* **Bottom sheets are fitted to what they actually contain.** A wrapped label reports a fantasy
  minimum height until it knows its width, and a container stretches its child to the rect it was
  given, so fitting a sheet to either number clips it or inflates it. `KitchenTask._fit_sheet` /
  `_refit_measured` and `KitchenHUD.content_top()` were corrected on 2026-10-17 to use the
  post-layout minimum and the visible bottom of the instruction area; the new outcome-B message
  exposed the fault, and all five sheets were re-checked in a windowed run afterwards.
* **A fifth suite drives the real pointer pipeline** (`tests/behaviour_test.tscn`): it pushes
  `InputEventMouseButton` / `InputEventMouseMotion` into the viewport and checks that a
  demonstration blocks input, that a wrong answer is explained and the step stays open (on a
  required question), that a wrong quiz answer leaves a retry, that a short press does **not**
  finish a hold but a real one does, that releasing a cook early does not finish it, and that
  swiping and dragging complete their steps. This is the suite that proves the *interactions*
  work, not just the flow. Writing it caught a real trap: events pushed into the viewport as
  window coordinates land in the wrong place in a headless run, so the whole suite silently
  "pressed" nothing until it was switched to viewport-local input.
* **Screen transitions.** `Game` now fades through black between every screen and fades in on
  launch (`_transition()` / `_fade_to()`), so the game never hard-cuts between a warm kitchen and
  a menu. Verified with a throwaway probe that walked menu → levels → kitchen and checked the
  scene, the state and the wash alpha at each step.
* **"Reset all progress" really resets.** It clears the save, the half-written temp file, a
  quarantined corrupt file **and** the runner-era `v1` files, from disk and memory. `smoke_test`
  now proves this by planting a file of every kind, resetting, and checking that none survived —
  saving and restoring any real file first, so the check can never cost a player their save.
* **A Windows build exists and runs.** `build/FlukeFreeKitchen.exe` is exported from
  `export_presets.cfg` (the preset metadata was still the runner's and has been retargeted);
  test tools are excluded from it.
* **A Web build exists and was driven in a real browser.** `build/web/` is exported
  single-threaded (so it runs from any plain static host, no COOP/COEP headers needed), served by
  `tools/serve_web.py`, and checked over the Chrome DevTools protocol by `tools/web_smoke.mjs`:
  title, canvas 1254 × 564, `Engine` global present, **0 console errors**, and a screenshot showing
  the Thai menu rendering correctly. `--headless --screenshot` was not enough — it catches the boot
  splash, because a 37 MB WebAssembly module takes real seconds to compile.
* **An Android build exists, is signed, and validates.** `build/android/FlukeFreeKitchen.apk`
  (55.51 MB): `apksigner verify` passes for signature schemes **v2 and v3**, the manifest is
  package `th.ac.kku.flukefreekitchen` at minSdk 24 / targetSdk 36, both `arm64-v8a` and
  `armeabi-v7a` carry `libgodot_android.so`, 25 launcher icons are generated from `icon.svg`, and
  the manifest requests **no permissions at all** — not even `INTERNET`, which makes "this game is
  offline" a checkable property instead of a claim. Getting there needed four real fixes: a project
  icon (the export hard-fails without one), ETC2/ASTC texture import, a `.gdignore` in `build/`
  (the first APK had the web build's PNGs bundled inside it), and `exclude_filter="…,build/*"` on
  every preset. **It has never been installed or launched** — no device or emulator existed.
* **iOS is documented as blocked, not faked.** A preset is committed so a Mac can pick it up, and
  `docs/EXPORTS.md` §6 lists exactly what is missing (macOS, Xcode, an Apple developer account).
* **The study is runnable even though it has not been run.** `docs/STUDY_PROTOCOL.md` is the
  step-by-step procedure, `docs/study/` holds the five bilingual paper documents, the assessment
  screen now carries an **optional case code** so a before/after record can be matched to a paper
  consent form without a name entering the game (`SaveData.sanitise_code`, asserted in
  `smoke_test`), and `tools/study/analyse_export.py` turns exported files into the report's tables
  with no third-party packages. Its `--selftest` pins every statistic against a reference value and
  runs the whole pipeline on clearly-labelled synthetic records; writing it caught a genuine
  Wilcoxon tie-correction bug (the variance was divided by 48 instead of only the tie term).
* **The six education/research documents**, the export and study documents, and this tracker.

---

## Remaining work

### Software
1. **M7 — presentation polish (remaining):** the steam/sizzle/chop/splash feedback is procedural and
   functional, and long actions now carry sustained beds that follow the gesture (see `docs/ROADMAP.md`
   B15), but the set has not had a dedicated audio review and no physical device has rendered this game —
   see the limits list in `docs/RESPONSIVE.md` §7.
2. **M9 — QA & delivery (remaining):** a manual play-through on a real phone or tablet (every
   result so far comes from window resizing on one laptop, and the APK has never been installed),
   and a final review of the interface strings in both languages by a native Thai reader.
   Cold-start launch, the responsive matrix, and the Windows, Web and Android exports are done —
   status and evidence in `docs/EXPORTS.md`.

### Content and study (largest gap)
3. ~~Re-open every source still marked `listed`~~ — **done 2026-10-16.** All eleven sources are
   now `verified`: the seven that were `listed` were opened and their claims checked against the
   source's own words (CDC pages, the WHO Five Keys manual, the Thai DDC press release of
   15 July 2026, the IARC Monographs Volume 100B PDF, the Sripa 2012 abstract via Europe PMC), and
   two wrong URLs were corrected. Log in `docs/REFERENCES.md` §6.
4. **Run the study.** The kit is finished: protocol, forms, instrument, case code and analysis
   tooling all exist. What is missing cannot be produced by software — approvals, signed consent
   and assent, and students in a room. Until that happens, the project and the game both state
   plainly that no learning result has been measured.

### Competition deliverables
5. ~~Chapters 1–5 of the report~~ — **drafted 2026-10-16** in `docs/report/` (chapters 1–5 in
   Thai, abstract/proposal/summary, a numbered reference list, a ≤ 7-minute video script, a
   display-board plan and a logbook template). What still needs a person rather than the code:
   typeset to A4 / TH SarabunPSK 16 pt, insert real screenshots, record the video, build the
   board, and keep the logbook with real dates.

---

## A note on how this project reports progress

Every claim in this tracker is something that was run and observed. Where something has not been
done — most importantly the study — it is marked ⬜ or 🔄 and said plainly, rather than described
as if it were finished. That is deliberate: the competition scores honesty directly, and a
project that over-claims is easier to mark down than one that states its limits precisely.
