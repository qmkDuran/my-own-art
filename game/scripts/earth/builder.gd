class_name Builder
extends Node2D
## The builder at the new house (Isa 65:21-22): a hand-drawn two-frame hammer and a gentle knock on each stroke.

const HAMMER: String = "res://art/earth/hammer.png"
const Z: int = 1

var _hammer: Sprite2D
var _at: Vector2
var _stroke: float = 0.65
var _hear: float = 380.0
var _last: int = -1


func build(cfg: Dictionary) -> void:
	_at = SceneData.vec(cfg["at"])
	_stroke = float(cfg["stroke"])
	_hear = float(cfg["hear"])
	_hammer = SpriteFactory.sprite(self, HAMMER, _at + SceneData.vec(cfg["hammer_offset"]), Z)
	_hammer.hframes = 2


func animate(time: float, listener: Vector2) -> void:
	var stroke: int = int(time / _stroke)
	_hammer.frame = stroke % 2
	if _hammer.frame == 1 and stroke != _last:
		_last = stroke
		var d: float = listener.distance_to(_at)
		if d < _hear:
			Audio.sfx("knock", lerpf(-16.0, -34.0, clampf(d / _hear, 0.0, 1.0)), randf_range(0.95, 1.05))
