class_name Moonlight
extends DirectionalLight3D
## The cool blue moonlight: a soft-shadowed directional light whose direction also places the moon in the sky
## shader. Dims behind the rain clouds.


func setup() -> void:
	name = "Moonlight"
	light_color = Tuning.look_color("moon", "color")
	rotation = Vector3(Tuning.look_f("moon", "pitch_deg"), Tuning.look_f("moon", "yaw_deg"), 0.0) * deg_to_rad(1.0)
	light_angular_distance = Tuning.look_f("moon", "angular_size_deg")
	shadow_enabled = true
	shadow_blur = Tuning.look_f("moon", "shadow_blur")
	directional_shadow_max_distance = Tuning.look_f("moon", "shadow_max_distance")
	directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	set_rain(0.0)


func set_rain(mix: float) -> void:
	light_energy = Tuning.look_f("moon", "energy") * lerpf(1.0, Tuning.look_f("moon", "rain_energy_share"), mix)
