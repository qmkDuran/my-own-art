extends Node
## --shots: review screenshots (needs a display: xvfb-run). Each shot is a short scripted scene in the real game:
## set things up, wait for effects to land, save out/<name>_<w>x<h>.png. --only=name runs one shot.

const SETTLE: float = 0.9
const PASS2: Array[String] = ["orbs", "school", "wren", "hollins", "town", "mayor", "falls", "marsh", "bellwright", "river", "forge", "tallow", "road", "hollow", "matron", "quests", "filter", "stash", "eclipse", "noon", "keystones",
	"eclipse_tree"]

var g: Game
var _out: String


func _ready() -> void:
	_out = TestRunner.out_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _only() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			return a.substr(7)
	return ""


func _run() -> void:
	await _wait(1.5)
	if _only() == "title":
		await _wait(1.5)
		await _save("title")
		get_tree().quit()
		return
	if _only() == "intro":
		await _intro_card()
		get_tree().quit()
		return
	g = Game.current
	if _only() != "" and has_method("_shot_" + _only()) and not _listed(_only()):
		await call("_shot_" + _only())
		get_tree().quit()
		return
	var shots: Array[String] = ["light", "dark", "skills", "passives", "inventory", "character", "boss", "overview",
		"orbs", "school", "wren", "hollins", "town", "mayor", "falls", "marsh", "bellwright", "river", "forge", "tallow", "road", "hollow", "matron", "quests", "filter", "stash", "eclipse", "noon", "keystones", "eclipse_tree"]
	for s: String in shots:
		if (_only() == "" and not PASS2.has(s)) or _only() == s:
			await call("_shot_" + s)
	get_tree().quit()


func _listed(id: String) -> bool:
	return ["light", "dark", "skills", "passives", "inventory", "character", "boss", "overview"].has(id) or PASS2.has(id)


## A story card part-typed and one fully typed, from the title's New Game.
func _intro_card() -> void:
	var title: Node = get_tree().current_scene
	title.call("_choose", "new")
	var intro: IntroCards = title.get("_intro")
	intro.press()
	intro.press()
	intro.press()
	await _wait(0.6)
	await _save("intro_card")
	intro.press()
	intro.press()
	intro.press()
	await _wait(1.0)
	await _save("intro_card_typing")


func _save(name: String) -> void:
	if g != null and is_instance_valid(g.player) and g.player.life <= 0.0:
		push_error("SHOT %s: the Lamplighter is dead in this shot" % name)   # never ship the death screen
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var res: Vector2i = DisplayServer.window_get_size()
	img.save_png("%s/%s_%dx%d.png" % [_out, name, res.x, res.y])
	print("SHOT ", name, "  fps %.0f" % Engine.get_frames_per_second())


func _bot() -> ShotHelper:
	return ShotHelper.new(g)


func _shot_light() -> void:
	var h := _bot()
	h.level_up(6)
	h.clear_near(900.0)
	h.pack_near(["gloam", "gloam", "hound", "gloam", "moth"], Vector2(150, 30))
	g.player.light.value = 85.0
	await _wait(1.2)
	h.cast("moth_swarm", g.player.global_position + Vector2(160, 20))
	await _wait(0.25)
	h.cast("flare", g.player.global_position + Vector2(100, 0))
	await _wait(0.1)
	await _save("gameplay_light")


func _shot_dark() -> void:
	var h := _bot()
	h.clear_near(900.0)
	h.pack_near(["gloam", "gloam", "gloam", "hound", "moth"], Vector2(-60, 160))
	g.player.light.value = 22.0
	await _wait(0.8)
	h.cast("lantern_toss", g.player.global_position + Vector2(260, -40))
	await _wait(1.1)
	h.cast("wickbolt", g.player.global_position + Vector2(-40, 120))
	await _wait(0.07)
	await _save("gameplay_dark")


func _shot_skills() -> void:
	var h := _bot()
	h.spec("wickbolt", ["quick_wick", "quick_wick", "long_flight", "sear", "sear", "kindling", "piercing"])
	g.ui.skills.selected = "wickbolt"
	g.ui.open(g.ui.skills)
	await _wait(0.3)
	h.hover(g.ui.skills.position + g.ui.skills.node_rect(GameData.skill("wickbolt")["nodes"][4]).get_center())
	await _wait(SETTLE)
	await _save("skill_tree")
	g.ui.open(g.ui.skills)


