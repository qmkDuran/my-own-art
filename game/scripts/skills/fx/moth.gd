class_name Moth
extends Node2D
## An ember moth: flutters out toward the cursor, then seeks the nearest enemy (lit ones first) and burns into it.
## Variants by the tree: lingering (survives one hit), cinder (bursts), great (Matriarch: bigger, pierces), and
## guardian (circles the Lamplighter, catching shots).

const TURN: float = 7.0
const FLUTTER: float = 0.05
const HIT_RADIUS: float = 8.0
const BURST_RADIUS: float = 36.0
const ORBIT_RADIUS: float = 34.0
const ORBIT_SPEED: float = 3.2
const GREAT_SCALE: float = 2.0
const FRAME_TIME: float = 0.06

var skill: MothSwarm
var velocity: Vector2
var life: float
var lives: int = 1
var great: bool = false
var guardian: bool = false
var orbit_phase: float = 0.0
var _sprite: Sprite2D
var _t: float = 0.0
var _hit: Array[Enemy] = []


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = PropSprite.tex("res://art/fx/moth.png")
	_sprite.hframes = 2
	_sprite.material = Fx.glow_material()
	_sprite.scale = Vector2.ONE * (GREAT_SCALE if great else 1.0)
	add_child(_sprite)
	var l := PointLight2D.new()
	l.texture = LightTex.soft(64)
	l.color = Pal.c("flame")
	l.energy = 0.8 if great else 0.5
	l.texture_scale = 1.2
	add_child(l)
	z_index = Fx.FX_Z
	if guardian:
		add_to_group("moth_guards")


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	_sprite.frame = int(_t / FRAME_TIME) % 2
	if life <= 0.0:
		_fade()
		return
	if guardian:
		_orbit()
		return
	var target: Enemy = _seek()
	var want: Vector2 = velocity
	if target != null:
		want = (target.global_position + Vector2(0, -target.body_height() * 0.5) - global_position).normalized() * skill.speed()
	want += Vector2(sin(_t * 17.0 + orbit_phase), cos(_t * 13.0)) * skill.speed() * FLUTTER
	velocity = velocity.lerp(want, minf(1.0, TURN * delta))
	position += velocity * delta
	rotation = velocity.angle() + PI * 0.5
	_touch()


func _seek() -> Enemy:
	var best: Enemy = null
	var best_d: float = skill.seek_range()
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if _hit.has(e):
			continue
		var d: float = e.global_position.distance_to(global_position) * (0.7 if not e.shrouded else 1.0)
		if d < best_d:
			best_d = d
			best = e
	return best


func _touch() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if _hit.has(e):
			continue
		var body: Vector2 = e.global_position + Vector2(0, -e.body_height() * 0.5)
		if body.distance_to(global_position) < HIT_RADIUS + e.radius:
			_strike(e)
			return


func _strike(e: Enemy) -> void:
	_hit.append(e)
	skill.moth_hit(e, global_position, great)
	if great:
		return
	lives -= 1
	if lives <= 0:
		queue_free()


func _orbit() -> void:
	orbit_phase += get_physics_process_delta_time() * ORBIT_SPEED
	position = skill.p.global_position + Vector2(cos(orbit_phase), sin(orbit_phase) * 0.6) * ORBIT_RADIUS + Vector2(0, -24)


func _fade() -> void:
	Fx.burst(get_parent(), global_position, 4, Vector2(10, 40), 0.3, [Pal.c("amber"), Pal.c("ember", 0.0)])
	queue_free()
