# Final Report — River Dash: Safe Feast Run

**Project:** `C:\Users\ASUS\river-dash-safe-feast-run`
**Engine:** Godot 4.7.2 stable (GDScript, Forward+)
**Report date:** 2026-10-15
**Status:** Complete and verified. Playable from source **and** as a shipped Windows build.

This report separates what is **implemented**, what is **tested** (with the actual
observed results), and what is **future work**, as required. Nothing here is projected or
assumed; every result was produced by running the delivered files.

---

## 1. Deliverables

| Deliverable | Location | Status |
| --- | --- | --- |
| Full Godot project | project root (46 `.gd` files, 8,557 lines; 1 shader; 6 scenes) | ✅ |
| `README.md` — exact run + export instructions | `README.md` | ✅ |
| Game design document | `docs/GAME_DESIGN.md` | ✅ |
| Health content + sources (review record) | `docs/HEALTH_CONTENT_SOURCES.md` | ✅ |
| Testing guide + results | `docs/TESTING.md` | ✅ |
| Placeholder-asset list + replacement hooks | `docs/PLACEHOLDER_ASSETS.md` | ✅ |
| Automated test suites | `tests/smoke_test.tscn`, `tests/runner.tscn`, `tests/flow_test.tscn` | ✅ |
| Windows builds | `build\RiverDash.exe` (debug), `build\RiverDash.console.exe`, `build\RiverDash-release.exe` | ✅ |

---

## 2. Implemented

### 2.1 Core run

* **Three-lane endless runner** with an auto-forward speed that ramps from 10 m/s to a
  per-difficulty ceiling (14 / 18 / 23 m/s), hard-clamped at 26 m/s overall.
* **Jump** (≈2 m apex, 0.12 s lockout, coyote time) and **slide** (0.7 s, collider drops
  1.7 m → 0.8 m). Neither can be re-triggered while already active.
* **3-point safety buffer** instead of a fear-based health bar. A hit costs one point,
  slows the runner briefly and breaks the combo; a **Sanitation Shield** absorbs it
  instead. Safety empty → the run ends and the score freezes.
* **Lane changes are clamped, not queued** — holding left at lane 0 does nothing.

### 2.2 The three required obstacles — one hazard, one verb

Volumes are chosen so exactly one avoidance verb works; no special-casing in code.

| Hazard | Volume | Verb |
| --- | --- | --- |
| Raw freshwater fish dish | 0 – 2.4 m | **change lane** (can't jump 2.4 m, can't slide under it) |
| Cross-contaminated chopping board | 0 – 0.7 m | **jump** (it starts at the ground) |
| Unsanitary wastewater curtain | 0.95 – 2.4 m | **slide** (0.8 m clears it; jumping goes into it) |

### 2.3 Power-ups and collectibles

* **Safe Cooking Flame** — live raw-fish hazards become safe cooked bonuses (+100 each);
  they revert when the flame expires. Only raw-fish hazards convert.
* **Sanitation Shield** — 3 charges or 20 s; absorbs a hit without costing safety;
  re-collecting refills to 3, never stacks to 6.
* **Medical Treatment Boost** — +4 m/s for 6 s and clears any slowdown.
* **Latrine Builder Tokens** — 3 tokens build a latrine beside the track and fire the
  sanitation event **exactly once**, then the counter resets.
* Same-kind power-ups refresh their timer; different kinds overlap independently.

### 2.4 Biomes and the endless course

* **Three Thai biomes cycling forever**, 800 m each: **Riverbank → Night Market →
  Village Health Center**, each changing sky, sun, fog, music, ambience, scenery and a
  banner title.
* **Recycled segment pool** of 8 × 60 m segments, rebuilt ahead of the runner and
  recycled 45 m behind. Reuse from the free list keeps the track contiguous by
  construction.
* **Guard-railed generation:** the pure planner (`segment_planner.gd`) can block one or
  two of the three lanes per row but **never all three**, enforces ≥ 16 m (and
  ≥ 1.15 s of reaction time) between rows, and keeps obstacles 4 m clear of segment
  edges. It is a pure function, so it is directly unit-testable.
* **Procedural scenery** per biome: stilt houses, piers, rice fields, grass and pebble
  fields, market stalls, produce crates, lantern strings, noodle carts, clinic
  buildings, hand-wash stations, info boards and signs.

### 2.5 Checkpoints

* Every **1000 m**, alternating **Kitchen Sizzle Station** and **Village Health Centre**,
  with the gate spawned 36 m ahead so it is visible on approach.
* **Kitchen**: a temperature-gauge mini-game — hold heat (Space/Enter, gamepad A or left
  mouse button) and release inside the target band (62–78 of 100) for success. The panel
  states plainly that the gauge is a game abstraction, not a validated temperature.
* **Clinic**: a screening *conversation* (nurse dialogue, a possible stool test) that
  never shows an X-ray and never produces a fictional diagnosis.
