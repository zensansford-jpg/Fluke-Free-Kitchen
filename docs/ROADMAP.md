# Roadmap — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Created:** 2026-10-17 · **Owner split:** 🤖 = doable with code in this environment · 👤 = needs a person (device, recording, language review) · ⛔ = blocked by environment/ethics

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

## 2. Baseline as of 2026-10-17 (verified this session)

| Check | Result | Evidence |
|-------|--------|----------|
| All 5 Godot test suites | ✅ **5/5 PASS** | `tools/run_all_tests.ps1` → smoke, flow, behaviour, cook, responsive |
| Responsive layout matrix | ✅ **132/132 layouts** across 12 sizes | `responsive_check` |
| Study data pipeline | ✅ **SELFTEST PASSED** | `analyse_export.py --selftest` (statistics pinned, synthetic data, empty-folder guard) |
| Windows export present | ✅ 104.605 MB | `build/FlukeFreeKitchen.exe` |
| Web export present | ✅ wasm 37.684 MB, pck 0.399 MB, js 0.267 MB | `build/web/` |
| Android export present + signed | ✅ 55.349 MB, `apksigner verify` v2+v3 true, 1 signer | `build/android/FlukeFreeKitchen.apk` |
| All 11 health sources verified | ✅ | `docs/REFERENCES.md` §6 |

---

## 3. Workstreams

### A. Feature completeness vs the brief (🤖)

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| A1 | Outcome **A** — safe dish | ✅ PASS | `flow_test` completes every level; cook passes at ~8.7 s |
| A2 | Outcome **C** — burnt/overcooked + quick retry | ✅ PASS | `cook_test` (burnt → retry → fresh fish, mistake kept) |
| A3 | Outcome **B** — *unsafe serving*: non-graphic, skippable, and it distinguishes **exposure risk** from **infection** | ✅ PASS | There was **no way to serve undercooked fish at all**. The cooking step now offers a deliberate "serve it now" choice; taking it under the safe temperature ends the step in the B outcome, records a mistake, separates exposure risk / infection / cancer in words, and offers either a fresh fish or "keep cooking this one" (one tap past the message). Covered by `cook_test` ("outcome B: an unsafe serving ended the step and was recoverable"); screenshot `cook_4_unsafe_serve.png` |
| A4 | Progressive cooking visuals raw→golden→burnt, separate from safety logic | ✅ PASS | `cook_test`; `KitchenScene.set_fish_browning`, `_update_cook_ui` |
| A5 | Interactive cooking with correct fish/pan alignment | ✅ PASS | `behaviour_test`, `cook_test`, screenshots |
| A6 | Exactly 3 outcomes, no auto-stars/scores, no double-counting | ✅ PASS | `smoke_test` scoring asserts; `flow_test` |
| A7 | Motion/flip controls N/A and reported honestly | ✅ PASS | Documented as N/A for this interaction set (fixed angled camera + direct manipulation) |
| A8 | Save/load v2 validated, corrupt-file handling, atomic write | ✅ PASS | `smoke_test` reset/load; `autoload/save_manager.gd` |
| A9 | Thai/English, no missing glyphs/tone marks, no clipped text | 🟡 PARTIAL | Responsive checker fails overflowing labels; full matrix passes. **Native-speaker review still 👤** |

### B. Verification & repeatability (🤖)

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| B1 | One command runs every suite | ✅ PASS | `tools/run_all_tests.ps1` (added this session) |
| B2 | Re-validate existing exports without rebuilding | ✅ PASS | `apksigner verify`; size listing (this session) |
| B3 | Reproducible re-export from the current source | ✅ PASS | All three working presets re-exported 2026-10-17 after the outcome-B change; Web build re-opened in real Chrome (0 console errors); APK signature re-verified. A clean-checkout re-export on another machine is still 👤/optional |
| B4 | Web build runs in a real browser (0 console errors) | ✅ PASS | CDP check + screenshot; `docs/EXPORTS.md` §4 |
| B5 | Memory/perf measurement on real hardware | ⛔ BLOCKED | No device; window resizing on one laptop is not a device measurement |

