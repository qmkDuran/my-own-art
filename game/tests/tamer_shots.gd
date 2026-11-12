extends Node
## --tamer-shots: review stills of the trainer prototype (needs a display; tools/tamer_shots.sh runs it under
## xvfb). --only=NAME picks one scene (SHOTS). Each is
## staged in the real prototype (moved into place, then played for real) and saved as NAME_<w>x<h>.png in --out.

const SHOTS: Array[String] = ["meeting", "exploring", "battle_start", "battle", "befriend", "victory", "info", "shiny", "swap",
	"camp", "camp_panel", "hud"]
const HUD_CROP: float = 0.3             ## the bottom share of the screen kept for the HUD close-up

var g: TamerGame
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
	await _wait(1.0)
	g = TamerGame.current
	var names: Array[String] = SHOTS.duplicate()
	if _only() != "":
		names = [_only()]
	for n: String in names:
		await call("_shot_" + n)
	get_tree().quit()


func _save(name: String, crop_bottom: float = 0.0) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if crop_bottom > 0.0:
		var h: int = int(img.get_height() * crop_bottom)
		img = img.get_region(Rect2i(0, img.get_height() - h, img.get_width(), h))
	var res: Vector2i = DisplayServer.window_get_size()
	img.save_png("%s/%s_%dx%d.png" % [_out, name, res.x, res.y])
	print("SHOT ", name)


# ------------------------------------------------------------------ staging
func _place(at: Vector2) -> void:
	g.trainer.global_position = g.layout.free_spot_near(at, 8.0)
	g.trainer.heading = Vector2.RIGHT
	g.camera.reset_smoothing()


func _clear_wild(r: float) -> void:
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		if (n as Node2D).global_position.distance_to(g.trainer.global_position) < r:
			n.queue_free()


func _team(starter: int, extra: Array[String]) -> void:
	g.meeting.pick(g.meeting.waiting[starter])
	for id: String in extra:
		g.team.add(CreatureRecord.make(id, 3, false))
	g.hud.caption("")
	g.guide.done("pick")


func _wild(kind: String, offset: Vector2, shiny: bool = false) -> Creature:
	var at: Vector2 = g.layout.free_spot_near(g.trainer.global_position + offset, 14.0)
	return g.spawner.spawn(kind, at, 2, -1, 1 if shiny else 0)


## Stands still for the camera but keeps breathing and glinting (no brain).
func _hold(c: Creature) -> void:
	c.brain = null
	c.facing = Vector2.LEFT


# ------------------------------------------------------------------ the stills
func _shot_meeting() -> void:
	_place(g.layout.start + Vector2(0, 40))
	await _wait(0.4)
	g.meeting.react(g.meeting.waiting[0])
	await _wait(0.12)
	g.input.cursor_override = g.meeting.waiting[1].global_position + Vector2(0, -12)
	await _wait(0.3)
	await _save("meeting")


func _shot_exploring() -> void:
	_team(0, [])
	_place(g.layout.start + Vector2(40, 60))
	_clear_wild(500.0)
	g.trainer.walk_to(g.trainer.global_position + Vector2(120, 20))
	await _wait(1.2)
	await _save("exploring")


## The battle-start beat: right-click a wild creature; "Go!", the leap, the vignette.
func _shot_battle_start() -> void:
	_team(0, [])
	_place(g.layout.start + Vector2(40, 60))
	_clear_wild(1400.0)
	await _wait(1.0)
	var foe: Creature = _wild("maned_wolf", Vector2(170, 0))
	foe.set_physics_process(false)
	(foe.brain as WildBrain).wake(g.field.partner)
	await _wait(0.22)
	await _save("battle_start")


