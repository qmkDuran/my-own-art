class_name Ally
extends Node2D
## Captain Marr at the gate: she walks to the nearest enemy and puts her pike through it, every so often.

const SPEED: float = 90.0
const REACH: float = 34.0
const SIGHT: float = 360.0
const EVERY: float = 0.9
const DAMAGE: float = 14.0
const FPS: float = 6.0

var _sprite: Sprite2D
var _cd: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = PropSprite.tex("res://art/actors/npc_ysolde.png")
	_sprite.hframes = Npc.FRAMES
	_sprite.offset = Vector2(0, -32 + 3)
	_sprite.self_modulate = ZoneView.person_modulate()
	add_child(PropSprite.shadow(26.0))
	add_child(_sprite)


func _process(delta: float) -> void:
	_t += delta * FPS
	PropSprite.set_frame(_sprite, int(_t) % Npc.FRAMES)
	_cd -= delta
	var foe: Enemy = _nearest()
	if foe == null:
		return
	var d: Vector2 = foe.global_position - global_position
	_sprite.flip_h = d.x < 0.0
	if d.length() > REACH:
		position += d.normalized() * SPEED * delta
	elif _cd <= 0.0:
		_cd = EVERY
		Combat.hit_enemy(foe, DAMAGE, {"kind": "attack", "dir": d.normalized(), "knockback": 20.0})


func _nearest() -> Enemy:
	var best: Enemy = null
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if not e.dead and e.global_position.distance_to(global_position) < SIGHT and (best == null or
				e.global_position.distance_to(global_position) < best.global_position.distance_to(global_position)):
			best = e
	return best
