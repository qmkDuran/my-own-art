@abstract
class_name PausingScreen
extends CanvasLayer
## A full screen over the game (the Ember Tree, the Link Rod): opening it pauses the game and
## fades it in; this layer keeps running (process mode Always) so the screen stays alive.
## It opens and closes with a short fade and a SLIDE_PIXELS slide (rising into place, sinking
## away); keys pressed while that plays are ignored, so a quick double press can't skip it.
## Behind it, the paused game is held as a still picture while open: the canvas switch would
## otherwise show the world and HUD jump to another scale under the fading screen.
## While open it draws at a whole multiple of the game's own resolution (`ui_size`), so its
## pixel font stays crisp (the hybrid approach in DESIGN.md); the game's own scale comes back
## on close.
##
## A screen builds its contents under `_root` in its `_ready` (after super._ready()) and
## overrides:
##   _can_open()  -> false when it must stay shut now (default: always opens)
##   _on_open()   -> brings its contents up to date just before it shows

## The smallest canvas width while open: the smallest whole multiple of the game's
## resolution at least this wide (leaves the Ember Tree room between its two cards).
const MIN_UI_WIDTH := 960
## How long opening or closing takes.
const TRANSITION_SECONDS := 0.12
## How far the screen slides while it fades, in screen pixels.
const SLIDE_PIXELS := 4.0

var is_open: bool = false

## Everything the screen shows; it takes the mouse while the screen is open.
var _root: Control
## The game as it looked just before opening (the game is paused, so it doesn't change).
var _frozen_game: TextureRect
var _resolution := UiResolutionSwap.new()
var _paused_by_me: bool = false
var _transition: Tween


## The canvas size used while open (see MIN_UI_WIDTH), e.g. 960×540 for a 480×270 game.
static func ui_size() -> Vector2i:
	var game_size := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	return game_size * ceili(float(MIN_UI_WIDTH) / game_size.x)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frozen_game()
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = EmberTreeFonts.ui_theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false


func _build_frozen_game() -> void:
	_frozen_game = TextureRect.new()
	_frozen_game.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frozen_game.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frozen_game.stretch_mode = TextureRect.STRETCH_SCALE
	_frozen_game.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_frozen_game)
	_frozen_game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frozen_game.visible = false


## Takes a still of the game as it is now, to show behind the screen; none when nothing is
## rendered (headless runs), where there is no jump to hide.
func _freeze_game() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var picture := get_viewport().get_texture().get_image()
	if picture == null or picture.is_empty():
		return
	_frozen_game.texture = ImageTexture.create_from_image(picture)
	_frozen_game.visible = true


func _exit_tree() -> void:
	if is_open:
		_finish_closing()


## Adds to `tween` a fade of `part` to shown or hidden over `seconds`, sliding SLIDE_PIXELS
## (up into place when showing, down when hiding) by whole pixels so pixel text stays crisp.
## Shared with screens that are not PausingScreens (the death screen).
static func fade_and_slide(tween: Tween, part: Control, showing: bool, seconds: float) -> void:
	if showing:
		part.position.y = SLIDE_PIXELS
	tween.tween_property(part, "modulate:a", 1.0 if showing else 0.0, seconds)
	var slide_to := 0.0 if showing else SLIDE_PIXELS
	var move := func(offset: float) -> void: part.position.y = roundf(offset)
	tween.tween_method(move, part.position.y, slide_to, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or _is_transitioning() or not _can_open():
		return
	is_open = true
	_freeze_game()
	_resolution.switch_to(get_window(), ui_size())
	_paused_by_me = not get_tree().paused
	get_tree().paused = true
	_on_open()
	_root.visible = true
	_root.modulate.a = 0.0
	_start_transition(true)


## Fades out; the game resumes once it is gone (is_open stays true until then).
func close() -> void:
	if not is_open or _is_transitioning():
		return
	_start_transition(false).finished.connect(_finish_closing)


## Runs while the game is paused and ignores the time scale (e.g. a death's slow motion).
func _start_transition(showing: bool) -> Tween:
	_transition = create_tween().set_parallel().set_ignore_time_scale(true)
	_transition.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_and_slide(_transition, _root, showing, TRANSITION_SECONDS)
	return _transition


func _is_transitioning() -> bool:
	return _transition != null and _transition.is_running()


func _finish_closing() -> void:
	if _transition != null:
		_transition.kill()
	is_open = false
	_root.visible = false
	_root.position.y = 0.0
	_frozen_game.visible = false
	_frozen_game.texture = null
	_resolution.restore(get_window())
	if _paused_by_me:
		get_tree().paused = false


func _can_open() -> bool:
	return true


@abstract func _on_open() -> void
