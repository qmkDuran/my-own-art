extends Node
## Review screenshots (autoload "Shots", dormant unless the user arg --shots is given; needs a display, e.g. xvfb-run):
## puts the player at fixed spots, triggers an action, waits, and saves the viewport to ../out/<name>.png.

const SHOTS: Array = [
	# [name, scene, player spot, facing, action ("" / "talk" / "fruit"), seconds to wait, camera scale]
	["district_gardens", "res://main.tscn", Vector2(300, 806), "down", "", 2.5, 2],
	["district_musicians", "res://main.tscn", Vector2(1432, 800), "up", "talk", 2.5, 2],
	["district_terrace_view", "res://main.tscn", Vector2(960, 940), "down", "", 2.5, 2],
	["gate_angel_city", "res://main.tscn", Vector2(500, 244), "up", "talk", 2.5, 2],
	["foundations_caption", "res://main.tscn", Vector2(200, 174), "up", "", 3.0, 2],
	["tree_of_life_fruit", "res://main.tscn", Vector2(350, 306), "up", "fruit", 1.4, 3],
	["gate_angel_new_earth", "res://earth.tscn", Vector2(960, 272), "up", "", 3.0, 2],
]


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--shots"):
		_run.call_deferred()


func _run() -> void:
	for s: Array in SHOTS:
		get_tree().change_scene_to_file(s[1])
		for i: int in 40:
			await get_tree().process_frame
		var scene: SceneBase = get_tree().current_scene as SceneBase
		var player: Player = get_tree().get_first_node_in_group("player") as Player
		player.global_position = s[2]
		player.face(s[3])
		scene.camera.go_to(int(s[6]))
		scene.camera.snap_to_target()
		await get_tree().create_timer(5.0).timeout          # past the scene title
		if s[4] == "talk":
			scene.talk_nearest()
		elif s[4] == "fruit":
			scene.call("pick_fruit", scene.call("tree_near", player.global_position))
		await get_tree().create_timer(float(s[5])).timeout
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://") + "../out/" + s[0] + ".png")
		print("SHOT ", s[0])
	get_tree().quit(0)
