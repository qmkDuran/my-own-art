class_name LightBudget
extends Node
## Keeps lighting affordable on a mid-range PC: of all the town's lamps, only the few nearest the camera cast
## shadows (re-chosen a few times a second); the rest light without shadows and fade out with distance.

## How many lights may cast shadows (set by the graphics tier).
var allowed: int = 0
var _lights: Array[OmniLight3D] = []
var _camera: Camera3D
var _timer: float = 0.0


func setup(lights: Array[OmniLight3D], camera: Camera3D) -> void:
	name = "LightBudget"
	_lights = lights
	_camera = camera
	allowed = Tuning.i_look("budget", "shadowed_lights")
	refresh()


func shadowed_count() -> int:
	return _lights.filter(func(light: OmniLight3D) -> bool: return light.shadow_enabled).size()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = Tuning.look_f("budget", "refresh_seconds")
		refresh()


func refresh() -> void:
	var view: Camera3D = _camera if is_instance_valid(_camera) else get_viewport().get_camera_3d()
	if view == null:
		return
	var eye: Vector3 = view.global_position
	var sorted: Array[OmniLight3D] = _lights.duplicate()
	sorted.sort_custom(func(a: OmniLight3D, b: OmniLight3D) -> bool:
		return a.global_position.distance_squared_to(eye) < b.global_position.distance_squared_to(eye))
	for index: int in sorted.size():
		sorted[index].shadow_enabled = index < allowed and sorted[index].light_energy > 0.0