func _shot_passives() -> void:
	var h := _bot()
	h.level_up(10)
	g.player.prog.choose_mastery("beacon")
	for id: String in ["wick", "wick", "wick", "trimmed", "trimmed", "iron_coat", "steady_hand", "kindler", "hunger"]:
		g.player.prog.add_passive(id)
	g.ui.passives.tab = "lamplighter"
	g.ui.open(g.ui.passives)
	await _wait(0.3)
	h.hover(g.ui.passives.position + g.ui.passives.node_rect(GameData.passives["trees"]["lamplighter"]["nodes"][7]).get_center())
	await _wait(SETTLE)
	await _save("passive_tree")
	g.ui.open(g.ui.passives)


func _shot_inventory() -> void:
	var h := _bot()
	h.fill_bag()
	g.ui.open(g.ui.inventory)
	await _wait(0.3)
	h.hover(g.ui.inventory.position + g.ui.inventory.bag_rect(1).get_center())
	await _wait(SETTLE)
	await _save("inventory_tooltip")
	g.ui.open(g.ui.inventory)


func _shot_character() -> void:
	g.ui.open(g.ui.character)
	await _wait(SETTLE)
	await _save("character_sheet")
	g.ui.open(g.ui.character)


func _shot_boss() -> void:
	var h := _bot()
	h.story_at("seven_heartbeats", 1)
	h.clear_near(5000.0)
	h.place_player(g.layout.circle_center() + Vector2(0, 80))
	g.player.light.value = 70.0
	await _wait(0.4)
	g.start_boss()
	await _wait(2.6)
	h.cast("flare", g.spawner.boss.global_position)
	await _wait(0.1)
	await _save("boss_glazier")


func _shot_overview() -> void:
	var h := _bot()
	h.overview()
	await _wait(SETTLE)
	await _save("zone_overview")


## Tallow: Mother Ottilie by the Great Lantern, mid-conversation.
func _shot_tallow() -> void:
	var c: Campaign = Session.campaign
	while c.step_index("seven_heartbeats") < 4 and not c.is_done("seven_heartbeats"):
		c._advance("seven_heartbeats")
	var ott: Npc = _npc("ottilie")
	_bot().place_player(ott.global_position + Vector2(70, 70))
	await _wait(2.5)
	g.player.face(ott.global_position)
	await _wait(0.6)
	ott.use(g)
	g.hud.messages.advance()
	await _wait(SETTLE)
	await _save("tallow_ottilie")


func _npc(id: String) -> Npc:
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		if n is Npc and (n as Npc).npc_id == id:
			return n
	return null


## The Ember Road: relighting a road lamp while Husks come for it.
func _shot_road() -> void:
	var h := _bot()
	h.story_at("ember_road", 1)
	h.level_up(10)
	h.gear_up(10)
	h.clear_near(100000.0)                                  # only the lamp's own wave comes for it
	var lamp: Waylamp = g.lamps[0]
	h.place_player(lamp.stand_point() + Vector2(40, 30))
	g.player.light.value = 70.0
	await _wait(0.4)
	lamp.use(g)
	lamp.progress = 0.45
	await _wait(1.5)
	h.cast("flare", g.player.global_position + Vector2(80, 0))
	await _wait(0.12)
	if g.player.global_position.distance_to(lamp.global_position) > 200.0:
		push_error("SHOT road: the Lamplighter woke elsewhere (fell before the shot)")
	await _save("ember_road_relight")


## Moth Hollow: a hunger nest drinking the light, crawlers and moths in the dark.
func _shot_hollow() -> void:
	var h := _bot()
	h.story_at("moth_hollow", 0)
	h.level_up(12)
	h.gear_up(12)
	h.clear_near(100000.0)                                  # only the staged pack, not the whole cave
	var nest: Vector2 = g.layout.center_of(g.layout.clearing_of_role("hunger")["center"])
	h.place_player(nest + Vector2(-40, 60))
	h.pack_near(["crawler", "crawler", "moth", "gloam"], Vector2(120, -40))
	g.player.light.value = 40.0
	await _wait(1.6)
	h.cast("moth_swarm", g.player.global_position + Vector2(120, -40))
	await _wait(0.3)
	await _save("moth_hollow_nest")


