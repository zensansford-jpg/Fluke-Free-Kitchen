# Game Design — River Dash: Safe Feast Run

This document describes what the game is, the numbers that drive it, and why the code
is organised the way it is. All tuning values live in
`scripts/data/game_config.gd`; nothing in this document is invented — every constant
named here exists in that file.

---

## 1. Design pillars

1. **Readable in one glance.** Three lanes, three hazards, three avoidance verbs. A
   player should never lose a run and be unsure why.
2. **Health content is the reward, not the punishment.** Messages are attached to
   *successes* (cooking, shield, checkpoints, building a latrine) far more than to
   failures.
3. **No fear framing.** The failure state is a 3-point safety buffer emptying, not
   illness. The game-over screen shows a prevention takeaway.
4. **No clerical claims.** Every health statement comes from the reviewed database
   (`docs/HEALTH_CONTENT_SOURCES.md`); no gameplay script writes health copy.
5. **PC-first, phone-ready architecture.** Input is abstracted into named actions;
   nothing depends on a keyboard, a mouse or a specific resolution.

---

## 2. Core loop

```
run forward → read the next hazard → apply the right verb → clean pass raises the combo
        ↘ collect pickups → power-ups → cook hazards into bonus points
        ↘ every ~1000 m → checkpoint mini-game → bonus + sourced health message
        ↘ 3 safety points lost → run ends → score frozen → sourced takeaway
```

---

## 3. The runner

`scripts/player/player.gd` (`class_name Player`, a `CharacterBody3D`). The origin is at
the **feet**, so a standing capsule spans y = 0 → 1.7 m and a slide spans y = 0 → 0.8 m.
That is what makes the obstacle height profiles below produce exactly one valid verb.

| Property | Value | Constant |
| --- | --- | --- |
| Lanes | 3, at x = −2.4 / 0 / +2.4 | `LANE_WIDTH = 2.4`, `LANE_COUNT = 3` |
| Lane blend rate | 14 (exponential approach, lateral velocity clamped to ±22 m/s) | `LANE_LERP_SPEED` / `LANE_X_RATE` |
| Collider radius | 0.35 m | `PLAYER_RADIUS` |
| Standing height | 1.7 m | `STAND_HEIGHT` |
| Sliding height | 0.8 m | `SLIDE_HEIGHT` |
| Gravity | 30 m/s² | `GRAVITY` |
| Jump velocity | 11 m/s (≈2 m apex) | `JUMP_VELOCITY` |
| Jump cooldown | 0.12 s | `JUMP_COOLDOWN` |
| Coyote time | 0.10 s | `COYOTE_TIME` |
| Slide duration | 0.7 s | `SLIDE_DURATION` |
| Slide cooldown | 0.1 s | `SLIDE_COOLDOWN` |
| Safety buffer | 3 points | `MAX_SAFETY` |
| Invulnerability after a real hit | 1.0 s | `HIT_INVULNERABILITY` |
| Invulnerability after an absorbed hit | 0.5 s | `SHIELD_INVULNERABILITY` |
| Stumble after a hit | 0.9 s at 55 % speed | `HIT_STUMBLE_DURATION`, `HIT_STUMBLE_SPEED_FACTOR` |
| Base forward speed | 10 m/s | `BASE_SPEED` |
| Speed gained | 0.11 m/s per metre travelled × preset ramp | `SPEED_PER_METER` |
| Absolute speed ceiling | 26 m/s (+4 with the treatment boost) | `ABSOLUTE_MAX_SPEED` |

`MAX_SAFETY`, `COYOTE_TIME`, `HIT_INVULNERABILITY` and `SHIELD_INVULNERABILITY` are
declared on `Player` itself; every other constant in the table lives in `GameConfig`.

**Lane movement is clamped, not queued.** `request_lane(direction)` returns the number
of lanes actually moved, so holding left at lane 0 is a no-op rather than banking a
move. This is asserted by the test suite.

**Jump cannot be re-triggered mid-air.** `try_jump()` requires `is_on_floor()` or an
active coyote window and a spent cooldown, so a held key cannot produce hovering.

