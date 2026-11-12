extends Node
## --tamer-smoke: headless play of the trainer prototype. Starts the real prototype scene, then: the meeting and
## picking a starter, the element chart, moves, battle mode (start, control, end with Victory), befriending
## (and being interrupted), swapping with the entry attack, a knock-out and the step-in, bond and the bond move, camp
## (rest, pet, an upgrade), drops, the shiny, the gauge, slow-time, commitment, stagger, the battle ring, the
## white-out retreat, and a pack fight. Prints
## TAMER PASS or FAIL.

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
	_clarity()
	await _battle()
	await _windup()
	await _befriend()
	await _swap_and_knockout()
	await _bond()
	await _combat_model()
	await _ring()
	await _rival()
	await _camp()
	await _drops_and_white_out()
	await TamerPackFight.new(self).run()
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
	wolf.brain = null                                      # held still (and not noticing anyone) for the check
	await frames(2)
	var before: float = wolf.rec.life
	g.input.cursor_override = wolf.global_position
	p.global_position = wolf.global_position + Vector2(-30, 0)
	g.team.gauge = 3.0
	expect(g.input.use_move(0), "Q uses the partner's first move at the cursor")
	await seconds(0.4)
	expect(wolf.rec.life < before, "Claw Rush hits the wild wolf (%d -> %d)" % [before, wolf.rec.life])
	expect(p.cooldown_frac("claw_rush") > 0.0, "a move locks out a moment against double casts")
	expect(p.rec.used_moves.has("claw_rush"), "the first use of a move is remembered (its name popped up)")
	_clear_wild(900.0)
	await frames(2)


## Exploring: left click walks the trainer, even on a wild creature; right click on one starts a battle in which
## you control the creature; the trainer keeps away and is never a target; the battle ends with a Victory.
func _battle() -> void:
	_clear_wild(2000.0)
	g.battle.end(false)
	await frames(2)
	expect(not g.battle.on, "you start out exploring as the trainer")
	g.field.partner.global_position = g.trainer.global_position
	var wolf: Creature = _wild("maned_wolf", Vector2(320, 0))
	wolf.set_physics_process(false)                         # it must not notice us before the clicks are checked
	await frames(2)
	g.input.cursor_override = wolf.global_position
	g.input.hovered = wolf
	g.input.press()
	expect(not g.battle.on and g.trainer.walking(), "left click on a wild creature walks, never attacks")
	g.trainer.stop()
	wolf.set_physics_process(true)
	g.input.attack()
	var p: Creature = g.field.partner
	expect(g.battle.on and p.brain is ControlledBrain, "right click on a wild creature starts a battle: you control your creature")
	expect(g.guide.is_done("battle"), "the guide counts the battle")
	var goal: Vector2 = g.layout.free_spot_near(p.global_position + Vector2(0, 90), 12.0)
	g.input.hovered = null
	g.input.cursor_override = goal
	g.input.press()
	await seconds(0.8)
	expect(p.global_position.distance_to(goal) < 40.0, "in battle, left click moves your creature")
	expect(g.battle.blend > 0.5, "the camera eases over to your creature")
	expect(p.dodge(p.global_position + Vector2(0, 80), TamerData.rule("control.dodge")), "Space is your creature's dodge")
	await seconds(0.4)
	await _battle_fight(p, wolf)


func _battle_fight(p: Creature, wolf: Creature) -> void:
	g.input.cursor_override = wolf.global_position
	g.input.hovered = wolf
	g.input.attack()
	expect(g.battle.brain().target == wolf, "right click in battle attacks the creature under the cursor")
	p.cooldowns.clear()
	g.team.gauge = 3.0
	g.input.start_aim(1)
	expect(g.aim.aiming() and g.aim.move_id == String(p.rec.moves()[1]), "holding W shows where the move will land")
	await frames(2)
	g.input.release_aim(1)
	expect(not g.aim.aiming() and p.cooldown_frac(String(p.rec.moves()[1])) > 0.0, "releasing W uses it at the cursor")
	await seconds(2.5)
	expect(get_tree().get_nodes_in_group(Combatant.SIDE_TEAM).all(func(n: Node) -> bool: return n is Creature),
		"only your creature can be targeted: the trainer never is")
	if is_instance_valid(wolf):
		expect(g.trainer.global_position.distance_to(wolf.global_position) > 50.0, "the trainer keeps back from the fight on their own (%.0f px)" % g.trainer.global_position.distance_to(wolf.global_position))
		wolf.faint()
	await seconds(1.0)
	expect(not g.battle.on and p.brain is PartnerBrain, "no foes left: the battle ends and the trainer leads again")
	await seconds(1.0)
	expect(g.hud._victory_t > 0.0, "a Victory summary shows what the fight earned")
	g.input.hovered = null
	await frames(2)


