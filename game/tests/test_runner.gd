extends Node
## Dispatches the automated checks from the command line (after `--`): --layout (zone rules over many seeds),
## --ui (HUD and panels at every 16:9 / 16:10 size), --smoke (headless play of the core loop), --shots (review
## screenshots, needs a display), --demo (the bot plays; used for the video), --tamer-smoke and --tamer-shots (the
## trainer prototype). Dormant otherwise.

const MODES: Dictionary = {
	"--layout": "res://tests/layout_test.gd", "--ui": "res://tests/ui_check.gd", "--smoke": "res://tests/smoke_test.gd",
	"--shots": "res://tests/shots_playtest.gd", "--probe": "res://tests/demo_probe.gd",
	"--balance": "res://tests/balance.gd", "--replay": "res://tests/replay.gd", "--animreel": "res://tests/anim_reel.gd", "--perf": "res://tests/perf.gd", "--devtest": "res://tests/dev_test.gd",
	"--tamer-smoke": "res://tests/tamer_smoke.gd", "--tamer-shots": "res://tests/tamer_shots.gd",
}


const TITLE: String = "res://scenes/title.tscn"
const LANTERNFALL_FLAGS: Array[String] = ["--demo", "--demo2", "--demo3", "--play"]


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--zone="):                      # start in a given zone (tests, screenshots)
			GameData.ensure()
			Session.reset()
			Session.zone_id = a.substr(7)
			if Session.zone_id != "tallow":        # tests set elsewhere start after the opening
				Session.campaign.place(Opening.QUEST, ShotHelper.ALL_STEPS)
				Session.campaign.start("seven_heartbeats")
	if _lanternfall(args):                                  # the project opens the trainer prototype; Lanternfall's modes
		get_tree().change_scene_to_file.call_deferred(TITLE)  # start from its title, as they always did
	if args.has("--demo") or args.has("--demo2") or args.has("--demo3"):
		var reel := DemoReel.new()
		reel.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(reel)
	for flag: String in MODES:
		if args.has(flag):
			var node: Node = (load(MODES[flag]) as GDScript).new()
			node.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(node)
			return


func _lanternfall(args: PackedStringArray) -> bool:
	for a: String in args:
		if (MODES.has(a) or LANTERNFALL_FLAGS.has(a)) and not a.begins_with("--tamer"):
			return true
	return false


static func out_dir() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--out="):
			return a.substr(6)
	return ProjectSettings.globalize_path("res://") + "../out"


static func has_flag(flag: String) -> bool:
	return OS.get_cmdline_user_args().has(flag)