* **Cannot re-trigger:** the gate is single-use *and* the milestone index is monotonic.
  Only a new run resets it.

### 2.6 Scoring

Distance 1 pt per whole metre; collectible 50; safe-cooked 100; checkpoint 250 flat;
kitchen success 300; latrine event 400. Combo += 1 per clean pass, +1 multiplier level
per 4 combo, capped at ×5; a hit breaks it. Whole-metre crediting and `maxf(0, …)`
distance prevent jitter/reverse farming, and scoring is gated on the run being active, so
game-over genuinely freezes the score.

### 2.7 Screens, settings and persistence

Main menu, How to Play (with a procedural lane diagram and a Relaxed practice run),
Health Facts, in-run HUD, pause menu, checkpoint panel, game-over screen, and a settings
overlay shared by the menu and the pause menu.

Settings: master/music/SFX volume, camera smoothing (0.25–2.5, actually changes the
camera feel), screen-shake toggle, fullscreen, five resolutions, quality low/medium/high
(queued mid-run to avoid a hitch), language EN/ไทย, difficulty Relaxed/Standard/
Challenging. Settings and personal progress persist in two versioned JSON files with
atomic-ish writes and corrupt-file quarantine.

### 2.8 Health content

**14 reviewed entries** in `scripts/data/education_data.gd`, covering the **8 required
myth-buster topics** plus screening and diagnosis framing, each with a citation, source
title, URL, last-reviewed date and review status. Only WHO, US CDC, NIH/NCBI and
Thailand's DDC are cited, and the permitted hosts are **enforced in code** — the smoke
test fails if any entry cites an unapproved host or a non-`https` URL.

Accurate nuances deliberately preserved in the copy: not all fish are infected; no single
temperature guarantees safety for every species; a dirty pipe is not automatically full
of flukes; one toilet does not instantly remove every egg; treatment is medically
supervised only.

### 2.9 Presentation

100 % procedural **art** (code-generated deterministic noise textures + primitive props)
and 100 % procedural **audio** (every SFX, music bed and ambience synthesised into an
`AudioStreamWAV` at startup on Master/Music/SFX buses), a code-driven water shader, a
rigged procedural avatar with run/jump/slide/stumble animation, and a single bundled
**Sarabun** font (OFL). There are **no paid assets or plugins**.

### 2.10 Architecture

Exactly six autoloads (`Settings`, `SaveData`, `Education`, `AudioManager`,
`InputManager`, `Game`); everything else is a named class instantiated by its owner.
Typed GDScript throughout; signals instead of scene-tree path lookups; dependency
injection instead of globals for gameplay systems; named collision-layer constants;
`get_tree().paused` for pause with gameplay pausable and UI/autoloads always-on; seeded
RNG for reproducible runs; and only three hand-authored game scenes (obstacles,
collectibles, gates and scenery are all built in code).

---

## 3. Tested — with observed results

Three automated suites, each returning a non-zero exit code on failure. Commands in
`docs/TESTING.md § 1`.

| Check | Observed result |
| --- | --- |
| Import from a clean copy (no `.godot/`) | exit 0, no errors |
| `smoke_test.tscn` | `SMOKE TEST PASSED`, exit 0 — 6 autoloads boot, **14 education entries all valid**, audio streams generated |
| `runner.tscn --fixed-fps 60` | **`checks run: 194` / `ALL TESTS PASSED`**, exit 0, **no leaked instances** |
| `flow_test.tscn --fixed-fps 60` (headless) | `FLOW TEST PASSED`, exit 0 |
| `flow_test.tscn` on the real renderer (Vulkan) | `FLOW TEST PASSED`, exit 0, no leaked instances |
| `game.tscn --quit-after 240` on the real renderer | exit 0, 240 frames, no shader or script errors |
| Main menu on the real renderer | exit 0 |
| Clean-directory launch (fresh copy, no `.godot/`) | `SMOKE TEST PASSED` + `FLOW TEST PASSED` |
| `--export-debug "Windows Desktop"` | exit 0 → `RiverDash.exe` ≈ 99 MB (self-contained, embedded `.pck`) + console wrapper |
| `--export-release "Windows Desktop"` | exit 0 → `RiverDash-release.exe` ≈ 105 MB |
| Exported debug build, headless | exit 0 |
| Exported release build, headless | exit 0 |

### All 18 required behaviours are covered

