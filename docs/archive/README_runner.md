# River Dash: Safe Feast Run

A 3D endless runner set in a rural Thai village that teaches practical **liver fluke
(*Opisthorchis viverrini*) prevention**: cook freshwater fish thoroughly, avoid
cross-contamination, and support safe sanitation. Health messages are sourced from
WHO, the US CDC, NIH/NCBI and Thailand's Department of Disease Control — every one of
them carries its citation and review date in-game.

* Engine: **Godot 4.7.2 stable** (GDScript, Forward+)
* Platform: **Windows PC** first; the architecture is ready for Android/iOS later
* All art and audio is **generated procedurally at runtime** — there are no binary
  asset dependencies beyond one bundled font (Sarabun, OFL)

---

## 1. Play it

### Option A — the exported build (easiest)

```
build\RiverDash.exe
```

Double-click it, or from a terminal:

```powershell
& "C:\Users\ASUS\river-dash-safe-feast-run\build\RiverDash.exe"
```

`build\RiverDash.console.exe` is the same build with a console attached; it prints
engine output and is the one to use when diagnosing a crash.
`build\RiverDash-release.exe` is the release build (no console wrapper).

### Option B — run from source with the Godot editor

1. Launch Godot 4.7.2.
2. **Import** → select `C:\Users\ASUS\river-dash-safe-feast-run\project.godot`.
3. Press **F5**. The project's main scene is `scenes/main/main_menu.tscn`.

### Option C — run from source from a terminal

```powershell
$godot = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64.exe"
& $godot --path "C:\Users\ASUS\river-dash-safe-feast-run"
```

The first launch may take a few seconds while Godot imports the font.

---

## 2. Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move left / right | `A` `D` or `←` `→` | D-pad left / right |
| Jump | `W`, `↑` or `Space` | A |
| Slide | `S` or `↓` | B |
| Pause / resume | `Esc` | Start |
| Confirm (checkpoints, menus) | `Enter`, `Space` | A |
| Heat the pan (kitchen mini-game) | hold `Space` / `Enter` | hold A |
| Toggle the debug overlay | `F3` | — |

Every action is registered at runtime by `autoload/input_manager.gd`, so touch swipes
(a future Android/iOS build) can be fed in as the same named actions without touching
gameplay code.

---

## 3. The rules in one screen

* You run down three lanes at an automatically increasing speed.
* **Raw freshwater fish dishes** block a whole lane — neither jumping nor sliding
  helps; change lane.
* **Cross-contaminated chopping boards** are low — jump them.
* **Unsanitary wastewater** hangs above the ground — slide under it.
* You have **3 points of safety**. A hit costs one, slows you briefly and breaks your
  combo. A **Sanitation Shield** absorbs a hit instead. When safety runs out the run
  ends and your score is frozen.
* Pick up the **Safe Cooking Flame** (raw-fish hazards become safe cooked bonuses worth
  100 points each), the **Sanitation Shield**, and the **Medical Treatment Boost**
  (speed plus clears any slowdown). Collect **3 Latrine Builder Tokens** to build a
  latrine beside the track.
* Roughly every **1000 m** you reach a checkpoint: a *Kitchen Sizzle Station*
  temperature-gauge timing game or a *Village Health Centre* screening chat. Each
  awards points and shows a sourced health message.

Menus: **Play**, **How to Play** (with a procedural lane diagram and a Relaxed
practice run), **Health Facts** (the full sourced database), **Settings**, **Quit**.

---

## 4. Project layout

```
river-dash-safe-feast-run/
├─ project.godot              # main scene = scenes/main/main_menu.tscn
├─ export_presets.cfg         # "Windows Desktop" preset (embedded .pck)
├─ icon.svg
├─ assets/fonts/              # Sarabun (OFL) + OFL.txt
├─ autoload/                  # Settings, SaveData, Education, AudioManager,
│                             # InputManager, Game
├─ scenes/main/               # game.tscn, main_menu.tscn
├─ scenes/player/             # player.tscn
├─ scripts/
│  ├─ data/                   # game_config.gd, difficulty_config.gd, education_data.gd
│  ├─ gameplay/               # difficulty, score, power-up managers
│  ├─ main/game.gd            # the game scene controller
│  ├─ obstacles/              # base Obstacle + 3 hazards + factory
│  ├─ collectibles/           # Collectible
│  ├─ checkpoints/            # gate + milestone manager
│  ├─ player/                 # player.gd, player_visual.gd (rigged avatar)
│  ├─ ui/                     # HUD, menus, popups, checkpoint mini-games
│  └─ world/                  # world_manager, course_segment, segment_planner,
│                             # prop_factory, prop_market, prop_clinic, materials
├─ shaders/water.gdshader
├─ tests/                     # smoke_test, runner (18 behaviours), flow_test
└─ docs/                      # GAME_DESIGN, HEALTH_CONTENT_SOURCES, TESTING,
                              # PLACEHOLDER_ASSETS
```

