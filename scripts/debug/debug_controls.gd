class_name DebugControls
extends CanvasLayer
## Developer switches for testing, toggled with keys checked directly here
## (no input actions, so the project settings stay untouched).
##
## F2: enemies passive. Toads sit still (no hops, no tongue) and Wardens stand still
## (no summons, no shove, no slam). They can still be hit and killed.
## While it's on, "ENEMIES PAUSED (F2)" shows at the top centre of the screen.

const PASSIVE_TOGGLE_KEY := KEY_F2
const BANNER_TEXT := "ENEMIES PAUSED (F2)"
## Top edge of the banner text, in screen pixels.
const BANNER_TOP := 3

## Read by the enemies every frame. A static var, so it survives a level restart.
## On by default for now, while the training dummy is being tuned.
static var enemies_passive: bool = true

@onready var banner: Node2D = $Banner


func _ready() -> void:
	banner.draw.connect(_draw_banner)
	_refresh_banner()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == PASSIVE_TOGGLE_KEY:
		enemies_passive = not enemies_passive
		_refresh_banner()
		get_viewport().set_input_as_handled()


func _refresh_banner() -> void:
	banner.visible = enemies_passive
	banner.queue_redraw()


func _draw_banner() -> void:
	var screen_width := get_viewport().get_visible_rect().size.x
	var left := floorf((screen_width - PixelFont.width_of(BANNER_TEXT)) / 2.0)
	PixelFont.draw_text(banner, BANNER_TEXT, Vector2(left, BANNER_TOP), ApolloPalette.GOLD, ApolloPalette.OUTLINE)
