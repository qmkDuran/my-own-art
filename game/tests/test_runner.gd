extends Node
## Autoload "TestRunner": dormant in play. With --smoke runs the headless smoke test, with --duel a long bot duel
## (the bot must never get stuck), with --shots the review stills (needs a display). Started after "--". Tests
## write session logs and the bot's memory to scratch files in user://, never to the real ones.

const TEST_SESSIONS: String = "user://test_sessions"
const TEST_MEMORY: String = "user://test_player_model.json"
const MODES: Dictionary = { "--smoke": "res://tests/smoke_test.gd", "--shots": "res://tests/shots.gd",
	"--duel": "res://tests/duel_probe.gd" }


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if MODES.keys().any(func(flag: String) -> bool: return args.has(flag)):
		SessionLog.directory = ProjectSettings.globalize_path(TEST_SESSIONS)
		Main.memory_path = TEST_MEMORY
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_MEMORY))
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
