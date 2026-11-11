extends Node
## --shots: review screenshots (needs a display: xvfb-run). Each shot is a short scripted scene in the real game:
## set things up, wait for effects to land, save out/<name>_<w>x<h>.png. --only=name runs one shot.

const SETTLE: float = 0.9

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
	g = Game.current
	var shots: Array[String] = ["light", "dark", "skills", "passives", "inventory", "character", "boss", "overview"]
	for s: String in shots:
		if _only() == "" or _only() == s:
			await call("_shot_" + s)
	get_tree().quit()


func _save(name: String) -> void:
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
	h.cast("flare", g.player.global_position + Vector2(100, 0))
	await _wait(0.12)
	h.cast("moth_swarm", g.player.global_position + Vector2(160, 20))
	await _wait(0.15)
	await _save("gameplay_light")


func _shot_dark() -> void:
	var h := _bot()
	h.clear_near(900.0)
	h.pack_near(["gloam", "gloam", "gloam", "hound", "moth"], Vector2(-60, 160))
	g.player.light.value = 22.0
	await _wait(0.8)
	h.cast("lantern_toss", g.player.global_position + Vector2(260, -40))
	await _wait(1.1)
	h.cast("sunlash", g.player.global_position + Vector2(-40, 120))
	await _wait(0.07)
	await _save("gameplay_dark")


func _shot_skills() -> void:
	var h := _bot()
	h.spec("sunlash", ["quick_wrist", "quick_wrist", "long_cord", "sear", "sear", "kindling", "backhand"])
	g.ui.skills.selected = "sunlash"
	g.ui.open(g.ui.skills)
	await _wait(0.3)
	h.hover(g.ui.skills.position + g.ui.skills.node_rect(GameData.skill("sunlash")["nodes"][4]).get_center())
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
	h.clear_near(5000.0)
	g.player.global_position = g.layout.boss["pos"] + Vector2(-40, 170)
	g.camera.reset_smoothing()
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