---

## 4. Obstacles: one hazard, one verb

The three required hazards are designed so that **exactly one** of *change lane*,
*jump*, *slide* clears them. That is enforced by the collision volumes, not by special
cases in code.

| Hazard | Kind id | Vertical extent | Collider | Valid verb | Invalid verbs |
| --- | --- | --- | --- | --- | --- |
| Raw freshwater fish dish | `raw_fish` | 0 → 2.40 m (`RAW_FISH_HEIGHT`) | full lane, 2.0 m wide, 0.8 m deep | **change lane** | jumping (2 m apex < 2.4 m) and sliding (rail is above the slide gap) both collide |
| Cross-contaminated chopping board | `cutting_board` | 0 → 0.70 m (`BOARD_HEIGHT`) | low box | **jump** | running into it collides; sliding does *not* help because the board starts at the ground |
| Unsanitary wastewater curtain | `wastewater` | 0.95 → 2.40 m (`WASTEWATER_GAP`, `WASTEWATER_TOP`) | hanging box | **slide** (0.8 m < 0.95 m) | standing collides; jumping goes *into* it |

Shared dimensions: `OBSTACLE_HALF_WIDTH = 1.0`, `OBSTACLE_DEPTH = 0.8`.
A hazard counts as **cleaned passed** once the runner is 1.4 m beyond it
(`OBSTACLE_PASS_MARGIN`), which raises the combo.

Each hazard is resolved **exactly once** (`Obstacle._done`), so an overlap spread over
several physics frames cannot be counted twice — neither as two hits nor as a hit *and*
a clean pass.

### Safe Cooking Flame conversion

While the flame is active, `WorldManager.set_cooking(true)` recolours every live
`raw_fish` hazard into safe cooked food. Touching one then emits `converted` instead of
`hit_player`, awarding `POINTS_SAFE_COOKED = 100` and letting the runner continue
untouched. When the flame expires every converted hazard reverts. Only `raw_fish`
hazards convert — boards and wastewater are hygiene hazards, not cooking hazards.

---

## 5. Collectibles and power-ups

`scripts/collectibles/collectible.gd` (`enum Kind { SNACK, COOKING, SHIELD, TREATMENT, LATRINE }`).
Pickups are single-shot: the first overlap sets `_collected`, disables monitoring and
emits `collected` once.

| Kind | What it does | Duration / charge |
| --- | --- | --- |
| `SNACK` | 50 points (`POINTS_COLLECTIBLE`) | — |
| `COOKING` — *Safe Cooking Flame* | raw-fish hazards become safe cooked bonuses (100 pts each) | `COOKING_FLAME_DURATION = 12 s` |
| `SHIELD` — *Sanitation Shield* | absorbs hits without costing safety | `SANITATION_SHIELD_CHARGES = 3`, `SANITATION_SHIELD_DURATION = 20 s` |
| `TREATMENT` — *Medical Treatment Boost* | +4 m/s and clears any slowdown | `TREATMENT_BOOST_DURATION = 6 s`, `TREATMENT_BOOST_SPEED_BONUS = 4` |
| `LATRINE` — *Latrine Builder Token* | 3 tokens build a latrine beside the track | `LATRINE_TOKENS_REQUIRED = 3` |

Stacking rules (in `PowerUpManager`):

* re-collecting the **same** power-up **refreshes** its timer, it never stacks;
* re-collecting the shield **refills to 3 charges**, never 6;
* different power-ups overlap independently;
* the token counter **resets to 0 when it fires**, so the sanitation event fires
  **exactly once per three tokens** — never twice for the same set, never partially;
* all timers are on a `PROCESS_MODE_PAUSABLE` node, so pausing freezes them.

---

## 6. Checkpoints

Milestones are every `KITCHEN_CHECKPOINT_INTERVAL = 1000 m`, alternating **Kitchen
Sizzle Station** (odd) and **Village Health Centre** (even). A gate is spawned
`CHECKPOINT_APPROACH = 36 m` *ahead* of the runner so it can be seen approaching.

