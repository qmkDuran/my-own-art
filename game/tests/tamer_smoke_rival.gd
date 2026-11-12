class_name TamerSmokeRival
extends RefCounted
## Part of --tamer-smoke: a rival trainer battle, from being spotted to winning it.

var smoke: Node


func _init(owner_test: Node) -> void:
	smoke = owner_test


## A rival trainer spots you, walks up, battles with a team, uses a heal once, and is beaten for a reward.
func run() -> void:
	smoke._clear_wild(3000.0)
	smoke.g.battle.end(false)
	smoke.g.battle._grace = 0.0
	smoke.g.team.rest()
	var r: RivalTrainer = smoke.g.rivals[0]
	smoke.expect(r.state == "waiting", "a rival trainer waits on the route")
	smoke.g.trainer.place(smoke.g.layout.free_spot_near(r.global_position + Vector2(-200, 0), 8.0))
	smoke.g.field.partner.global_position = smoke.g.trainer.global_position
	await smoke.seconds(float(TamerData.rule("rivals.talk_time")) + 2.0)
	smoke.expect(smoke.g.battle.on and smoke.g.battle.rival == r, "the rival spots you, walks up and battles")
	var first: Creature = r.active
	first.rec.life = first.rec.max_life() * 0.3
	await smoke.seconds(0.3)
	smoke.expect(r._item_used or r.active != first, "the rival heals or swaps when its creature is hurt")
	var wins: int = 0
	for k: int in 8:
		if not smoke.g.battle.on:
			break
		if r.active != null and is_instance_valid(r.active) and not r.active.fainted_now:
			r.active.faint()
			wins += 1
		await smoke.seconds(1.4)
	smoke.expect(r.state == "beaten" and not smoke.g.battle.on, "beating every creature wins the trainer battle (%d down)" % wins)
	smoke.expect(r.active == null, "the rival's creatures are gone")
