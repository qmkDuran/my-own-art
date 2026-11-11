extends Node
## Dispatches the automated checks from the command line (after `--`): --layout (zone rules over many seeds),
## --ui (HUD and panels at every 16:9 / 16:10 size), --smoke (headless play of the core loop), --shots (review
## screenshots, needs a display), --demo (the bot plays; used for the video). Dormant otherwise.

const MODES: Dictionary = {
	"--layout": "res://tests/layout_test.gd", "--ui": "res://tests/ui_check.gd", "--smoke": "res://tests/smoke_test.gd",
	"--shots": "res://tests/shots_late.gd", "--probe": "res://tests/demo_probe.gd",
	"--balance": "res://tests/balance.gd", "--replay": "res://tests/replay.gd",
}


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--zone="):                      # start in a given zone (tests, screenshots)
			GameData.ensure()
			Session.reset()
			Session.zone_id = a.substr(7)
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


static func out_dir() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--out="):
			return a.substr(6)
	return ProjectSettings.globalize_path("res://") + "../out"


static func has_flag(flag: String) -> bool:
	return OS.get_cmdline_user_args().has(flag)
