class_name Traversal
extends RefCounted
## How a creature is getting around: on the ground, underground (burrowed in soft soil), perched in a tree crown, or
## submerged in water. It says which moves fit the situation, how fast the creature moves, whether it is deeply
## concealed, and leaves the honest trace each mode costs: a rumbling dust trail underground, bubbles underwater.

enum Mode { GROUND, UNDERGROUND, PERCHED, SUBMERGED }

## Moves that still work in each special mode (the move that got you there always works, to get you out).
const MODE_ROLES: Dictionary = {
	Mode.UNDERGROUND: ["burrow"], Mode.PERCHED: ["climb", "ranged", "sense", "buff"],
	Mode.SUBMERGED: ["submerge", "sense"],
}

var mode: Mode = Mode.GROUND
var perch: Vector3 = Vector3.ZERO
var _creature: Creature
var _trace_left: float = 0.0


func _init(owner: Creature) -> void:
	_creature = owner


func allows(move: Move) -> bool:
	if mode != Mode.GROUND:
		return (MODE_ROLES[mode] as Array).has(move.role())
	match move.role():
		"burrow":
			return _woods() != null and _woods().soft_at(_creature.global_position)
		"submerge":
			return _woods() != null and _woods().water_at(_creature.global_position)
		"climb":
			return _woods() != null and _woods().climbable_near(_creature.global_position, move.number("reach")) \
					!= Vector3.INF
		"leap":
			return _creature.is_on_floor()
	return true


## Movement speed multiplier for the mode (wading through water slows you too).
func speed_factor() -> float:
	match mode:
		Mode.UNDERGROUND:
			return _mode_move_factor("burrow")
		Mode.SUBMERGED:
			return _mode_move_factor("submerge")
		Mode.PERCHED:
			return 0.0
	var wading: bool = _woods() != null and _woods().water_at(_creature.global_position)
	return Tuning.f("creature", "wade_factor") if wading else 1.0


## Deeply concealed: no one sees it at any distance unless a sense reveals it.
func deep() -> bool:
	return mode == Mode.UNDERGROUND or mode == Mode.SUBMERGED


## Underground the body leaves the surface: shots and bodies pass over it.
func enter(next: Mode) -> void:
	mode = next
	_creature.stealth.set_deep(deep())
	_creature.stealth.set_perched(mode == Mode.PERCHED)
	_creature.collision_layer = 0 if mode == Mode.UNDERGROUND else Layers.CREATURE


## Underground the soil rumbles (dust and noise); underwater bubbles rise. Both are the price of those moves.
func tick(delta: float) -> void:
	if not deep() or _creature.horizontal_speed() < Creature.MOVING_SPEED:
		return
	_trace_left -= delta
	if _trace_left > 0.0:
		return
	_trace_left = Tuning.f("noise", "rumble_interval")
	if mode == Mode.UNDERGROUND:
		NoiseBus.emit_noise(_creature, _creature.global_position, Tuning.f("noise", "rumble_radius"), "rumble")
	TraceFx.spawn(_creature.get_parent(), _creature.global_position, mode == Mode.UNDERGROUND)


## Can the creature keep moving to this point in its mode? Burrowers stay inside soft soil, swimmers in water.
func can_reach(point: Vector3) -> bool:
	if mode == Mode.UNDERGROUND:
		return _woods().soft_at(point)
	if mode == Mode.SUBMERGED:
		return _woods().water_at(point)
	return true


func _mode_move_factor(role: String) -> float:
	for move: Move in _creature.moves:
		if move.role() == role:
			return move.number("speed_factor")
	return 1.0


func _woods() -> Woods:
	return _creature.woods