Only three **game** scenes are hand-authored (the main menu, the game scene and the
player root); the test scenes are three more. Obstacles, collectibles, checkpoints,
scenery and the whole world are built in code, which keeps them testable and impossible
to corrupt with a bad `.tscn`.

---

## 5. Testing

All suites run headless and return a non-zero exit code on failure.

```powershell
$godot = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe"
$proj  = "C:\Users\ASUS\river-dash-safe-feast-run"

# 0. Import (do this after a fresh clone)
& $godot --headless --path $proj --import

# 1. Smoke test: autoloads boot, education database validates, audio generates
& $godot --headless --path $proj res://tests/smoke_test.tscn

# 2. Behaviour suite: the 18 required behaviours (194 checks)
& $godot --headless --path $proj res://tests/runner.tscn --fixed-fps 60

# 3. Scene-flow test: menu -> run -> pause -> game over -> restart -> menu
& $godot --headless --path $proj res://tests/flow_test.tscn --fixed-fps 60
```

`--fixed-fps 60` makes timing-dependent tests deterministic (one physics tick per
frame). Expected tail for suite 2:

```
checks run: 194
ALL TESTS PASSED
```

See `docs/TESTING.md` for the behaviour-to-test mapping and the known limits of the
automated coverage.

---

## 6. Exporting a Windows build

Export templates must be installed once. They live in
`%APPDATA%\Godot\export_templates\4.7.2.stable\` and must contain
`windows_debug_x86_64.exe` and `windows_release_x86_64.exe`.

Install them either from the Godot editor (**Editor → Manage Export Templates →
Download and Install**) or manually:

```powershell
$tpz = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
$dst = "C:\Users\ASUS\godot-tools\templates.tpz"
curl.exe -L -o $dst $tpz

$tmp = "C:\Users\ASUS\godot-tools\templates_extract"
tar -xf $dst -C $tmp
Copy-Item "$tmp\templates\*" "$env:APPDATA\Godot\export_templates\4.7.2.stable" -Recurse -Force
Remove-Item $tmp -Recurse -Force
```

Then export (the preset name is case-sensitive and must match `export_presets.cfg`):

```powershell
$godot = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe"
$proj  = "C:\Users\ASUS\river-dash-safe-feast-run"
& $godot --headless --path $proj --export-debug   "Windows Desktop" "$proj\build\RiverDash.exe"
& $godot --headless --path $proj --export-release "Windows Desktop" "$proj\build\RiverDash-release.exe"
```

The preset embeds the `.pck` into the executable, so `RiverDash.exe` is a single
self-contained file (about 100 MB, mostly the engine). Sanity-check an export with:

```powershell
& "$proj\build\RiverDash.console.exe" --headless --quit-after 200
```

---

## 7. Where to read more

| Document | Contents |
| --- | --- |
| `docs/GAME_DESIGN.md` | Systems, tuning constants, difficulty presets, scoring rules, architecture decisions, future work |
| `docs/HEALTH_CONTENT_SOURCES.md` | Every health claim with its citation, URL, last-reviewed date and review status; the accuracy rules the content follows |
| `docs/TESTING.md` | How to run each suite, the 18 required behaviours mapped to tests, and coverage limits |
| `docs/PLACEHOLDER_ASSETS.md` | What is still placeholder art/audio and exactly how to replace it |
| `docs/FINAL_REPORT.md` | Delivery report separating what is implemented, what is tested (with observed results), and what is future work |

## 8. Credits and licensing

* Code, procedural art and procedural audio: written for this project.
* **Sarabun** font — © Cadson Demak, licensed under the SIL Open Font Licence 1.1
  (`assets/fonts/OFL.txt`).
* No paid assets, plugins or third-party runtime dependencies are used.
