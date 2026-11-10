class_name Bolt
extends Node2D
## A caster's "flaming arrow of the evil one" (Eph 6:16). The Shield of Faith extinguishes it.

const LIFE: float = 2.4
const HIT_RADIUS: float = 18.0

var dir: Vector2
var speed: float
var damage: float
var target: Michael
var _age: float = 0.0


static func fire(parent: Node, at: Vector2, direction: Vector2, spd: float, dmg: float, michael: Michael) -> Bolt:
	var b := Bolt.new()
	b.position = at
	b.dir = direction
	b.speed = spd
	b.damage = dmg
	b.target = michael
	parent.add_child(b)
	return b


func _ready() -> void:
	z_index = 5
	var light := PointLight2D.new()
	light.texture = LightTex.radial(64)
	light.color = Color(0.75, 0.35, 1.0)
	light.energy = 1.2
	add_child(light)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color("6b3e75"))
	draw_circle(Vector2.ZERO, 3.0, Color("e83b3b"))
	draw_circle(Vector2(-dir.x * 5, -dir.y * 5), 2.0, Color("f57d4a"))


func _physics_process(delta: float) -> void:
	_age += delta
	position += dir * speed * delta
	var hit_at: Vector2 = target.global_position + Vector2(0, -28)
	if target.shield_active() and global_position.distance_to(hit_at) < target.shield_radius():
		target.shield_blocked(global_position)
		queue_free()
	elif global_position.distance_to(hit_at) < HIT_RADIUS:
		target.take_hit(damage, self, true, "shadow")
		queue_free()
	elif _age > LIFE:
		queue_free()
