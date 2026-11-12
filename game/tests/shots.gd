extends Node
## --shots --only=<name> --out=<dir>: stages one review still in the real game and saves it as <dir>/<name>.png.
## Stills only (no video). Needs a display (xvfb-run is fine).

const SHOTS: Array[String] = ["overview", "third_person", "lock_on", "spit_tree", "hiding", "searching",
	"ridge_fight", "hud_closeup"]
const OVERVIEW_EYE: Vector3 = Vector3(0, 52, 44)
const HUD_STRIP_SHARE: float = 0.3

var stage: Stage
var m: Main


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	Main.skip_intro = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	await get_tree().physics_frame
	m = Main.current
	stage = Stage.new(m)
	await stage.frames(5)
	var shot: String = TestRunner.arg_value("--only=")
	assert(SHOTS.has(shot), "unknown shot " + shot)
	await call("_stage_" + shot)
	await stage.frames(3)
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if shot == "hud_closeup":
		var strip: int = int(image.get_height() * HUD_STRIP_SHARE)
		image = image.get_region(Rect2i(0, image.get_height() - strip, image.get_width(), strip))
	var out: String = TestRunner.arg_value("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	image.save_png(out.path_join(shot + ".png"))
	print("SHOT saved ", shot)
	get_tree().quit()


func _stage_overview() -> void:
	m.hud.visible = false
	stage.freeze_bot()
	var eye := Camera3D.new()
	m.add_child(eye)
	eye.fov = 60.0
	eye.look_at_from_position(OVERVIEW_EYE, Vector3(0, 0, -2))
	eye.current = true
	await stage.frames(20)


func _stage_third_person() -> void:
	stage.freeze_bot()
	stage.place(m.player, Vector2(-14, 14), m.woods.ground_at(Vector2(2, -1)))
	stage.place(m.bot, Vector2(1, 0), m.player.global_position)
	stage.camera_behind_player(-12.0)
	await stage.frames(30)
