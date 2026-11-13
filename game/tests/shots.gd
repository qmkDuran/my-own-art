extends Node
## --shots --only=<name> --out=<dir>: stages one review still in the real town and saves <dir>/<name>.png. Stills
## only (no video). Needs a display (xvfb-run is fine). An unknown shot name quits with an error.

## name -> [eye, look-at, player spot [x, z, yaw_deg] or empty, rain]
const SHOTS: Dictionary = {
	"overview": [Vector3(30, 40, 50), Vector3(0, 0, 5), [], false],
	"square": [Vector3(3.0, 2.3, 10.0), Vector3(-0.5, 2.6, -6), [1.6, 6.6, 170.0], false],
	"street": [Vector3(-14, 1.9, 1.2), Vector3(-40, 2.2, -0.5), [-17.0, 0.4, 100.0], false],
	"canal_bridge": [Vector3(-14, 1.6, 12.6), Vector3(4, 0.0, 17.5), [], false],
	"alley": [Vector3(13.2, 1.8, 0.4), Vector3(30, 2.6, -0.2), [16.0, 0.2, -90.0], false],
	"overlook": [Vector3(47.5, 8.6, 17.5), Vector3(10, -1.0, 16.0), [46.2, 16.0, -95.0], false],
	"rain": [Vector3(-2.5, 2.4, 9.5), Vector3(1.5, 1.6, -6), [-1.2, 6.0, 160.0], true],
	"player_closeup": [Vector3(-1.1, 1.45, 4.6), Vector3(-1.6, 1.05, 6.0), [-1.6, 6.0, 160.0], false],
	"defence": [Vector3(-1.5, 4.2, 12.5), Vector3(0.5, 0.6, 1.0), [0.0, 5.0, 0.0], false],
	"boss": [Vector3(3.5, 3.0, 13.0), Vector3(-1.0, 1.6, -1.0), [0.5, 6.0, 0.0], false],
	"level_up": [Vector3(-1.5, 4.2, 12.5), Vector3(0.5, 0.6, 1.0), [0.0, 5.0, 0.0], false],
	"busy": [Vector3(-1.5, 4.2, 12.5), Vector3(0.5, 0.6, 1.0), [0.0, 5.0, 0.0], false],
	"busy_no_actors": [Vector3(-1.5, 4.2, 12.5), Vector3(0.5, 0.6, 1.0), [0.0, 5.0, 0.0], false],
	"contrast_on": [Vector3(-1.5, 4.2, 12.5), Vector3(0.5, 0.6, 1.0), [0.0, 5.0, 0.0], false],
	"contrast_off": [Vector3(-1.5, 4.2, 12.5), Vector3(0.5, 0.6, 1.0), [0.0, 5.0, 0.0], false],
	"bridge_end": [Vector3(3.2, 1.5, 11.0), Vector3(0.4, 0.0, 14.6), [], false],
	"house_gap": [Vector3(-24.0, 1.7, 1.8), Vector3(-29.5, 1.6, -4.0), [], false],
	"barrier": [Vector3(55.0, 7.6, 21.5), Vector3(58.5, 7.0, 18.5), [57.2, 18.8, 90.0], false],
	"seam_check": [Vector3(2.0, 1.35, -5.3), Vector3(3.5, 1.1, -9.3), [2.6, -7.0, 160.0], false],
	"outskirts": [Vector3(56.5, 9.5, 19.0), Vector3(140.0, 4.0, -10.0), [], false],
	"outskirts_west": [Vector3(-46.0, 2.0, 22.5), Vector3(-140.0, 6.0, 40.0), [], false],
	"fish": [Vector3(-7.5, 2.4, 12.2), Vector3(-10.0, -0.8, 17.0), [], false],
	"bench": [Vector3(-2.0, 1.3, -3.4), Vector3(-4.5, 0.6, -5.2), [], false],
	"townsfolk": [Vector3(2.6, 1.6, -1.2), Vector3(-1.2, 1.0, -7.5), [], false],
}

