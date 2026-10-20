# Exports — Android, Web, iOS, Windows

**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`
**Export templates:** `%APPDATA%\Godot\export_templates\4.7.2.stable` (`version.txt` = `4.7.2.stable`)
**Last export run:** 2026-10-20 (all three working presets re-exported from the current source
after the interface and art pass; sizes re-measured, APK signature and manifest re-verified,
Windows build relaunched headless, Web build re-run in Chrome)

This file records what was actually exported, on what toolchain, with what
evidence, and what was **not** verified. Nothing here is aspirational: if an
artefact is listed with a size, it exists on disk; if a platform is marked
NOT TESTED, no build was produced for it.

---

## 1. Status summary

| Platform | Preset | Build produced | Runs on the target | Evidence |
| --- | --- | --- | --- | --- |
| Windows desktop | `Windows Desktop` | **YES** — `build/FlukeFreeKitchen.exe` | **PASS** (launched headless, 8 s, no errors) | engine banner on stdout, empty stderr |
| Web (HTML5) | `Web` | **YES** — `build/web/` | **PASS** (rendered in real Chrome) | DevTools-protocol check: canvas 1254×564, `Engine` global present, 0 console errors, screenshot |
| Android | `Android` | **YES** — `build/android/FlukeFreeKitchen.apk` | **NOT TESTED** — no device or emulator was available | APK built, `apksigner verify` PASS, manifest + contents inspected |
| iOS | `iOS` | **NO** | **BLOCKED** — requires macOS + Xcode | reason recorded in §6 |

The three presets that exist now:

```
[preset.0]  Windows Desktop
[preset.1]  Web
[preset.2]  Android
[preset.3]  iOS
```

### 1.1 Re-export and re-verification — 2026-10-17

An export is only evidence for the source it was built from, so after the outcome-B change all
three working presets were re-exported from the current source and re-checked:

| Artefact | Size (2026-10-17) | Check |
| --- | --- | --- |
| `build/FlukeFreeKitchen.exe` | 104.605 MB | export exit 0, no errors |
| `build/web/` | wasm 37.684 MB · pck 0.399 MB · js 0.267 MB | served over HTTP and opened in real headless Chrome via the DevTools protocol: title *Fluke Free Kitchen*, canvas 1254 × 564, `Engine` global present, **0 console errors**, screenshot inspected |
| `build/android/FlukeFreeKitchen.apk` | 55.349 MB | export exit 0 (aligned + signed); `apksigner verify` — v2 **true**, v3 **true**, 1 signer, `CN=Android Debug` |

The APK is a debug build and is still **NOT** installed or launched on any device.

### 1.2 Re-export and re-verification — 2026-10-18

The animation library (`scripts/world/anim.gd`) and the sustained audio beds changed
only GDScript, so the export toolchain and presets are untouched; the three working
presets were re-exported so the packaged `.pck` matches the current source, and the
artefacts were re-checked:

| Artefact | Size (2026-10-18) | Check |
| --- | --- | --- |
| `build/FlukeFreeKitchen.exe` | 104.754 MB | export exit 0, no errors; relaunched `--headless --quit-after 300`: engine banner on stdout, empty stderr |
| `build/web/` | wasm 37.684 MB · pck 0.548 MB · js 0.267 MB | export exit 0; the re-exported `.pck` was then loaded in real headless Chrome over the DevTools protocol (`node tools/web_smoke.mjs`): title *Fluke Free Kitchen*, canvas 1254 × 564, `Engine` global present, **0 console errors**, screenshot `build/web_smoke.png` |
| `build/android/FlukeFreeKitchen.apk` | 55.505 MB | `--export-debug` exit 0 (aligned + signed); `apksigner verify` — v2 **true**, v3 **true**, 1 signer, `CN=Android Debug`; manifest re-printed: package `th.ac.kku.flukefreekitchen`, minSdk 24, targetSdk 36, `compileSdkVersion 36`, **no `<uses-permission>` elements** |

The APK remains a debug build and is still **NOT** installed or launched on any device.

### 1.3 Re-export and re-verification — 2026-10-20 (interface and art pass)

The interface and art pass changed game code under `scripts/` (new `UIIcon` and
`AmbientBackground`, a rebuilt `KitchenProps.fish`, a painted `DishPreview`, the `UIFactory`
style/motion layer and the restyled screens), so all three working presets were re-exported
and re-checked:

| Artefact | Size (2026-10-20) | Check |
| --- | --- | --- |
| `build/FlukeFreeKitchen.exe` | 104.775 MB | export exit 0, no errors; relaunched `--headless --quit-after 300`: engine banner on stdout, **0** error lines |
| `build/web/` | wasm 37.684 MB · pck 0.568 MB · js 0.267 MB | export exit 0; the re-exported `.pck` was then loaded in real headless Chrome over the DevTools protocol (`node tools/web_smoke.mjs`): title *Fluke Free Kitchen*, canvas 754 × 424, `Engine` global present, **0 console errors**, screenshot `build/web_smoke.png` |
| `build/android/FlukeFreeKitchen.apk` | 55.525 MB | `--export-debug` exit 0 (aligned + signed); `apksigner verify` — v2 **true**, v3 **true**, 1 signer; `aapt2 dump badging` — package `th.ac.kku.flukefreekitchen`, minSdk 24, targetSdk 36, compileSdk 36; `apkanalyzer manifest print` — **0 `<uses-permission>` elements** |

The APK remains a debug build and is still **NOT** installed or launched on any device.

---

## 2. What had to change to make the mobile/web exports possible

These are source changes, not one-off build flags. They are committed to the
project files, so a fresh clone exports the same way.

### 2.1 `project.godot`

| Setting | New value | Why |
| --- | --- | --- |
| `application/config/icon` | `res://icon.svg` | Was **unset**. Android export hard-fails with *"No project icon specified"*, and without it the APK has no launcher icon. Godot rasterises the SVG into all 25 `mipmap-*` launcher resources (including the adaptive-icon foreground/background layers). |
| `rendering/textures/vram_compression/import_etc2_astc` | `true` | Was **unset**. Android export hard-fails with *"ETC2/ASTC texture compression is required for Android export"*. Mobile GPUs do not accept the S3TC/BPTC-only variants the project was previously importing. |

