class_name Projectile
extends Node2D
## A moving shot. Enemy shards hit the Lamplighter; the Lamplighter's bolts hit enemies (pierce or not).
## Stops at forest and walls (it flies over water). Glows (additive) and lights its surroundings a little.

const HIT_RADIUS: float = 12.0
const LIGHT_RANGE: float = 50.0
const MIRROR_RANGE: float = 40.0

var velocity: Vector2
var life: float = 2.0
var hostile: bool = true            ## true: hits the player; false: hits enemies
var pierce: bool = false
var on_hit: Callable                ## func(target: Node2D) -> void
var hit_radius: float = HIT_RADIUS
var tint: Color = Color.WHITE
var _hit: Array[Node] = []


static func spawn(parent: Node, at: Vector2, vel: Vector2, tex: Texture2D, col: Color, hostile_shot: bool, hit_fn: Callable) -> Projectile:
	var p := Projectile.new()
	p.position = at
	p.velocity = vel
	p.hostile = hostile_shot
	p.on_hit = hit_fn
	p.tint = col
	p.rotation = vel.angle()
	p.z_index = Fx.FX_Z
	var s := Sprite2D.new()
	s.texture = tex
	s.material = Fx.glow_material()
	s.modulate = col
	p.add_child(s)
	var l := PointLight2D.new()
	l.texture = LightTex.soft(64)
	l.texture_scale = LIGHT_RANGE / 32.0
	l.color = col
	l.energy = 0.7
	p.add_child(l)
	parent.add_child(p)
	return p


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	var z: ZoneLayout = Game.current.layout
	var t: int = z.t(z.cell_of(position))
	if life <= 0.0 or t == ZoneLayout.T.THICKET or t == ZoneLayout.T.WALL:
		_fizzle()
		return
	if hostile:
		var p: Player = Game.current.player
		if p.global_position.distance_to(position + Vector2(0, 14)) < hit_radius + p.radius:
			on_hit.call(p)
			_fizzle()
		elif Game.current.moth_guards_catch(position) or _mirror(p):
			_fizzle()
		return
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.dead or _hit.has(e):
			continue
		if e.global_position.distance_to(position + Vector2(0, e.body_height() * 0.3)) < hit_radius + e.radius:
			_hit.append(e)
			on_hit.call(e)
			if not pierce:
				_fizzle()
				return


## Glass Ward's Mirror: shots that reach a warded Lamplighter shatter.
func _mirror(p: Player) -> bool:
	var w: GlassWard = p.skills.skill("glass_ward") as GlassWard
	return w.up() and w.rank("mirror") > 0 and p.global_position.distance_to(position) < MIRROR_RANGE


func _fizzle() -> void:
	Fx.burst(get_parent(), position, 6, Vector2(30, 80), 0.25, [tint, Color(tint, 0.0)])
	queue_free()