**Kitchen Sizzle Station** — a temperature-gauge timing mini-game. Hold *heat*
(`Space`/`Enter`, a gamepad A, or the left mouse button) to raise the gauge; release
inside the target band (62–78 of 100) for success. `POINTS_KITCHEN_SUCCESS = 300`
on success, on top of the flat checkpoint award. The gauge is explicitly described as a
game abstraction teaching *cook it through*, not a validated temperature.

**Village Health Centre** — a short screening chat, followed by the vetted
`clinic_checkpoint` entries. It frames screening as a conversation, mentions a possible
**stool test**, states that only a health professional can diagnose, and shows no
X-ray and no fictional personal diagnosis. Full detail in
`docs/HEALTH_CONTENT_SOURCES.md § 5`.

**A checkpoint cannot re-trigger.** Two independent mechanisms guarantee it: the gate is
single-use (`CheckpointGate._used`), and the manager's milestone index is **monotonic**
(`_next_index` only increases). Only a *new run* resets the index, which is why a
restart builds a fresh checkpoint manager rather than reusing the old one.

**Order-of-operations note.** The run leaves the `CHECKPOINT` state *before* the points
are awarded, because scoring is gated on `Game.is_run_active()`. Awarding while paused
would silently score nothing.

---

## 7. Scoring

`scripts/gameplay/score_manager.gd`. Every award is gated on
`Game.state == State.PLAYING`, which is what makes game-over freeze the score for good.

| Source | Points | Multiplied by combo? |
| --- | --- | --- |
| Distance | 1 per whole metre (`POINTS_PER_METER`) | no (accumulated directly) |
| Collectible | 50 (`POINTS_COLLECTIBLE`) | yes |
| Safe cooked bonus | 100 (`POINTS_SAFE_COOKED`) | yes |
| Checkpoint | 250 flat (`POINTS_CHECKPOINT`) | no |
| Kitchen success | 300 (`POINTS_KITCHEN_SUCCESS`) | no |
| Latrine sanitation event | 400 (`POINTS_LATRINE_EVENT`) | no |

**Combo.** A clean obstacle pass adds 1 combo. Every `COMBO_STEP_PER_MULT = 4` combo
adds one multiplier level, capped at `COMBO_MULT_CAP = 5`. A hit breaks the combo back
to 1 (`COMBO_BREAK_ON_HIT`). Flat milestone rewards deliberately ignore the multiplier
so they cannot snowball.

**No exploits.** Distance is credited only for *whole* metres, so jittering back and
forth cannot farm points; distance is `maxf(0, start_z − z)` so reversing cannot
subtract; and a stopped score cannot be restarted by a late collision because `end_run`
sets `finished` and guards re-entry.

---

## 8. Difficulty

`scripts/data/difficulty_config.gd` defines three presets; `difficulty_manager.gd`
turns distance into speed, density and complexity. Nothing else hard-codes these
numbers.

| Preset | Display | Max speed | Density | Collectibles | Ramp scale | Complex patterns |
| --- | --- | --- | --- | --- | --- | --- |
| `relaxed` | Relaxed — *"Slower speed, more room to react."* | 14 m/s | 0.8× | 0.7× | 1.2 | 0.10 |
| `standard` | Standard — *"The intended first-time experience."* | 18 m/s | 1.0× | 1.0× | 1.1 | 0.25 |
| `challenging` | Challenging — *"Faster, denser, and less forgiving."* | 23 m/s | 1.25× | 1.15× | 1.0 | 0.45 |

```
speed_for(d)      = clamp(BASE_SPEED + max(0,d) · SPEED_PER_METER · ramp_scale,
                          BASE_SPEED, max_speed)
density_for(d)    = lerp(0.55, 1.00, clamp(d / (ramp_distance·4), 0, 1)) · obstacle_density
complexity_for(d) = lerp(0.15, 1.00, clamp(d / (ramp_distance·6), 0, 1)) · complex_pattern_chance
```

`ramp_distance = 150 m`. The hard ceiling (`max_speed`) is clamped in `speed_for`
itself and asserted by the tests for every preset out to 100 km of distance.

