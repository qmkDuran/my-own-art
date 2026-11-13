extends Node
## --sequence --out=<dir> --source=<blender|godot> --frames=a,b,c [--view=gameplay] (run with --fixed-fps 30 so
## frames are deterministic): one Lantern Flare cast at a ghost down Lamp Street, from the gameplay camera or a
## close-up, saving <dir>/<source>_<view>_<frame>.png at each listed frame after the cast. Stills only.

const PLAYER_SPOT: Vector3 = Vector3(-20, 0.05, 0.5)
const GHOST_SPOT: Vector3 = Vector3(-26.5, 0, 0.5)
const EYE: Vector3 = Vector3(-23.2, 2.3, 5.2)
const LOOK: Vector3 = Vector3(-23.2, 0.9, 0.4)
const GHOST_HEALTH: float = 5.0

var m: Main


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	for frame: int in 10:
		await get_tree().process_frame
	m = Main.current
	seed(1)
	m.vfx.source = TestRunner.arg_value("--source=")
	m.controller.enabled = false
	m.player.global_position = PLAYER_SPOT
	m.player.yaw = PI * 0.5
	m.player.rotation.y = m.player.yaw
	m.start_night()
	m.night.set_physics_process(false)
	m.night.loadout.process_mode = Node.PROCESS_MODE_DISABLED
	m.night_hud.visible = false
	m.hud.visible = false
	var ghost: Creature = m.night.horde.spawn("sheet_ghost", GHOST_SPOT)
	ghost.set_physics_process(false)
	ghost.rotation.y = PI * 0.5
	ghost.health = GHOST_HEALTH
	if TestRunner.arg_value("--view=") == "gameplay":
		m.camera_rig.yaw = m.player.yaw
		m.camera_rig.snap()
	else:
		var eye := Camera3D.new()
		eye.fov = 50.0
		m.add_child(eye)
		eye.look_at_from_position(EYE, LOOK)
		eye.current = true
	for frame: int in 20:
		await get_tree().process_frame
	await _capture(ghost)
	get_tree().quit()


func _capture(ghost: Creature) -> void:
	var wanted: Array = Array(TestRunner.arg_value("--frames=").split(",")).map(func(s: String) -> int: return int(s))
	var out: String = TestRunner.arg_value("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	(m.night.loadout.attacks["lantern_flare"] as LanternFlare).cast(ghost)
	var frame: int = 0
	while frame <= int(wanted.max()):
		await RenderingServer.frame_post_draw
		if wanted.has(frame):
			var view: String = TestRunner.arg_value("--view=")
			var file: String = "%s_%s_%02d.png" % [m.vfx.source, view if view != "" else "closeup", frame]
			get_viewport().get_texture().get_image().save_png(out.path_join(file))
			print("SEQUENCE saved ", frame)
		frame += 1