## Mid-battle: holding W shows the ghost of the move, the mouse is on its icon (tooltip), a red warning is coming.
func _shot_battle() -> void:
	_team(0, [])
	_place(g.layout.start + Vector2(40, 60))
	_clear_wild(1400.0)
	await _wait(1.0)
	var foes: Array[Creature] = [_wild("tas_devil", Vector2(190, -10)), _wild("maned_wolf", Vector2(230, 40))]
	g.battle.engage(foes[0])
	await _wait(1.6)
	var p: Creature = g.field.partner
	g.input.cursor_override = foes[1].global_position
	g.aim.aim(p, "ember_pounce")
	g.hud.forced_tip = 1
	p.cast("claw_rush", foes[0].global_position)
	await _wait(0.07)
	await _save("battle")
	g.hud.forced_tip = -1
	g.aim.clear()


func _shot_befriend() -> void:
	_team(2, [])
	_place(g.layout.start + Vector2(30, 60))
	_clear_wild(1400.0)
	await _wait(0.8)
	var wolf: Creature = _wild("maned_wolf", Vector2(150, -6))
	_hold(wolf)
	wolf.receive_hit(wolf.rec.max_life() * 0.65, Vector2.RIGHT, 0.0, 0.0, null)
	await _wait(0.4)
	g.befriend.request()
	await _wait(1.3)
	await _save("befriend")


func _shot_victory() -> void:
	_team(0, [])
	_place(g.layout.start + Vector2(40, 60))
	_clear_wild(1400.0)
	await _wait(1.0)
	var foe: Creature = _wild("tas_devil", Vector2(120, 0))
	g.battle.engage(foe)
	await _wait(0.8)
	foe.receive_hit(9999.0, Vector2.RIGHT, 0.0, 0.0, g.field.partner)
	await _wait(2.4)
	await _save("victory")


func _shot_info() -> void:
	_team(0, ["aye_aye"])
	_place(g.layout.start + Vector2(40, 60))
	await _wait(0.6)
	g.hud.info_panel.open(g.team.members[0])
	await _wait(0.3)
	await _save("info")


func _shot_shiny() -> void:
	_team(0, [])
	_place(g.layout.start + Vector2(40, 60))
	_clear_wild(1400.0)
	await _wait(0.6)
	g.field.partner.global_position = g.trainer.global_position + Vector2(-30, 10)
	g.field.partner.brain = null
	var shiny: Creature = _wild("maned_wolf", Vector2(120, 20), true)
	var plain: Creature = _wild("maned_wolf", Vector2(230, 90))
	_hold(plain)
	_hold(shiny)
	await _wait(0.6)
	g.input.cursor_override = shiny.global_position + Vector2(0, -12)
	await _wait(0.35)
	await _save("shiny")


func _shot_swap() -> void:
	_team(0, ["aye_aye", "maned_wolf"])
	_place(g.layout.start + Vector2(40, 60))
	_clear_wild(1400.0)
	await _wait(0.8)
	for off: Vector2 in [Vector2(-60, -20), Vector2(-50, 40)]:
		_hold(_wild("tas_devil", off))
	g.field.swap(1)
	await _wait(0.22)
	await _save("swap")


func _shot_camp() -> void:
	_team(0, ["aye_aye", "pangolin"])
	g.team.members[1].bond = 70.0
	_place(g.camp_point() + Vector2(10, 52))
	await _wait(2.5)
	g.hud.camp_panel.close()
	await _wait(0.3)
	await _save("camp")


func _shot_camp_both() -> void:
	await _shot_camp()
	await _shot_camp_panel()


func _shot_camp_panel() -> void:
	g.team.add_material("rot_fang", 3)
	g.team.add_material("wind_tuft", 1)
	g.team.add_material("night_whisker", 4)
	g.hud.camp_panel.open()
	await _wait(0.3)
	await _save("camp_panel")


func _shot_hud() -> void:
	if g.team.members.is_empty():
		_team(0, ["aye_aye", "maned_wolf"])
	g.hud.camp_panel.close()
	g.team.add_material("wind_tuft", 2)
	_place(g.layout.start + Vector2(40, 60))
	await _wait(0.8)
	g.field.partner.rec.bond = 45.0
	g.field.partner.cooldowns["ember_pounce"] = 2.4
	g.field.partner.cooldowns["cinder_roar"] = 5.0
	g.team.members[2].knock_out()
	await _wait(0.3)
	await _save("hud", HUD_CROP)
