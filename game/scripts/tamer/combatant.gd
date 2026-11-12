class_name Combatant
extends CharacterBody2D
## Anything on the field that fights or can be hit: the trainer and every creature. Two sides: "team" (the trainer
## and the active partner) and "wild". Gives them one way to be hit (receive_hit), shared knockback, and steering
## around blocked ground (a straight line when it is clear, else a grid path, refreshed now and then).

const SIDE_TEAM: String = "team_side"
const SIDE_WILD: String = "wild"
const KNOCK_DECAY: float = 9.0
const ARRIVE: float = 6.0
const REPATH: float = 0.35
const WORLD_MASK: int = 1

var side: String = SIDE_TEAM
var stun_t: float = 0.0
var iframe_t: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _path := PackedVector2Array()
var _path_goal: Vector2 = Vector2.INF
var _repath: float = 0.0


func hit_radius() -> float:
	return 10.0


## The element hits are measured against ("" for the trainer: no matchup).
func element_id() -> String:
	return ""


func alive() -> bool:
	return true


func max_life_value() -> float:
	return 1.0


## A hit lands: damage, a shove along `dir` (px), a stun (s). The attacker may be null (a hazard).
func receive_hit(_dmg: float, _dir: Vector2, _knock_px: float, _stun: float, _attacker: Combatant) -> void:
	pass


func foes() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for n: Node in get_tree().get_nodes_in_group(SIDE_WILD if side == SIDE_TEAM else SIDE_TEAM):
		var c := n as Combatant
		if c != null and c.alive():
			out.append(c)
	return out


func shove(dir: Vector2, px: float) -> void:
	_knock += dir.normalized() * px * KNOCK_DECAY


func knock_velocity(delta: float) -> Vector2:
	var k: Vector2 = _knock
	_knock = _knock.lerp(Vector2.ZERO, minf(1.0, KNOCK_DECAY * delta))
	return k


## The way to go toward `goal`: straight if the line is clear, else along a grid path (refreshed every REPATH s
## or when the goal moves far).
func steer_to(goal: Vector2, delta: float) -> Vector2:
	var nav: Nav = TamerGame.current.nav
	if nav.line_free(global_position, goal):
		_path.clear()
		return (goal - global_position).normalized() if global_position.distance_to(goal) > ARRIVE else Vector2.ZERO
	_repath -= delta
	if _path.is_empty() or _repath <= 0.0 or _path_goal.distance_to(goal) > 48.0:
		_repath = REPATH
		_path_goal = goal
		_path = nav.path(global_position, goal)
	while not _path.is_empty() and global_position.distance_to(_path[0]) < ARRIVE:
		_path.remove_at(0)
	if _path.is_empty():
		return Vector2.ZERO
	return (_path[0] - global_position).normalized()


func untouchable() -> bool:
	return iframe_t > 0.0 or not alive()