| # | Behaviour | Test |
| --- | --- | --- |
| 1 | Lane bounds | `_test_lane_bounds` |
| 2 | Jump / slide termination | `_test_jump_slide_termination` |
| 3 | No repeated collision counts | `_test_obstacle_single_hit` |
| 4 | Score (incl. combo cap, no jitter farming) | `_test_scoring_rules` |
| 5 | Save persistence | `_test_save_persistence` |
| 6 | No double collect | `_test_no_double_collect` |
| 7 | Power-up expiry / refresh | `_test_powerup_expiry` |
| 8 | Shield rules | `_test_shield_rules` |
| 9 | 3-token event exactly once | `_test_latrine_event_exactly_once` |
| 10 | Difficulty limits | `_test_difficulty_limits` |
| 11 | Segment recycling gaps | `_test_segment_recycling` |
| 12 | Impossible patterns | `_test_planner_generation` + `_test_planner_rejection` |
| 13 | Pause freezes | `_test_pause_freezes` + `flow_test._test_pause_and_resume` |
| 14 | Restart resets run data, keeps progress | `_test_restart_keeps_progress` + `flow_test._test_game_over_then_restart` |
| 15 | Game-over blocks score | `_test_game_over_blocks_score` |
| 16 | Clean-directory launch | `_test_clean_launch_and_missing_assets` + clean-copy run + exported build |
| 17 | Missing optional assets don't crash | `_test_clean_launch_and_missing_assets` (+ water-shader fallback path) |
| 18 | Checkpoints can't re-trigger without a new run | `_test_checkpoint_cannot_retrigger` |

Behaviours 2, 3, 6 and 13 use **real physics** (`Area3D` overlaps and `move_and_slide()`
against real `StaticBody3D` ground), not mocks. The full mapping, including what each
assertion checks, is in `docs/TESTING.md § 4`; the suite's known limits are in § 6.

---

## 4. Future work / not done

Being explicit about the boundary of "done":

| Item | Notes |
| --- | --- |
| **Thai localisation** | Headlines and bodies for the eight core topics, both checkpoint messages and several other entries are translated; tutorial and menu prose are still English. Thai strings are stored per entry and fall back to English. |
| **Real art and audio** | Everything is high-quality procedural placeholder. `docs/PLACEHOLDER_ASSETS.md` gives the exact hook for each category (`GameMaterials._build()`, `AudioManager._load_overrides()`, the prop builders, `player_visual.gd`). |
| **Android / iOS builds** | Deliberately prepared but not built: all input is named actions, touch swipes already synthesise them, and the renderer/preset keep mobile texture formats available. Missing: on-screen touch controls and the export presets. |
| **Cosmetics / leaderboards / run history** | `SaveData.unlocked_cosmetics` is persisted but unused; `SaveData.record_run()` already returns a before/after diff a history UI could use. |
| **In-game debug overlay** | `Game.debug_overlay` and the F3 toggle drive physics debug drawing; a proper stats overlay is not built. |
| **Automated visual/audio verification** | Not possible headless. The scene was launched on the real Vulkan renderer to prove it initialises and runs without shader errors, but "does it look and sound good?" needs a human. |
| **Long-session soak test** | Recycling is verified at 3,000 m; a multi-hour soak was not run. |
| **Save-corruption test** | The quarantine path exists and was read, but no test injects a corrupt file. |

---

## 5. Known issues and caveats

1. **Export templates had to be installed manually.** The `%APPDATA%\Godot\export_templates\4.7.2.stable\`
   folder was empty, so the 1.28 GB `.tpz` was downloaded and extracted there
   (`windows_debug_x86_64.exe` and `windows_release_x86_64.exe` are now present). The
   one-time procedure is documented in `README.md § 6`. No work was blocked by this.
2. **Headless audio playback is intentionally disabled.** The dummy audio driver never
   releases its `AudioStreamPlaybackWAV` objects, which the engine reports as leaked
   instances at exit and would mask a real leak. `AudioManager.playback_enabled` is false
   only when `DisplayServer.get_name() == "headless"`; stream generation, name lookup and
   bus setup are still fully exercised, and audio is verified for real by the windowed
   runs.
3. **Force-quitting a non-headless run while music plays** can print a benign
   `ObjectDB instances were leaked` warning (an engine teardown artifact of
   `--quit-after`). The in-game Quit button goes through `Game.quit_game()`, which
   silences audio first — the windowed flow test exits with no leak warning.
4. **Exported binary sizes vary by a few hundred bytes** between exports (the build
   embeds a timestamp/engine hash). `docs/TESTING.md` therefore quotes approximate sizes.
5. **`build/` is git-ignored** but the binaries are present on disk. No git repository was
   initialised and no commits were made; all work is uncommitted files on disk.

---

## 6. Verify it yourself in five minutes

```powershell
$godot = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe"
$proj  = "C:\Users\ASUS\river-dash-safe-feast-run"

& $godot --headless --path $proj res://tests/smoke_test.tscn
& $godot --headless --path $proj res://tests/runner.tscn --fixed-fps 60
& $godot --headless --path $proj res://tests/flow_test.tscn --fixed-fps 60
```

Expect `SMOKE TEST PASSED`, `checks run: 194 / ALL TESTS PASSED`, and `FLOW TEST PASSED`,
all with exit code 0. Then play the shipped build:

```powershell
& "$proj\build\RiverDash.exe"
```

`docs/TESTING.md § 7` has a nine-step manual checklist for a human reviewer.
