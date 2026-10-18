# Responsive layout — *Fluke Free Kitchen* (ครัวปลอดพยาธิ)

**Version:** 2.0.0 · **Updated:** 2026-10-16
**Verification tool:** `tests/responsive_check.tscn` (`.gd`)
**Screenshots:** `%TEMP%\opencode\responsive\*.png` on this machine, produced by
`godot --path <project> res://tests/responsive_check.tscn -- <w> <h> shots`

---

## 1. Why this document exists

A phone-shaped window is not a scaled-down desktop window. The interface was therefore
built to **reflow**, not to shrink: it changes the number of columns, moves buttons and
text onto separate rows, drops optional decoration and gives long Thai labels the whole
width of the page when they need it.

Whether that actually works is not a matter of opinion, so it is measured. This document
records what was measured, at which sizes, with which tool, and what is still unverified.

---

## 2. The approach

| Decision | Reason |
|---|---|
| `display/window/stretch/mode = "disabled"` | One UI unit is one screen pixel, so 16 px text is 16 px tall on every device. `canvas_items` scaling was tried and rejected: on a 390 px-wide phone window it scaled the whole interface to about 0.3×, which is unreadable. |
| Breakpoint at **700 px** width (`UIFactory.COMPACT_WIDTH`) | Below it, grids collapse to one column, margins drop from 44 px to 16 px, and side-by-side elements stack. |
| `UIFactory` owns every size decision | One place for `fit_width()`, `fit_half()`, `grid_width()`, `heading_size()`, `columns()`, `ui_margin()`, `centre_row()`. Screens ask; they do not measure themselves. |
| Menu screens **rebuild** their page on resize | A menu is cheap to rebuild and the rebuild guarantees a correct layout. Debounced 0.18 s (`MenuScreen._reflow_soon()`). |
| The kitchen **reflows in place** | The 3D scene cannot be rebuilt mid-cooking, so `KitchenScreen.reflow()` re-fits the HUD, the task, the camera and every sheet instead. |
| Centring by container alignment, never by spacer `Control`s | Two expanding spacers add the row's separation on both sides to the minimum width. At 320 px that was enough to push a small sheet off the screen. |
| Grid children ask for a **column**, not the page | `UIFactory.grid_width()` caps a grid child's requested width at its share of the window. Before this, two 380 px buttons needed 774 px and a 768 px tablet overflowed by 74 px. |
| The camera re-frames per aspect | `KitchenScene.apply_layout()` keeps the authored angle and moves back only until the whole working area is inside the frustum. It never moves closer than the authored distance. |

---

## 3. The sizes checked

Twelve sizes, all run in one pass. The first column is the name used in the test output.

| Name | Size | Represents |
|---|---|---|
| `phone_small` | 320 × 568 | The narrowest phone still worth supporting |
| `phone_360` | 360 × 800 | Common budget Android |
| `phone_390` | 390 × 844 | Modern iPhone-class |
| `phone_430` | 430 × 932 | Large phone |
| `tablet_600` | 600 × 960 | 7-inch tablet, portrait |
| `tablet_768` | 768 × 1024 | 10-inch tablet, portrait (just above the breakpoint) |
| `landscape_1024` | 1024 × 768 | Small tablet, landscape |
| `laptop_1280` | 1280 × 720 | The design target |
| `laptop_1366` | 1366 × 768 | Very common laptop |
| `desktop_1920` | 1920 × 1080 | Full HD |
| `ultrawide` | 2560 × 1080 | 21:9 |
| `uhd` | 3840 × 2160 | 4K |

At each size the tool builds **30 layouts**: the ten menu screens (the main menu, the mode
picker, the challenge picker, the dish browser, Free Cook, the recipe creator, the cookbook,
the Discover browser, the journal and the assessment screen), a filled recipe creator and a
filled cookbook, the settings modal, HUD and task layouts for three story-kitchen steps, and
a full recipe walk (HUD plus one layout per step). That is **360 layouts** in a full run.

---

## 4. What is asserted

For every one of those 30 layouts per size (360 in a full run), from the real rectangles the engine computed:

1. **The viewport really is the requested size.** Guards against a test that silently
   checks a 64 × 64 default viewport (which is what a headless run gets when scaling is
   disabled — see `tests/test_window.gd`).
