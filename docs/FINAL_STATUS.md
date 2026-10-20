# Final Status Summary - Fluke Free Kitchen (Fluke Free Fighters)

**Date:** 2026-10-18 · **Updated:** 2026-10-20 (interface pass)  
**Godot Version:** 4.7.2.stable.official.ed1daf0bf

## Interface and art pass (added this session)

The interface was rebuilt for presence rather than flatness, and two genuine layout bugs
surfaced and were fixed in the process. Everything below is verified by the eight suites
(8/8 PASS, 360 layouts, 0 problems) and by the regenerated captures in
`build/screenshots/visual/` (46) and `build/screenshots/responsive/` (300).

**New drawing, all in code (no external art):**

- `scripts/ui/ui_icon.gd` (`UIIcon`) — a vector icon set drawn from 100 × 100 design
  space: play, book, compass, chef, sparkle, star, flame, fish, knife, pot, drop, search,
  check, cross, arrow, lock, leaf, and the five gesture glyphs (hand, stir, hold, flip,
  tap). Icons are decoration: the word is always beside them, never replaced by them.
- `scripts/ui/ambient_bg.gd` (`AmbientBackground`) — four drifting warm radial glows
  behind the menus, on a click-through layer.
- `DishPreview` now draws a real plate: drop shadow, rim, well, contact shadow, dorsal
  highlight and tail fin, all still driven by the species in `RecipeDB`.
- `KitchenProps.fish` is a proper fish now — head, four tapering body segments, dorsal and
  pectoral fins, a forked tail, gill line and eyes. Flesh parts are tagged `food_surface`
  (so they brown); the gill line and eyes deliberately are not, so a cooked fish stays
  readable.

**Interface system (`UIFactory`):** panel and button style boxes gained drop shadows and a
distinct focus ring; every button answers the pointer with a small scale pulse; screens
stagger their content in on open; new helpers `icon`, `chip`, `hero`, `entrance`,
`tag_row`. Menu mastheads are `hero` (title plus accent bar), the mode screen grew five
drawn emblems, dish cards grew region / real-vs-variation / no-cooking-step capsules, the
instruction bar grew a gesture emblem and a capsule, and the kitchen HUD shows step
progress as dots (the step count is kept beside them).

**Motion is gated, not hidden.** `UIFactory.set_motion_enabled(false)` turns off entrance
and pointer motion for the whole game. `responsive_check`, `visual_capture`, `layout_check`
and `cook_test` call it, because a capture taken three frames after a screen opens would
otherwise record a half-faded page. Entrance animation touches only opacity and scale — never
layout — so measured rectangles and click coordinates are unaffected.

**Two real bugs fixed (causes, not offsets):**

1. *The dish page overflowed a 320 px phone.* Three variable-length Thai capsules in one
   `HBoxContainer` give that row — and so the card, the grid and the page — a minimum width
   of all three laid end to end: **343 px asked, 320 px available** (measured, not guessed).
   The badges now sit in `UIFactory.tag_row()`, a `FlowContainer`, which reports the widest
   single tag and folds the rest onto another line. The page minimum is 316 px.
2. *The instruction bar grew past the screen on a phone.* Putting the emblem, the sentence
   and the gesture capsule in one fixed row squeezed the sentence into a two-word column and
   the bar reached 452 px tall. The narrow layout now keeps the emblem and the words and
   drops the capsule, which repeats what the emblem already says.

The same pass also added `RecipeDB.region_of()`, which maps a recipe id to its documented
region (Central Thai / Northeastern Thai) or to nothing at all — the card shows no capsule
rather than guessing, and no dish claims a region it is not known for.

## Test Results (run_all_tests.ps1)

| Suite | Status | Notes |
|---|---|---|
| smoke_test | ✅ PASS | Core smoke checks |
| anim_test | ✅ PASS | The kitchen motion library: each verb moves a node and leaves it where it belongs, and a missing or loose node is refused |
| flow_test | ✅ PASS | Full level flow |
| behaviour_test | ✅ PASS | Gestures and cooking behaviour |
| cook_test | ✅ PASS | A/B/C outcomes |
| recipe_test | ✅ PASS | Catalogue, generator, v3 save migration with quarantine (its one stderr JSON line is the deliberate corrupt-file case) |
| minigame_test | ✅ PASS | Full generated recipe driven with real pointer input; plate finish race guarded |
| responsive_check | ✅ PASS | 360 layouts across 12 screen sizes, 0 problems |

**Result:** **8/8 suites PASS** (re-run 2026-10-20 from `tools/run_all_tests.ps1`, which now
writes its verdict logs to `build/test_runs/`).

Two test-infrastructure defects were fixed this session so the summary is trustworthy:

1. `tests/minigame_test.gd` drove a stir/plate task that could finish mid-drive and free
   itself; the loop now stops on `watch["finished"]` / a freed task instead of poking it.
