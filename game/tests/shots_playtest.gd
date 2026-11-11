extends "res://tests/shots_opening.gd"
## Playtest 2 stills: a Wickbolt impact mid-hit, a death in progress, damage numbers, the character sheet with a
## tooltip, the gear comparison, the Tab map overlay, the skill and passive trees, the specialisation card, the
## new game's fade and pan, and the practice ground inside Tallow.

const IMPACT_TIMES: Array[float] = [0.14, 0.2, 0.26, 0.32]
const DEATH_TIMES: Array[float] = [0.0, 0.15, 0.4, 1.4]
const PAN_TIMES: Array[float] = [0.7, 2.6, 4.4, 6.4]


func _staged_pack(kinds: Array) -> Array[Enemy]:
	var h := _bot()
	h.level_up(8)
	h.clear_near(100000.0)
	h.place_player(g.layout.start)
	g.player.light.value = 85.0
	g.camera.frames = []
	await _wait(0.6)
	var pack: Array[Enemy] = h.pack_near(kinds, Vector2(150, 30))
	for e: Enemy in pack:
		e.set_physics_process(false)                 # hold still for the camera
	await _wait(0.4)
	return pack


func _shot_p2_impact() -> void:
	var pack: Array[Enemy] = await _staged_pack(["hound"])
	for i: int in IMPACT_TIMES.size():
		pack[0].life = pack[0].max_life
		_bot().cast("wickbolt", pack[0].global_position + Vector2(0, -10))
		await _wait(IMPACT_TIMES[i])
		await _save("p2_impact_%d" % i)
		await _wait(1.0)


func _shot_p2_death() -> void:
	var pack: Array[Enemy] = await _staged_pack([])
	var at: Vector2 = g.layout.free_spot_near(g.player.global_position + Vector2(150, 30), 14.0)
	pack.append(g.spawner.spawn("hound", at, "magic", [], g.spawner.level_at(0.5)))
	pack[0].set_physics_process(false)
	await _wait(0.3)
	Dev.one_hit = true
	_bot().cast("wickbolt", pack[0].global_position + Vector2(0, -10))
	while is_instance_valid(pack[0]) and not pack[0].dead:      # from the moment the bolt lands
		await get_tree().process_frame
	for i: int in DEATH_TIMES.size():
		await _wait(DEATH_TIMES[i] - (DEATH_TIMES[i - 1] if i > 0 else 0.0))
		await _save("p2_death_%d" % i)
	Dev.one_hit = false


func _shot_p2_numbers() -> void:
	var pack: Array[Enemy] = await _staged_pack(["gloam", "hound", "gloam", "moth", "gloam"])
	for e: Enemy in pack:
		e.max_life *= 6.0                            # they live through the volley, so every number shows
		e.life = e.max_life
	g.player.stats.total["crit_chance"] = 40.0       # some crits among them
	for k: int in 6:
		_bot().cast("wickbolt", pack[k % pack.size()].global_position + Vector2(0, -10))
		await _wait(0.1)
	_bot().cast("flare", pack[0].global_position)
	await _wait(0.2)
	await _save("p2_numbers")


func _shot_p2_charsheet() -> void:
	_bot().level_up(9)
	_bot().gear_up(9)
	g.player.refresh_stats()
	g.ui.open(g.ui.character)
	await _wait(0.4)
	var y: float = CharacterPanel.TOP_Y
	for row: Array in CharacterPanel.rows(g.player):
		if row.size() == 1:
			y += 4.0
		elif String(row[2]) == "armour":
			break
		y += CharacterPanel.ROW
	_bot().hover(g.ui.character.position + Vector2(CharacterPanel.COL_X + 30.0, y - 3.0))
	await _wait(SETTLE)
	await _save("p2_charsheet_tip")


