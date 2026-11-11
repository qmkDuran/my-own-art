extends Node
## --tamer-smoke: headless play of the trainer prototype. Starts the real prototype scene, then: the meeting and
## picking a starter, the element chart, moves and the partner's auto-attack, hybrid control on and off, befriending
## (and being interrupted), swapping with the entry attack, a knock-out and the step-in, bond and the bond move, camp
## (rest, pet, an upgrade), drops, the shiny, and the trainer falling and waking at camp. Prints TAMER PASS or FAIL.

var g: TamerGame
var _fails: PackedStringArray = []
var _count: int = 0


func _ready() -> void:
	_run.call_deferred()


func expect(ok: bool, what: String) -> void:
	_count += 1
	print("TAMER ok: " if ok else "TAMER FAIL: ", what)
	if not ok:
		_fails.append(what)


func frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(s * Engine.physics_ticks_per_second))


func _run() -> void:
	if get_tree().current_scene == null or not get_tree().current_scene is TamerGame:
		get_tree().change_scene_to_file("res://scenes/tamer.tscn")
	await frames(20)
	g = TamerGame.current
	expect(g != null and LayoutCheck.problems(g.layout).is_empty(), "the meadow keeps every layout rule")
	_chart()
	await _meeting()
	await _fight()
	await _hybrid()
	await _befriend()
	await _swap_and_knockout()
	await _bond()
	await _camp()
	await _fall()
	await _pack_fight()
	print("TAMER %s (%d checks, %d failed)" % ["PASS" if _fails.is_empty() else "FAIL", _count, _fails.size()])
	get_tree().quit(0 if _fails.is_empty() else 1)


func _chart() -> void:
	expect(TamerData.matchup("ember", "glass") == TamerData.SUPER, "Ember is super effective on Glass")
	expect(TamerData.matchup("ember", "tide") == TamerData.RESISTED, "Ember is resisted by Tide")
	expect(TamerData.element_mult("gale", "ember") > 1.0 and TamerData.element_mult("ember", "gale") < 1.0, "Gale beats Ember both ways")
	var ok: bool = true
	var E: Dictionary = TamerData.elements["elements"]
	for a: String in E:
		ok = ok and (E[a]["strong"] as Array).size() == 2 and (E[a]["weak"] as Array).size() == 2
		for b: String in E[a]["strong"]:
			ok = ok and (E[b]["weak"] as Array).has(a)
	expect(ok, "the chart is consistent: each element strong vs 2, weak vs 2, mirrored")


func _meeting() -> void:
	expect(g.meeting.waiting.size() == 3, "three starters wait in the meadow")
	for c: Creature in g.meeting.waiting:
		g.trainer.global_position = g.layout.free_spot_near(c.global_position + Vector2(0, 40), 8.0)
		await frames(3)
	expect(g.meeting._reacted.size() == 3, "each starter reacts when the trainer comes close")
	g.meeting.pick(g.meeting.waiting[0])
	await frames(10)
	expect(g.team.members.size() == 1 and g.field.partner != null, "picking the honey badger makes it your partner")
	expect(g.guide.is_done("pick"), "the guide moves on after the pick")
	expect(g.trainer.global_position.distance_to(g.field.partner.global_position) < 120.0, "the partner stands by the trainer")


func _wild(kind: String, offset: Vector2, level: int = 1) -> Creature:
	var at: Vector2 = g.layout.free_spot_near(g.trainer.global_position + offset, 14.0)
	var c: Creature = g.spawner.spawn(kind, at, level, -1, 0)
	return c


func _clear_wild(r: float) -> void:
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		if (n as Node2D).global_position.distance_to(g.trainer.global_position) < r:
			n.queue_free()


