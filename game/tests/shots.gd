extends Node
## --shots --only=<name> --out=<dir>: stages one review still in the real town and saves <dir>/<name>.png. Stills
## only (no video). Needs a display (xvfb-run is fine). An unknown shot name quits with an error.

## name -> [eye, look-at, player spot [x, z, yaw_deg] or empty, rain]
const SHOTS: Dictionary = {
	"overview": [Vector3(30, 40, 50), Vector3(0, 0, 5), [], false],
	"square": [Vector3(-2.5, 2.4, 9.5), Vector3(1.5, 2.2, -6), [-1.2, 6.0, 160.0], false],
	"street": [Vector3(-14, 1.9, 1.2), Vector3(-40, 2.2, -0.5), [-17.0, 0.4, 100.0], false],
	"canal_bridge": [Vector3(-14, 1.6, 12.6), Vector3(4, 0.0, 17.5), [], false],
	"alley": [Vector3(13.2, 1.8, 0.4), Vector3(30, 2.6, -0.2), [16.0, 0.2, -90.0], false],
	"overlook": [Vector3(46.5, 8.2, 22.6), Vector3(10, 1.0, 12), [46.0, 21.5, -100.0], false],
	"rain": [Vector3(-2.5, 2.4, 9.5), Vector3(1.5, 1.6, -6), [-1.2, 6.0, 160.0], true],
	"player_closeup": [Vector3(-1.1, 1.45, 4.6), Vector3(-1.6, 1.05, 6.0), [-1.6, 6.0, 160.0], false],
	"townsfolk": [Vector3(-0.2, 1.7, 1.6), Vector3(-3.5, 0.9, -5.0), [], false],
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
	m.player.yaw = deg_to_rad(spot[2])
	m.player.rotation.y = m.player.yaw
