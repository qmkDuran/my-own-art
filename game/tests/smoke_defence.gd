class_name SmokeDefence
extends RefCounted
## Defence-night checks for the smoke test: a night starts, creatures spawn fairly (away from the player, never
## inside walls), lantern magic defeats them and they drop light motes, level-ups offer choices and the combo
## appears when its parts are maxed, moths snuff lamps and the player relights them, fainting keeps a share of the
## bag, and beating the Gloom King wins the night.

var m: Main
var tree: SceneTree
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main
	tree = main.get_tree()
	m.night.pantry.save_path = "user://test_pantry.json"


func run() -> Array[String]:
	m.start_night()
	_expect(m.night.state == NightRun.State.RUNNING, "night starts")
	_expect(m.night.loadout.attacks.has("lantern_flare"), "starter attack")
	_expect(not m.townsfolk[0].visible, "townsfolk go indoors")
	m.night.spawner.set_physics_process(false)
	m.night.set_physics_process(false)
	_check_spawns()
	await _check_combat()
	_check_levels()
	await _check_lamps()
	await _check_faint()
	await _check_boss()
	return failures


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _check_spawns() -> void:
	var near: float = Tuning.number("defence", "spawn", "radius_min")
	for index: int in 30:
		var creature: Creature = m.night.spawner.spawn_kind(["sheet_ghost", "pumpkin_head", "lantern_moth"][index % 3])
		if creature == null:
			continue
		var flat: float = Vector2(creature.global_position.x - m.player.global_position.x,
			creature.global_position.z - m.player.global_position.z).length()
		_expect(flat >= near - 0.01, "spawn keeps away from the player (%.1f m)" % flat)
		_expect(m.night.spawner.is_open(creature.global_position), "spawn not inside geometry at %s" %
			creature.global_position)
	_expect(m.night.horde.creatures.size() >= 20, "creatures spawn (%d)" % m.night.horde.creatures.size())
	m.night.horde.clear()


func _check_combat() -> void:
	var ghost: Creature = m.night.horde.spawn("sheet_ghost", m.player.global_position + Vector3(4, 0, 0))
	ghost.set_physics_process(false)
	await tree.create_timer(3.0).timeout
	_expect(not is_instance_valid(ghost) or ghost.health <= 0.0, "lantern flare defeats a ghost")
	_expect(m.night.pickups.count() > 0 or m.night.xp > 0.0, "the ghost drops a light mote")


func _check_levels() -> void:
	var offers: Array[Dictionary] = m.night.loadout.offers()
	_expect(offers.size() == 3, "three level-up choices")
	for id: String in ["firefly_swarm", "candle_ring", "moonbeam", "bell_chime"]:
		m.night.loadout.apply({ "kind": "attacks", "id": id })
	for level: int in 4:
		m.night.loadout.apply({ "kind": "attacks", "id": "firefly_swarm" })
	for level: int in int(Tuning.doc("skills")["passives"]["brighter_wick"]["max_level"]):
		m.night.loadout.apply({ "kind": "passives", "id": "brighter_wick" })
	var combo: bool = m.night.loadout.offers().any(func(o: Dictionary) -> bool: return o["kind"] == "combo")
	_expect(combo, "Star Swarm offered when Firefly Swarm and Brighter Wick are maxed")
	m.night.loadout.apply({ "kind": "combo", "id": "star_swarm" })
	_expect(m.night.loadout.attacks.has("star_swarm") and not m.night.loadout.attacks.has("firefly_swarm"),
		"the combo replaces Firefly Swarm")
	_expect(m.night.loadout.magic.area > 0.5, "Brighter Wick widens the magic")


func _check_lamps() -> void:
	var lamp: LampLight = m.night.lamps.lamps[0]
	var moth: Creature = m.night.horde.spawn("lantern_moth", lamp.global_position + Vector3(0.3, 0, 0.3))
	moth.hurt(0.0)
	await tree.create_timer(0.3).timeout
	_expect(not lamp.lit, "a moth snuffs its lamp")
	m.night.horde.clear()
	m.player.global_position = Vector3(lamp.global_position.x, 0.05, lamp.global_position.z) + lamp.global_basis.z
	await tree.create_timer(Tuning.number("defence", "lamps", "relight_seconds") + 0.8).timeout
	_expect(lamp.lit, "standing by a snuffed lamp relights it")


func _check_faint() -> void:
	m.night.bag = { "pumpkin_goo": 4 }
	var result: Array = []
	m.night.ended.connect(func(won: bool, kept: Dictionary) -> void: result.append([won, kept]), CONNECT_ONE_SHOT)
	m.night.vitality.reset(1.0)
	m.night.vitality.hurt(5.0)
	await tree.process_frame
	_expect(result.size() == 1 and not result[0][0], "fainting ends the night")
	_expect(result.size() == 1 and int(result[0][1].get("pumpkin_goo", 0)) == 2, "fainting keeps half the bag")
	_expect(m.night.horde.creatures.is_empty() and m.night.lamps.lit_count() == m.night.lamps.lamps.size(),
		"the town is tidied after the night")


func _check_boss() -> void:
	m.start_night()
	m.night.set_physics_process(false)
	var king: Creature = m.night.horde.spawn("gloom_king", m.player.global_position + Vector3(6, 0, 0))
	var result: Array = []
	m.night.ended.connect(func(won: bool, _kept: Dictionary) -> void: result.append(won), CONNECT_ONE_SHOT)
	king.hurt(king.health + 1.0)
	await tree.process_frame
	_expect(result == [true], "beating the Gloom King wins the night")