`display/window/handheld/orientation=6` (screen sensor) and
`display/window/stretch/mode="disabled"` were already set and are what let the
game follow device rotation and reflow its UI instead of scaling it.

### 2.2 `build/.gdignore` (new file)

`build/` sits inside the project, and Godot's resource scanner walks into it
unless told not to. This is not theoretical: the first Android export bundled
`build/web/index.png`, `index.icon.png` and `index.apple-touch-icon.png` into
the APK as imported textures. Adding `build/.gdignore` stops the scanner at the
directory, and every preset now also carries `exclude_filter="tests/*,build/*"`
as a second line of defence. After the fix the APK contains **0** build-output
entries.

### 2.3 Editor settings (`%APPDATA%\Godot\editor_settings-4.7.tres`)

The Android platform reads its toolchain paths from Godot's *editor* settings,
not from the project, so these are per-machine and are not in the repository:

```ini
export/android/android_sdk_path  = "C:/Users/ASUS/Android/Sdk"
export/android/java_sdk_path     = "C:/Program Files/Android/openjdk/jdk-21.0.8"
export/android/debug_keystore    = "C:/Users/ASUS/.android/debug.keystore"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
```

See §5 for how to reproduce that toolchain on another machine.

---

## 3. Windows desktop

```powershell
godot --headless --path . --export-release "Windows Desktop" build/FlukeFreeKitchen.exe
```

| Property | Value |
| --- | --- |
| File | `build/FlukeFreeKitchen.exe` |
| Size | 104.775 MB |
| Architecture | x86_64 |
| PCK | embedded (`binary_format/embed_pck=true`) |
| Icon | `res://icon.svg` |
| Excluded | `tests/*`, `build/*` |

