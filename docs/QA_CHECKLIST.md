# QA checklist — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Use this before a demo, before submission, and again after any change to the source.**
Every line is either a command whose result you can look at, or a task only a person can do.
Tick nothing you have not actually seen. This is a condensed, practical view of
`docs/ROADMAP.md`; the evidence behind each PASS is recorded in `docs/PROJECT_AUDIT.md` §13.

Legend: 🤖 run it · 👁 look at it · 👤 needs a person

---

## 1. Run the checks (🤖, ~10 minutes)

```powershell
# 1. Every Godot suite, one summary line each. Expect: 8/8 suites passed.
powershell -ExecutionPolicy Bypass -File tools\run_all_tests.ps1

# 2. The study data pipeline, on synthetic records only. Expect: SELFTEST PASSED.
python tools\study\analyse_export.py --selftest
```

- [ ] 1. `run_all_tests.ps1` → **smoke · flow · behaviour · cook · recipe · minigame · responsive** all print PASSED
- [ ] 2. `responsive_check` reports **360/360 layouts** across the 12 sizes
- [ ] 3. `analyse_export.py --selftest` → all statistics match their reference values

If any of these fails, stop: do not demo or submit until it is green again.

---

## 2. Play it once, deliberately (👁, ~15 minutes)

Play on the machine you will demo on, in **Thai**, then flip to **EN** mid-session.

- [ ] Menu → **เล่น** starts a challenge; nothing starts by itself
- [ ] The first step of each challenge is demonstrated before you are asked to do it
- [ ] Stars are **0** before you earn them; a score never appears out of nowhere
- [ ] Every step ends with a lesson card you must read past
- [ ] The knowledge question must be answered correctly before the level can pass
- [ ] Level 1, 2 and 3 can each be finished; the journal then shows all **13 lessons**
- [ ] Quitting mid-level and returning does not carry a half-finished attempt into a new one
- [ ] **Outcome A** — cook the fish properly: the step succeeds at a safe inside temperature
- [ ] **Outcome B** — press **เสิร์ฟเลยตอนนี้ / Serve it now** while the fish is still cold: the
      step stops, says the eater would be *exposed* (a risk, not an infection, not cancer), and
      offers a fresh fish or keep cooking — either leaves the message in one tap
- [ ] **Outcome C** — hold the heat until the fish burns: the burnt outcome appears with a retry
- [ ] After B or C, the mistake is still counted (a retry must not erase it)
- [ ] The panel that says a golden colour is not a safety check is on screen while cooking
- [ ] Holding the heat makes the pan **hiss continuously** and letting go stops it; a pot recipe
      bubbles instead of hissing; washing the board runs water only while you scrub
- [ ] Nothing teleports: the fish visibly browns as it heats, and carried items, the flip, the cut
      and the knife all move smoothly rather than jumping
- [ ] Settings: pause really pauses; closing a dialog does not lose the attempt
- [ ] Turning the language to EN and back does **not** restart or lose the challenge
- [ ] Nothing overlaps or is cut off at the demo window size, in both languages

---

## 3. Look at the layout across sizes (👁)

The matrix already runs headless; this is about *looking* at a few of the extremes.

```powershell
# NB: no --headless. The dummy renderer cannot read the framebuffer, so screenshots
# need a real window (the run quits by itself when it is done).
godot --path . res://tests/responsive_check.tscn -- 320 568 shots
godot --path . res://tests/responsive_check.tscn -- 3840 2160 shots
```

- [ ] Open the screenshots the run writes to `build\screenshots\responsive` and confirm nothing is
      squeezed to a sliver, clipped, or overlapping (the full 12-size set was regenerated on
      2026-10-20 with a real GPU: 360/360 layouts, 300 PNGs)
- [ ] Rotate the window from landscape to portrait while a challenge is running: the panel reflows
      and the wok stays framed
- [ ] Increase the OS text size / display scaling and repeat step 2's "nothing overlaps" line

---

## 4. Exports (🤖 build, 👁 run)

```powershell
godot --headless --path . --export-release "Windows Desktop" build/FlukeFreeKitchen.exe
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-debug  "Android" build/android/FlukeFreeKitchen.apk
```

- [ ] Windows `.exe` launches and plays
- [ ] Web build served over HTTP (`python tools/serve_web.py`) plays in a browser; console clean
      (re-verified 2026-10-18 on the re-exported build: canvas 1254 × 564, 0 console errors)
- [ ] Android APK verifies: `apksigner verify --verbose build/android/FlukeFreeKitchen.apk` → v2/v3 true
- [ ] Android APK **installed on a real phone** (`adb install -r …`) and played once — this is the
      step that has *not* been done yet
- [ ] iOS: not possible on Windows (macOS + Xcode required) — state this, do not claim it

---

## 5. Signs and study material (👤)

- [ ] A native Thai speaker has read every screen and every string in `scripts/data/ui_strings.gd`
      and `scripts/data/lesson_data.gd`
- [ ] An English speaker has read the English tier of the same
- [ ] A health professional has read `docs/SCIENTIFIC_CONTENT.md` and agrees with each claim
- [ ] Each of the 11 sources in `docs/REFERENCES.md` still opens at the URL given
- [ ] The five forms in `docs/study/` have been read and approved by the school
- [ ] **If and only if** a study will be run: parent information sheet, consent, student assent and
      ethics approval are all in place **before** any data is collected

---

## 6. Competition paperwork (👤)

- [ ] The report set in `docs/report/` is typeset to A4, TH SarabunPSK 16 pt, within the page limits
- [ ] Real screenshots are inserted (no placeholders)
- [ ] The report contains **no** learning-outcome number, participant count or improvement
      percentage — nothing was measured
- [ ] The ≤ 7-minute video follows `docs/report/video_script.md` and shows no unmeasured result
- [ ] The 150 cm board is built from `docs/report/board_layout.md`
- [ ] The logbook has real dates in it (replace every "(ประมาณ)")
- [ ] Registration form submitted; oral presentation rehearsed to ≤ 5 minutes

---

## 7. If something fails

1. Note the exact command, the window size, the language and the screen.
2. Re-run the single suite, not the whole set: `godot --headless --path . res://tests/<suite>.tscn`.
3. Check `docs/PROJECT_AUDIT.md` §13 for whether it was ever PASS, and `docs/ROADMAP.md` for the
   owner (🤖 / 👤 / ⛔).
4. Fix the cause, then re-run `tools\run_all_tests.ps1` before anything else.
