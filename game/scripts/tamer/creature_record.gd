class_name CreatureRecord
extends RefCounted
## One creature as a living record, in the world or not: its species, level and growth (CreatureGrowth: XP, moves,
## evolution), shiny or alpha form, raised stats, current life and knock-out time. A team
## member keeps its record while it is called back; the Creature node that fights is made from it and writes its
## life back.

var species_id: String
var shiny: bool = false
var wild: bool = false
var level: int = 1
var upgrades: Dictionary = {"life": 0, "power": 0, "speed": 0}
var life: float = -1.0                  ## -1: full
var ko_left: float = 0.0                ## seconds until it recovers from a knock-out (0: awake)
var used_moves: Dictionary = {}         ## moves it has used with you (the first use shows the move's name)
var alpha: bool = false                 ## a rare bigger wild one (tamer.json "alpha")
var growth: CreatureGrowth


static func make(id: String, lvl: int, is_wild: bool, is_shiny: bool = false) -> CreatureRecord:
	var r := CreatureRecord.new()
	r.species_id = id
	r.level = lvl
	r.wild = is_wild
	r.shiny = is_shiny
	r.growth = CreatureGrowth.new(r)
	r.life = r.max_life()
	return r


func data() -> Dictionary:
	return TamerData.species(species_id)


func element() -> String:
	return String(data()["element"])


func display_name() -> String:
	return ("Shiny " if shiny else "") + ("Alpha " if alpha else "") + growth.form_name()


## Its signature move: the one it learns last (an alpha already knows it).
func signature_move() -> String:
	var learn: Array = data()["learn"]
	return String(learn[learn.size() - 1][1])


func A() -> Dictionary:
	return TamerData.rule("alpha")


func max_life() -> float:
	var base: float = float(data()["stats"]["life"]) * (1.0 + float(TamerData.rule("level.life")) * (level - 1))
	base *= 1.0 + float(TamerData.rule("upgrades.life.per_level")) * int(upgrades["life"])
	if alpha:
		base *= float(A()["life"])
	return roundf(base * growth.life_mult())


func power() -> float:
	var p: float = float(data()["stats"]["power"]) * (1.0 + float(TamerData.rule("level.power")) * (level - 1))
	p *= 1.0 + float(TamerData.rule("upgrades.power.per_level")) * int(upgrades["power"])
	if alpha:
		p *= float(A()["power"])
	return p * growth.power_mult()


func speed() -> float:
	return float(data()["stats"]["speed"]) * (1.0 + float(TamerData.rule("upgrades.speed.per_level")) * int(upgrades["speed"]))


func base_radius() -> float:
	return float(data()["stats"]["radius"])


func radius() -> float:
	return base_radius() * body_scale()


## How much bigger than its species it is drawn and built (evolved, alpha).
func body_scale() -> float:
	return growth.size_mult() * (float(A()["scale"]) if alpha else 1.0)


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


func heal_points(amount: float) -> void:
	if not knocked_out():
		life = minf(max_life(), life + amount)


func heal(frac: float) -> void:
	if not knocked_out():
		life = minf(max_life(), life + max_life() * frac)


## Called every frame for team members out of the world too: a knocked-out creature wakes up after a while.
func tick(delta: float) -> void:
	if ko_left > 0.0:
		ko_left -= delta
		if ko_left <= 0.0:
			revive(1.0)


## Materials the next level of `stat` costs; -1 when it is maxed.
func upgrade_cost(stat: String) -> int:
	var costs: Array = TamerData.rule("upgrades." + stat + ".cost")
	var lvl: int = int(upgrades[stat])
	return int(costs[lvl]) if lvl < costs.size() else -1


func moves() -> Array:
	return growth.active
