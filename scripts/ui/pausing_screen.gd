@abstract
class_name PausingScreen
extends CanvasLayer
## A full screen over the game (the Ember Tree, the Link Rod): opening it pauses the game and
## fades it in; this layer keeps running (process mode Always) so the screen stays alive.
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
const FADE_SECONDS := 0.15

var is_open: bool = false

## Everything the screen shows; it takes the mouse while the screen is open.
var _root: Control
var _resolution := UiResolutionSwap.new()
var _paused_by_me: bool = false


## The canvas size used while open (see MIN_UI_WIDTH), e.g. 960×540 for a 480×270 game.
static func ui_size() -> Vector2i:
	var game_size := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	return game_size * ceili(float(MIN_UI_WIDTH) / game_size.x)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = EmberTreeFonts.ui_theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false


func _exit_tree() -> void:
	if is_open:
		close()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or not _can_open():
		return
	is_open = true
	_resolution.switch_to(get_window(), ui_size())
	_paused_by_me = not get_tree().paused
	get_tree().paused = true
	_on_open()
	_root.visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, FADE_SECONDS)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	_resolution.restore(get_window())
	if _paused_by_me:
		get_tree().paused = false


func _can_open() -> bool:
	return true


@abstract func _on_open() -> void
