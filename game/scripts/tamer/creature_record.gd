class_name CreatureRecord
extends RefCounted
## One creature as a living record, in the world or not: its species, level, shiny form, bond, raised stats,
## current life and knock-out time. A team member keeps its record while it is called back; the Creature node that
## fights is made from it and writes its life back.

signal bond_unlocked(rec: CreatureRecord)

var species_id: String
var shiny: bool = false
var wild: bool = false
var level: int = 1
var bond: float = 0.0
var upgrades: Dictionary = {"life": 0, "power": 0, "speed": 0}
var life: float = -1.0                  ## -1: full
var ko_left: float = 0.0                ## seconds until it recovers from a knock-out (0: awake)


static func make(id: String, lvl: int, is_wild: bool, is_shiny: bool = false) -> CreatureRecord:
	var r := CreatureRecord.new()
	r.species_id = id
	r.level = lvl
	r.wild = is_wild
	r.shiny = is_shiny
	r.life = r.max_life()
	return r


func data() -> Dictionary:
	return TamerData.species(species_id)


func element() -> String:
	return String(data()["element"])


func display_name() -> String:
	return ("Shiny " if shiny else "") + String(data()["name"])


func max_life() -> float:
	var base: float = float(data()["stats"]["life"]) * (1.0 + float(TamerData.rule("level.life")) * (level - 1))
	base *= 1.0 + float(TamerData.rule("upgrades.life.per_level")) * int(upgrades["life"])
	if wild:
		base *= float(TamerData.rule("wild.life_mult"))
	return roundf(base)


func power() -> float:
	var p: float = float(data()["stats"]["power"]) * (1.0 + float(TamerData.rule("level.power")) * (level - 1))
	p *= 1.0 + float(TamerData.rule("upgrades.power.per_level")) * int(upgrades["power"])
	if wild:
		p *= float(TamerData.rule("wild.power_mult"))
	return p


func speed() -> float:
	return float(data()["stats"]["speed"]) * (1.0 + float(TamerData.rule("upgrades.speed.per_level")) * int(upgrades["speed"]))


func radius() -> float:
	return float(data()["stats"]["radius"])


func life_frac() -> float:
	return clampf(life / maxf(max_life(), 1.0), 0.0, 1.0)


func knocked_out() -> bool:
	return ko_left > 0.0


func knock_out() -> void:
	life = 0.0
	ko_left = float(TamerData.rule("knockout.recover"))


func revive(frac: float) -> void:
	ko_left = 0.0
	life = maxf(life, max_life() * frac)


func heal(frac: float) -> void:
	if not knocked_out():
		life = minf(max_life(), life + max_life() * frac)


## Called every frame for team members out of the world too: a knocked-out creature wakes up after a while.
func tick(delta: float) -> void:
	if ko_left > 0.0:
		ko_left -= delta
		if ko_left <= 0.0:
			revive(1.0)


func bond_frac() -> float:
	return bond / float(TamerData.rule("bond.max"))


func bond_move_ready() -> bool:
	return bond >= float(TamerData.rule("bond.unlock"))


## Bond grows; crossing the threshold unlocks the bond move once.
func add_bond(amount: float) -> void:
	var was: bool = bond_move_ready()
	bond = minf(float(TamerData.rule("bond.max")), bond + amount)
	if not was and bond_move_ready():
		bond_unlocked.emit(self)


## Materials the next level of `stat` costs; -1 when it is maxed.
func upgrade_cost(stat: String) -> int:
	var costs: Array = TamerData.rule("upgrades." + stat + ".cost")
	var lvl: int = int(upgrades[stat])
	return int(costs[lvl]) if lvl < costs.size() else -1


func moves() -> Array:
	return data()["kit"]


func bond_move() -> String:
	return String(data()["bond_move"])