**Verified:** launched with `--headless --quit-after 300`: it stayed up, stdout
contained only the normal `Godot Engine v4.7.2.stable.official.ed1daf0bf` banner,
and stderr was empty. That proves the export boots and that every autoload and
resource resolved; it does **not** prove the interactive loop, which is covered by
the eight test suites run against the project itself.

---

## 4. Web (HTML5)

```powershell
godot --headless --path . --export-release "Web" build/web/index.html
```

| File | Size | Note |
| --- | --- | --- |
| `index.html` | 5 KB | default Godot shell, `canvas_resize_policy=2` (adaptive) |
| `index.js` | 267 KB | loader |
| `index.wasm` | 37.684 MB | engine |
| `index.pck` | 568 KB | the game |
| `index.png`, `index.icon.png`, `index.apple-touch-icon.png` | — | page icons |
| `index.audio.worklet.js`, `index.audio.position.worklet.js` | — | Web Audio worklets |

### 4.1 Threading choice

`variant/thread_support=false`. This is deliberate: a threaded build only runs
behind `Cross-Origin-Opener-Policy: same-origin` +
`Cross-Origin-Embedder-Policy: require-corp`, which most simple hosts (a school
web server, a USB stick served by `python -m http.server`, GitHub raw, most
school LMS file viewers) do not send. A single-threaded build runs anywhere.
The cost is CPU-side throughput; on a menu-and-3D-scene game of this size that
is an acceptable trade for *it actually opening*.

`tools/serve_web.py` ships with the project and serves the folder with
the correct `.wasm` MIME type. It takes `--threads` to add the COOP/COEP
headers, for if the preset is ever switched back to threaded.

### 4.2 Verification — what was actually done

`--headless --screenshot` was **not** enough: it captured the Godot boot splash
at ~85 % because the browser spends real seconds compiling a 37 MB WebAssembly
module. Instead the build was driven through the Chrome DevTools protocol by
`tools/web_smoke.mjs`, which waits, then reads back the page state and every
console message:

```
--- Fluke Free Kitchen web build check ---
  opening http://localhost:8060/index.html
  title: Fluke Free Kitchen
  canvas: {"w":1254,"h":564,"cw":1254,"ch":564}
  Engine global present
--- results ---
WEB BUILD CHECK PASSED (page loaded, canvas present, no console errors)
```

The captured frame shows the Thai main menu rendering correctly — Sarabun
glyphs, tone marks and all, with the responsive two-column layout. Reproduce
with:

```powershell
python tools/serve_web.py --port 8060            # in one terminal
chrome --headless=new --remote-debugging-port=9222 --remote-allow-origins=* `
       --enable-unsafe-swiftshader --no-sandbox --user-data-dir=<temp> about:blank
