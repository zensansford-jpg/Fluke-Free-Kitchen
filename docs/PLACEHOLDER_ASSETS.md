# Placeholder assets, and how to replace them

**The headline: this project ships no binary placeholder art or audio.** Every material, mesh,
effect, music bed and sound is generated in code at startup, so there is nothing to hunt down and
delete. What follows is where each generated asset comes from and the exact hook to swap in a real
one.

The only binary assets in the repository are the **Sarabun fonts** (SIL Open Font Licence 1.1),
which are the intended typeface and not a placeholder, and `icon.svg` for the application icon.

| Category | Status | Produced by | Replacement hook |
| --- | --- | --- | --- |
| Surface materials / textures | Generated (73 named, deterministic 64 px noise) | `scripts/world/game_materials.gd → _build()` | set `albedo_texture` in `_textured()` / `_build()` |
| 3D props and the kitchen set | Generated primitives | `scripts/world/kitchen_props.gd`, `scripts/world/prop_factory.gd` | replace the body of one builder, keep its signature |
| The cook character | Generated primitives + code poses | `scripts/world/kitchen_character.gd → build()` | swap the rig; keep `build()` and `react(kind)` |
| Water | Shader | `shaders/water.gdshader` via `PropFactory.water_material()` | edit the shader (a fallback already exists) |
| Sound effects (20) | Synthesised | `autoload/audio_manager.gd → _synth_sfx()` | `AudioManager._load_overrides()` |
| Sustained beds (3) | Synthesised, looping | `audio_manager.gd → _synth_loop()` | same |
| Music (3) | Synthesised | `audio_manager.gd → _synth_music()` | same |
| Ambience (2) | Synthesised | `audio_manager.gd → _synth_ambience()` | same |
| Icon | Placeholder SVG | `icon.svg` | replace the file (same name) |
| Font | **Intended** (Sarabun, OFL) | `assets/fonts/` | optional: another OFL font + edit the paths in `prop_factory.gd` |
| Motion rhythm | **Intended** | `scripts/world/anim.gd` | not an asset: changing it changes how the kitchen feels everywhere |
| Health copy, tuning, strings, layout | **Intended, not placeholder** | `scripts/data/`, `scripts/ui/ui_factory.gd` | see the note at the end |

---

## 1. Materials and textures

**Current behaviour.** `GameMaterials` builds a deterministic 64 × 64 noise texture per material
from code (`noise_texture()`, `TEX_SIZE = 64`) and caches the finished `StandardMaterial3D` by name
in a static dictionary. 73 materials are named — `wood`, `tile_floor`, `fish_raw`, `fish_cooked`,
`steel_dull` and so on. An unknown name does **not** crash: `_build()`'s default branch returns a
plain material.

**Why it is a placeholder.** 64 px procedural noise reads as the right tone and roughness, but it
is not real texture art: no normal maps, no close-range detail, no hand-made variation between two
planks.

**To replace.**

1. Drop real textures into `res://assets/textures/` (PNG, ideally with a matching `*_normal.png`).
2. In `game_materials.gd`, give `_textured()` a texture-path parameter, or special-case one name
   inside `_build()`:

   ```gdscript
   "wood":
       var m := _textured(name, Color(0.55, 0.36, 0.22), 0.05, 117, 0.5)
       m.albedo_texture = load("res://assets/textures/wood.png")
       m.normal_texture = load("res://assets/textures/wood_normal.png")
       return m
   ```

3. Keep the material **names** unchanged — they are the interface every prop builder uses
   (`PropFactory.box(parent, size, "wood", …)`).

**Verify:** run the game for real (not `--headless`) and confirm no "resource not found" errors;
check the export includes `assets/textures/`.

---

## 2. Props and the kitchen set

**Current behaviour.** Everything is assembled from Godot primitives (box, cylinder, sphere,
prism, plane, torus) through `PropFactory` and `KitchenProps`. `KitchenProps` is the kitchen set:
`room()`, `counter()`, `sink()`, `stove()`, `chopping_board()`, `knife()`, `fish()`, `plate()`,
`basket()`, `chef()` and the ingredient visuals. `PropFactory` supplies the primitives, the water,
the label meshes and the shared font.

**Why it is a placeholder.** These are readable, correctly proportioned proxies, not modelled art.

**To replace.** Each prop has exactly one builder. Replace the body of one and keep its
**signature** and its return type — callers only rely on those. For example:

```gdscript
static func chopping_board(parent: Node3D, pos: Vector3, dirty: bool = false) -> Node3D:
    var root := (load("res://assets/models/board.glb") as PackedScene).instantiate()
    root.position = pos
    parent.add_child(root)
    return root
```

Anything the builders tag for food surfaces (`_tag_food_surface()`) and anything the tasks look up
by node name must keep that name — the cooking tasks find the fish, the grime layer and the pan by
name.