**Readable tiers.** `TIER_LABELS = ["Gentle", "Steady", "Brisk", "Fast", "Rapid",
"Blistering"]`, one every `TIER_DISTANCE = 500 m`, emitted as `tier_changed`.

---

## 9. The endless world

`scripts/world/world_manager.gd`.

* **Recycled pool.** `SEGMENT_POOL_SIZE = 8` segments of `SEGMENT_LENGTH = 60 m` are
  kept alive. Each frame the manager tops the frontier up to
  `player.distance() + 8 · 60` and recycles any segment that is more than
  `SEGMENT_RECYCLE_MARGIN = 45 m` behind. A segment reused from the free list is
  emptied and rebuilt, so the track stays contiguous **by construction** — the test
  suite asserts the surviving segment start distances differ by exactly 60 m.
* **Biomes.** `BIOMES = ["riverbank", "market", "clinic"]`, each
  `BIOME_LENGTH = 800 m` long, cycling forever. Each biome changes the sky palette, sun
  colour and energy, fog colour/density, the music and the ambience, and the scene
  dresses built by `CourseSegment`. A banner announces each arrival.
* **Ground.** A `GROUND_WIDTH = 16 m` strip; scenery starts at
  `|x| ≥ SCENERY_MIN_X = 5`, keeping the playable corridor visually clear.
* **Fairness by construction.** `segment_planner.gd` is a **pure** function
  (`plan_segment(rng, distance, speed, density, complexity)`) plus a guard-rail
  (`validate_plan`). It can produce one or two blocked lanes per row and **never**
  three; rows are separated by at least `ROW_GAP_MIN_METERS = 16 m` (and at least
  `row_gap_for_speed(speed) = max(16, speed · 1.15)` m — 1.15 s of reaction time);
  obstacles stay inside `SEGMENT_EDGE_MARGIN = 4 m` from either end. The test suite runs
  the planner over 40 seeds × 3 presets and asserts `validate_plan` is always empty, and
  separately asserts that it *rejects* hand-crafted impossible plans.
* **The stats that spawn.** `GameConfig` stores the obstacle/collectible probabilities
  inside the planner (`OBSTACLE_WEIGHTS`, `PICKUP_WEIGHTS`); raw fish (the transmission
  risk) is the most common hazard at 0.42.

---

## 10. Presentation

* **Camera.** `ChaseCamera` sits 6.4 m behind and 3.0 m above, easing with an
  exponential blend. The blend rate is `base_stiffness / Settings.camera_smoothing`, so
  the accessibility setting genuinely changes the feel. `shake(amount)` fades over
  ~0.4 s and is suppressed when `Settings.shake_enabled` is off.
* **Art.** 100 % procedural. `game_materials.gd` builds deterministic 64-px noise
  textures from code and caches them by name, so the project ships no image files while
  still reading as weathered wood, mud, concrete, roof tiles, foliage and food. An
  unknown material name falls back to grey rather than crashing.
* **Water.** `shaders/water.gdshader`, loaded by `PropFactory.water_material(flow_speed)`
  with a **code path that falls back to a plain material if the shader cannot be
  loaded**.
* **Props.** `prop_factory.gd` (primitives, fields, rivers), `prop_market.gd` (stalls,
  crates, lanterns, noodle carts), `prop_clinic.gd` (checkpoint arch, clinic building,
  hand-wash station, info boards).
* **Audio.** `audio_manager.gd` synthesises every effect, music bed and ambience into an
  `AudioStreamWAV` at startup, on the `Master` / `Music` / `SFX` buses. See
  `docs/PLACEHOLDER_ASSETS.md`.
* **UI.** `ui_factory.gd` centralises the Sarabun-based look (colours
  `TEXT_BRIGHT` / `TEXT_DIM` / `ACCENT` / `GOOD` / `BAD`, `CARD_COLOR`), so every panel
  is consistent and restyling is one file.

---

## 11. Screens