func _shot_p2_compare() -> void:
	_bot().level_up(9)
	_bot().gear_up(9)
	var lv: int = g.player.prog.level
	var it: Dictionary = LootGen.make_from_base(LootGen.base_by_id("wickpole"), lv, "rare")
	LootGen.add_affixes(it, 4, lv)
	it["name"] = LootGen.item_name(it, LootGen.base_by_id("wickpole"))
	it["new"] = true
	g.player.inv.add(it)
	g.player.inv.add(LootGen.make(lv, "magic"))
	g.player.refresh_stats()
	g.ui.open(g.ui.inventory)
	await _wait(0.4)
	_bot().hover(g.ui.inventory.position + g.ui.inventory.bag_rect(0).get_center())
	await _wait(SETTLE)
	await _save("p2_gear_compare")


func _shot_p2_overlay() -> void:
	_bot().place_player(g.layout.start + Vector2(0, -400))
	g.ui.minimap.reveal_all()
	Minimap.overlay = true
	await _wait(1.0)
	await _save("p2_map_overlay")
	Minimap.overlay = false


func _shot_p2_trees() -> void:
	var h := _bot()
	h.level_up(12)
	h.spec("wickbolt", ["quick_wick", "quick_wick", "long_flight", "sear", "sear", "kindling", "piercing"])
	Session.campaign.set_flag(SpecSlotsView.FLAG)
	g.ui.skills.selected = "wickbolt"
	g.ui.open(g.ui.skills)
	await _wait(0.4)
	var n: Dictionary = GameData.skill("wickbolt")["nodes"][4]
	g.ui.skills._art.burst(g.ui.skills.node_rect(GameData.skill("wickbolt")["nodes"][2]).get_center())
	h.hover(g.ui.skills.position + g.ui.skills.node_rect(n).get_center())
	await _wait(0.12)
	await _save("p2_skill_tree")
	g.ui.open(g.ui.skills)
	g.player.prog.choose_mastery("beacon")
	for id: String in ["wick", "wick", "wick", "trimmed", "trimmed", "iron_coat", "steady_hand", "kindler", "hunger", "night_eyes"]:
		g.player.prog.add_passive(id)
	g.ui.open(g.ui.passives)
	await _wait(0.4)
	var nodes: Array = GameData.passives["trees"]["lamplighter"]["nodes"]
	g.ui.passives._art.burst(g.ui.passives.node_rect(nodes[9]).get_center())
	h.hover(g.ui.passives.position + g.ui.passives.node_rect(nodes[6]).get_center())
	await _wait(0.12)
	await _save("p2_passive_tree")


func _shot_p2_spec() -> void:
	TutorialTips.forced = true
	_bot().level_up(5)
	g.ui.skills.selected = "flare"
	g.ui.open(g.ui.skills)
	await _wait(SETTLE)
	await _save("p2_spec_card")
	SpecSlotsView.dismiss()
	g.player.prog.specialise("wickbolt")
	_bot().hover(g.ui.skills.position + SpecSlotsView.socket_rect(g.ui.skills.slots_origin(), 2).get_center())
	await _wait(SETTLE)
	await _save("p2_spec_slots")


func _shot_p2_opening() -> void:
	Session.campaign.place(Opening.QUEST, 0)
	g.player.global_position = g.layout.start
	g._establish(GameData.biome["view"]["establish"])
	for i: int in PAN_TIMES.size():
		await _wait(PAN_TIMES[i] - (PAN_TIMES[i - 1] if i > 0 else 0.0))
		await _save("p2_opening_%d" % i)


func _shot_p2_ground() -> void:
	await _opening_at(4)
	var c: Vector2 = g.layout.center_of(g.layout.clearing_of_role("yard")["center"])
	_bot().place_player(c + Vector2(-60, 60))
	g.camera.frames = []
	g.camera.intro(c + Vector2(0, 20), 10.0)
	g.camera.reset_smoothing()
	await _wait(1.2)
	_bot().cast("wickbolt", g.event_target)
	await _wait(0.18)
	await _save("p2_practice_ground")


func _shot_p2_town() -> void:
	Session.campaign.place(Opening.QUEST, ShotHelper.ALL_STEPS)
	Session.campaign.start("seven_heartbeats")
	await _reenter()
	_bot().place_player(Vector2(860, 1090))
	g.camera.frames = []
	await _wait(9.0)
	await _save("p2_town")
