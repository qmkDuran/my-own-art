class_name LightSource
extends PointLight2D
## A warm (or cold) pool of light: porch lights, streetlights, windows, fire, TV glow.
## Types live in data/lights.json; zone entities may override any field.

const TEXTURE_SIZE := 256

static var _shared_texture: Texture2D

var group := ""
var base_energy := 1.0
var flicker := 0.0
var pulse := 0.0
var _switch := 1.0
var _time := 0.0
var _flicker_value := 1.0


func setup(type_id: String, overrides: Dictionary = {}) -> void:
	var spec: Dictionary = (DB.lights.get(type_id, {}) as Dictionary).duplicate()
	spec.merge(overrides, true)
	color = Color.from_string(String(spec.get("color", "#ffd090")), Color.WHITE)
	base_energy = float(spec.get("energy", 1.0))
	flicker = float(spec.get("flicker", 0.0))
	pulse = float(spec.get("pulse", 0.0))
	group = String(spec.get("group", ""))
	texture = shared_texture()
	texture_scale = float(spec.get("radius", 96.0)) * 2.0 / TEXTURE_SIZE
	blend_mode = Light2D.BLEND_MODE_ADD
	if spec.get("start_off", false):
		_switch = 0.0
	_time = randf() * 10.0
	energy = base_energy * _switch


func _process(delta: float) -> void:
	_time += delta
	var value := base_energy * _switch
	if flicker > 0.0:
		_flicker_value = lerpf(_flicker_value, 1.0 - flicker * randf(), minf(1.0, delta * 20.0))
		value *= _flicker_value
	if pulse > 0.0:
		value *= 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * TAU * pulse))
	energy = value


## state: "on", "off" (stutters out like failing power) or "dim".
func set_state(state: String, duration: float = 0.6) -> void:
	var tween := create_tween()
	match state:
		"on":
			tween.tween_property(self, "_switch", 1.0, duration)
		"dim":
			tween.tween_property(self, "_switch", 0.35, duration)
		_:
			var step := maxf(duration, 0.1) / 5.0
			for value: float in [0.15, 0.9, 0.05, 0.5, 0.0]:
				tween.tween_property(self, "_switch", value, step)


static func shared_texture() -> Texture2D:
	if _shared_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.55))
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = TEXTURE_SIZE
		tex.height = TEXTURE_SIZE
		_shared_texture = tex
	return _shared_texture
