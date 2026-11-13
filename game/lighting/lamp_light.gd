class_name LampLight
extends OmniLight3D
## One warm light of the town: a street lamp, a wall lantern or a lit window. Reads its look from the matching
## section of data/lighting.json, flickers gently like a flame, and can be snuffed out and relit (the night's
## creatures snuff lamps; the player relights them). The light sits inside the lamp's glass, which glows by itself
## (the asset shader), so there is no separate flame or ball.

const FADE_SPEED: float = 2.5
const MS_TO_SECONDS: float = 0.001

var kind: String = ""
var lit: bool = true
var _base_energy: float = 0.0
var _level: float = 1.0
var _phase: float = 0.0


func setup(lamp_kind: String) -> void:
	kind = lamp_kind
	name = lamp_kind.to_pascal_case()
	light_color = Tuning.look_color(kind, "color")
	_base_energy = Tuning.look_f(kind, "energy")
	light_energy = _base_energy
	omni_range = Tuning.look_f(kind, "range")
	omni_attenuation = Tuning.look_f(kind, "attenuation")
	light_volumetric_fog_energy = Tuning.look_f(kind, "fog_energy")
	distance_fade_enabled = true
	distance_fade_begin = Tuning.look_f("budget", "light_fade_begin")
	distance_fade_length = Tuning.look_f("budget", "light_fade_length")
	shadow_enabled = false
	_phase = randf() * TAU


func snuff() -> void:
	lit = false


func relight() -> void:
	lit = true


func _process(delta: float) -> void:
	_level = move_toward(_level, 1.0 if lit else 0.0, FADE_SPEED * delta)
	var time: float = Time.get_ticks_msec() * MS_TO_SECONDS
	var flicker: float = sin(time * Tuning.look_f("flicker", "speed") + _phase) * sin(time * PI + _phase * 2.0)
	light_energy = _base_energy * _level * (1.0 + flicker * Tuning.look_f("flicker", "amount"))
