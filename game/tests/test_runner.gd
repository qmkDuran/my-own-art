extends Node
## Autoload "TestRunner": dormant in play. With --smoke runs the headless smoke test; with --shots takes the
## review stills (needs a display). Both are started from the command line after "--".

const MODES: Dictionary = { "--smoke": "res://tests/smoke_test.gd", "--shots": "res://tests/shots.gd" }


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for flag: String in MODES:
		if args.has(flag):
			var runner: Node = (load(MODES[flag]) as GDScript).new()
			runner.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(runner)
			return


static func arg_value(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return ""