## The Moth Matron: her gust cone filling toward you.
func _shot_matron() -> void:
	var h := _bot()
	h.story_at("moth_hollow", 1)
	h.level_up(14)
	h.clear_near(100000.0)
	h.place_player(g.layout.circle_center() + Vector2(0, 40))
	g.player.light.value = 70.0
	await _wait(0.4)
	g.start_boss()
	await _wait(2.6)
	h.place_player(g.layout.circle_center() + Vector2(-30, 40))          # her gust shoves; stand him back in the clear
	await _wait(0.4)
	h.cast("wickbolt", g.spawner.boss.global_position)
	await _wait(0.1)
	await _save("matron_fight")


func _shot_quests() -> void:
	Session.campaign.start("tea_on_tuesdays")
	Session.campaign.start("teagues_trail")
	g.ui.open(g.ui.quests)
	await _wait(SETTLE)
	await _save("quest_log")
	g.ui.open(g.ui.quests)


func _shot_filter() -> void:
	LootFilter.toggle_rarity("normal")
	LootFilter.toggle_slot("ring")
	g.ui.open(g.ui.filter)
	await _wait(SETTLE)
	await _save("loot_filter")
	g.ui.open(g.ui.filter)


func _shot_stash() -> void:
	var h := _bot()
	h.fill_bag()
	for i: int in 5:
		g.ui.stash.store(LootGen.make(6, LootGen.roll_rarity("rare")))
	g.ui.open(g.ui.stash)
	await _wait(0.3)
	h.hover(g.ui.stash.position + g.ui.stash.cell_rect(2).get_center())
	await _wait(SETTLE)
	await _save("stash_tooltip")
	g.ui.open(g.ui.stash)


func _shot_eclipse() -> void:
	var h := _bot()
	h.story_at("ember_road", 1)
	h.level_up(12)
	h.gear_up(12)
	h.clear_near(900.0)
	h.pack_near(["gloam", "hound", "gloam", "husk", "gloam"], Vector2(90, 20))
	await _wait(0.8)
	h.cast("eclipse", g.player.global_position)
	await _wait(1.2)
	h.cast("wickbolt", g.player.global_position + Vector2(80, 10))
	await _wait(0.06)
	await _save("eclipse")


func _shot_noon() -> void:
	var h := _bot()
	h.story_at("ember_road", 1)
	h.level_up(12)
	h.gear_up(12)
	h.clear_near(900.0)
	h.pack_near(["gloam", "hound", "gloam", "moth", "gloam", "hound"], Vector2(140, 40))
	await _wait(0.8)
	h.cast("noon", g.player.global_position)
	await _wait(0.2)
	await _save("noon")


func _shot_keystones() -> void:
	var h := _bot()
	h.level_up(30)
	g.player.prog.choose_mastery("duskwalker")
	for id: String in ["wick", "wick", "wick", "wick", "wick", "deep_oil", "deep_oil", "steady_hand", "steady_hand", "trimmed",
			"iron_coat", "kindler", "kindler", "road_legs", "hunger", "hunger", "night_eyes", "night_eyes", "steady_flame", "keen", "ks_lighthouse"]:
		g.player.prog.add_passive(id)
	g.ui.passives.tab = "lamplighter"
	g.ui.open(g.ui.passives)
	await _wait(0.3)
	h.hover(g.ui.passives.position + g.ui.passives.node_rect(GameData.passives["trees"]["lamplighter"]["nodes"][14]).get_center())
	await _wait(SETTLE)
	await _save("passive_keystones")
	g.ui.open(g.ui.passives)


func _shot_eclipse_tree() -> void:
	var h := _bot()
	h.level_up(12)
	h.spec("eclipse", ["long_night", "long_night", "hunger", "predator", "unshutter", "umbra"])
	g.ui.skills.selected = "eclipse"
	g.ui.open(g.ui.skills)
	await _wait(0.3)
	h.hover(g.ui.skills.position + g.ui.skills.node_rect(GameData.skill("eclipse")["nodes"][4]).get_center())
	await _wait(SETTLE)
	await _save("eclipse_tree")
	g.ui.open(g.ui.skills)


## The Upward River: Undertows and Drowned Lanterns by the hamlet, the river climbing behind them.
## The Ember Forge: a rare staff on the anvil, an affix chosen, materials in hand.
## The Bellwright: a toll rolling out across the flooded square, a gap to stand in.
## The Rising Falls: an updraft column, herons diving.
## The Saltmarsh: a lure has just sprung; Bog Lurkers rise round the Lamplighter.
## The Town of One Tuesday: Repeaters in a square, the hour on the HUD.
## The Mayor: two clock hands filling toward you.
