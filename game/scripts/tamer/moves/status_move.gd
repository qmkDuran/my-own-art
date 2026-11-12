class_name StatusMove
extends MoveKind
## A channelled status move: its effect (effects.json) on the user (a buff) or on the foe nearest the aim (a debuff),
## as strong as it was channelled. Every buff carries its own cost.


func cast(user: Creature, m: Dictionary, at: Vector2, strength: float = 1.0) -> void:
	var el: String = element(user, m)
	var effect: String = String(m["effect"])
	var who: Creature = user if String(m["target"]) == "self" else _foe_near(user, m, at)
	if who == null:
		TamerFx.word(user.global_position, "No one there", Pal.c("pale"))
		return
	who.effects.add(effect, strength)
	var name: String = String(CreatureEffects.data(effect)["name"])
	TamerFx.word(who.global_position, "%s! (%d%%)" % [name, roundi(strength * 100.0)], Pal.c(String(CreatureEffects.data(effect)["color"])))
	TamerFx.blast(who.global_position, 30.0 + 30.0 * strength, el)
	Audio.sfx("lamp_lit", -8.0, 1.0 + strength * 0.4)


## The foe within range closest to where the move was aimed.
func _foe_near(user: Creature, m: Dictionary, at: Vector2) -> Creature:
	var best: Creature = null
	for f: Combatant in user.foes():
		var c := f as Creature
		if c == null or c.global_position.distance_to(user.global_position) > float(m.get("range", 260.0)):
			continue
		if best == null or c.global_position.distance_to(at) < best.global_position.distance_to(at):
			best = c
	return best