node tools/web_smoke.mjs --url http://localhost:8060/index.html --out web.png --wait 32000
```

**Not verified for web:** touch input on a real device, audio autoplay policy
behaviour, and performance on low-end hardware. Software rendering
(SwiftShader) was used, so the frame rate measured here is not indicative.

---

## 5. Android

```powershell
godot --headless --path . --export-debug "Android" build/android/FlukeFreeKitchen.apk
```

| Property | Value |
| --- | --- |
| File | `build/android/FlukeFreeKitchen.apk` (55.525 MB) + `FlukeFreeKitchen.apk.idsig` (0.443 MB) |
| Package | `th.ac.kku.flukefreekitchen` |
| Version | versionCode `1`, versionName `1.0` |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 |
| ABIs | `arm64-v8a`, `armeabi-v7a` (both `libgodot_android.so` + `libc++_shared.so`) |
| Build type | **debug** (`android:debuggable="true"`) |
| Signing | APK Signature Scheme **v2 and v3** (debug keystore) |
| Permissions requested | **none** — the manifest has no `<uses-permission>` at all, not even `INTERNET` |
| Orientation | `fullUser` — follows device rotation in all four directions, honouring a user's rotation lock |
| Multi-window | `resizeableActivity="true"` |
| Launcher icon | 25 generated resources from `icon.svg` (adaptive foreground/background/monochrome) |

### 5.1 Why "no permissions" matters

The game is offline by design. The exported manifest proves that claim rather
than asserting it: there is no `<uses-permission>` element anywhere in the APK.
This is worth stating in the competition report — it is a verifiable
data-protection property, not a promise.

### 5.2 Verification — what was actually done

| Check | Tool | Result |
| --- | --- | --- |
| Build completed, no errors | Godot exporter | PASS — `[ DONE ] export`, exit clean |
| Signature valid | `apksigner verify --verbose` | PASS — v1 `false`, **v2 `true`, v3 `true`**, 1 signer |
| Package/label/SDK levels | `aapt2 dump badging` | PASS — matches the table above |
| Manifest contents | `apkanalyzer manifest print` | PASS — no permissions, GLES 3.0 required |
| Native libraries present for both ABIs | ZIP inspection | PASS |
| No build output leaked in | ZIP inspection | PASS — 0 `build/web` entries (it was 3 before the `.gdignore` fix) |
| Launcher icons embedded | ZIP inspection | PASS — 25 resources |

`apkanalyzer` warns that `aapt2` exits 1 over a `themed_icon` file reference
that the Godot Gradle template declares but does not ship. It is a cosmetic
template quirk inherited from Godot's own `android_source.zip`; the APK
installs and the icon resolves through `mipmap-anydpi-v26/icon.xml`.

### 5.3 What is NOT tested

- **The APK has never been installed or launched.** No Android device was
  attached and no emulator was available. "It builds, it is signed, and its
  internals are correct" is not the same claim as "it runs", and only the first
  is being made.
- Because `android:glEsVersion="0x30000"` is `required="true"`, a device
  without OpenGL ES 3.0 cannot install it at all. Essentially every Android
  device from ~2013 onwards has ES 3.0.
- Touch input, the virtual keyboard, safe-area insets (notches), back-button
  behaviour and thermals are all unverified on hardware.

To install on a device once one is available:

```powershell
$env:ANDROID_HOME = "C:\Users\ASUS\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" install -r build\android\FlukeFreeKitchen.apk
```

### 5.4 Producing a release APK or an AAB (not done)

The committed preset exports a **debug** APK, which is what "hand it to
someone to install" needs. For the Play Store you need a release keystore that
you keep forever (losing it means you can never update the app):

```powershell
$jdk = "C:\Program Files\Android\openjdk\jdk-21.0.8"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.android" | Out-Null
& "$jdk\bin\keytool.exe" -keyalg RSA -genkeypair -alias flukefree `
    -keystore "$env:USERPROFILE\.android\release.keystore" -validity 10950 `
    -dname "CN=Fluke Free Kitchen, O=<your organisation>, C=TH"