2. `tools/run_all_tests.ps1` decided the verdict with a case-insensitive search for
   `FAILED` across the whole output, so `recipe_test`'s *expected* "Parse JSON failed"
   line (the corrupt-save probe) was read as a failure. The verdict now comes from the
   suite's final, case-sensitive `PASSED`/`FAILED` line.

## Responsive layout (fixed this session)

`responsive_check` went from 41 problems to 0 by fixing causes, not by nudging offsets:

- `UIFactory.bottom_box` grows a box to its own content height (never past the screen),
  so a panel shorter than its content can no longer hang off the bottom edge.
- `UIFactory.responsive_grid_size` gained an `inset`, so a button inside a grid *card*
  caps its minimum to the card's inner column instead of the card's full width. Applied to
  the mode cards (`mode_select`), the dish cards (`dish_select`) and the Free Cook
  fish/method grids (`free_cook`).
- The cook/press-and-hold panels now size themselves from their content (the existing
  `content_sheet` machinery) and the cook panel stacks its labels instead of forcing a
  385 px row, so both fit a 320 px phone.
- `responsive_check` no longer measures a page frame or the scroller inside it against the
  window's bottom edge: a page taller than the frame is a scroll bar, not a layout bug.
  Width is still checked against the window everywhere, and real overflow is still caught
  for anything outside a scroller.
- The interface pass above found and fixed two further overflows (a capsule row and the
  instruction bar); the matrix was re-run and is clean again.

The same matrix was re-run with a real window on 2026-10-20 (NVIDIA GPU, Forward+; the first
such run was 2026-10-18), which also writes one PNG per screen per size into
`build/screenshots/responsive/`: **360/360 layouts, 0 problems, 300 screenshots** across the
12 sizes from 320 × 568 to 3840 × 2160. The cooking and screen captures live beside them in
`build/screenshots/cook/` (4) and `build/screenshots/visual/` (46).

## Animation library (added this session)

All of the kitchen short-form motion now comes from one place, `scripts/world/anim.gd`
(class_name `Anim`): the fish turning in the pan, an ingredient settling onto a plate,
the knife crossing the board, a puff of steam rising, a toast fading out. Instead of
each script opening its own tween, the tasks call a small library of verbs, and the
library owns the one rhythm (TAP, NUDGE, SETTLE, POP) the whole kitchen shares.

The library is careful in two ways. A helper returns the tween it started, so a caller
can await it or add a step; and a helper asked to animate a node that is missing, loose
or freed returns nothing at all, so the game can never open a tween on something that is
going away. Every previous hand-rolled tween now goes through it: the carried item and
its lift, the flip arc, the cut and its scraps, the knife crossing the board, snapping
onto a plate, dropping onto a target, the encouragement and correction toasts, the
effect puffs, and the cook reactions.

`tests/anim_test.tscn` (the eighth suite) drives each verb and checks the two things a
player cares about, that it moved and that it ended where it belongs, plus the refusal
contract.

## Sustained audio layers (added this session)

Long actions now sound like long actions. `AudioManager` grew a third kind of
sound beside the one-shot effects and the looping music: **sustained beds** that a
task fades in while the gesture is happening and fades out when it ends. Three of
them — `loop_sizzle` (a pan), `loop_boil` (a pot), `loop_wash` (running water) —
play on their own dedicated players and their own bus, so they layer under the
chop/tap/star cues instead of replacing them.

The point is that the sound follows the gesture, not the step. `HoldTask` reads
`step.vessel` to choose a hiss or a bubble, and calls `play_loop`/`stop_loop` from
`_process` on the same `_holding` flag that drives the heat meter, so the pan
hisses for exactly as long as the player is holding it. `SwipeCleanTask` runs the
water while the player is working the board. Every task clears its own bed in
`_exit_tree`, and leaving a level stops all beds, so a hiss can never outlive the
action that started it. `play_loop` is a no-op when the level is already set, so
calling it once per frame is safe; the muted intent is tracked separately from
the audio device, which is what lets `smoke_test` and `minigame_test` check the
synchronisation under `--headless`.

## Procedural dish composition (added this session)

`RecipeDB.generate_recipe(seed)` / `generate_dish(seed)` compose a new dish from the
same real fish, ingredients and methods, as a pure function of one integer seed. The
composed dish is a runnable challenge in exactly the shape `ChallengeGenerator.build`
produces, so the kitchen runs it like any other — but it is **never** presented as a
traditional dish (`real: false` plus a bilingual `note`), and it is held to the same
`validate` / `validate_steps` before it can be played. `generated_pool(count, seed)`
backs a browse list or a "surprise me" roll. Free Cook grew a picture-first row of
three composed dishes (each drawn with `DishPreview`) and a **Surprise me** button;
`Game.start_generated(seed)` runs one. `recipe_test` now checks 200 consecutive seeds
(every one valid, honest, and with exactly one safe cook step), determinism, and a
six-dish pool.

## Player-made dishes and the personal cookbook (added this session)

