extends Node
## --walk-sheet --out=<dir> (run with --fixed-fps 30): the player walks across Lamp Street seen from the side, the
## camera keeping pace, and a still is saved every few frames (<dir>/walk_<n>.png) for a contact sheet. Stills only.

const START: Vector3 = Vector3(-38, 0.05, 0.6)
const SIDE: Vector3 = Vector3(0, 0.9, 3.2)
const EVERY: int = 3
const SHOTS: int = 12

var m: Main


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	for frame: int in 10:
		await get_tree().process_frame
	m = Main.current
	m.controller.enabled = false
	m.hud.visible = false
	m.player.global_position = START
	var eye := Camera3D.new()
	eye.fov = 40.0
	m.add_child(eye)
	eye.current = true
	m.player.wish = Vector3.RIGHT
	var out: String = TestRunner.arg_value("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	for frame: int in 30 + SHOTS * EVERY:
		eye.look_at_from_position(m.player.global_position + SIDE, m.player.global_position + Vector3.UP * SIDE.y)
		await RenderingServer.frame_post_draw
		if frame >= 30 and (frame - 30) % EVERY == 0:
			get_viewport().get_texture().get_image().save_png(out.path_join("walk_%02d.png" % ((frame - 30) / EVERY)))
	print("WALK saved")
	get_tree().quit()
