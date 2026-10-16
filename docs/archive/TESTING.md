# Testing — River Dash: Safe Feast Run

Three automated suites plus one manual smoke check. All automated suites are headless,
print a machine-readable verdict and **return a non-zero exit code on failure**, so they
can be wired into CI unchanged.

```powershell
$godot = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe"
$proj  = "C:\Users\ASUS\river-dash-safe-feast-run"
```

> **Always use the `_console.exe` binary.** The windowed executable does not attach a
> console on Windows and you will not see the output.

---

## 1. Running everything

```powershell
# 0. Import the project (needed once after a fresh clone, and after adding files)
& $godot --headless --path $proj --import

# 1. Smoke test — autoloads boot, the education database validates, audio generates
& $godot --headless --path $proj res://tests/smoke_test.tscn

# 2. Behaviour suite — the 18 required behaviours
& $godot --headless --path $proj res://tests/runner.tscn --fixed-fps 60

# 3. Scene-flow test — menu -> run -> pause -> game over -> restart -> menu
& $godot --headless --path $proj res://tests/flow_test.tscn --fixed-fps 60
```

### Why `--fixed-fps 60`

Godot's main loop derives the physics step count from wall-clock time. In a headless run
that is non-deterministic, which would make every timing-dependent assertion (slide
duration, power-up expiry, jump apex, "the runner is frozen while paused") flaky.
`--fixed-fps 60` forces exactly one 1/60 s step per frame, so 60 frames is exactly one
simulated second. Tests that assert on simulation time therefore measure frames and
assume `--fixed-fps 60`.

---

## 2. Expected output

### `smoke_test.tscn` — exit 0

```
--- River Dash smoke test ---
  autoload ok: Settings
  autoload ok: SaveData
  autoload ok: Education
  autoload ok: AudioManager
  autoload ok: InputManager
  autoload ok: Game
  education database: 14 entries, all valid
  audio: procedural streams generated
  settings: difficulty=standard lang=en quality=medium
SMOKE TEST PASSED
```

### `runner.tscn --fixed-fps 60` — exit 0

```
=== River Dash automated tests ===

--- results ---
checks run: 194
ALL TESTS PASSED
```

Failures are printed one per line as `  ✗ [test name] message`, and the exit code
becomes 1.

### `flow_test.tscn --fixed-fps 60` — exit 0

```
=== River Dash scene-flow test ===

--- results ---
FLOW TEST PASSED
```

---

## 3. Results as recorded for this delivery

| Suite | Command | Verified result |
| --- | --- | --- |
| Import | `--headless --import` | exit 0, no errors |
| Smoke test | `res://tests/smoke_test.tscn` | `SMOKE TEST PASSED`, exit 0 |
| Behaviour suite | `res://tests/runner.tscn --fixed-fps 60` | `checks run: 194`, `ALL TESTS PASSED`, exit 0, **no leaked instances** |
| Scene-flow test (headless) | `res://tests/flow_test.tscn --fixed-fps 60` | `FLOW TEST PASSED`, exit 0 |
| Scene-flow test (real window + Vulkan) | `res://tests/flow_test.tscn --fixed-fps 60` (no `--headless`) | `FLOW TEST PASSED`, exit 0, no leaked instances |
| Game scene, real renderer | `res://scenes/main/game.tscn --quit-after 240` | exit 0, 240 frames, no shader/script errors |
| Clean-directory launch | fresh copy of the project with no `.godot/` → `--headless --import` → `smoke_test.tscn` + `flow_test.tscn` | import 0 errors; `SMOKE TEST PASSED`; `FLOW TEST PASSED` |
| Main menu, real renderer | `--quit-after 180` | exit 0 |
| Windows export (debug) | `--export-debug "Windows Desktop" build\RiverDash.exe` | exit 0 → `RiverDash.exe` ≈ 99 MB (single file, embedded `.pck`) + `RiverDash.console.exe` ≈ 185 KB |
| Windows export (release) | `--export-release "Windows Desktop" build\RiverDash-release.exe` | exit 0 → `RiverDash-release.exe` ≈ 105 MB (no console wrapper, as expected) |
| Exported debug build, headless | `build\RiverDash.console.exe --headless --quit-after 200` | exit 0 |
| Exported release build, headless | `build\RiverDash-release.exe --headless --quit-after 200` | exit 0 |
| Exported build, real window | `build\RiverDash.console.exe --quit-after 150` | exit 0, Vulkan, no errors |

Everything above was run on this machine against the delivered files. Nothing in this
document is projected or assumed.

---

## 4. The 18 required behaviours → tests

Suite 2 (`tests/runner.gd`) is organised as one function per behaviour. Suite 3
(`tests/flow_test.gd`) covers the front-end path that unit tests cannot.

