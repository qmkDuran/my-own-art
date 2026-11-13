extends Node
## Autoload "TestRunner": dormant in play. Test modes, started after "--" on the command line: --smoke (headless
## smoke test), --collision (collision and clipping suite), --perf (rendered performance probe), --balance (the
## balance bot; with --stability, the back-to-back stability run), --sequence (an effect still sequence) and
## --shots (review stills). --perf, --sequence and --shots need a display.

const MODES: Dictionary = { "--smoke": "res://tests/smoke_test.gd", "--shots": "res://tests/shots.gd",
	"--collision": "res://tests/collision_suite.gd", "--perf": "res://tests/perf_probe.gd",
	"--balance": "res://tests/balance_suite.gd", "--sequence": "res://tests/vfx_sequence.gd" }


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