| Screen | Script | Notes |
| --- | --- | --- |
| Main menu | `scripts/ui/main_menu.gd` | Play, difficulty selector, How to Play, Health Facts, Settings, language toggle, Quit; shows the personal best |
| How to Play | `scripts/ui/how_to_play.gd` | Procedurally drawn lane diagram, one section per avoidance verb, pickups, checkpoints, safety, controls; offers a **Relaxed practice run** |
| HUD | `scripts/ui/hud.gd` | Score, distance, combo, speed, personal best, difficulty, power-up bars, shield charges, builder tokens, and a flashing `+N` feedback label. Read-only: it never changes game state |
| Pause | `scripts/ui/pause_menu.gd` | Resume, Restart, Settings, Main Menu. Emits intent only |
| Checkpoint | `scripts/ui/checkpoint_panel.gd` | Kitchen gauge (an inner `Gauge` control that draws the target band and marker) and the clinic chat |
| Game over | `scripts/ui/game_over.gd` | Frozen score, final distance, personal best, collectibles, checkpoints, obstacles hit, and a sourced takeaway |
| Settings | `scripts/ui/settings_menu.gd` | Shared overlay, opened from the menu *or* in-run pause |
| Health Facts | `scripts/ui/health_facts.gd` | Every database entry with headline, body, extended note, source title, URL, last-reviewed date and status |
| Education popups | `scripts/ui/educational_popup.gd` | Queued bottom-of-screen cards; early messages are never overwritten mid-sentence |
| Biome banner | `scripts/ui/biome_title.gd` | Fades in/out a "now entering…" title |
| UI controller | `scripts/ui/game_ui.gd` | An always-on `CanvasLayer` that owns every widget, forwards intent as signals, and routes the pause key |

### Settings and comfort

| Group | Options | Default |
| --- | --- | --- |
| Volume | Master, Music, SFX (0–1) | 1.0 / 0.7 / 0.9 |
| Camera | Smoothing 0.25–2.5 | 1.0 |
| Motion comfort | Screen shake on/off | on |
| Display | Fullscreen; resolution 1280×720 / 1366×768 / 1600×900 / 1920×1080 / 2560×1440 | windowed, 1920×1080 |
| Quality | low / medium / high (queued if a run is in progress, to avoid a mid-run hitch) | medium |
| Language | English / ไทย | English |
| Difficulty | Relaxed / Standard / Challenging | Standard |

---

## 12. Persistence

Two independent, versioned JSON files in `user://`. No personal information is stored
and no network access is used.

| File | Owner | Contents |
| --- | --- | --- |
| `settings_v1.json` | `Settings` | the settings above |
| `save_v1.json` | `SaveData` | `best_score`, `longest_distance`, `total_runs`, `total_collectibles`, `total_checkpoints`, `unlocked_cosmetics` |

Writes are atomic-ish: the data is written to `save_v1.json.tmp` and then swapped in, so
a crash during a save cannot leave a half-written file. A file that is not valid JSON is
copied to `save_v1.corrupt.json` and the game starts fresh. A save from a *newer* version
is refused rather than mis-parsed; `_migrate()` is the hook for older ones.

**The rule that matters:** a restart resets *run* data only. Personal best, longest
distance and totals survive, and the test suite asserts exactly that.

---

## 13. Code architecture

### Autoloads (exactly six)

`Settings`, `SaveData`, `Education`, `AudioManager`, `InputManager`, `Game`.

