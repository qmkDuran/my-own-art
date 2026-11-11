class_name StatusRules
extends RefCounted
## The three battle conditions (data/statuses.json): Singed loses a little HP each round, Drowsy may skip its
## turn, Rattled may miss an attack. Each lasts a few rounds; a creature has at most one. Pure rules.


static func data(id: String) -> Dictionary:
	return Db.statuses[id]


## Rolls a move's chance to inflict its condition; returns the condition id or "".
static func roll_inflict(move_id: String, target: Battler, rng: RandomNumberGenerator) -> String:
	var s: Dictionary = Db.move(move_id).get("status", {})
	if s.is_empty() or target.status != "" or target.creature.is_fainted():
		return ""
	return String(s["id"]) if rng.randf() < float(s["chance"]) else ""


static func apply(target: Battler, id: String) -> void:
	target.status = id
	target.status_turns = int(data(id)["turns"])


static func skips_turn(b: Battler, rng: RandomNumberGenerator) -> bool:
	return b.status == "drowsy" and rng.randf() < float(data("drowsy")["skip"])


static func misses(b: Battler, rng: RandomNumberGenerator) -> bool:
	return b.status == "rattled" and rng.randf() < float(data("rattled")["miss"])


static func chip(b: Battler) -> int:
	if b.status != "singed":
		return 0
	return maxi(1, int(b.creature.max_hp() * float(data("singed")["chip"])))


## Counts a round down; returns true when the condition just wore off.
static func tick(b: Battler) -> bool:
	if b.status == "":
		return false
	b.status_turns -= 1
	if b.status_turns > 0:
		return false
	b.status = ""
	return true


static func line(id: String, key: String, who: String) -> String:
	return String(data(id)[key]) % who
