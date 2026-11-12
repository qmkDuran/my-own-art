class_name TamerPackFight
extends RefCounted
## The feel check of --tamer-smoke: the honey badger at its level against a near pack of two (a level-1 maned wolf
## and aye-aye), three times: basic combos on the nearest foe, a move whenever the gauge can pay for one, and a
## dodge when a red warning is about to land (as a player who reads the tells would). It should win and lose a fair
## share of life (target 20-35% on average). Printed for tuning.

const PACK_ID: int = 999
const DODGE_AT: float = 0.25

var smoke: Node


func _init(owner_test: Node) -> void:
	smoke = owner_test


const PLAYER_CADENCE: float = 1.0
const PACK_FIGHTS: int = 3


## Feel check: a starter at its level, with its moves used as they come ready, beats a near pack of two and loses
## a fair share of life (target 20-35%). Printed for tuning.
func run() -> void:
	var losses: Array[float] = []
	var times: Array[float] = []
	for k: int in PACK_FIGHTS:
		var r: Array[float] = await _one_pack()
		times.append(r[0])
		losses.append(r[1])
	var lost: float = (losses[0] + losses[1] + losses[2]) / PACK_FIGHTS
	print("TAMER pack fight: %s s, partner lost %s life (average %d%%)" % [times, losses, roundi(lost * 100.0)])
	var wins: int = times.filter(func(x: float) -> bool: return x < 40.0).size()
	smoke.expect(wins >= 2, "the starter wins a near pack of two (%d of 3 within 40 s; a kiting aye-aye can stall a melee bot)" % wins)
	smoke.expect(lost >= 0.15 and lost <= 0.4, "the pack fight costs a fair share of life (%d%% on average; target 20-35%%)" % roundi(lost * 100.0))


## One level-1 wolf and aye-aye against the honey badger, full life, the player pressing a move about once a second.
func _one_pack() -> Array[float]:
	smoke.g.battle.end(false)
	smoke.g.battle._grace = 0.0                            # the next fight may start at once
	smoke.g.trainer.global_position = smoke.g.layout.free_spot_near(smoke.g.layout.start + Vector2(0, 40), 8.0)
	smoke._clear_wild(1400.0)
	smoke.g.team.rest()
	if smoke.g.team.active != 0:
		smoke.g.field.swap(0)
	await smoke.seconds(1.0)
	var p: Creature = smoke.g.field.partner
	var rec: CreatureRecord = p.rec
	p.cooldowns.clear()
	smoke.g.team.gauge = 0.0
	var pack: Array[Creature] = [_member("maned_wolf", Vector2(150, 0)), _member("aye_aye", Vector2(170, 40))]
	for c: Creature in pack:
		(c.brain as WildBrain).wake(p)
	var t: float = 0.0
	var cadence: float = 0.0
	while t < 40.0 and is_instance_valid(p) and pack.any(func(c: Creature) -> bool: return is_instance_valid(c) and c.alive() and not c.dazed):
		cadence -= 0.1
		if cadence <= 0.0:                                 # a player presses a move about once a second
			cadence = PLAYER_CADENCE
			_use_moves(p, pack)
		_dodge_tells(p, pack)
		var b: ControlledBrain = smoke.g.battle.brain()
		if b != null and (b.target == null or not is_instance_valid(b.target) or not b.target.alive()):
			b.target = PartnerBrain.nearest_foe(p, 600.0)
		await smoke.frames(6)
		t += 0.1
	var out: Array[float] = [snappedf(t, 0.1), snappedf(1.0 - rec.life_frac(), 0.01)]
	return out


## Like a player who reads the red warnings: dodge away from an attack that is about to land (often a perfect dodge).
func _dodge_tells(p: Creature, pack: Array[Creature]) -> void:
	for c: Creature in pack:
		if not is_instance_valid(c):
			continue
		var b := c.brain as WildBrain
		if b != null and b.winding_at(p) and b.windup_left() <= DODGE_AT:
			p.dodge(p.global_position + (p.global_position - c.global_position).normalized() * 100.0, TamerData.rule("control.dodge"))
			return


## One of the test pack (they share a pack, so they fight together inside one ring).
func _member(kind: String, offset: Vector2) -> Creature:
	var at: Vector2 = smoke.g.layout.free_spot_near(smoke.g.trainer.global_position + offset, 14.0)
	return smoke.g.spawner.spawn(kind, at, 1, PACK_ID, 0)


## Like a player: each move at the nearest living foe as soon as it is ready (not the ward unless hurt).
func _use_moves(p: Creature, pack: Array[Creature]) -> void:
	if not is_instance_valid(p) or not p.alive():
		return
	var foe: Creature = null
	for c: Creature in pack:
		if is_instance_valid(c) and c.alive() and not c.dazed and (foe == null or c.global_position.distance_to(p.global_position) < foe.global_position.distance_to(p.global_position)):
			foe = c
	if foe == null:
		return
	for id: String in p.rec.moves():
		var m: Dictionary = TamerData.move(id)
		var cost: int = int(m.get("cost", 0))
		if p.global_position.distance_to(foe.global_position) <= float(m.get("range", 80.0)) + 20.0 and p.move_ready(id) \
				and smoke.g.team.spend_gauge(cost):
			p.cast(id, foe.global_position)
			return
