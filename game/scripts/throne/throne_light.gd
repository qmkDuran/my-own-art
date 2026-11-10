class_name ThroneLight
extends Node2D
## The One on the throne is shown only as light (Rev 4:2-3): a blazing burst with jasper and carnelian rays.
## Seven lamps of fire burn before the throne; lightnings proceed out of it (Rev 4:5).

const ART: String = "res://art/throne/"
const CORE_FRAMES: int = 4
const FLAME_FRAMES: int = 4
const GLOW_HALF := Vector2(320, 150)       # light centre inside throne_glow.png
const RAYS_OFFSET := Vector2(0, 60)        # rays.png's light centre sits 60 px above its middle
const LAMP_GLOW_SCALE := Vector2(0.09, 0.12)
const BOLT_SEGMENTS: int = 7

var _core: Sprite2D
var _glow: Sprite2D
var _rays: Sprite2D
var _flames: Array[Sprite2D] = []
var _rng: RandomNumberGenerator
var _origin: Vector2


func build(light_centre: Vector2, throne_centre: Vector2, lamps: Array, rng: RandomNumberGenerator) -> void:
	_rng = rng
	_origin = throne_centre + Vector2(0, 20)
	_glow = SpriteFactory.sprite(self, ART + "throne_glow.png", light_centre - GLOW_HALF, -15, true)
	_core = SpriteFactory.sprite(self, ART + "throne_core.png", light_centre - Vector2(64, 64), -14)
	_core.hframes = CORE_FRAMES
	_rays = SpriteFactory.sprite(self, ART + "rays.png", light_centre, -13, true)
	_rays.centered = true
	_rays.offset = RAYS_OFFSET
	for lamp: Array in lamps:
		var f := SpriteFactory.sprite(self, ART + "flame.png", Vector2(int(lamp[0]) - 3, int(lamp[1]) - 35), -12)
		f.hframes = FLAME_FRAMES
		f.frame = _rng.randi_range(0, FLAME_FRAMES - 1)
		_flames.append(f)
		SpriteFactory.glow(self, ART + "throne_glow.png", Vector2(lamp[0], int(lamp[1]) - 30), LAMP_GLOW_SCALE, -11)


## Blazing light: slow breathing plus flicker; the rays turn slowly; the lamp flames dance.
func animate(time: float) -> void:
	_core.frame = int(time * 7.0) % CORE_FRAMES
	_core.modulate = Color(1, 1, 1, 0.92 + 0.08 * sin(time * 5.0))
	_glow.modulate.a = 0.85 + 0.15 * sin(time * 1.1)
	_rays.rotation = time * 0.05
	for i: int in _flames.size():
		_flames[i].frame = (int(time * 9.0) + i * 3) % FLAME_FRAMES


## Out of the throne proceeded lightnings and thunderings (Rev 4:5): 1-2 bolts, a soft flash, thunder after.
func lightning(flash: ColorRect) -> void:
	Audio.sfx("thunder%d" % _rng.randi_range(1, 2), -14.0, _rng.randf_range(0.85, 1.05), _rng.randf_range(0.15, 0.4))
	for b: int in _rng.randi_range(1, 2):
		_bolt()
	var fl := create_tween()
	fl.tween_property(flash, "color:a", 0.22, 0.04)
	fl.tween_property(flash, "color:a", 0.0, 0.25)


func _bolt() -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1, 1, 1, 1)
	line.antialiased = false
	line.z_index = 7
	line.material = SpriteFactory.additive()
	var ang: float = _rng.randf_range(-PI * 0.95, -PI * 0.05)
	var p: Vector2 = _origin
	line.add_point(p)
	for s: int in BOLT_SEGMENTS:
		p += Vector2.from_angle(ang + _rng.randf_range(-0.7, 0.7)) * _rng.randf_range(9, 17)
		line.add_point(p.round())
	var inner := line.duplicate() as Line2D
	inner.width = 1.0
	inner.default_color = Color("8fd3ff")
	add_child(line)
	add_child(inner)
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(line, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(inner, "modulate:a", 0.0, 0.12)
	tw.tween_callback(line.queue_free)
	tw.tween_callback(inner.queue_free)
