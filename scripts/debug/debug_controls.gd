class_name DebugControls
extends CanvasLayer
## Developer switches for testing, toggled with keys checked directly here
## (no input actions, so the project settings stay untouched).
##
## F2: enemies passive. Toads sit still (no hops, no tongue) and Wardens stand still
## (no summons, no shove, no slam). They can still be hit and killed.
## F3: DEBUG ONLY, +5 Ember Tree skill points, to try out builds without levelling.
## While enemies are passive, a banner at the top centre of the screen lists both keys.

const PASSIVE_TOGGLE_KEY := KEY_F2
const GRANT_POINTS_KEY := KEY_F3
## Skill points F3 grants (debug only).
const DEBUG_SKILL_POINTS := 5
## "%d" is DEBUG_SKILL_POINTS.
const BANNER_FORMAT := "ENEMIES PAUSED (F2)   F3 +%d POINTS"
## Top edge of the banner text, in screen pixels.
const BANNER_TOP := 3

## Read by the enemies every frame. A static var, so every enemy can read it without a reference.
static var enemies_passive: bool = false

## Whether enemies start paused in this level: on in the test arena (for tuning against the
## training dummy), off in real zones.
@export var start_with_enemies_paused: bool = false

@onready var banner: Node2D = $Banner


func _ready() -> void:
	enemies_passive = start_with_enemies_paused
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
	elif key.keycode == GRANT_POINTS_KEY:
		Progression.add_skill_points(DEBUG_SKILL_POINTS)
		get_viewport().set_input_as_handled()


func _refresh_banner() -> void:
	banner.visible = enemies_passive
	banner.queue_redraw()


func _draw_banner() -> void:
	var banner_text := BANNER_FORMAT % DEBUG_SKILL_POINTS
	var screen_width := get_viewport().get_visible_rect().size.x
	var left := floorf((screen_width - PixelFont.width_of(banner_text)) / 2.0)
	PixelFont.draw_text(banner, banner_text, Vector2(left, BANNER_TOP), ApolloPalette.GOLD, ApolloPalette.OUTLINE)
