extends Node
## --shots (with --demo): review screenshots into ../out/ (needs a display, e.g. xvfb-run; any --resolution).
## The demo bot plays; at set times this opens a panel and points the mouse at something with a tooltip, then saves
## out/<name>_<width>x<height>.png. Prints frame timings.

const SHOTS: Array = [   # [seconds, name, panel, mouse target]
	[9.0, "combat", "", ""], [13.0, "hud_tooltip", "", "slot"], [18.6, "inventory", "inventory", "bag"],
	[22.0, "character", "character", "row"], [25.0, "skills", "skills", "skill"], [28.0, "stars", "stars", "star"],
	[31.0, "prayer_objective", "prayer", ""],
]

var _t: float = 0.0
var _i: int = 0


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--shots"):
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		set_process(false)


func _process(delta: float) -> void:
	_t += delta
	if _i >= SHOTS.size():
		get_tree().quit()
		return
	var s: Array = SHOTS[_i]
	var g := get_tree().current_scene as Game
	if _t > float(s[0]) - 0.6:
		_prepare(g, String(s[2]), String(s[3]))
	if _t >= float(s[0]):
		var img: Image = get_viewport().get_texture().get_image()
		var res: Vector2i = DisplayServer.window_get_size()
		img.save_png(ProjectSettings.globalize_path("res://") + "../out/%s_%dx%d.png" % [s[1], res.x, res.y])
		print("SHOT ", s[1], "  fps %.0f  physics %.2f ms  process %.2f ms" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
		for p: GamePanel in [g.skill_panel, g.hosts_panel, g.character_panel, g.inventory_panel]:
			p.visible = false
		_i += 1


func _prepare(g: Game, panel: String, target: String) -> void:
	g.skill_panel.visible = panel == "skills"
	g.hosts_panel.visible = panel == "stars"
	g.character_panel.visible = panel == "character"
	g.inventory_panel.visible = panel == "inventory"
	if panel == "prayer" and not has_meta("moved"):
		set_meta("moved", true)
		g.michael.position = g.objective.points[1]["at"] + Vector2(0, 50)
	var vp: Viewport = get_viewport()
	var to_screen: Transform2D = vp.get_final_transform()
	var p := Vector2(-100, -100)
	match target:
		"slot": p = g.hud.slot_rect(2).get_center()
		"bag": p = g.inventory_panel.position + InventoryPanel.BAG_ORIGIN + Vector2(17, 17)
		"row": p = g.character_panel.position + Vector2(40, 110)
		"skill": p = g.skill_panel.position + Vector2(36, SkillPanel.ROW_Y + 16)
		"star": p = g.hosts_panel.position + HostsPanel.CENTER + SceneData.vec(GameData.hosts["groups"]["vigil"]["stars"][0]["pos"])
	if target != "":
		var screen: Vector2 = to_screen * p
		Input.warp_mouse(screen)
		var ev := InputEventMouseMotion.new()
		ev.position = screen
		Input.parse_input_event(ev)
