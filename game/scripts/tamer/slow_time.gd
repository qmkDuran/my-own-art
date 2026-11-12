class_name SlowTime
extends CanvasLayer
## Tactical slow-time: while a move is aimed, time runs at a fraction (a moment to think, never a pause), the world
## drains toward grey and the battle vignette deepens. It lasts at most `max_real` real seconds; then the move goes
## off on its own (TamerInput.release_aim).

const LAYER: int = 3
const FADE: float = 0.12

var g: TamerGame
var on: bool = false
var _rect := ColorRect.new()
var _mat := ShaderMaterial.new()
var _real_left: float = 0.0


func setup(game: TamerGame) -> void:
	g = game
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mat.shader = preload("res://shaders/slow_time.gdshader")
	_rect.material = _mat
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	add_child(_rect)


func begin() -> void:
	var S: Dictionary = TamerData.rule("combat.slow_time")
	on = true
	_real_left = float(S["max_real"])
	HitStop.set_base(float(S["scale"]))
	_rect.visible = true
	create_tween().set_ignore_time_scale().tween_method(_amount, 0.0, 0.6, FADE)
	g.hud.vignette(true)


func end() -> void:
	if not on:
		return
	on = false
	HitStop.set_base(1.0)
	create_tween().set_ignore_time_scale().tween_method(_amount, 0.6, 0.0, FADE)
	if not g.battle.on:
		g.hud.vignette(false)


func _amount(v: float) -> void:
	_mat.set_shader_parameter("amount", v)
	_rect.visible = v > 0.01


func _process(delta: float) -> void:
	if not on:
		return
	_real_left -= delta / maxf(Engine.time_scale, 0.01)
	if _real_left <= 0.0:
		g.input.release_aim(0)                            # it cannot be held forever