### C. Content & science (🤖 done, 👤 review left)

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| C1 | Every claim traceable, 11 sources verified | ✅ PASS | `docs/SCIENTIFIC_CONTENT.md`, `docs/REFERENCES.md` |
| C2 | Six ideas kept distinct (transmission/food/sanitation/screening/treatment/cancer) | ✅ PASS | `SCIENTIFIC_CONTENT.md` §1 |
| C3 | No invented temperature/duration; golden ≠ safety | ✅ PASS | `task.colour_not_proof`; `cook_thoroughly` lesson |
| C4 | Screening lesson matches CDC nuance (not travel-only self-testing) | ✅ PASS | Corrected this project's previous revision; `references.md` [2] |
| C5 | Independent health-professional review | 👤 HUMAN | Not done; recommend before submission |

### D. Study (⛔/👤)

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| D1 | Instrument, forms, protocol, analysis tool | ✅ PASS | `docs/study/`, `docs/STUDY_PROTOCOL.md`, `tools/study/` |
| D2 | Ethics approval, consent, assent | ⛔ BLOCKED | Must precede any data collection; not obtained |
| D3 | Collected data + Chapter 4 results | ❌ NOT DONE | Marked placeholders in `docs/report/ch4_results.md` §4.5. **Never fabricate** |

### E. Competition deliverables (👤 mostly)

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| E1 | Report chapters 1–5 (Thai) | 🟡 drafted | `docs/report/ch1…ch5`; needs typesetting + real screenshots |
| E2 | Abstract / proposal / summary | 🟡 drafted | `docs/report/00_abstract_and_proposal.md` |
| E3 | References list | ✅ ready | `docs/report/references.md` |
| E4 | ≤ 7-min video | 🟡 scripted | `docs/report/video_script.md`; not recorded |
| E5 | Display board (150 cm) | 🟡 planned | `docs/report/board_layout.md`; not built |
| E6 | Logbook | 🟡 template | `docs/report/logbook.md`; keep with real dates |
| E7 | Registration / oral script | ❌ NOT DONE | By the team |

### F. Platform reach

| # | Item | Status | Evidence / next action |
|---|------|--------|------------------------|
| F1 | Windows | ✅ PASS | launched clean |
| F2 | Web (single-threaded, static host) | ✅ PASS | real Chrome, 0 errors |
| F3 | Android build/sign | ✅ PASS | apksigner v2+v3 |
| F4 | Android runtime on hardware | ⛔ BLOCKED | no device/emulator (SDK image ~1.5 GB at ~190 KB/s) |
| F5 | iOS | ⛔ BLOCKED | needs macOS + Xcode; preset committed, untested |

---

## 4. What "continue all" means concretely (🤖 queue)

1. ~~**A3 — implement Outcome B** and cover it with a test~~ — **done**, 5/5 suites green.
2. ~~Re-run `tools\run_all_tests.ps1` and confirm 5/5 still green~~ — **done**.
3. ~~Fix the bottom-sheet fitting so a tall sheet (the B message) is not clipped by the
   HUD's stale height measurement~~ — **done** (`KitchenTask._fit_sheet` / `_refit_measured`,
   `KitchenHUD.content_top()`); all four existing sheets re-checked in a windowed run.
4. ~~Commit~~ — see git log.
5. ~~Add a short `docs/QA_CHECKLIST.md`~~ — **done** (`docs/QA_CHECKLIST.md`: run it, play it, look at
   the sizes, export it, the human items, and the paperwork).

Everything else in §3 that is not ✅ is either 👤 (a person must do it) or ⛔ (blocked by the
environment or by ethics). Those are **not** silently dropped; they are named with their reason.

---

## 5. Definition of done (per workstream)

| Workstream | Done when |
|-----------|-----------|
| A | All three outcomes A/B/C exist and each is covered by a test; 5/5 suites pass |
| B | `run_all_tests.ps1` passes on a clean checkout; exports re-validate |
| C | Every source `verified`; a health professional signs off |
| D | Ethics approved, data collected, Chapter 4 filled from real data, analysis reported |
| E | Typeset PDF within page limits, video uploaded, board built, logbook kept |
| F | APK installed and played on a real phone; iOS built on a Mac |
