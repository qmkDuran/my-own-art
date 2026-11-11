class_name Walker
extends Node2D
## A passer-by in Tallow: strolls between a few places on the cobbles, pauses, strolls on. Not interactive; only
## there so the city feels lived in. Walks straight lines between waypoints chosen on open ground.

const SPEED: float = 34.0
const PAUSE: Vector2 = Vector2(1.5, 4.0)
const FPS: float = 8.0
const FRAMES: int = 8
const ARRIVE: float = 4.0

var kind: String
var route: Array[Vector2] = []
var _i: int = 0
var _wait: float = 0.0
var _t: float = 0.0
var _sprite: Sprite2D


static func make(parent: Node, folk: String, points: Array[Vector2]) -> Walker:
	var w := Walker.new()
	w.kind = folk
	w.route = points
	w.position = points[0]
	parent.add_child(w)
	return w


func _ready() -> void:
	add_child(PropSprite.shadow(24.0))
	_sprite = Sprite2D.new()
	_sprite.texture = PropSprite.tex("res://art/actors/folk_%s.png" % kind)
	_sprite.hframes = FRAMES
	_sprite.vframes = 2
	_sprite.offset = Vector2(0, -29)
	_sprite.self_modulate = ZoneView.person_modulate()
	_sprite.light_mask = 1 | Fx.STANDING_MASK
	add_child(_sprite)
	_wait = randf_range(PAUSE.x, PAUSE.y)


func _process(delta: float) -> void:
	_t += delta * FPS
	if _wait > 0.0:
		_wait -= delta
		_sprite.frame = int(_t) % FRAMES
		return
	var to: Vector2 = route[(_i + 1) % route.size()]
	position = position.move_toward(to, SPEED * delta)
	_sprite.flip_h = to.x < position.x
	_sprite.frame = FRAMES + int(_t) % FRAMES
	if position.distance_to(to) < ARRIVE:
		_i = (_i + 1) % route.size()
		_wait = randf_range(PAUSE.x, PAUSE.y)