func _fight() -> void:
	_clear_wild(900.0)
	await frames(2)
	var p: Creature = g.field.partner
	var wolf: Creature = _wild("maned_wolf", Vector2(70, 0))
	await frames(2)
	var before: float = wolf.rec.life
	g.input.cursor_override = wolf.global_position
	p.global_position = wolf.global_position + Vector2(-30, 0)
	expect(g.input.use_move(0), "Q uses the partner's first move at the cursor")
	await frames(4)
	expect(wolf.rec.life < before, "Claw Rush hits the wild wolf (%d -> %d)" % [before, wolf.rec.life])
	expect(p.cooldown_frac("claw_rush") > 0.0, "the move goes on cooldown")
	wolf.rec.life = wolf.rec.max_life()
	g.trainer.attack_target = wolf
	var mid: float = wolf.rec.life
	await seconds(2.0)
	expect(not is_instance_valid(wolf) or wolf.rec.life < mid, "the partner auto-attacks what you clicked")
	g.trainer.attack_target = null
	_clear_wild(900.0)
	await frames(2)


func _hybrid() -> void:
	var p: Creature = g.field.partner
	expect(g.control.take(), "holding Shift hands control to the creature")
	expect(p.brain is ControlledBrain and g.control.controlled() == p, "the creature is the one you steer")
	var from: Vector2 = p.global_position
	var goal: Vector2 = g.layout.free_spot_near(from + Vector2(120, 0), 12.0)
	g.control.brain().goal = goal
	var trainer_at: Vector2 = g.trainer.global_position
	await seconds(1.0)
	expect(p.global_position.distance_to(goal) < from.distance_to(goal) - 40.0, "the steered creature goes where you click")
	expect(g.trainer.global_position.distance_to(trainer_at) < 4.0, "the trainer waits while you steer (moved %.1f)" % g.trainer.global_position.distance_to(trainer_at))
	expect(g.control.blend > 0.5, "the camera eases over to the creature")
	expect(p.dodge(p.global_position + Vector2(0, 80), TamerData.rule("control.dodge")), "the creature has its own dodge")
	await seconds(0.4)
	g.control.release()
	expect(p.brain is PartnerBrain and g.control.controlled() == g.trainer, "letting go hands back to the trainer")
	await seconds(1.5)
	expect(p.global_position.distance_to(g.trainer.global_position) < 110.0, "the creature returns to following")


func _befriend() -> void:
	var aye: Creature = _wild("aye_aye", Vector2(50, 10))
	await frames(2)
	aye.set_physics_process(false)
	aye.receive_hit(aye.rec.max_life() * 0.7, Vector2.RIGHT, 0.0, 0.0, null)
	expect(aye.dazed, "a weakened wild creature is dazed (can be befriended)")
	g.befriend.set_meta("forced", true)
	await seconds(0.5)
	g.trainer.iframe_t = 0.0
	g.trainer.receive_hit(1.0, Vector2.LEFT, 0.0, 0.0, null)
	await frames(2)
	expect(g.befriend.progress < 0.2, "being hit interrupts befriending (progress %.2f, life %.0f)" % [g.befriend.progress, g.trainer.life])
	g.trainer.iframe_t = 0.0
	await seconds(1.4)
	g.befriend.set_meta("forced", false)
	expect(g.team.members.size() == 2 and g.team.members[1].species_id == "aye_aye", "holding F wins the aye-aye over")
	expect(g.guide.is_done("befriend"), "the guide counts the befriending")


func _swap_and_knockout() -> void:
	var wolf: Creature = _wild("maned_wolf", Vector2(30, 20))
	await frames(2)
	wolf.set_physics_process(false)
	var before: float = wolf.rec.life
	expect(g.field.swap(1), "pressing 2 swaps to the aye-aye")
	await frames(3)
	expect(g.field.partner.rec.species_id == "aye_aye" and g.team.active == 1, "the aye-aye is out")
	expect(not is_instance_valid(wolf) or wolf.rec.life < before, "the swap-in strikes as it enters")
	g.field.partner.receive_hit(9999.0, Vector2.RIGHT, 0.0, 0.0, null)
	await seconds(1.5)
	expect(g.team.members[1].knocked_out(), "a creature at 0 life is knocked out")
	expect(g.field.partner != null and g.field.partner.rec.species_id == "honey_badger", "the next creature steps in")
	expect(g.field.use_item("salts") and not g.team.members[1].knocked_out(), "smelling salts wake the knocked-out one")
	g.field.partner.rec.life = 10.0
	expect(g.field.use_item("berry") and g.field.partner.rec.life > 10.0, "a honeyberry heals the partner")
	_clear_wild(900.0)


