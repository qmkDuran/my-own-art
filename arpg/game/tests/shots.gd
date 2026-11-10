extends Node
## --shots: review screenshots into ../out/ (needs a display, e.g. xvfb-run). Uses the demo bot to fight for a while,
## then captures combat, loot, the inventory, the skills panel, the stars panel and the prayer objective.

const SHOTS: Array = [   # [seconds after start, name, setup]
	[13.0, "combat", ""], [19.0, "loot", ""], [24.6, "inventory", ""], [31.8, "skills", ""], [35.0, "stars", ""],
	[40.0, "prayer_objective", "prayer"],
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
	if s[2] in ["skills", "stars"] and _t > float(s[0]) - 0.5:
		g.skill_panel.visible = s[2] == "skills"
		g.hosts_panel.visible = s[2] == "stars"
	if s[2] == "prayer" and _t > float(s[0]) - 2.0 and not has_meta("moved"):
		set_meta("moved", true)
		var p: Dictionary = g.objective.points[1]
		g.michael.position = p["at"] + Vector2(0, 50)
	if _t >= float(s[0]):
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://") + "../out/" + String(s[1]) + ".png")
		print("SHOT ", s[1], "  fps %.0f  physics %.2f ms  process %.2f ms  objects %d" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
		g.skill_panel.visible = false
		g.hosts_panel.visible = false
		_i += 1
