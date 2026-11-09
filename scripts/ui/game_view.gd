class_name GameView
extends RefCounted
## The game's view and how it sits in the window: the game draws at `size()` (640×360) and the
## window shows it at a whole-number scale (3× at 1080p, 4× at 1440p, 6× at 4K).
##
## Higher-resolution UI (the HUD's cards, the Ember Tree, the Link Rod) is drawn with
## `ui_pixel_size()` window pixels per UI pixel, the same everywhere, so the Monogram font
## stays crisp: 2 window pixels per font pixel at 1080p and 1440p, 4 at 4K.

## The smallest width of the UI canvas while a full screen is open (leaves the Ember Tree
## room between its two cards).
const MIN_UI_WIDTH := 960


## The game's own resolution in game pixels (the project's viewport size).
static func size() -> Vector2i:
	return Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))


## Window pixels per game pixel: the biggest whole scale at which the game fits the window.
static func window_scale(window: Window = null) -> int:
	var game := size()
	var shown := _window_size(window)
	return maxi(1, mini(shown.x / game.x, shown.y / game.y))


## Window pixels per UI pixel: the biggest whole number that still leaves the UI canvas at
## least MIN_UI_WIDTH wide and divides the game's shown area exactly.
static func ui_pixel_size(window: Window = null) -> int:
	var shown := size() * window_scale(window)
	for pixel_size in range(maxi(1, shown.x / MIN_UI_WIDTH), 1, -1):
		if shown.x % pixel_size == 0 and shown.y % pixel_size == 0:
			return pixel_size
	return 1


## The UI canvas while a full screen is open: the game's shown area in UI pixels
## (960×540 at 1080p, 1280×720 at 1440p).
static func ui_size(window: Window = null) -> Vector2i:
	return size() * window_scale(window) / ui_pixel_size(window)


## UI pixels drawn per game pixel, e.g. 2/3 at 1080p: the scale of a HUD card laid out in
## UI pixels.
static func ui_to_game_scale(window: Window = null) -> float:
	return float(ui_pixel_size(window)) / window_scale(window)


## The window's size; a window smaller than the game (a headless run has a tiny dummy one)
## counts as the window size the game is made for.
static func _window_size(window: Window) -> Vector2i:
	if window == null:
		window = (Engine.get_main_loop() as SceneTree).root
	var game := size()
	if window.size.x >= game.x and window.size.y >= game.y:
		return window.size
	return Vector2i(
		ProjectSettings.get_setting("display/window/size/window_width_override"),
		ProjectSettings.get_setting("display/window/size/window_height_override"))