| # | Required behaviour | Test | What is actually asserted |
| --- | --- | --- | --- |
| 1 | **Lane bounds** | `_test_lane_bounds` | lane x = −2.4 / 0 / +2.4; `lane_x` and `lane_index_from_x` clamp; 20 presses left from lane 0 stay at 0 and `request_lane` returns −1 for every one of them, i.e. no queued moves |
| 2 | **Jump/slide termination** | `_test_jump_slide_termination` | the runner settles on the ground; jump starts once and cannot re-trigger mid-air; `is_airborne()` is true 12 frames later and the body gains > 0.2 m; it lands, is grounded, is no longer airborne and returns below 0.35 m; slide starts once, lowers the capsule to 0.8 m, and ends after `SLIDE_DURATION`, restoring 1.7 m |
| 3 | **No repeated collision counts** | `_test_obstacle_single_hit` | running a real physics overlap into a board emits `hit_player` **exactly once**, does **not** also emit `passed`, and the obstacle reports `is_done()` |
| 4 | **Score** | `_test_scoring_rules` | 1 pt/whole metre (5 m → 5); collectible = 50; safe cooking = 100; checkpoint = 250 and increments the run stat; 4 clean passes → ×2; 60 more passes stay at the cap (≤ 5); a bonus uses the multiplier (10 × 5 = 50); a hit breaks the combo back to ×1 |
| 5 | **Save persistence** | `_test_save_persistence` | values are written, `save_v1.json` exists, the in-memory values are zeroed, `load_progress()` restores `best_score` / `total_runs` / `longest_distance` exactly, and no load error is reported. Original values are restored afterwards |
| 6 | **No double collect** | `_test_no_double_collect` | a real physics pickup emits `collected` once and frees itself; calling the overlap handler twice in one frame still emits once |
| 7 | **Power-up expiry** | `_test_powerup_expiry` | the flame is active, still active before its shortened duration elapses, inactive after; the treatment boost sets a positive speed bonus and the expiry clears it to exactly 0; re-collecting the shield refills to 3 charges rather than stacking |
| 8 | **Shield rules** | `_test_shield_rules` | a shielded hit is processed, absorbed, costs no safety and consumes exactly one charge; draining via the public charge API depletes to 0 and further consumption returns false; after the invulnerability window a real hit is not absorbed and costs exactly one safety |
| 9 | **3-token event exactly once** | `_test_latrine_event_exactly_once` | 3 tokens fire exactly one event and reset the counter to 0; 3 more fire exactly one more; 2 tokens fire nothing |
| 10 | **Difficulty limits** | `_test_difficulty_limits` | 3 presets exist; for every preset at 0 / 50 / 500 / 2000 / 10000 / 100000 m, speed never exceeds the preset cap and never drops below the base, density stays in 0–3 and complexity in 0–0.9; the peak over the sweep is capped |
| 11 | **Segment recycling gaps** | `_test_segment_recycling` | the initial pool is filled (≥ 8); after teleporting the runner 3000 m the live count stays bounded (≤ 10); surviving segments' start distances are **contiguous**, every consecutive pair exactly 60 m apart |
| 12 | **Impossible patterns** | `_test_planner_generation` + `_test_planner_rejection` | 40 seeds × 3 presets × 6 segments produce **zero** `validate_plan` problems, and the planner actually produced obstacles; `validate_plan` returns problems for all-three-lanes-blocked, two obstacles in one lane, an unknown hazard kind, rows closer than the minimum gap, and an out-of-segment offset |
| 13 | **Pause freezes** | `_test_pause_freezes` (+ `flow_test._test_pause_and_resume`) | pausing sets `PAUSED`; after 30 physics frames the runner's z and `distance()` are unchanged and a power-up timer is unchanged; resuming returns to `PLAYING` and the runner advances again. The flow test additionally asserts the pause overlay appears and Resume hides it |
| 14 | **Restart resets run data, keeps progress** | `_test_restart_keeps_progress` (+ `flow_test._test_game_over_then_restart`) | 500 m recorded; after `restart_run()` distance is 0 and run stats are cleared, while `SaveData.best_score` (4321) and `total_runs` (12) are untouched; the new run is active. The flow test drives the real "Play Again" button in the real game-over screen |
| 15 | **Game-over blocks score** | `_test_game_over_blocks_score` | `end_run` sets `GAME_OVER`; a later `add_points(9999)` returns 0 and leaves the total frozen; the combo cannot change; `is_run_active()` is false |
| 16 | **Clean-directory launch** | `_test_clean_launch_and_missing_assets` + the windowed runs in §3 | a freshly instantiated game scene has a player, a world, a UI and the run managers, advances > 0 m, and the whole project imports and runs from source with no external assets |
| 17 | **Missing optional assets don't crash** | `_test_clean_launch_and_missing_assets` | the bundled font loads; `GameMaterials.get_material("no_such_material")` returns a usable (grey) material instead of null; a known material builds; the procedural avatar builds its rig. `PropFactory.water_material()` also falls back to a plain material if `shaders/water.gdshader` cannot be loaded |
| 18 | **Checkpoints can't re-trigger without a new run** | `_test_checkpoint_cannot_retrigger` | no gate is built before the milestone and no milestone is counted; crossing it builds **exactly one** gate; entering it opens the checkpoint, marks one milestone passed and pauses into `CHECKPOINT`; finishing resumes to `PLAYING`, clears the gate, spawns **no** second gate, keeps the milestone count at 1, and has scored the checkpoint exactly once |