---

## 3. The cook character

**Current behaviour.** `scripts/world/kitchen_character.gd` builds the chef from primitives in
`build()` and animates facial poses in code: `react(kind)` where `kind` is one of `idle`, `happy`,
`celebrate`, `surprised`, `worried`, `think`, `encourage`, `oops`.

**To replace.** Swap the rig for an `AnimationPlayer`-driven `.glb` and map those `kind` keys onto
animation names inside `react()`. `build()` and `react(kind)` are the whole interface the kitchen
uses, so nothing else has to change. Keep the reactions **short** — a task never waits on them.

---

## 4. Water

**Current behaviour.** `shaders/water.gdshader`, wrapped by `PropFactory.water_material(flow_speed)`
and `KitchenProps.water_material()`. The loader checks the shader exists and falls back to a plain
material with a warning if it does not, so a missing shader cannot break the game.

**To replace.** Edit the shader in place, or point the wrapper at a `ShaderMaterial` of your own.
Keep `flow_speed` meaningful. The project policy is **no paid assets**; a free MIT/OFL asset is
fine, but then add its licence to the credits.

**Verify:** launch for real. `--headless` cannot compile or display shaders.

---

## 5. Audio

**Current behaviour.** `AudioManager._generate_all()` builds every stream at startup as an
`AudioStreamWAV` and routes it onto the `Master`, `Music` and `SFX` buses:

* `SFX_NAMES` (20): `chop`, `wash`, `scrub`, `stir`, `sizzle`, `bubble`, `pour`, `sprinkle`,
  `tap_ok`, `tap_bad`, `star`, `star_full`, `level_complete`, `paper`, `sweep`, `pop`, `ui_click`,
  `ui_back`, `page`, `error_soft`
* `LOOP_NAMES` (3): `loop_sizzle`, `loop_boil`, `loop_wash` — sustained beds a task fades in while
  a gesture lasts and out when it ends
* `MUSIC_NAMES` (3): `menu`, `kitchen`, `result`
* `AMBIENCE_NAMES` (2): `kitchen`, `village`

**Why it is a placeholder.** These are synthesis approximations (noise bursts, filtered beds, bell
tones, sweeps), not recorded audio.

**To replace.**

1. Drop files into `res://assets/audio/`.
2. Add a line to `AudioManager._load_overrides()`, e.g.

   ```gdscript
   overrides["chop"] = preload("res://assets/audio/chop.ogg")
   overrides["loop_sizzle"] = preload("res://assets/audio/sizzle_loop.ogg")
   ```

The generated stream is used for any name not in `overrides`, so you can replace one sound at a
time. A looping bed must actually loop: for an `.ogg` import that means enabling **Loop** in the
import settings.

**Verify:** launch for real — `--headless` uses a dummy audio driver and starts no playback on
purpose, so nothing can be heard there. The `smoke_test` suite only checks that every name exists;
listening is the real check.

---

## 6. Icon and window title

`icon.svg` is a placeholder mark. Replace the file (keep the name, or update
`application/config/icon` in `project.godot`), then run a headless `--import`.

---

## 7. What is **not** a placeholder

Do not casually change these:

* **The health copy** in `scripts/data/lesson_data.gd` is the reviewed product. Every claim carries
  a source and a review note; `docs/SCIENTIFIC_CONTENT.md` maps claims to lessons and
  `docs/REFERENCES.md` lists the sources and how each was checked. `Education.validate_database()`
  rejects a lesson that cites an unknown or disallowed source, so a careless edit fails loudly
  rather than shipping.
* **The tuning constants** in `scripts/data/game_config.gd` (including the safe internal
  temperature) are the tested baseline; the cooking tests assert against them.
* **The interface strings** in `scripts/data/ui_strings.gd` are the intended Thai and English copy;
  `Loc.validate_table()` refuses a key that is missing in either language.
* **The layout and visual identity** in `scripts/ui/ui_factory.gd` (colours, sizes, fonts) is the
  intended look, not a wireframe.
* **The motion rhythm** in `scripts/world/anim.gd` (TAP, POP, NUDGE, SETTLE) is deliberate; it is
  what makes two different actions feel like they belong to the same kitchen.

---

## 8. Replacement checklist

1. Add the asset under `res://assets/<category>/`.
2. Wire it through the hook above — never by editing gameplay logic.
3. Run a headless `--import`.
4. Run the eight suites (`powershell -File tools\run_all_tests.ps1`, or `docs/QA_CHECKLIST.md §1`)
   — they must all still pass.
5. Launch the game for real and look at or listen to the asset in motion; `--headless` cannot
   verify visuals or audio.
6. Re-export and check the asset is inside the build (`docs/EXPORTS.md`).
7. If the asset carries a licence, add its name, source URL and licence to the credits.