```

then set `export/android/release_keystore`, `_user`, `_pass` in Editor Settings
and change `gradle_build/export_format=1` in the preset for an AAB.
**Not performed** — it would store a private key, and that is a decision for
the project owner, not for an automated pass.

### 5.5 Reproducing the toolchain

Godot 4.7's Android requirements were read out of the shipped Gradle template
(`config.gradle` in `android_source.zip`), not guessed:
`compileSdk 36`, `targetSdk 36`, `buildTools 36.1.0`, `minSdk 24`,
`androidGradlePlugin 8.6.1`, `javaVersion 17`.

What was installed on this machine:

| Component | Version / location |
| --- | --- |
| JDK | **21.0.8** — `C:\Program Files\Android\openjdk\jdk-21.0.8` (already present) |
| Android command-line tools | `commandlinetools-win-16111833_latest.zip` → `C:\Users\ASUS\Android\Sdk\cmdline-tools\latest` |
| `platform-tools` | 37.0.1 (`adb`) |
| `platforms;android-36` | API 36, rev 2 |
| `build-tools;36.1.0` | provides `apksigner`, `zipalign`, `aapt2` |
| Licenses | `licenses/android-sdk-license` accepted |
| Debug keystore | `C:\Users\ASUS\.android\debug.keystore`, alias `androiddebugkey`, store/key pass `android` |

Two traps, both hit here:

1. **`;` in package names.** `sdkmanager "platforms;android-36"` fails with
   *"Package platforms not found. Package android-36 not found."* — the package
   id is split at the semicolon before it reaches the tool. Wrap the whole
   invocation in `cmd /c`:
   ```powershell
   cmd /c '"C:\Users\ASUS\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="C:\Users\ASUS\Android\Sdk" "platforms;android-36" "build-tools;36.1.0"'
   ```
2. **`apkanalyzer` needs JDK 17+ on `PATH`.** This machine's `PATH` java is
   1.8, which makes `apkanalyzer` exit with *"Java version 17 or higher is
   required"*. Point `JAVA_HOME` at the JDK 21 first.

A **release** APK needs no Gradle build template installed. `gradle_build/use_gradle_build=false`
keeps the export on the prebuilt template path, so only `build-tools` (for
`apksigner`/`zipalign`) is actually required — no `gradlew` run, no
`android/build/` folder in the project, and no network access at export time.

---

## 6. iOS — BLOCKED

An `iOS` preset now exists in `export_presets.cfg` so the project is ready, but
**no iOS build was produced and the preset is untested.** Godot's iOS exporter
requires Xcode on macOS; there is no cross-compiler for it on Windows. Apple's
toolchain licence also only permits building on Apple hardware.

```powershell
# This does not work on Windows. It is listed so the failure mode is documented.
godot --headless --path . --export-release "iOS" build/ios/FlukeFreeKitchen.ipa
```

What is needed on a Mac:

1. Godot 4.7.2 stable (macOS build) and the 4.7.2 export templates.
2. Xcode with the iOS SDK, plus `xcode-select --install` command-line tools.
3. An Apple Developer account; for a device build, an App Store team ID and
   provisioning profile.
4. Then set, in the preset or in Editor Settings: `app_store_team_id`,
   `code_sign_identity_*`, `provisioning_profile_uuid_*`, and
   `export_method_debug` / `export_method_release`.

Two iOS-specific things worth checking at that point, neither of which can be
checked from here:

- `application/targeted_device_family=2` is set to *universal*. Switch to `0`
  (iPhone) or `1` (iPad) if the game is only meant for one.
- The game reports no permissions, so `privacy/*_usage_description` should stay
  empty. If a camera/microphone string is ever added without the matching
  capability, App Review rejects it — and note that the *motion controls*
  discussion in `docs/PROJECT_AUDIT.md` concluded motion input is N/A for this
  interaction set, so there is no `motion` usage string to add.

**Nothing in this section was executed.** It is a plan, not a result.

---

## 7. Rebuilding everything

```powershell
$godot = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe"
$p     = "C:\Users\ASUS\river-dash-safe-feast-run"

& $godot --headless --path $p --import                                      # refresh imports
& $godot --headless --path $p --export-release "Windows Desktop" "$p\build\FlukeFreeKitchen.exe"
& $godot --headless --path $p --export-release "Web"             "$p\build\web\index.html"
& $godot --headless --path $p --export-debug   "Android"         "$p\build\android\FlukeFreeKitchen.apk"
```

Notes that cost time to rediscover:

- `Start-Process` splits unquoted arguments containing spaces, so the preset
  name must be passed as `'"Windows Desktop"'`, not `"Windows Desktop"`.
- Import the project (`--import`) after touching `project.godot`. The change to
  `import_etc2_astc` in particular needs a re-import before the Android export
  will succeed.
- Godot writes its progress to **stdout** and its errors to **stderr**. A
  parse error means `quit()` never runs and a naive wait hangs forever, so
  always redirect both streams and impose a timeout.

---

## 8. Where each artefact is

```
build/
  .gdignore                      # keeps the scanner out of this directory
  FlukeFreeKitchen.exe           # Windows desktop, 104.78 MB
  android/
    FlukeFreeKitchen.apk         # Android debug, 55.53 MB
    FlukeFreeKitchen.apk.idsig   # v4 signature side-file (unused, harmless)
  web/
    index.html index.js index.wasm index.pck
    index.png index.icon.png index.apple-touch-icon.png
    index.audio.worklet.js index.audio.position.worklet.js
```

`build/` is output. It can be deleted and regenerated at any time; nothing in
it is a source of truth.
