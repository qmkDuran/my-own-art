class_name UiResolutionSwap
extends RefCounted
## Switches the window to a higher-resolution canvas while a screen is open (so its text
## stays crisp), and puts the game's own scaling back afterwards.
##
## Ask for a whole multiple of the game's resolution (e.g. 960×540 for the 480×270 game):
## the window is a whole multiple of the game too (1920×1080 = 4×), so the screen still
## scales by whole pixels and stays sharp.

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var _saved_aspect: Window.ContentScaleAspect
var _saved_stretch: Window.ContentScaleStretch


## Remembers the window's scaling, then scales the canvas to `ui_size`, keeping its shape.
func switch_to(window: Window, ui_size: Vector2i) -> void:
	_saved_size = window.content_scale_size
	_saved_mode = window.content_scale_mode
	_saved_aspect = window.content_scale_aspect
	_saved_stretch = window.content_scale_stretch
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_size = ui_size
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


## Puts back the scaling remembered by the last `switch_to`.
func restore(window: Window) -> void:
	window.content_scale_size = _saved_size
	window.content_scale_mode = _saved_mode
	window.content_scale_aspect = _saved_aspect
	window.content_scale_stretch = _saved_stretch
