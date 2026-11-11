extends "res://tests/shots.gd"
## The later review shots (Act 2, Act 3, the forge), same machinery as shots.gd.


func _shot_river() -> void:
	var h := _bot()
	h.story_at("upward_river", 2)
	h.level_up(16)
	h.gear_up(16)
	var at: Vector2 = g.layout.center_of(g.layout.clearing_of_role("pool")["center"])
	h.clear_near(100000.0)
	h.place_player(at + Vector2(-60, 40))
	h.pack_near(["undertow", "undertow", "drowned", "undertow", "drowned"], Vector2(140, 0))
	g.player.light.value = 70.0
	await _wait(1.4)
	h.cast("lull", g.player.global_position)
	await _wait(0.15)
	await _save("upward_river")


func _shot_forge() -> void:
	var h := _bot()
	h.level_up(10)
	h.gear_up(10)
	for m: String in ["ash", "kindle", "temper", "quench", "anneal"]:
		g.player.inv.add_material(m, 6)
	g.ui.open(g.ui.forge)
	g.ui.forge.put(g.player.inv.equipped["staff"])
	g.ui.forge.affix = 1
	g.ui.forge._do("temper")
	await _wait(0.3)
	h.hover(g.ui.forge.position + g.ui.forge.craft_rect(0).get_center())
	await _wait(SETTLE)
	await _save("ember_forge")
	g.ui.open(g.ui.forge)


func _shot_bellwright() -> void:
	var h := _bot()
	h.story_at("drowned_belfry", 1)
	h.level_up(20)
	h.gear_up(20)
	h.clear_near(100000.0)
	h.place_player(g.layout.circle_center() + Vector2(0, 90))
	g.player.light.value = 70.0
	await _wait(0.4)
	g.start_boss()
	var b: Enemy = g.spawner.boss
	(b.brain as BellwrightBrain)._i = 0
	await _wait(1.9)
	await _save("bellwright_toll")


func _shot_falls() -> void:
	var h := _bot()
	h.story_at("rising_falls", 1)
	h.level_up(17)
	h.gear_up(17)
	h.clear_near(100000.0)
	var at: Vector2 = g.layout.center_of(g.layout.clearing_of_role("terrace")["center"])
	h.place_player(at + Vector2(-40, 70))
	h.pack_near(["heron", "heron", "undertow", "heron"], Vector2(130, -30))
	g.player.light.value = 70.0
	await _wait(1.6)
	h.cast("sunlash", g.player.global_position + Vector2(80, -20))
	await _wait(0.08)
	await _save("rising_falls")


func _shot_marsh() -> void:
	var h := _bot()
	h.story_at("saltmarsh", 0)
	h.level_up(19)
	h.gear_up(19)
	h.clear_near(100000.0)
	var at: Vector2 = g.layout.center_of(g.layout.clearing_of_role("marsh")["center"])
	h.place_player(at + Vector2(0, 140))
	g.player.light.value = 60.0
	await _wait(0.6)
	g.player.walk_to(at + Vector2(0, 60))
	await _wait(1.8)
	h.cast("flare", g.player.global_position)
	await _wait(0.12)
	await _save("saltmarsh_lure")


func _shot_town() -> void:
	var h := _bot()
	h.story_at("one_tuesday", 3)
	h.level_up(25)
	h.gear_up(25)
	h.clear_near(100000.0)
	var at: Vector2 = g.layout.center_of(g.layout.clearing_of_role("market")["center"])
	h.place_player(at + Vector2(-40, 70))
	h.pack_near(["repeater", "repeater", "clockface", "repeater", "repeater"], Vector2(140, -20))
	g.player.light.value = 70.0
	g.loop.t = TuesdayLoop.LOOP * 0.7
	await _wait(1.5)
	h.cast("moth_swarm", g.player.global_position + Vector2(120, -20))
	await _wait(0.3)
	await _save("tuesday_town")


func _shot_mayor() -> void:
	var h := _bot()
	h.story_at("one_tuesday", 4)
	h.level_up(28)
	h.gear_up(28)
	h.clear_near(100000.0)
	h.place_player(g.layout.circle_center() + Vector2(0, 110))
	g.player.light.value = 70.0
	await _wait(0.4)
	g.start_boss()
	await _wait(3.0)
	await _save("mayor_of_tuesday")
