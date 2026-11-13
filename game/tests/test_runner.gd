extends Node
## Autoload "TestRunner": dormant in play. With --smoke runs the headless smoke test, with --collision the
## collision and clipping suite, with --shots the review stills (needs a display). Started after "--" on the
## command line.

const MODES: Dictionary = { "--smoke": "res://tests/smoke_test.gd", "--shots": "res://tests/shots.gd",
	"--collision": "res://tests/collision_suite.gd" }


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for flag: String in MODES:
		if args.has(flag):
			var script: GDScript = load(MODES[flag])
			if script == null or not script.can_instantiate():
				get_tree().quit(1)
				return
			var runner: Node = script.new()
			runner.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(runner)
			return


## True in normal play (no test mode on the command line).
static func is_playing() -> bool:
	return not MODES.keys().any(func(flag: String) -> bool: return OS.get_cmdline_user_args().has(flag))


static func arg_value(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return ""
