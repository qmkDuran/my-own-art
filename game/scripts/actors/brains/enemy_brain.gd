class_name EnemyBrain
extends RefCounted
## What an enemy wants to do this frame (a velocity) and which animation row shows it. Subclasses: SwarmBrain
## (gloam), LeaperBrain (hound), RangedBrain (moth), GlazierBrain (mini-boss). Shared: chasing with the grid when
## the straight way is blocked, melee checks, shard shots.

const CIRCLE_SPEED: float = 0.45
const HOLD_BACK: float = 90.0
const PATH_REFRESH: float = 0.6
const ROW_IDLE: int = 0
const ROW_MOVE: int = 1
const ROW_ATTACK: int = 2
const SHARD_TEX: String = "res://art/fx/shard.png"
const SHOT_HEIGHT: float = 22.0

var e: Enemy
var state: String = "chase"
var t: float = 0.0
var cd: float = 0.0
var aim: Vector2
var _path := PackedVector2Array()
var _path_t: float = 0.0


static func make(enemy: Enemy) -> EnemyBrain:
	var b: EnemyBrain
	match String(enemy.data["ai"]):
		"leaper": b = LeaperBrain.new()
		"ranged": b = RangedBrain.new()
		"boss": b = GlazierBrain.new()
		"matron": b = MatronBrain.new()
		"bellwright": b = BellwrightBrain.new()
		"mayor": b = MayorBrain.new()
		"dummy": b = DummyBrain.new()
		_: b = SwarmBrain.new()
	b.e = enemy
	b.cd = randf_range(0.2, 0.8)
	return b


func player() -> Player:
	return Game.current.player


func to_player() -> Vector2:
	return player().global_position - e.global_position


func think(delta: float) -> Vector2:
	if not e.awake or player().dead:
		return Vector2.ZERO
	t -= delta
	cd -= delta * e.attack_speed()
	return _think(delta)


func _think(_delta: float) -> Vector2:
	return Vector2.ZERO


## At most `max_engaged` melee enemies wind up at once (Last Epoch pacing): the rest hold back and circle.
func may_engage() -> bool:
	var busy: int = 0
	for n: Node in e.get_tree().get_nodes_in_group("enemies"):
		var o := n as Enemy
		if o != e and o.brain != null and (o.brain.state == "windup" or o.brain.state == "strike"):
			busy += 1
	return busy < int(GameData.enemies["max_engaged"])


## Hold back at a distance, drifting sideways around the Lamplighter.
func circle_around(dist: float, spd: float) -> Vector2:
	var away: Vector2 = -to_player()
	var side: Vector2 = away.orthogonal().normalized() * (1.0 if e.get_instance_id() % 2 == 0 else -1.0)
	var want: Vector2 = side * 0.6 + away.normalized() * clampf((dist - away.length()) / dist, -1.0, 1.0)
	return want.normalized() * spd * CIRCLE_SPEED


func anim_row(want: Vector2) -> int:
	if state == "windup" or state == "strike":
		return ROW_ATTACK
	return ROW_MOVE if want.length() > 5.0 else ROW_IDLE


## Velocity toward a point: straight if the way is clear, else along a grid path (refreshed now and then).
func chase(goal: Vector2, spd: float) -> Vector2:
	var nav: Nav = Game.current.nav
	if nav.line_free(e.global_position, goal):
		_path.clear()
		return (goal - e.global_position).normalized() * spd
	_path_t -= get_delta()
	if _path.is_empty() or _path_t <= 0.0:
		_path = nav.path(e.global_position, goal)
		_path_t = PATH_REFRESH
	while not _path.is_empty() and e.global_position.distance_to(_path[0]) < 10.0:
		_path.remove_at(0)
	if _path.is_empty():
		return Vector2.ZERO
	return (_path[0] - e.global_position).normalized() * spd


func get_delta() -> float:
	return e.get_physics_process_delta_time()


## Hits the player if within reach now.
func melee(reach: float) -> bool:
	if to_player().length() <= reach + player().radius + e.radius:
		Combat.hit_player(e, e.damage, String(e.data["type"]), e.global_position)
		var slow: Array = e.data.get("slow_on_hit", [])
		if not slow.is_empty():
			player().slow(float(slow[0]), float(slow[1]))
		return true
	return false


## A shot: a shard of stolen light, or (crawlers) a gob of silk that slows.
func shoot(dir: Vector2, spd: float) -> void:
	var from: Vector2 = e.global_position + Vector2(0, -SHOT_HEIGHT)
	var src_id: int = e.get_instance_id()
	var dmg: float = e.damage
	var kind: String = String(e.data["type"])
	var slow: Array = e.data.get("slow", [])
	var col: Color = Pal.c("bone") if String(e.data.get("shot", "")) == "silk" else Pal.c("glint")
	Projectile.spawn(Game.current.fx_layer, from, dir.normalized() * spd, PropSprite.tex(SHARD_TEX), col, true,
		func(p: Node2D) -> void:
			Combat.hit_player(instance_from_id(src_id) as Enemy, dmg, kind, from)
			if not slow.is_empty():
				(p as Player).slow(float(slow[0]), float(slow[1])))


func shard_ring(n: int) -> void:
	for k: int in n:
		shoot(Vector2.RIGHT.rotated(TAU * k / n), float(GameData.enemy("moth")["shot_speed"]))
