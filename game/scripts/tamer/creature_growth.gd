class_name CreatureGrowth
extends RefCounted
## How a creature grows: experience and levels, moves unlocked by level (species "learn"), the 4 active moves
## chosen from those (the team station), and one evolution (species "evolve") with its stronger form.

signal leveled(rec: CreatureRecord)
signal evolved(rec: CreatureRecord)

var rec: CreatureRecord
var xp: float = 0.0
var active: Array[String] = []          ## the 4 moves on Q W E R
var evolved_form: bool = false


func _init(r: CreatureRecord) -> void:
	rec = r
	reset_moves()


static func xp_to_next(level: int) -> float:
	return float(TamerData.rule("progression.xp_growth")) * level


func xp_frac() -> float:
	return xp / xp_to_next(rec.level)


## Moves learned exactly at `level` (for the "learned X" notice).
func learned_at(level: int) -> Array[String]:
	var out: Array[String] = []
	for e: Array in rec.data()["learn"]:
		if int(e[0]) == level:
			out.append(String(e[1]))
	return out


## Moves this creature knows at its level, in learn order.
func learned() -> Array[String]:
	var out: Array[String] = []
	for e: Array in rec.data()["learn"]:
		if int(e[0]) <= rec.level:
			out.append(String(e[1]))
	return out


## The default active moves: the species kit, topped up with learned moves.
func reset_moves() -> void:
	active.clear()
	for m: String in rec.data()["kit"]:
		active.append(m)
	for m: String in learned():
		if active.size() < 4 and not active.has(m):
			active.append(m)


## Puts `move` into slot `i` (it must be learned; a move already in another slot swaps places).
func set_move(i: int, move: String) -> bool:
	if not learned().has(move) or i < 0 or i >= 4:
		return false
	var j: int = active.find(move)
	if j >= 0:
		active[j] = active[i]
	active[i] = move
	return true


func add_xp(amount: float) -> int:
	xp += amount
	var ups: int = 0
	while xp >= xp_to_next(rec.level) and rec.level < int(TamerData.rule("progression.max_level")):
		xp -= xp_to_next(rec.level)
		rec.level += 1
		ups += 1
		leveled.emit(rec)
	if ups > 0:
		_check_evolution()
	return ups


## Jump to a level (the team station): learns what that level knows and evolves if it should.
func set_level(lvl: int) -> void:
	rec.level = lvl
	xp = 0.0
	evolved_form = false
	rec.life = rec.max_life()
	reset_moves()
	_check_evolution()


func _check_evolution() -> void:
	var e: Dictionary = rec.data().get("evolve", {})
	if e.is_empty() or evolved_form or rec.level < int(e["level"]):
		return
	evolved_form = true
	rec.life = rec.max_life()
	evolved.emit(rec)


func life_mult() -> float:
	return float(rec.data()["evolve"]["life"]) if evolved_form else 1.0


func power_mult() -> float:
	return float(rec.data()["evolve"]["power"]) if evolved_form else 1.0


func size_mult() -> float:
	return float(rec.data()["evolve"]["scale"]) if evolved_form else 1.0


func form_name() -> String:
	return String(rec.data()["evolve"]["into"]) if evolved_form else String(rec.data()["name"])