var m: Main


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var shot: String = TestRunner.arg_value("--only=")
	if not SHOTS.has(shot):
		print("SHOT unknown ", shot)
		get_tree().quit(1)
		return
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.3).timeout
	m = Main.current
	var spec: Array = SHOTS[shot]
	_stage_player(spec[2])
	if spec[3]:
		m.weather.set_raining(true)
		m.weather.settle()
	var wait: String = TestRunner.arg_value("--wait=")
	await get_tree().create_timer(float(wait) if wait != "" else 4.0).timeout
	var eye := Camera3D.new()
	eye.fov = 55.0
	m.add_child(eye)
	eye.look_at_from_position(spec[0], spec[1])
	eye.current = true
	m.hud.visible = false
	m.budget.set_process(false)
	if has_method("_stage_" + shot):
		await call("_stage_" + shot)
	await get_tree().create_timer(1.5).timeout
	m.budget.refresh()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var out: String = TestRunner.arg_value("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png(out.path_join(shot + ".png"))
	print("SHOT saved ", shot)
	get_tree().quit()


func _stage_player(spot: Array) -> void:
	m.controller.enabled = false
	if spot.is_empty():
		m.player.position = Vector3(60, 6, 40)
		return
	m.player.position = Vector3(spot[0], 0.05, spot[1])
	if spot[0] > 44.0:
		m.player.position.y = 6.05
	m.player.yaw = deg_to_rad(spot[2])
	m.player.rotation.y = m.player.yaw


func _night() -> void:
	m.start_night()
	m.night.set_physics_process(false)
	m.night_hud.banner("", 0.0)
	m.night_hud.visible = true
	for id: String in ["firefly_swarm", "candle_ring", "moonbeam", "bell_chime"]:
		m.night.loadout.apply({ "kind": "attacks", "id": id })
		m.night.loadout.apply({ "kind": "attacks", "id": id })
	m.night.bag = { "pumpkin_goo": 3, "moth_dust": 2, "ghost_pepper": 4 }
	m.night.level = 7
	m.night.clock = 200.0
	var kinds: Array[String] = ["sheet_ghost", "pumpkin_head", "lantern_moth"]
	for index: int in 34:
		var angle: float = TAU * index / 34.0
		var at: Vector3 = m.player.global_position + Vector3(cos(angle), 0, sin(angle)) * (4.0 + (index % 4) * 1.6)
		var creature: Creature = m.night.horde.spawn(kinds[index % 3], at)
		creature.rotation.y = atan2(-cos(angle), -sin(angle))
	for index: int in 12:
		m.night.pickups.drop(Pickups.XP if index % 3 else "pumpkin_goo", 1, m.player.global_position + Vector3(
			randf_range(-5, 5), 0, randf_range(-3, 3)))


func _freeze_horde() -> void:
	for creature: Creature in m.night.horde.creatures:
		creature.set_physics_process(false)
	m.night.horde.set_physics_process(false)


func _stage_defence() -> void:
	await _night()
	await get_tree().create_timer(1.2).timeout
	_freeze_horde()
	m.hud.visible = true
	m.hud.visible = false


func _stage_boss() -> void:
	await _night()
	m.night.horde.spawn("gloom_king", Vector3(-1.0, 0, -2.0))
	await get_tree().create_timer(1.0).timeout
	_freeze_horde()


func _stage_level_up() -> void:
	await _night()
	await get_tree().create_timer(0.8).timeout
	_freeze_horde()
	m.level_panel.show_offers(m.night.loadout.offers())


## Creatures with no magic, fireflies or dust, so the only difference to contrast_off is the creatures.
func _stage_contrast_on() -> void:
	await _night()
	_freeze_horde()
	m.night.loadout.visible = false
	m.night.loadout.process_mode = Node.PROCESS_MODE_DISABLED
	m.night.pickups.clear()
	m.night_hud.visible = false
	for node: Node in m.find_children("*", "GPUParticles3D", true, false):
		(node as GPUParticles3D).visible = false


func _stage_contrast_off() -> void:
	await _stage_contrast_on()
	m.night.horde.visible = false


## A busy wave with every effect showing, frozen so a second shot without the actors matches it.
func _stage_busy() -> void:
	await _night()
	await get_tree().create_timer(1.2).timeout
	_freeze_horde()
	m.night.loadout.process_mode = Node.PROCESS_MODE_DISABLED
	m.night.pickups.process_mode = Node.PROCESS_MODE_DISABLED


func _stage_busy_no_actors() -> void:
	await _stage_busy()
	m.night.horde.visible = false
	m.player.visible = false