2. **Every visible `Control` stays inside its clipping parent.** Any rectangle reaching
   past the window edge by more than 2 px is a failure. A 2 px tolerance absorbs sub-pixel
   rounding, not layout bugs.
3. **No `Label` or `Button` is asked to draw more text than its box can hold** (with 40 px
   allowed for button padding). This is the check that catches clipped Thai text, because a
   wrapped label with too small a box still reports the "correct" rectangle while hiding
   half a word.
4. **Scroll containers bound only the axis they scroll.** A vertically scrolling list is
   allowed to have content taller than its box; it is *not* allowed to be wider than it.

---

## 5. Result

```
godot --headless --path <project> res://tests/responsive_check.tscn
--- Fluke Free Kitchen responsive check ---
  phone_small (320x568) checked
  ... (12 sizes)
--- results ---
RESPONSIVE CHECK PASSED (360 layouts checked)
```

**PASS — 360/360 layouts, 2026-10-18, Godot 4.7.2 stable.**

The first run of this tool found **157** overflow problems at 320 × 568 and **17** more at
768 × 1024 and 1024 × 768. The settings modal, added to the tool later, found **14** more on
the three small phone sizes — including a fault no screenshot had caught: the modal was
being drawn *behind* the page. Every one was a real fault, not a test artefact. The fixes,
in the order they were needed:

| Fault | Fix |
|---|---|
| Titles drawn as a 1 px-wide vertical column of characters | `MenuScreen.centred()` used spacer `Control`s, which shared the leftover width with any expanding child. Replaced with container alignment. |
| `UIFactory.title()` collapsed when given no explicit width | `SIZE_EXPAND_FILL` + centred alignment + `WORD_SMART` wrapping. |
| Buttons with long Thai labels clipped their text | `UIFactory.button()` / `check()` set `autowrap_mode` (guarded with `if "autowrap_mode" in b:`). |
| Journal cards forced the whole page wider than the window | A `ScrollContainer` with horizontal scrolling off propagates its child's minimum width upward, so one non-wrapping label made the page wider than the screen. The long labels (level titles, dish names, lesson titles, counters) now wrap. |
| Checklist task sheet 40 px too wide at 320 px | The confirm button was centred with two spacers; `UIFactory.centre_row()` centres it without adding separations. Applied to the hold, lesson-card, result, quiz and settings-centring rows as well. |
| A wrapped label's height was wrong ("content-fitted" sheets too short or too tall) | A wrapped `Label`'s minimum height is its height at ~1 px width. Sheets are now measured in two passes — at the real width — via `KitchenTask._refit_measured()`. |
| Two 380 px menu buttons needed 774 px on a 768 px tablet | `UIFactory.grid_width()` caps a grid child at its column; `UIFactory.responsive_grid_size()` remembers the column count so a live resize re-fits. |
| Three cards of 340 px needed 1060 px on the same tablet | The card's start button now fills the card (`SIZE_EXPAND_FILL`) instead of demanding a fixed 300 px, so it no longer sets the card's minimum width. |
| Three journal tab buttons needed 740 px inside a 696 px page | The tab bar now measures itself and becomes a dropdown when three labels would not fit, instead of switching only at the 700 px breakpoint. |
| Assessment status cards needed 932 px across two columns | Same `responsive_grid_size()` treatment. |
| A grid that exactly filled the window left no room for the scrollbar | `grid_width()` now reserves 12 px. |
| Settings rows demanded 348 px on a 320 px phone (slider plus a 56 px readout on one line) | The volume readout moved into the label row; the slider now has a whole line of its own. |
| The settings panel asked for 574 px of height on a 568 px phone | `responsive_min_size()` gained a `reserve` (how much room the screen around a control needs); the settings scroll reserves 260 px instead of the generic 150. |
| **Modals were drawn behind the page** | A screen builds its page *after* `super()` has added the overlay, so the page was a later sibling and painted over the settings / "how to play" panels. `show_overlay()` now raises the overlay, and a rebuild on resize raises it again if a modal is open. The settings screenshots are what exposed this — the numeric check alone would not have. |

---

## 6. Screenshots

Produced with a real window (rendering requires one), one PNG per size per layout:

```
godot --path <project> res://tests/responsive_check.tscn -- 390 844 shots
```