## Wild attacks wind up (a telegraph) before they land.
func _windup() -> void:
	var p: Creature = g.field.partner
	var wolf: Creature = _wild("maned_wolf", Vector2(30, 0))
	await frames(2)
	var brain := wolf.brain as WildBrain
	var life: float = p.rec.life
	p.global_position = wolf.global_position + Vector2(24, 0)
	wolf.cooldowns.clear()
	brain.attack("wolf_nip", p)
	await frames(3)
	expect(p.rec.life == life and brain.winding_at(p), "a wild attack winds up before it lands")
	g.battle.end(false)
	_clear_wild(900.0)
	await frames(2)


## Every move says what it does; the HUD tooltip and the info panel show it.
func _clarity() -> void:
	var missing: Array[String] = []
	for id: String in TamerData.moves:
		if String(TamerData.move(id).get("desc", "")) == "":
			missing.append(id)
	expect(missing.is_empty(), "every move has a description %s" % [missing])
	var rows: Array = MoveText.rows(g.hud.card, "ember_pounce", 1.2, "ember", "W")
	expect(rows.size() >= 5 and String(rows[0][0]).contains("Ember Pounce"), "a move tooltip has its name, words and numbers")
	expect(not g.hud.card.move_at(g.hud.card._slot_rect(0).get_center()).is_empty(), "hovering a move slot finds the move")
	g.hud.info_panel.open(g.team.current())
	expect(g.hud.info_panel.visible, "the creature info panel opens")
	g.hud.info_panel.close()


## Befriending is the trainer's job: F sends them to a dazed creature to calm it.
func _befriend() -> void:
	var aye: Creature = _wild("aye_aye", Vector2(140, 10))
	aye.brain = null
	await frames(2)
	aye.receive_hit(aye.rec.max_life() * 0.7, Vector2.RIGHT, 0.0, 0.0, null)
	expect(aye.dazed, "a weakened wild creature is dazed (can be befriended)")
	expect(g.befriend.request(), "F sends the trainer to the dazed creature")
	await seconds(1.0)
	aye.receive_hit(1.0, Vector2.LEFT, 0.0, 0.0, null)
	await frames(2)
	expect(g.befriend.progress < 0.2 and g.befriend.target == null, "hitting the creature you calm startles it")
	g.befriend.request()
	await seconds(2.5)
	expect(g.team.members.size() == 2 and g.team.members[1].species_id == "aye_aye", "the trainer wins the aye-aye over")
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
	g.team.gauge = 3.0
	g.field.partner.cooldowns.clear()
	expect(g.input.use_bond_move(), "T uses the bond move (it costs the whole gauge)")


func _camp() -> void:
	g.team.add_material("rot_fang", 3)
	g.team.members[0].life = 1.0
	g.trainer.global_position = g.layout.free_spot_near(g.camp_point() + Vector2(0, 40), 8.0)
	await seconds(0.5)
	expect(g.camp.resting and g.hud.camp_panel.visible, "walking into camp rests and opens the camp panel")
	expect(g.team.members[0].life >= g.team.members[0].max_life(), "resting heals the team")
	var rec: CreatureRecord = g.team.members[0]
	var life_before: float = rec.max_life()
	var fangs: int = g.team.count("rot_fang")
	expect(g.team.upgrade(rec, "life") and rec.max_life() > life_before and g.team.count("rot_fang") == fangs - 2, "materials raise a stat")
	var bond: float = g.team.members[1].bond
	expect(g.camp.care(g.team.members[1], "pet") and g.team.members[1].bond > bond, "petting at camp raises bond")
	expect(not g.camp.care(g.team.members[1], "pet"), "petting is once per rest")
	var shiny: Creature = g.spawner.spawn_shiny_near(g.trainer.global_position)
	expect(shiny.rec.shiny and TamerData.species("maned_wolf")["shiny_chance"] < 0.02, "shinies are rare (1 in 64); F1 spawns one")
	shiny.queue_free()


func _drops_and_white_out() -> void:
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
	await _white_out()


