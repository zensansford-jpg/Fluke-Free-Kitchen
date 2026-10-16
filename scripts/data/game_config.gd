class_name GameConfig
## Central tuning constants for *Fluke Free Kitchen*.
##
## Everything a designer may want to nudge lives here, so gameplay scripts stay
## readable and tests can assert against one source of truth. This file never
## touches the scene tree.

extends RefCounted

# ------------------------------------------------------------------ identity --
const GAME_TITLE := "Fluke Free Kitchen"
const GAME_TITLE_THAI := "ครัวปลอดพยาธิ"
const GAME_SUBTITLE := "Cook safely, and learn how to prevent liver flukes and bile duct cancer."
const GAME_SUBTITLE_THAI := "ทำอาหารให้ปลอดภัย เรียนรู้การป้องกันพยาธิใบไม้ตับและมะเร็งท่อน้ำดี"
const GAME_VERSION := "2.0.0"
const COMPETITION := "Fluke Free Fighters"
const COMPETITION_TH := "พิชิตพยาธิใบไม้ตับและมะเร็งท่อน้ำดี"

# ---------------------------------------------------------------- collision ---
const LAYER_WORLD := 1
const LAYER_INTERACTIVE := 2

# ------------------------------------------------------------------- camera ---
## The camera does not move during play. A fixed three-quarter view keeps the
## kitchen readable and makes big, forgiving click targets possible.
const CAMERA_POSITION := Vector3(0.0, 3.55, 5.25)
const CAMERA_LOOK_AT := Vector3(0.0, 0.88, 0.15)
const CAMERA_FOV := 38.0
const CAMERA_ZOOM_MIN := 3.4
const CAMERA_ZOOM_MAX := 5.6

# -------------------------------------------------------------- interaction ---
const RAY_LENGTH := 90.0
## Pointer travel (pixels) below which press + release is treated as a click.
const CLICK_MAX_TRAVEL := 16.0
## Pointer travel at which an interactive object begins to be dragged.
const DRAG_START_TRAVEL := 12.0
## Seconds a press must last before hold progress starts counting.
const HOLD_START_TIME := 0.12
## Every interactive body gets an invisible hit volume this much larger than its
## mesh, so players never need pixel precision.
const HIT_AREA_PADDING := 1.35
const SWIPE_MIN_PIXELS := 46.0
const SWIPE_MAX_TIME := 0.6

# ------------------------------------------------------------------ cooking ---
## Internal temperature for safely cooked freshwater fish.
## Source: US CDC, "Clinical Overview of Opisthorchis" (docs/REFERENCES.md).
const COOK_SAFE_TEMP_C := 63.0
const COOK_DANGER_TEMP_C := 58.0
const COOK_MAX_TEMP_C := 78.0
const COOK_START_TEMP_C := 22.0
## Seconds the fish must stay at or above COOK_SAFE_TEMP_C.
const COOK_HOLD_SECONDS := 5.0
const COOK_HEAT_RATE := 11.0
const COOK_COOL_RATE := 5.0

## Cooking *visuals*, deliberately separate from the safety rule above.
##
## `browning` is how far the surface of the fish has coloured: 0 is raw, about 0.85
## reads as a golden cooked surface, and COOK_BURNT_AT is burnt. It is only a
## picture of how much heat the pan has put into the fish. It is never consulted
## when deciding whether the fish is safe — the internal temperature and the time
## held at it decide that, and the cooking step tells the player so on screen.
const COOK_SEAR_TEMP_C := 45.0
## Browning added per second with the pan at full heat.
const COOK_BROWN_RATE := 0.14
## Browning at which the surface reads as burnt and the fish is spoiled.
const COOK_BURNT_AT := 1.35

# ------------------------------------------------------------------ scoring ---
const STARS_MAX := 3
const POINTS_ACTION := 120
## Extra credit when an action is correct on the first attempt.
const POINTS_ACTION_PERFECT := 40
const POINTS_KNOWLEDGE := 250
const POINTS_TIDY_BONUS := 150
## Fraction of a level's available score needed for two and three stars.
const STAR_THRESHOLD_2 := 0.55
const STAR_THRESHOLD_3 := 0.85
## Three stars additionally require an accurate level, never a rushed one.
const STAR3_MIN_ACCURACY := 0.85
## Actions the player must get right before a level can be credited at all.
const LEVEL_PASS_ACCURACY := 0.5

# ------------------------------------------------------------------ session ---
## Longest a single level should take. Used by the UI to warn, not to fail.
const LEVEL_TARGET_SECONDS := 180.0
## How many hints a level offers before it will show the full demonstration.
const HINTS_BEFORE_DEMO := 2