func _bond() -> void:
	var rec: CreatureRecord = g.field.partner.rec
	expect(not rec.bond_move_ready(), "the bond move starts locked")
	rec.add_bond(100.0)
	await frames(2)
	expect(rec.bond_move_ready() and g.guide.is_done("bond"), "a full bond meter unlocks the bond move")
	g.input.cursor_override = g.trainer.global_position + Vector2(100, 0)
	expect(g.input.use_bond_move(), "T uses the bond move")


func _camp() -> void:
	g.team.add_material("rot_fang", 3)
	g.team.members[0].life = 1.0
	g.trainer.global_position = g.layout.free_spot_near(g.camp_point() + Vector2(0, 40), 8.0)
	await seconds(0.5)
	expect(g.camp.resting and g.hud.camp_panel.visible, "walking into camp rests and opens the camp panel")
	expect(g.team.members[0].life >= g.team.members[0].max_life(), "resting heals the team")
	var rec: CreatureRecord = g.team.members[0]
	var life_before: float = rec.max_life()
	expect(g.team.upgrade(rec, "life") and rec.max_life() > life_before and g.team.count("rot_fang") == 1, "materials raise a stat")
	var bond: float = g.team.members[1].bond
	expect(g.camp.care(g.team.members[1], "pet") and g.team.members[1].bond > bond, "petting at camp raises bond")
	expect(not g.camp.care(g.team.members[1], "pet"), "petting is once per rest")
	var shinies: int = get_tree().get_nodes_in_group(Combatant.SIDE_WILD).filter(func(n: Node) -> bool: return (n as Creature).rec.shiny).size()
	expect(shinies >= 1, "a shiny maned wolf is out in the meadow (%d shiny)" % shinies)


func _fall() -> void:
	g.trainer.global_position = g.layout.free_spot_near(g.camp_point() + Vector2(0, 400), 8.0)
	await seconds(0.3)
	var wolf: Creature = _wild("maned_wolf", Vector2(40, 0))
	await frames(2)
	wolf.set_physics_process(false)
	wolf.receive_hit(9999.0, Vector2.RIGHT, 0.0, 0.0, null)
	await frames(2)
	var drops: int = get_tree().get_nodes_in_group("material_drops").size()
	await seconds(1.0)
	expect(drops > 0 or g.team.count("wind_tuft") > 0, "a fainted wild creature drops its material")
	g.trainer.iframe_t = 0.0
	g.trainer.receive_hit(9999.0, Vector2.RIGHT, 0.0, 0.0, null)
	expect(not g.trainer.alive(), "the trainer can fall")
	await seconds(float(TamerData.rule("trainer.respawn_delay")) + 0.5)
	expect(g.trainer.alive() and g.trainer.global_position.distance_to(g.camp_point()) < 140.0, "the trainer wakes at camp")


## Feel check: a starter at its level beats a near pack of two on auto-attack alone in reasonable time, and it is a
## real fight (it loses some life). Printed for tuning.
func _pack_fight() -> void:
	g.trainer.global_position = g.layout.free_spot_near(g.layout.start + Vector2(0, 40), 8.0)
	g.team.rest()
	g.field.swap(0)
	await seconds(1.0)
	_clear_wild(1400.0)
	var pack: Array[Creature] = [_wild("maned_wolf", Vector2(150, 0)), _wild("aye_aye", Vector2(170, 40))]
	for c: Creature in pack:
		(c.brain as WildBrain).wake(g.trainer)
	var p: Creature = g.field.partner
	var t: float = 0.0
	while t < 40.0 and pack.any(func(c: Creature) -> bool: return is_instance_valid(c) and c.alive()):
		for c: Creature in pack:
			if is_instance_valid(c) and c.dazed:
				c.faint()
		await frames(6)
		t += 0.1
	var lost: float = 1.0 - (p.rec.life_frac() if is_instance_valid(p) else 0.0)
	print("TAMER pack fight: %.1f s, partner lost %d%% life, trainer life %d" % [t, roundi(lost * 100.0), g.trainer.life])
	expect(t < 40.0, "the starter wins a near pack of two on its own (%.1f s)" % t)
