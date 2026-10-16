# Placeholder Assets and How to Replace Them

**The headline: this project ships no binary placeholder art or audio at all.** Every
material, mesh, effect, music bed and sound is generated in code at startup, so there is
nothing to hunt down and delete. What follows is exactly where each generated asset
comes from and the precise hook to swap in a real one.

The only binary asset in the repository is the **Sarabun font**, which is the intended
font (SIL Open Font Licence 1.1) and not a placeholder.

| Category | Status | Where it is produced | Replacement hook |
| --- | --- | --- | --- |
| Surface materials / textures | Generated | `scripts/world/game_materials.gd → _build()` | set `albedo_texture` in `_textured()` |
| 3D meshes (props, hazards, avatar) | Generated primitives | `prop_factory.gd`, `prop_market.gd`, `prop_clinic.gd`, `player_visual.gd`, `collectible.gd`, `*_obstacle.gd` | replace the builder call inside the class |
| Water surface | Shader | `shaders/water.gdshader` via `PropFactory.water_material()` | edit the shader (a fallback material path already exists) |
| Sound effects (15) | Synthesised | `audio_manager.gd → _synth_sfx()` | `AudioManager._load_overrides()` |
| Music (4) | Synthesised | `audio_manager.gd → _synth_music()` | same |
| Ambience (3) | Synthesised | `audio_manager.gd → _synth_ambience()` | same |
| Icon | Placeholder SVG | `icon.svg` | replace the file (same name) |
| Font | **Final** (Sarabun, OFL) | `assets/fonts/` | optional: swap in another OFL font and update `PropFactory._load_font()` paths |
| Health copy, layout, tuning | **Final, not placeholder** | `education_data.gd`, `game_config.gd`, `ui/` | see the note at the end |

---

## 1. Materials and textures

**Current behaviour.** `GameMaterials` builds a deterministic 64 × 64 noise texture per
material from code (`noise_texture()`; `TEX_SIZE = 64`) and caches the finished
`StandardMaterial3D` by name in a static dictionary. Roughly 80 named materials exist —
`mud`, `grass`, `rice_field`, `wood`, `roof_tile`, `plaster_cream`, `fish_raw`,
`fish_cooked`, `wastewater`, `sign_red`, `token_wood` and so on. An unknown name does
**not** crash: `_build()`'s default branch returns a grey material.

**Why it is a placeholder.** 64-px procedural noise reads as "correct tone and
roughness" but it is not real texture art: no proper normal maps, no detail at close
range, no hand-authored variation between, say, two different planks.

**To replace.**

1. Drop real textures into `res://assets/textures/` (PNG, ideally with matching
   `*_normal.png`).
2. In `game_materials.gd`, give `_textured()` a texture path parameter, or override per
   material inside `_build()`:

   ```gdscript
   "roof_tile":
       var m := _textured(name, Color(0.62, 0.28, 0.20), 0.06, 117, 0.5)
       m.albedo_texture = load("res://assets/textures/roof_tile.png")
       m.normal_texture = load("res://assets/textures/roof_tile_normal.png")
       return m
   ```

3. Keep the material **names** unchanged — they are the interface used by every prop
   builder (`PropFactory.box(parent, size, "roof_tile", …)`).

**Verify:** run the main menu and a game scene for real (not `--headless`) and confirm no
"resource not found" errors; check the export includes `assets/textures/`.

---

## 2. 3D meshes

**Current behaviour.** Everything is assembled from Godot primitives (box, cylinder,
sphere, prism, plane, torus) through `PropFactory`. The closest thing to a "model" is the
runner's rig, which `player_visual.gd` builds as nested pivot nodes with a real `animate(delta, state)`
that drives run/jump/slide/stumble poses.

**Why it is a placeholder.** These are readable, correctly proportioned proxies — not
modelled art. The runner is stylised boxes rather than an animated character.

**To replace (props).** Each prop has one builder function. For example, replace the body
of `PropMarket.add_stall()` or `PropClinic.add_clinic_building()`:

```gdscript
static func add_clinic_building(parent: Node3D, pos: Vector3, rot: float,
        rng: RandomNumberGenerator, with_collision: bool) -> Node3D:
    var root := (load("res://assets/models/clinic.glb") as PackedScene).instantiate()
    root.position = pos
    root.rotation_degrees = Vector3(0, rot, 0)
    parent.add_child(root)
    if with_collision:
        PropFactory.add_static_box(root, Vector3(8, 4, 6), Vector3(0, 2, 0))
    return root
```

Keep the function **signature** and keep returning a `Node3D` — callers
(`course_segment.gd`) only rely on that.

**To replace (the runner).** `player_visual.gd` exposes exactly three things the rest of
the game uses: `animate(delta, state)` (called every frame from `Player._process`),
`flash_hit()`, `set_shield_visible(bool)` and `set_powerup_tint()`. Swap in an
`AnimationPlayer`-driven `gltf`/`glb` character and map `state` keys
(`speed_ratio`, `grounded`, `sliding`, `stumble`, `vertical_velocity`) onto animation
names. Nothing else needs to change.

