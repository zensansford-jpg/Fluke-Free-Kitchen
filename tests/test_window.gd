extends RefCounted
## Window sizing for the test tools.
##
## The game runs with `display/window/stretch/mode="disabled"` so that one UI unit
## is one screen pixel and the interface can genuinely reflow on a small window
## instead of being scaled down to a sliver.
##
## That has one sharp edge: with stretch disabled the root viewport follows the
## window, and a headless run has no real window — the dummy display server reports
## a 64x64 viewport. Every test therefore has to state the window size it wants,
## otherwise every control is laid out for a 64x64 screen and coordinates computed
## from real rectangles land nowhere.

## Sets the root window (and with it the viewport) to an exact pixel size.
static func use(width: int, height: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.size = Vector2i(width, height)


## Waits for the layout to settle after a resize. Two frames: one for the viewport
## size notification, one for the containers to re-sort their children.
static func settle(frames: int = 2) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for _i in maxi(1, frames):
		await tree.process_frame
