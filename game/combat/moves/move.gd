class_name Move
extends Ability
## A move from the library, driven by its data: wind-up (the telegraph, with the move's glow and pose), active part,
## recovery and cooldown, plus how much the creature can move while winding up. Archetype subclasses (melee,
## projectile, area, leap, buff, sense, burrow ...) say what happens when it fires.

var id: String
var spec: Dictionary
var ambush: bool = false


func _init(owner: Creature, move_id: String) -> void:
	id = move_id
	spec = MoveLibrary.spec(move_id)
	super(owner, float(spec["windup"]), float(spec["active"]), float(spec["recovery"]), float(spec["cooldown"]))


func display_name() -> String:
	return spec["name"]


func role() -> String:
	return spec["role"]


func category() -> String:
	return spec["category"]


func number(key: String) -> float:
	return float(spec[key])


func windup_move_factor() -> float:
	return float(spec.get("windup_move", 0.0))


## Whether the move can start right now in the creature's situation (soft ground for burrow, water to submerge...).
func usable() -> bool:
	return creature.traversal.allows(self)


## Damage this move deals now: its base times the user's damage effects and a pending critical.
func damage_now() -> float:
	return number("damage") * creature.effects.value("damage_out", 1.0) * creature.effects.consume("crit")


func _on_start() -> void:
	ambush = creature.ambush_ready()
	if category() == "attack" or category() == "debuff" or spec.get("reveals", false):
		creature.announce_attack(float(spec.get("loud_radius", Tuning.f("noise", "attack_radius"))))


## Applies the move's on-hit effect (slow, blind, confused, weaken) to a creature it hit.
func apply_on_hit(target: Creature) -> void:
	var on_hit: Dictionary = spec.get("on_hit", {})
	if not on_hit.is_empty():
		target.effects.add(on_hit["effect"], float(on_hit["value"]), float(on_hit["duration"]))
