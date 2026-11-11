extends Node
## Runs the automated checks from the command line (after `--`): --smoke (headless play of the core loop),
## --maps (map rules), --ui (every screen inside the screen and its containers at several sizes), --shots
## (review screenshots; needs a display). Dormant in normal play.

const MODES: Dictionary = {
	"--smoke": "res://tests/smoke_test.gd", "--maps": "res://tests/map_check.gd", "--ui": "res://tests/ui_check.gd",
	"--shots": "res://tests/shots.gd",
}


func active() -> bool:
	return _mode() != ""


func _mode() -> String:
	for flag: String in MODES:
		if OS.get_cmdline_user_args().has(flag):
			return flag
	return ""


func _ready() -> void:
	var flag: String = _mode()
	if flag == "":
		return
	var node: Node = (load(MODES[flag]) as GDScript).new()
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child.call_deferred(node)


static func out_dir() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			return a.substr(6)
	return ProjectSettings.globalize_path("res://") + "../out"


## Finds the game's root node (scene main) once it is ready.
func main() -> Node:
	return get_tree().root.get_node("Main")