## The trainer is never a target; with every creature knocked out the team retreats to camp and recovers.
func _white_out() -> void:
	g.trainer.place(g.layout.free_spot_near(g.layout.start, 8.0))      # far from camp (resting there would revive them)
	var wolf: Creature = _wild("maned_wolf", Vector2(40, 0))
	await seconds(1.0)
	var foes: Array = get_tree().get_nodes_in_group(Combatant.SIDE_TEAM).filter(func(n: Node) -> bool: return n is Trainer)
	expect(foes.is_empty() and not g.trainer.has_method("receive_hit"), "the trainer can never be targeted or hit")
	for n: Node in get_tree().get_nodes_in_group("material_drops"):
		n.queue_free()
	g.team.add_material("bloom_leaf", 2)
	var tufts: int = g.team.count("bloom_leaf")
	for r: CreatureRecord in g.team.members:
		if r != g.field.partner.rec:
			r.knock_out()
	g.field.partner.receive_hit(99999.0, Vector2.RIGHT, 0.0, 0.0, null)
	await seconds(1.0 + float(TamerData.rule("white_out.fade")) * 2.0 + float(TamerData.rule("white_out.hold")) + 0.5)
	expect(g.trainer.global_position.distance_to(g.camp_point()) < 160.0, "a wiped team retreats to camp")
	expect(not g.team.all_out() and g.field.partner != null, "the team recovers at camp")
	expect(g.team.count("bloom_leaf") == tufts - int(TamerData.rule("white_out.lose")), "the white-out costs one of each material (gentle: %d -> %d)" % [tufts, g.team.count("bloom_leaf")])


func _combat_model() -> void:
	var p: Creature = g.field.partner
	_clear_wild(2000.0)
	g.battle.end(false)
	await seconds(4.5)                                      # the grace after a battle
	var wolf: Creature = _wild("maned_wolf", Vector2(60, 0))
	wolf.brain = null
	await frames(2)
	g.team.gauge = 0.0
	g.input.cursor_override = wolf.global_position
	expect(not g.input.use_move(0), "a move needs gauge: with none it does not go off")
	p.global_position = wolf.global_position + Vector2(-24, 0)
	p.cooldowns.clear()
	for k: int in 6:
		p.cast(String(p.rec.data()["basic"]), wolf.global_position)
		await seconds(0.6)
	expect(g.team.gauge > 0.5, "basic combo hits fill the gauge (%.2f)" % g.team.gauge)
	g.team.gauge = 3.0
	g.input.start_aim(0)
	expect(g.slow.on and Engine.time_scale < 0.5, "holding a move key slows time")
	g.input.release_aim(0)
	expect(not g.slow.on and Engine.time_scale > 0.5 and g.team.gauge <= 2.01, "releasing casts it, spends its gauge, and time returns")
	expect(p.commit_t > 0.0 and not p.dodge(p.global_position + Vector2(0, 50), TamerData.rule("control.dodge")), "a move commits: no dodging during it")
	wolf.stagger.add(wolf.stagger.max_value())
	expect(wolf.stagger.is_staggered() and wolf.stagger.damage_taken() > 1.0, "a full stagger bar staggers: it takes more damage")
	wolf.queue_free()
	await seconds(1.0)


## The ring: outsiders are kept out, and only creatures in the fight join it.
func _ring() -> void:
	var p: Creature = g.field.partner
	var foe: Creature = _wild("tas_devil", Vector2(120, 0))
	var outsider: Creature = _wild("aye_aye", Vector2(-420, 0))
	outsider.brain = null
	await frames(2)
	g.battle.engage(foe)
	expect(g.battle.on and g.battle.ring.inside.has(foe), "a battle raises a ring around the fight")
	outsider.global_position = g.battle.ring.global_position + Vector2(40, 0)
	await frames(3)
	expect(outsider.global_position.distance_to(g.battle.ring.global_position) >= g.battle.ring.radius, "an outsider cannot get into the ring")
	expect(not g.battle.may_join(outsider), "an outsider cannot join the battle")
	foe.faint()
	outsider.queue_free()
	await seconds(1.0)
	expect(not g.battle.on and g.battle._grace > 0.0, "after a battle there is a grace before the next one")
	expect(p.alive(), "your creature is fine")
	await seconds(4.5)


## A rival trainer spots you, walks up, battles with a team, uses a heal once, and is beaten for a reward.
func _rival() -> void:
	_clear_wild(3000.0)
	g.battle.end(false)
	g.battle._grace = 0.0
	g.team.rest()
	var r: RivalTrainer = g.rivals[0]
	expect(r.state == "waiting", "a rival trainer waits on the route")
	g.trainer.place(g.layout.free_spot_near(r.global_position + Vector2(-200, 0), 8.0))
	g.field.partner.global_position = g.trainer.global_position
	await seconds(float(TamerData.rule("rivals.talk_time")) + 2.0)
	expect(g.battle.on and g.battle.rival == r, "the rival spots you, walks up and battles")
	var first: Creature = r.active
	first.rec.life = first.rec.max_life() * 0.3
	await seconds(0.3)
	expect(r._item_used or r.active != first, "the rival heals or swaps when its creature is hurt")
	var wins: int = 0
	for k: int in 8:
		if not g.battle.on:
			break
		if r.active != null and is_instance_valid(r.active) and not r.active.fainted_now:
			r.active.faint()
			wins += 1
		await seconds(1.4)
	expect(r.state == "beaten" and not g.battle.on, "beating every creature wins the trainer battle (%d down)" % wins)
	expect(r.active == null, "the rival's creatures are gone")