Captured on 2026-10-16 for 390 × 844, 768 × 1024, 1280 × 720 and 1920 × 1080. Looked at by
hand to confirm the *quality* of the reflow, not only its legality — the numeric check
cannot tell a cramped layout from a good one. What was confirmed:

* **390 × 844 (phone):** single-column menu, title on one line with tone marks intact,
  competition footer dropped as designed, kitchen HUD with the step card above the prompt
  bar and the task sheet at the bottom with no overlap, and the settings modal on top of a
  properly dimmed page.
* **320 × 568 (smallest phone):** the settings modal fits the window and scrolls; only the
  sound section is visible at once, which is the honest consequence of a 320 px width.
* **768 × 1024 (tablet, portrait):** the journal shows a tab *dropdown* because three tab
  buttons do not fit; the challenge cards stack to one column.
* **1280 × 720 (laptop, design target):** unchanged from the original design — centred
  two-column menu, wide HUD card left with the buttons right.
* **1920 × 1080:** same layout, simply more room.

The cooking stages were captured separately by `tests/cook_test.tscn -- shots`
(`cook_1_raw.png`, `cook_2_browning.png`, `cook_3_burnt.png`).

---

## 7. Limits — what is *not* verified

Stated plainly, because "it passed the matrix" is not the same as "it works everywhere":

* **No physical device has run this game.** Every result above comes from resizing a
  window on one Windows laptop with a discrete GPU. A real phone differs in touch
  behaviour, GPU, font rendering and safe-area insets — none of that is tested here.
* **Orientation.** Portrait ↔ landscape transitions are covered in so far as the tool
  resizes the window between sizes within one run, which exercises the rebuild/reflow path
  repeatedly. A real device rotation event is not tested.
* **System font scaling / accessibility text size.** The interface uses fixed pixel sizes
  and does not read the OS text-size setting. A user who has enlarged text system-wide
  will not see it honoured.
* **Safe areas (notches, rounded corners).** Not handled: on a notched phone in portrait
  the top HUD strip may sit under the notch. Android/iOS export would need
  `DisplayServer.get_display_safe_area()` wiring.
* **The `uhd` (3840 × 2160) and `ultrawide` sizes** were checked for layout correctness
  only. Performance at 4K was not measured.
* **Very long translated strings** are covered for the current Thai and English text. A
  language with longer compound words (German, for example) has not been tested; the
  wrapping rules that protect Thai would very likely protect it, but that is an
  expectation, not a result.
* **Motion / tilt controls** do not exist in this game. Cooking is dragging a finger or
  holding a mouse button; there is no sensor input to be responsive to, and none is
  claimed. See §8.

---

## 8. Motion controls: not applicable, not faked

The prompt that produced this work asked for motion controls with graceful fallbacks. This
game has **no motion-controlled interaction**, so there is nothing to fall back *from*:

* All eight task kinds are pointer interactions — tap, drag, swipe, hold, choose, order,
  tick. Every one is fully usable with a mouse, a finger or a keyboard.
* `InputManager` centralises input and the task base class reads pointer events; there is
  no accelerometer or gyroscope code path anywhere in the project, so no menu offers a
  choice that would do nothing.
* The Settings screen therefore exposes only settings that exist: master/music/SFX volume,
  language, graphics quality, resolution, fullscreen, screen feedback and detailed health
  text. No placeholder toggles.

If motion control is added later (for example tilting a phone to pour), it should arrive as
a new task kind with sensor support *and* a pointer fallback for the same step, plus a
Settings choice, rather than as an option on existing steps.

---

## 9. How to re-run

```powershell
$g = "C:\Users\ASUS\godot-tools\Godot_v4.7.2-stable_win64_console.exe"
$p = "C:\Users\ASUS\river-dash-safe-feast-run"

# Whole matrix, no rendering needed
& $g --headless --path $p res://tests/responsive_check.tscn

# One size
& $g --headless --path $p res://tests/responsive_check.tscn -- 320 568

# One size, plus screenshots (needs a real window)
& $g --path $p res://tests/responsive_check.tscn -- 390 844 shots
```

Exit code is 0 on pass. Every failure is printed as
`FAIL: <size>: <screen> > <node path> <what>`, with the rectangle and the minimum size that
were compared — enough to find the node in `tests/layout_check.tscn -- <w> <h>`, which
dumps the full geometry of one size.
