class_name Loadout
extends Node3D
## The lantern magic the player has tonight: owned attacks (each its own node), passive levels and what they add
## up to, the level-up offers (new or stronger attacks and passives, a combo once both its parts are maxed, Warm
## Tea when nothing is left) and applying the chosen one.

const ATTACK_SCRIPTS: Dictionary = {
	"lantern_flare": "res://defence/skills/lantern_flare.gd", "firefly_swarm": "res://defence/skills/orbit_attack.gd",
	"candle_ring": "res://defence/skills/orbit_attack.gd", "moonbeam": "res://defence/skills/moonbeam.gd",
	"bell_chime": "res://defence/skills/bell_chime.gd", "star_swarm": "res://defence/skills/orbit_attack.gd",
}

## Magic you already have is this many times likelier to be offered (so builds deepen towards combos).
const OWNED_WEIGHT: int = 3

var attacks: Dictionary = {}
var passives: Dictionary = {}
var magic := MagicStats.new()
var _player: Player
var _horde: Horde
var _vitality: Vitality
var _pickups: Pickups
var _kit: VfxKit


func setup(player: Player, horde: Horde, vitality: Vitality, pickups: Pickups, kit: VfxKit) -> void:
	name = "Loadout"
	_kit = kit
	_player = player
	_horde = horde
	_vitality = vitality
	_pickups = pickups


## Back to just the starter attack and no passives.
func reset() -> void:
	for attack: Attack in attacks.values():
		attack.queue_free()
	attacks.clear()
	passives.clear()
	magic = MagicStats.new()
	_player.speed_scale = 1.0
	_pickups.magnet_bonus = 0.0
	_add_attack(Tuning.doc("skills")["starter"], Tuning.doc("skills")["attacks"])


func level_of(id: String) -> int:
	if attacks.has(id):
		return (attacks[id] as Attack).level
	return int(passives.get(id, 0))


## Up to `choices` random offers (magic you own is likelier); a ready combo is always among them.
func offers() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var combos: Array[Dictionary] = []
	for id: String in Tuning.doc("skills")["combos"]:
		if _combo_ready(id):
			combos.append(_offer("combo", id, Tuning.doc("skills")["combos"][id]))
	for kind: String in ["attacks", "passives"]:
		var table: Dictionary = Tuning.doc("skills")[kind]
		for id: String in table:
			if level_of(id) < int(table[id]["max_level"]) and not _replaced_by_combo(id):
				for copy: int in OWNED_WEIGHT if level_of(id) > 0 else 1:
					pool.append(_offer(kind, id, table[id]))
	pool.shuffle()
	var picked: Array[Dictionary] = combos
	for offer: Dictionary in pool:
		if not picked.any(func(other: Dictionary) -> bool: return other["id"] == offer["id"]):
			picked.append(offer)
	picked.resize(mini(picked.size(), int(Tuning.doc("skills")["choices"])))
	if picked.is_empty():
		picked.append(_offer("heal", "warm_tea", Tuning.doc("skills")["heal_choice"]))
	return picked


func apply(offer: Dictionary) -> void:
	var id: String = offer["id"]
	match offer["kind"]:
		"attacks":
			if attacks.has(id):
				(attacks[id] as Attack).level_up()
			else:
				_add_attack(id, Tuning.doc("skills")["attacks"])
		"passives":
			passives[id] = int(passives.get(id, 0)) + 1
			_apply_passive(id)
		"combo":
			var replaced: String = Tuning.doc("skills")["combos"][id]["replaces"]
			(attacks[replaced] as Attack).queue_free()
			attacks.erase(replaced)
			_add_attack(id, Tuning.doc("skills")["combos"])
		"heal":
			_vitality.heal(float(Tuning.doc("skills")["heal_choice"]["heal"]))


func _offer(kind: String, id: String, spec: Dictionary) -> Dictionary:
	return { "kind": kind, "id": id, "name": spec["name"], "text": spec["text"], "level": level_of(id) + 1 }


func _combo_ready(id: String) -> bool:
	if attacks.has(id):
		return false
	for part: String in Tuning.doc("skills")["combos"][id]["needs"]:
		var spec: Dictionary = Tuning.doc("skills")["attacks"].get(part, Tuning.doc("skills")["passives"].get(part, {}))
		if level_of(part) < int(spec.get("max_level", 1)):
			return false
	return true


func _replaced_by_combo(id: String) -> bool:
	for combo: String in Tuning.doc("skills")["combos"]:
		if attacks.has(combo) and Tuning.doc("skills")["combos"][combo]["replaces"] == id:
			return true
	return false


func _add_attack(id: String, table: Dictionary) -> void:
	var attack: Attack = (load(ATTACK_SCRIPTS[id]) as GDScript).new()
	add_child(attack)
	attack.kit = _kit
	attack.setup(id, table[id], _player, _horde, magic)
	attacks[id] = attack


func _apply_passive(id: String) -> void:
	var bonus: Dictionary = Tuning.doc("skills")["passives"][id]["per_level"]
	magic.area += float(bonus.get("area", 0.0))
	magic.cooldown += float(bonus.get("cooldown", 0.0))
	magic.speed += float(bonus.get("speed", 0.0))
	_player.speed_scale = magic.speed_scale()
	_pickups.magnet_bonus = magic.area
	if bonus.has("max_health"):
		_vitality.raise_max(float(bonus["max_health"]))
	for attack: Attack in attacks.values():
		attack.on_level_changed()