The player can now build a dish of their own. `RecipeDB.custom_recipe(...)` composes a
recipe from the **same real catalogue** the rest of the game uses (real fish, ingredients,
methods, garnishes, plating), and `RecipeDB.build_custom(...)` turns it into a runnable
challenge in exactly the shape `ChallengeGenerator.build` produces — so the kitchen runs
it unchanged, and it passes the same `validate` / `validate_steps` as a hand-written
recipe before it can be cooked. It is never dressed up as a traditional dish (`real:
false`, `custom: true`, a bilingual note), and the mandatory safe-cook step is present
exactly as everywhere else.

The creator screen (`custom_cook.gd`, *Create a dish*) has a name field, single-choice
fish/method/plating chips and multi-choice ingredient/garnish chips (capped at 5 and 2),
with a live `DishPreview` and a status line that names the one thing still missing. It can
cook the dish immediately (`Game.start_custom`) or save it. The **personal cookbook**
(`cookbook.gd`, *My Cookbook*, a fourth card on the mode screen) lists saved dishes as
cards with a Cook and a Delete button, and `Game.start_saved` rebuilds a saved dish with
the current rules.

The cookbook is stored in the existing **v3** save file as a new `cookbook` array; the
format is unchanged and still migrates a v2 file in place, because a missing field loads
as an empty list. Only the *composition* is stored (never a step list), and a
hand-edited cookbook entry is sanitised on load — anything without an id, a method and a
fish is dropped, so a malformed file cannot smuggle a broken dish into the kitchen. Saving
a dish unlocks the new *Signature dish* achievement (a real event, not a screen visit).
`recipe_test._check_custom` checks every fish × every method (48 dishes) for validity,
honesty and exactly one safe cook step, the refusals (no name / no ingredient / unknown
fish / too many), order-independent ids, and a real save → reload → remove round-trip
including a malformed-save sanitisation case.

## Discover: a paged browser over the composed pool (added this session)

The composed dishes are now browsable. `explore.gd` (*Discover*, a fifth card on the mode
screen) shows a page of six dishes composed from the same real catalogue and lets the
player ask for more. It composes lazily — a page at a time, only what has been asked for —
and de-duplicates across pages by composition (`RecipeDB.composition_signature`), so
"show me more" never just reshuffles the same handful. Every dish is labelled as a game
creation (never a traditional recipe), is validated, and carries the same mandatory
safe-cook step; "Cook this" runs it through `Game.start_generated`. The loaded dishes are
cached on the instance, so a resize reflows the same page. `recipe_test._check_browse`
checks the signature is stable, order-independent, and that 60 seeds yield at least 40
distinct dishes.

## Expansion Completed

✅ Data-driven catalogue (11 dishes, 8 real recipes + 3 challenge variations)  
✅ Reusable minigame library (14 interaction kinds, real input required)  
✅ Zero-reading tutorial system with teach-once-per-session demo gating  
✅ Character reactions integrated  
✅ Endless challenge generator (seeded, validated, with fallbacks)  
✅ Visual-only quiz integration  
✅ Three modes: Let's Cook, Endless Kitchen, Free Cook (experimental)  
✅ Player recipe creator + personal cookbook (composed from the real catalogue, saved in v3)  
✅ Discover: a paged, picture-first browser over the composed dishes  
✅ Progression/unlocks (≥2 dishes open at start, all 11 reachable)  
✅ v3 save system with v2 migration  
✅ Raycast fix to exclude carried items  
✅ Ingredient visuals & visual_for fix  
✅ Debug prints cleaned from test and plate task  
✅ 8 test suites integrated into run_all_tests.ps1  
✅ Shared animation library (`Anim`) — one rhythm for all kitchen motion  
✅ Sustained audio beds synced to the gesture (fry / boil / wash)  
✅ Windows / Web / Android re-exported and re-verified (2026-10-18; re-exported after the
  interface pass — see `docs/EXPORTS.md`)
✅ Interface and art pass: drawn icon set, ambient background, plate and fish art, shadows,
  staggered entrances, instinct-level pointer feedback, and two real overflow bugs fixed  

**Verified state:** the eight suites at the top of this file pass on `main` (re-run
2026-10-20 after the interface and art pass). The interface/art pass changed game code under
`scripts/`, so the three working exports built from `e6741f3` **no longer match what runs**:
Windows / Web / Android were re-exported and re-verified after this pass — see
`docs/EXPORTS.md` for the build times and the checks that were run against each.

## Known Issues

None open in the automated suites. The remaining real gaps are outside the code (see
below): a native-Thai-speaker review, an on-device Android run, an iOS build, and the
competition paperwork.

## Remaining (optional polish)

- Full manual play-through across all three modes on the demo machine (checklist in `docs/QA_CHECKLIST.md` §2)
- An on-device Android run (the APK builds and verifies but has never been installed)
- A native-Thai-speaker string review

## Conclusion

The CRITICAL GAMEPLAY EXPANSION is functionally complete and **all eight automated suites
pass**. Core gameplay, catalogue, minigames, modes, validation, layout reflow and the save
system are implemented and verified by passing tests.