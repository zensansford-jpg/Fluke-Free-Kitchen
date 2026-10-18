# Roadmap — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)
**Updated:** 2026-10-17 · **Owner split:** 🤖 = doable with code in this environment · 👤 = needs a person (device, recording, language review) · ⛔ = blocked by environment/ethics

This is the single consolidated plan for everything that is **not** finished, plus the proof for
everything that is. It exists so that no requirement silently disappears and no untested thing is
called done. Update the status column as items close; keep the evidence column honest.

**Repeatable commands**

```powershell
# every test suite in one line, prints PASS/FAIL per suite
powershell -ExecutionPolicy Bypass -File tools\run_all_tests.ps1

# the study data pipeline (no real data needed)
python tools\study\analyse_export.py --selftest
```

---

## 1. Status legend

| Mark | Meaning |
|------|---------|
| ✅ PASS | Ran and reported; evidence recorded |
| 🟡 PARTIAL | Some part exists/runs, some part does not |
| ❌ NOT DONE | Not started or not produced |
| ⛔ BLOCKED | Cannot be done in this environment; reason given |
| 👤 HUMAN | Requires a person/device/approval, not software |

---

## 2. Baseline as of 2026-10-18 (verified this session)

| Check | Result | Evidence |
|-------|--------|----------|
| All 8 Godot test suites | ✅ **8/8 PASS** | `tools/run_all_tests.ps1`: smoke, anim, flow, behaviour, cook, recipe, minigame, responsive all PASSED |
| Responsive layout matrix | ✅ **360/360 layouts, 0 problems** | `tests/responsive_check.gd`: 12 sizes × 10 menu screens + settings modal + 3 kitchens + full recipe walk + filled creator and filled cookbook |
| Recipe catalogue (data-driven) | ✅ **11 dishes, 27 ingredients, 8 recipes + 3 challenge variations** | `scripts/data/recipe_data.gd` - validation via `validate_steps`, unlock graph with ≥2 dishes open at start |
| Procedural dish composition | ✅ **Implemented + tested (200 seeds)** | `RecipeDB.generate_recipe(seed)` / `generate_dish(seed)` / `generated_pool(count, seed)`; every composed dish is validated, labelled a game creation, and carries exactly one safe-cook step; surfaced in Free Cook as a picture-first row + "Surprise me" (`Game.start_generated`); `recipe_test` checks 200 seeds, determinism and a 6-dish pool |
| Player dish creator + personal cookbook | ✅ **Implemented + tested** | `RecipeDB.custom_recipe` / `build_custom` (same catalogue, same validator); `scripts/ui/custom_cook.gd`, `scripts/ui/cookbook.gd`; `Game.start_custom` / `start_saved`; cookbook persisted in the existing v3 file (`cookbook` array, sanitised on load); *Signature dish* achievement; `recipe_test._check_custom` covers 48 fish×method dishes, refusals, order-independent ids and a real save/reload/remove round-trip |
| Discover browser (paged) | ✅ **Implemented + tested** | `scripts/ui/explore.gd` composes pages lazily over `RecipeDB.generate_dish`, de-duplicates by `composition_signature` across pages, and runs a dish with `Game.start_generated`; `recipe_test._check_browse` checks the signature is stable, order-independent and that 60 seeds give 40+ distinct dishes |
| Animation library (one vocabulary for all motion) | ✅ **Implemented + tested** | `scripts/world/anim.gd` — static verbs (move/scale/settle/hop/flip/pop/drift/toast) with one shared rhythm; used by the carried item, the minigames, the toasts, the effect puffs and the cook reactions; `tests/anim_test.tscn` is the eighth suite |
| Minigame library (14 interaction kinds wired) | ✅ **Implemented** | `scripts/tasks/task_slice.gd`, `task_stir.gd`, `task_flip.gd`, `task_plate.gd`, `task_serve.gd`, `task_factory.gd` with gesture hints; character reactions integrated |
| Three modes (Let's Cook, Endless Kitchen, Free Cook) | ✅ **Implemented** | `scenes/main/mode_select.tscn`, `dish_select.tscn`, `free_cook.tscn`, `dish_preview.tscn`; `scripts/ui/*.gd`; Free Cook clearly marked experimental |
| Endless challenge generator (validated) | ✅ **Implemented** | `scripts/data/challenge_generator.gd` uses shared `RecipeDB.validate_steps`; seeded deterministic with fallbacks |
| Save system (v3) with migration | ✅ **v3 schema, v2 migration quarantined** | `autoload/save_manager.gd` - migrations, recipes/endless/favourites/recent/free_cook_runs/achievements, `record_endless` |
| Study data pipeline | ✅ **SELFTEST PASSED** | `analyse_export.py --selftest` (statistics pinned, synthetic data, empty-folder guard) |
| Windows export present | ✅ 104.605 MB | `build/FlukeFreeKitchen.exe` |
| Web export present | ✅ wasm 37.684 MB, pck 0.399 MB, js 0.267 MB | `build/web/` |
| Android export present + signed | ✅ 55.349 MB, `apksigner verify` v2+v3 true, 1 signer | `build/android/FlukeFreeKitchen.apk` |
| All 11 health sources verified | ✅ | `docs/REFERENCES.md` §6 |

---

## 3. Workstreams

### A. CRITICAL GAMEPLAY EXPANSION (🤖) - Core Deliverables

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| A1 | Data-driven dish catalogue (infinite-data-driven, not fabricated assets) | ✅ PASS | `scripts/data/recipe_data.gd` - 8 fish + 1 colour variant, 27 ingredients, 6 methods, 7 garnishes, 5 plating styles, 8 real recipes + 3 challenge variations; `build_steps`, `build_free_cook`, validation, unlocks; **plus `generate_recipe`/`generate_dish`/`generated_pool` — procedural dishes composed from the same real data and held to the same validator** |
| A2 | Reusable minigame library (14 interaction kinds) | ✅ PASS | All task types wired via `task_factory.gd`; gesture hints; requires real input (verified in `minigame_test`) |
| A3 | Zero-reading tutorials (teach-once-per-session demo gating) | ✅ PASS | `scripts/tasks/task_base.gd` gains `is_accepting_input()` and session-taught demo gating (teach-once-per-session) to reduce friction in Endless Kitchen |
| A4 | Character reactions to real actions | ✅ PASS | `scripts/world/kitchen_character.gd` + `scripts/world/kitchen_scene.gd`.react() integrated |
| A5 | Endless challenge generator (validated, seeded, with fallbacks) | ✅ PASS | `challenge_generator.gd` uses `RecipeDB.validate_steps`; deterministic across seeds; history/fallbacks; thin pools handled |
| A6 | Visual-only quizzes | ✅ PASS | Integrated in KitchenScreen result flow; mode-aware quiz helpers |
| A7 | Progression/unlocks/records | ✅ PASS | Unlock graph updated so ≥2 dishes open at start, all 11 dishes reachable; `save_manager.gd` tracks recipes/endless/favourites/recent/free_cook_runs/achievements/records |
| A8 | Three modes: Let's Cook, Endless Kitchen, Free Cook (Free Cook clearly experimental) | ✅ PASS | Dedicated fish+method picker for Free Cook; cooking visuals driven by `browning` separate from safety logic; mode branching in `KitchenScreen` |
| A9 | Demonstrate every minigame requires real input | ✅ PASS | `minigame_test` executes full generated recipe with real pointer events; validates "wrong gesture does not finish", "correct gesture finishes"; exercises all interactions |

### B. Code Quality & Polish (🤖)

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| B1 | Raycast fix to exclude carried InteractiveItem from drop zones | ✅ PASS | `kitchen_scene.gd.raycast_pointer` accepts `exclude_rids`; `task_plate.gd` and `task_drag_to.gd` exclude carried item during drop raycasts (updated to use Area3D check) |
| B2 | Ingredient visuals & visual_for fix | ✅ PASS | `kitchen_props.gd`: `ingredient_mound`, `ingredient_visual`; fixed `visual_for` default crate leak (returns live node) |
| B3 | Clean debug prints from minigame_test.gd and task_plate.gd | ✅ PASS | Debug diagnostics removed from test and plate task; code cleaned |
| B4 | Run all 8 test suites end-to-end | ✅ PASS | `tools/run_all_tests.ps1`: 8/8 PASS (`smoke`, `anim`, `flow`, `behaviour`, `cook`, `recipe`, `minigame`, `responsive`) |
| B5 | Responsive matrix (12 sizes × 7 menu screens + 3 kitchens + recipe walk) | ✅ PASS | `responsive_check` PASSED, 360 layouts, 0 problems. Root-cause fixes: `bottom_box` content-height guard; `responsive_grid_size(..., inset)` for grid-card buttons (`mode_select`, `dish_select`, `free_cook`); cook/hold panels content-fitted and stacked |
| B6 | Re-export builds (Windows/Web/Android) | ❌ NOT DONE | Existing builds present; re-export after fixes recommended but not completed |
| B7 | Full end-to-end play-through across all three modes | 🟡 PARTIAL | Core logic verified via tests (smoke/flow/cook/recipe/minigame integration); manual full play-through not completed in this session |
| B8 | Update documentation with honest status | ✅ PASS | Updated ROADMAP.md, QA_CHECKLIST.md and FINAL_STATUS.md this session to reflect 8/8 PASS |
| B9 | Commit expansion if all tests pass | ✅ PASS | Committed once all eight suites were green (`Green the suite: responsive layout, cook/hold panels, test-infra fixes`) |
| B11 | Procedural dish composition (build + validate + surface + test) | ✅ PASS | `RecipeDB.generate_recipe`/`generate_dish`/`generated_pool`; `Game.start_generated`; Free Cook composed-dish row + "Surprise me"; `recipe_test._check_generated` (200 seeds, determinism, pool) |
| B12 | Player dish creator + personal cookbook (build + validate + persist + test) | ✅ PASS | `RecipeDB.custom_recipe`/`build_custom`; `scripts/ui/custom_cook.gd` + `cookbook.gd` + scenes; `Game.start_custom`/`start_saved`; `cookbook` array in the v3 save (sanitised on load, compositions only); *Signature dish* achievement; `recipe_test._check_custom` (48 fish×method dishes, refusals, order-independent ids, save/reload/remove, malformed-save case); `responsive_check` gained filled creator + filled cookbook |
| B13 | Discover browser over the composed pool (paged + de-duplicated + test) | ✅ PASS | `scripts/ui/explore.gd` + scene + `State.EXPLORE`; lazy page composition, `RecipeDB.composition_signature` de-dup, `Game.start_generated`; `recipe_test._check_browse`; `responsive_check` gained the explore screen |
| B10 | Test-infrastructure fixes (minigame drive-loop race; orchestrator verdict case bug) | ✅ PASS | `minigame_test` guards on `watch["finished"]`/freed task; `run_all_tests.ps1` verdict now the final case-sensitive `PASSED`/`FAILED` line |
| B14 | Animation library (one shared vocabulary for motion) | ✅ PASS | `scripts/world/anim.gd`; every hand-rolled tween replaced (carried item, flip, cut/scraps, knife, plate snap, drag-to, toasts, puffs, cook reactions); `tests/anim_test` added as the eighth suite |

### C. Baseline Feature Completeness vs Original Brief

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| C1 | Outcome A — safe dish | ✅ PASS | `flow_test` completes every level; cook passes at ~8.7 s |
| C2 | Outcome C — burnt/overcooked + quick retry | ✅ PASS | `cook_test` (burnt → retry → fresh fish, mistake kept) |
| C3 | Outcome B — unsafe serving: non-graphic, distinguishes exposure risk from infection | ✅ PASS | `cook_test` ("outcome B: an unsafe serving ended the step and was recoverable") |
| C4 | Progressive cooking visuals raw→golden→burnt, separate from safety logic | ✅ PASS | `cook_test`; `KitchenScene.set_fish_browning`, `_update_cook_ui` |
| C5 | Save/load v2 validated, corrupt-file handling, atomic write | ✅ PASS | `smoke_test`, `recipe_test` validates save v2 migration, corrupt/quarantine handling |
| C6 | Thai/English parity | 🟡 PARTIAL | Implemented throughout; full native-speaker review still 👤 |

### D. Platform & Export

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| D1 | Windows | ✅ PASS | Existing build at `build/FlukeFreeKitchen.exe` |
| D2 | Web (single-threaded, static host) | ✅ PASS | Existing build; needs re-verification after changes |
| D3 | Android build/sign | ✅ PASS | Existing APK verified; needs re-verification after changes |
| D4 | Android runtime on hardware | ⛔ BLOCKED | No physical device/emulator available for runtime smoke (APK statically validated only) |
| D5 | iOS | ⛔ BLOCKED | Needs macOS + Xcode (BLOCKED) |

### E. Study & Ethics

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| E1 | Instrument, forms, protocol, analysis tool | ✅ PASS | `docs/study/`, `docs/STUDY_PROTOCOL.md`, `tools/study/` |
| E2 | Ethics approval, consent, assent | ⛔ BLOCKED | Must precede any data collection; not obtained |
| E3 | Collected data + Chapter 4 results | ❌ NOT DONE | Marked placeholders in `docs/report/ch4_results.md` §4.5. **Never fabricate** |
| E4 | Learning-outcome study with participants | ⛔ BLOCKED | No ethics approval, consent/assent, or participant data collection (must obtain approvals **before** running any study) |
| E5 | Localization/review | 👤 HUMAN | Native-Thai-speaker review of both languages pending |

### F. Competition Deliverables

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| F1 | Report chapters 1–5 (Thai) | 🟡 DRAFTED | `docs/report/ch1…ch5`; needs typesetting to A4/TH SarabunPSK 16 pt, real screenshots |
| F2 | Abstract / proposal / summary | 🟡 DRAFTED | `docs/report/00_abstract_and_proposal.md` |
| F3 | References list | ✅ READY | `docs/report/references.md` |
| F4 | ≤ 7-min video | 🟡 SCRIPTED | `docs/report/video_script.md`; not recorded |
| F5 | Display board (150 cm) | 🟡 PLANNED | `docs/report/board_layout.md`; not built |
| F6 | Logbook | 🟡 TEMPLATE | `docs/report/logbook.md`; keep with real dates |
| F7 | Registration / oral script | ❌ NOT DONE | By the team |
| F8 | Clean re-export on another machine | 👤 OPTIONAL | Optional verification |

---

## 4. Immediate Next Steps (Priority Order)

Based on the expansion session, the immediate priorities are:

1. **Test suite green** (🤖) - Done: **8/8 PASS**, including `minigame_test` and `responsive_check` (360 layouts).
2. **Responsive matrix verification** (🤖) - Done: 0 problems; fixes were root-cause (layout primitives), not per-screen offsets.
3. **Re-export builds** (🤖) - Existing builds present; re-export after fixes optional.
4. **Full end-to-end play-through** (🤖) - Core validated via tests; manual play-through recommended.
5. **Update documentation** (🤖) - Done (ROADMAP.md, QA_CHECKLIST.md, FINAL_STATUS.md).
6. **Commit expansion** (🤖) - Done: two commits (`Green the suite…`, `Add procedural dish composition…`); working tree clean.
7. **Rebuild mandate, remaining slices** (🤖) - Done: procedural dish composition + validation (Free Cook); the player recipe creator + personal cookbook (same real catalogue, saved in the existing v3 file, sanitised on load); and the paged Discover browser over the composed pool (lazy pages, de-duplicated by composition). Still open: an animation-library overhaul, audio layering, and mission-first UI removal.

---

## 5. Definition of done (per workstream)

| Workstream | Done when |
|-----------|-----------|
| A (Expansion) | All catalogue items, minigames, modes implemented and validated by tests; `minigame_test` passes with real input; generator deterministic; unlocks correct |
| B (Quality) | No debug prints; all 8 test suites PASS; responsive matrix clean; exports re-verified; full play-through completed |
| C (Baseline) | All three outcomes A/B/C covered; save v3 + migration tested; core functionality preserved |
| D (Platform) | Windows/Web/Android re-exported and verified; iOS/macOS blocked as documented |
| E (Study) | Ethics approved BEFORE any data collection (BLOCKED - must not proceed without approval) |
| F (Competition) | All deliverables prepared with real content (screenshots from verified builds, real dates, etc.) |