**Verify:** run the scene for real and confirm collisions still match the hazard height
profiles in `game_config.gd` (`RAW_FISH_HEIGHT`, `BOARD_HEIGHT`, `WASTEWATER_GAP`). If a
hazard model's visual height no longer matches its collider, update the collider — the
one-hazard-one-verb guarantee depends on it.

---

## 3. Water

**Current behaviour.** `shaders/water.gdshader`, wrapped by
`PropFactory.water_material(flow_speed)`. The loader checks that
`res://shaders/water.gdshader` exists and **falls back to a plain material with a
warning** if it does not, which is why a missing shader cannot break the game.

**To replace.** Edit the shader in place, or point
`PropFactory.water_material()` at a `ShaderMaterial` of your own. Keep the
`flow_speed` parameter meaningful (it is what makes the river read as moving). If you
use a Godot `Water`/`WaterBody` asset from the Asset Library, note that the project
policy is no paid assets — a free MIT/OFL-licensed one is fine, but adjust
`docs/PLACEHOLDER_ASSETS.md` and the credits in `README.md` if you add a licence.

**Verify:** launch for real. `--headless` cannot compile or display shaders.

---

## 4. Audio

**Current behaviour.** `AudioManager._generate_all()` builds every stream at startup as
an `AudioStreamWAV` and routes them onto the `Master`, `Music` and `SFX` buses:

* `SFX_NAMES` (15): `footstep`, `jump`, `land`, `slide`, `pickup`, `powerup`,
  `powerup_end`, `shield_hit`, `hit`, `checkpoint`, `latrine`, `ui_click`, `ui_back`,
  `game_over`, `combo`
* `MUSIC_NAMES` (4): `menu`, `run_market`, `run_river`, `run_clinic`
* `AMBIENCE_NAMES` (3): `river`, `market`, `clinic`

**Why it is a placeholder.** These are synthesis approximations (bell tones, noise
bursts, sweeps, thuds, arpeggios, filtered noise beds), not composed or recorded audio.

**To replace.** The hook already exists and is documented in the source:

```gdscript
func _load_overrides() -> Dictionary:
    var overrides := {}
    # Placeholder asset hooks — uncomment and point at real files when available.
    # overrides["pickup"] = preload("res://assets/audio/pickup.ogg")
    # overrides["menu"] = preload("res://assets/audio/menu_theme.ogg")
    return overrides
```

Add one line per clip, using the **exact keys listed above**, and drop the files into
`res://assets/audio/`. Anything you do not override keeps its synthesised version, so you
can migrate one sound at a time. Music and ambience should be loopable — set
`loop_mode` on the imported stream (for Ogg Vorbis, enable **Loop** in the Import dock).

**Verify:** run for real (audio playback is intentionally disabled under `--headless`) and
check each sound through: `AudioManager.play_sfx("pickup")` in the debugger, or simply
play and listen. The smoke test's `audio.has_stream(name)` check still validates that the
*name* resolves after an override.

---

## 5. Icon and window title

`icon.svg` is a placeholder mark. Replace the file, keeping the name `icon.svg` (or update
`[application] config/icon` in `project.godot`), then re-run `--headless --import` so
Godot regenerates `icon.svg.import`. The window title comes from
`config/name = "River Dash: Safe Feast Run"`.

For a shipping Windows build you may also want to set `application/icon` in
`export_presets.cfg` (currently empty) so the `.exe` carries the icon.

---

## 6. What is **not** a placeholder

Do not treat these as throwaway content:

* **The health copy** in `scripts/data/education_data.gd` is the reviewed product. It
  carries real citations and a review date; see `docs/HEALTH_CONTENT_SOURCES.md` before
  changing a word. `validate_database()` will reject an entry that cites an unapproved
  source host.
* **The tuning constants** in `scripts/data/game_config.gd` are a balanced, tested
  baseline. Changing `RAW_FISH_HEIGHT`, `BOARD_HEIGHT` or `WASTEWATER_GAP` invalidates
  the one-hazard-one-verb guarantee and the corresponding test expectations.
* **The layout and visual identity** in `scripts/ui/ui_factory.gd` (colours, sizes,
  fonts) is the intended look, not a wireframe.
* **The font** is the intended typeface under a permissive licence.

---

## 7. Replacement checklist

1. Add the asset under `res://assets/<category>/`.
2. Wire it through the hook above — never by editing gameplay logic.
3. Run `--headless --import`.
4. Run the three automated suites (`docs/TESTING.md § 1`) — they must still pass.
5. Launch the game for real and check the asset in motion; `--headless` cannot verify
   visuals or audio.
6. Re-export and check the asset is inside the build (the preset uses
   `export_filter="all_resources"` and embeds the `.pck`, so anything under `res://` is
   included by default).
7. If the asset carries a licence, add its name, source URL and licence to
   `README.md § 8` and to the credits in the main menu.
