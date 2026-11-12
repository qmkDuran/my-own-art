class_name TrainerCommands
extends Node
## The trainer's own part in a fight (keys A S D G): Cheer (your creature hits harder for a while), Focus (its next
## move is a critical hit), Rally (it heals over a few seconds) and Mark (the wild creature under the cursor: your
## creature goes for it and deals more to it). Each has a cooldown and grows stronger with the creature's bond.

signal used(id: String)

const IDS: Array[String] = ["cheer", "focus", "rally", "mark"]
const MARK_PICK: float = 30.0

var g: TamerGame
var cooldowns: Dictionary = {}


func setup(game: TamerGame) -> void:
	g = game


func data(id: String) -> Dictionary:
	return TamerData.rule("commands." + id)


func cooldown_frac(id: String) -> float:
	return clampf(float(cooldowns.get(id, 0.0)) / float(data(id)["cooldown"]), 0.0, 1.0)


## How much stronger a command is with this creature's bond (x1 at none, x1.5 at full by default).
func bond_scale(c: Creature) -> float:
	return 1.0 + c.rec.bond_frac() * float(TamerData.rule("command_bond_scale"))


func use(id: String, at: Vector2) -> bool:
	var c: Creature = g.field.partner
	if float(cooldowns.get(id, 0.0)) > 0.0 or c == null or not c.alive():
		return false
	var d: Dictionary = data(id)
	var k: float = bond_scale(c)
	match id:
		"cheer":
			c.cheer_t = float(d["time"])
			c.cheer_power = float(d["power"]) * k
		"focus":
			c.focus_ready = true
			c.focus_crit = 1.0 + (float(d["crit"]) - 1.0) * k
		"rally":
			c.regen_t = float(d["time"])
			c.regen_rate = c.rec.max_life() * float(d["heal"]) * k / float(d["time"])
		"mark":
			if not _mark(at, float(d["time"]), float(d["damage"]) * k):
				return false
	cooldowns[id] = float(d["cooldown"])
	_show(id, c)
	used.emit(id)
	return true


func _mark(at: Vector2, time: float, bonus: float) -> bool:
	var best: Creature = null
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var w := n as Creature
		if w.global_position.distance_to(at) < w.hit_radius() + MARK_PICK and (best == null or
				w.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = w
	if best == null:
		g.hud.notice("Point at a wild creature to mark it")
		return false
	best.marked_t = time
	best.mark_bonus = bonus
	g.trainer.attack_target = best
	Fx.ring(g.fx_layer, best.global_position, 40.0, 12.0, Pal.c("rose"), 0.3)
	return true


## The trainer calls it out (a word over the trainer) and the creature lights up in the command's colour.
func _show(id: String, c: Creature) -> void:
	var d: Dictionary = data(id)
	var col: Color = Pal.c(String(d["color"]))
	TamerFx.word(g.trainer.global_position, String(d["name"]) + "!", col)
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -12), 18, Vector2(40, 140), 0.5, [Pal.c("sun"), col, Color(col, 0.0)], Vector2.UP)
	Fx.ring(g.fx_layer, c.global_position, 8.0, 40.0, col, 0.3)
	Audio.sfx("ui_click", -6.0, 1.5)


func _process(delta: float) -> void:
	for id: String in cooldowns:
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