Autoload scripts deliberately carry **no `class_name`** (a `class_name` on an autoload
script collides with the singleton's global name). Everything else is a plain class with
a `class_name`, instantiated by whoever owns it.

### Gameplay modules, all signal-driven

| Module | File | Responsibility |
| --- | --- | --- |
| `Game` (autoload) | `autoload/game_manager.gd` | The state machine (`MENU`, `PLAYING`, `PAUSED`, `CHECKPOINT`, `GAME_OVER`), pause (via `get_tree().paused`), run statistics, run result |
| `DifficultyManager` | `scripts/gameplay/difficulty_manager.gd` | distance → speed / density / complexity / tier |
| `ScoreManager` | `scripts/gameplay/score_manager.gd` | distance, combo, bonuses; gated on the run being active |
| `PowerUpManager` | `scripts/gameplay/powerup_manager.gd` | timers, shield charges, latrine tokens, cooking/treatment signals |
| `WorldManager` | `scripts/world/world_manager.gd` | the course pool, biomes, pass detection, cooking conversion |
| `CheckpointManager` | `scripts/checkpoints/checkpoint_manager.gd` | milestone gates |
| `Player` | `scripts/player/player.gd` | movement, jump/slide state, the safety buffer, hit arbitration |
| `GameScene` | `scripts/main/game.gd` | builds everything, owns the wiring, and is the only place that awards points |

### Rules the code follows

* **Typed GDScript.** Every member and local that can be typed is typed. This is what
  makes the compiler catch API drift instead of failing at runtime.
* **No giant scripts.** The largest file is a data/prop library; the gameplay
  controllers are each a few hundred lines with a single responsibility.
* **Signals over scene-tree lookups.** Nothing calls `get_node("../../Foo")`. Managers
  emit; the game scene listens and decides. That is why the tests can drive any system
  in isolation.
* **Injection over globals for gameplay.** `ScoreManager.bind(player, difficulty)`,
  `PowerUpManager.bind(player)`, `WorldManager.setup(player, difficulty, seed)`. The
  Player's `powerups` reference is optional, so `Player` is unit-testable alone.
* **Pause correctness.** `get_tree().paused` freezes physics, tweens and timers
  together. Gameplay nodes stay `PROCESS_MODE_PAUSABLE`; the UI `CanvasLayer` and the
  autoloads are `PROCESS_MODE_ALWAYS`. The game root is pausable, so a pause really does
  stop the world.
* **Seeded RNG.** `Game.rng_seed` (0 = seed from the clock) feeds the world, the
  checkpoint manager and the practice/test paths, which is what makes generation
  reproducible in tests.
* **Three hand-authored game scenes only** (`game.tscn`, `main_menu.tscn`,
  `player.tscn`; the three `tests/*.tscn` are just script hosts). Obstacles,
  collectibles, gates and scenery are built in code, so there are no per-prop `.tscn`
  files to corrupt and everything is testable without the editor.
* **Collision layers** are named constants, not magic numbers: `LAYER_WORLD = 1`,
  `LAYER_PLAYER = 2`, `LAYER_OBSTACLE = 4`, `LAYER_COLLECTIBLE = 8`,
  `LAYER_CHECKPOINT = 16`.

---

## 14. Mobile readiness (prepared, not yet built)

Done now, deliberately:

* All input is registered at runtime in `input_manager.gd` as named actions; touch
  swipes synthesise the same `InputEventAction`s (`SWIPE_MIN_PIXELS = 40`,
  `SWIPE_MAX_TIME = 0.45`). No gameplay script reads raw keys.
* `project.godot` uses the `canvas_items` stretch mode with `keep` aspect.
* Renderer is Forward+ on desktop; the preset keeps `texture_format/etc2_astc` available
  for Android.
* `export_presets.cfg` contains only the Windows Desktop preset today; adding Android/iOS
  presets does not require code changes.

Not done (future work): on-screen touch controls and an Android export preset.

---

## 15. Future work

1. **Thai body-text localisation.** Headlines and bodies for the eight core topics are
   already translated; the tutorial and menu prose are not.
2. **Real audio and textures.** See `docs/PLACEHOLDER_ASSETS.md` for the exact hook
   points (`AudioManager._load_overrides()`, `GameMaterials` textures).
3. **On-screen touch controls + Android/iOS presets.**
4. **Cosmetics.** `SaveData.unlocked_cosmetics` is persisted and currently unused —
   the intended unlock framework for runner skins.
5. **Leaderboards / run history.** `SaveData.record_run()` already returns a diff
   (`new_best_score`, `new_longest_distance`, previous values), so a history UI has the
   data it needs.
6. **A debug overlay.** `Game.debug_overlay` and `toggle_debug()` (F3) exist and toggle
   physics debug drawing; a proper on-screen stats overlay is not built.
