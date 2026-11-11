extends Node
## Review screenshots (needs a display): `-- --shots --only=NAME --out=DIR` stages one scene and saves the
## 320x180 frame as DIR/NAME.png (tools/shoot.sh upscales them for review).

const SETTLE_FRAMES: int = 30

var _main: Node


func _ready() -> void:
	_main = TestRunner.main()
	Game.rng.seed = 3
	var only: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	await get_tree().process_frame
	await call("_shot_" + only)
	await _frames(SETTLE_FRAMES)
	await _secs(0.5)
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(TestRunner.out_dir())
	img.save_png(TestRunner.out_dir().path_join(only + ".png"))
	print("SHOT ", only)
	get_tree().quit()


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _game(stage: int, friends: Array[String] = []) -> void:
	Game.new_game()
	Game.choose_starter("mossfawn")
	for id: String in friends:
		Game.befriend(Creature.create(id, 5))
	Game.heal_stage = stage
	for s: int in range(1, stage + 1):
		Game.flags["stage_%d" % s] = true
	Game.flags["met_gran"] = true


func _world(map: String, cell: Vector2i, stage: int, facing: Vector2i = Vector2i.UP) -> Overworld:
	_game(stage)
	Game.map_id = map
	Game.cell = cell
	Game.facing = facing
	var w: Overworld = _main.start_overworld()
	await _frames(5)
	w.banner.hide()
	return w


func _shot_title() -> void:
	_main.show_title()


func _shot_starter() -> void:
	Game.new_game()
	var intro := IntroScene.new()
	_main._swap(intro)
	await _frames(2)
	intro._bg.texture = load("res://art/scenes/intro_shoot.png")
	intro._show_starters()
	intro._highlight()


func _shot_intro() -> void:
	Game.new_game()
	var intro := IntroScene.new()
	_main._swap(intro)
	intro.run()


func _shot_town() -> void:
	await _world("fernhollow", Vector2i(13, 9), 0)


func _shot_town_healed() -> void:
	await _world("fernhollow", Vector2i(13, 9), 1)


func _shot_route() -> void:
	await _world("bramble_lane", Vector2i(11, 26), 0)


func _shot_route_healed() -> void:
	await _world("bramble_lane", Vector2i(11, 26), 1)


func _shot_grove_before() -> void:
	await _world("wellspring_grove", Vector2i(11, 9), 0)


func _shot_grove_after() -> void:
	await _world("wellspring_grove", Vector2i(11, 8), 3)


func _shot_home() -> void:
	await _world("home", Vector2i(4, 5), 0)


func _shot_mender() -> void:
	await _world("mender", Vector2i(4, 5), 0)


func _shot_dialogue() -> void:
	var w: Overworld = await _world("home", Vector2i(6, 4), 0)
	w.dialog.say(Db.lines("gran", {}), "Gran")


func _battle(kind: String, foe: String, menu: bool) -> BattleScene:
	var w: Overworld = await _world("bramble_lane", Vector2i(5, 32), 0)
	Game.fast = true
	var b := BattleScene.new()
	b.kind = kind
	b.trainer_id = "lio" if kind == "trainer" else ""
	w.add_child(b)
	var foes: Array[Creature] = [Creature.create(foe, 5)]
	if not menu:
		b.menus.queued.append({"type": "move", "move": "leafdart"}) if b.menus != null else null
	b.run(foes)
	await _frames(20)
	Game.fast = false
	return b


func _shot_battle_timing() -> void:
	TimingRing.hold_at = 0.42
	await _battle("wild", "drizzlesnail", true)
	for i: int in 2:
		_press("accept")
		await _secs(0.3)
	await _secs(2.5)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _shot_battle_trust() -> void:
	var b: BattleScene = await _battle("wild", "thistlehog", true)
	b.foe.trust = 50
	b.foe.mood = "hungry"
	b.foe_card.update_trust()


func _shot_battle_moves() -> void:
	var b: BattleScene = await _battle("wild", "kindlemoth", true)
	b.foe.trust = 20
	b.foe_card.update_trust()
	_press("accept")


func _shot_battle_status() -> void:
	var b: BattleScene = await _battle("wild", "kindlemoth", true)
	StatusRules.apply(b.foe, "drowsy")
	b.foe_card.show_status()
	StatusRules.apply(b.ally, "singed")
	b.ally_card.show_status()
	b.foe.mood = "sleepy"
	b.view.set_mood("sleepy")
	b.foe.trust = 70
	b.foe_card.update_trust()


func _shot_battle_fx() -> void:
	var b: BattleScene = await _battle("wild", "cobblemole", true)
	b.view.set_mood("wary")
	var fx := MoveFx.new().setup("bloom", b.view.body_point(true), b.view.body_point(false))
	b.view.add_child(fx)
	fx.set("_t", 0.55)
	fx.set_process(false)
	fx.queue_redraw()


func _shot_trainer() -> void:
	await _battle("trainer", "thistlehog", true)


func _panel_world() -> Overworld:
	_game(1)
	Game.befriend(Creature.create("thistlehog", 6))
	Game.befriend(Creature.create("puffwren", 5))
	Game.befriend(Creature.create("drizzlesnail", 6))
	Game.party[2].hp = 9
	Game.journal.see("kindlemoth")
	Game.journal.see("cobblemole")
	var w: Overworld = _main.start_overworld()
	return w


func _shot_party() -> void:
	var w: Overworld = _panel_world()
	await _frames(3)
	var p := PartyPanel.new()
	w.ui.add_child(p)
	p.run()


func _shot_summary() -> void:
	var w: Overworld = _panel_world()
	Game.party[0].bond = 45
	await _frames(3)
	var p := SummaryPanel.new()
	w.ui.add_child(p)
	p.run_for(0)


func _shot_journal() -> void:
	var w: Overworld = _panel_world()
	await _frames(3)
	var p := JournalPanel.new()
	w.ui.add_child(p)
	p.run()


func _shot_bag() -> void:
	var w: Overworld = _panel_world()
	await _frames(3)
	var p := BagPanel.new()
	w.ui.add_child(p)
	p.run()


func _shot_shop() -> void:
	var w: Overworld = _panel_world()
	await _frames(3)
	var p := ShopPanel.new()
	w.ui.add_child(p)
	p.run()


func _shot_menu() -> void:
	var w: Overworld = _panel_world()
	await _frames(3)
	w.interactions.open_menu()


func _shot_evolution() -> void:
	var w: Overworld = _panel_world()
	await _frames(3)
	var e := EvolutionScene.new()
	w.ui.add_child(e)
	Game.fast = true
	e.run(Game.party[0], "grovehart")
	await _frames(40)