### Additional coverage in the flow test

`tests/flow_test.gd` performs **real scene switches** (`Game.auto_switch_scene = true`)
and asserts:

* the main menu loads, its script is attached, and the How to Play / Health Facts /
  Settings overlays exist;
* Play switches to `GameScene` with `PLAYING`, a runner, a world, a HUD and the run
  managers, and the run actually advances and scores under its own power;
* the pause overlay appears/disappears with the state;
* game over shows the overlay, "Play Again" loads a *fresh* run with a reset score and
  distance, and the finished run was recorded to persistent progress (`total_runs` ≥ 1);
* quitting to the menu returns to the main menu, unpaused, in `MENU`.

It also exits through `Game.quit_game()`, so it exercises the real shutdown path.

---

## 5. Test-design notes worth knowing

* **Determinism.** `Game.rng_seed` is pinned (4242 in the behaviour suite, 777/555/31337
  for specific world tests, 99 in the flow test). Generation is reproducible.
* **Real physics, not mocked.** Behaviours 3, 6, 2 and 13 run actual `Area3D` overlaps
  and `move_and_slide()` against real `StaticBody3D` ground — the same code path a
  player hits.
* **Time is simulated, not slept.** Expiry tests call `PowerUpManager._process(dt)` with
  a synthetic `dt`, which is exact and fast; movement tests advance real physics frames.
* **The suite pauses and unpauses the tree** (pause / game-over / checkpoint tests), so
  the runner node itself is `PROCESS_MODE_ALWAYS`.
* **White-box access is deliberate and limited** to a few read-only internals
  (`WorldManager._segments`, `CheckpointManager._active_gate`) where the observable
  behaviour is the *absence* of something. Scoring, collisions and pickups are all
  asserted through the public API.
* **`--headless` disables audio playback** (`AudioManager.playback_enabled` is false when
  `DisplayServer.get_name() == "headless"`). The dummy audio driver never releases its
  `AudioStreamPlaybackWAV` objects, which the engine then reports as leaked instances at
  exit and which would mask a real leak. Stream *generation*, name lookup and bus setup
  are still fully exercised, and the audio path is verified for real by the windowed
  runs in §3.
* **`build/` is git-ignored** but the exported binaries are present on disk.

---

## 6. What the automated suites do **not** prove

Being explicit about this is part of the deliverable.

| Area | Status |
| --- | --- |
| Visual quality, composition, readability of the 3D world | **Not automatically verified.** `--headless` has no renderer. The scene was launched for real with Vulkan (see §3) to confirm it initialises, runs and produces no shader errors — but "does it look good?" requires a human. |
| Audio *sound* quality | Not verified. The synthesis is code-verified; whether the generated sounds are pleasant is a listening judgement. They are explicitly placeholders. |
| Reading comprehension of the health copy | Not verified automatically. The content is source-checked (`docs/HEALTH_CONTENT_SOURCES.md`), not audience-tested. |
| Thai localisation beyond the translated entries | Partial. Eight core topics plus specific entries have Thai text; tutorial/menu prose is English. |
| Frame rate on low-end hardware | Not measured. The scene stays under ~60 segments × a handful of props, but no profiling was done. |
| Android / iOS | Not built. Only the Windows Desktop preset exists. |
| Long-session stability (e.g. 30-minute runs) | The recycling maths is tested at 3000 m; beyond that it is the same code path, but no multi-hour soak test was run. |
| Save-file corruption recovery | The code path exists (`save_v1.corrupt.json` quarantine) and was read, but no test injects a corrupt file. |

---

## 7. Manual verification checklist

For a human reviewer, in order:

1. Run `build\RiverDash.exe`. The main menu appears with music.
2. **Play** on Standard. Confirm: the runner moves smoothly; lane changes, jumps and
   slides each work; a raw-fish dish in your lane hurts you unless you change lane; a
   board is clearable by jumping and not by running; wastewater is clearable by sliding.
3. Lose all 3 safety points. Confirm the run ends, the score stops changing, and a
   sourced takeaway appears.
4. Play again and reach ~1000 m. Confirm the Kitchen Sizzle Station opens, that holding
   heat and releasing inside the green band counts as success, and that the sourced
   message is readable.
5. Collect 3 latrine tokens and confirm a latrine is built beside the track (and that
   the same three tokens never build two).
6. Press `Esc` mid-run. Confirm the world genuinely freezes (obstacles stop moving) and
   that Resume continues smoothly.
7. Open **Settings**, turn screen shake off, set camera smoothing to 2.5, and confirm
   both changes are felt. Restart the game and confirm the settings persisted.
8. Open **Health Facts** and confirm every entry shows a source title, URL, review date
   and status.
9. Open **How to Play**, then start the Relaxed practice run from it.
