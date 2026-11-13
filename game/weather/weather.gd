class_name Weather
extends Node
## Clear night or rain (R toggles). Eases a 0..1 rain mix and tells the world: the global shader wetness and rain
## values (puddles grow, roofs and stones darken and shine), and everyone listening to rain_mix_changed (fog,
## moonlight, rain particles, rain sound).

signal rain_mix_changed(mix: float)

var raining: bool = false
var mix: float = 0.0


func _ready() -> void:
	name = "Weather"
	_apply()


func toggle() -> void:
	set_raining(not raining)


func set_raining(value: bool) -> void:
	raining = value


## Jump straight to the current target (staged screenshots).
func settle() -> void:
	mix = 1.0 if raining else 0.0
	_apply()


func _process(delta: float) -> void:
	var goal: float = 1.0 if raining else 0.0
	if mix == goal:
		return
	mix = move_toward(mix, goal, Tuning.look_f("wet", "change_per_second") * delta)
	_apply()


## How wet the town is now (0 bone dry .. 1 soaked), as the shaders see it.
func wetness() -> float:
	return lerpf(Tuning.look_f("wet", "dry"), Tuning.look_f("wet", "rain"), mix)


func _apply() -> void:
	RenderingServer.global_shader_parameter_set("wetness", wetness())
	RenderingServer.global_shader_parameter_set("rain", mix)
	rain_mix_changed.emit(mix)
