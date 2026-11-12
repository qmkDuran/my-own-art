class_name Transition
extends CanvasLayer
## The old-school battle transition: a black swirl closes over the screen; while it is closed the scene changes
## (`midway`), then it opens again.

const LAYER: int = 20

var _rect := ColorRect.new()
var _mat := ShaderMaterial.new()
var busy: bool = false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mat.shader = preload("res://shaders/swirl.gdshader")
	_rect.material = _mat
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	add_child(_rect)


func play(midway: Callable) -> void:
	var time: float = float(TamerData.rule("battle.transition"))
	busy = true
	_rect.visible = true
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", vp.x / vp.y)
	Audio.sfx("flare", -8.0, 0.7)
	var tw := create_tween()
	tw.tween_method(_set_progress, 0.0, 1.0, time)
	tw.tween_callback(midway)
	tw.tween_interval(time * 0.3)
	tw.tween_method(_set_progress, 1.0, 0.0, time)
	tw.tween_callback(func() -> void:
		_rect.visible = false
		busy = false)


func progress() -> float:
	return float(_mat.get_shader_parameter("progress"))


func _set_progress(v: float) -> void:
	_mat.set_shader_parameter("progress", v)
