extends Node
## Headless smoke test (autoload "SmokeTest", dormant unless the user arg --smoke is given): loads the menu and
## each scene, runs it ~5 s, and checks the essentials: player spawned, colliders exist, talk / kneel works.
## Run:  tests/run_smoke.sh   (godot --headless --fixed-fps 60 --path game -- --smoke)

const FRAMES_PER_SCENE: int = 300
const SCENES: Array = [
	["res://menu.tscn", "menu"],
	["res://main.tscn", "talk"],
	["res://throne.tscn", "kneel"],
	["res://earth.tscn", "talk"],
]

var _failures: Array[String] = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--smoke"):
		_run.call_deferred()


func _run() -> void:
	for s: Array in SCENES:
		get_tree().change_scene_to_file(s[0])
		for i: int in FRAMES_PER_SCENE:
			await get_tree().process_frame
		_check(s[0], s[1])
	if _failures.is_empty():
		print("SMOKE PASS: ", SCENES.size(), " scenes")
		get_tree().quit(0)
	else:
		for f: String in _failures:
			print("SMOKE FAIL: ", f)
		get_tree().quit(1)


func _check(path: String, kind: String) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		_failures.append(path + ": scene did not load")
		return
	if kind == "menu":
		_expect(scene.find_children("*", "Label", true, false).size() >= 3, path + ": menu labels missing")
		return
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	_expect(player != null, path + ": no player")
	_expect(scene.find_children("*", "StaticBody2D", true, false).size() > 0, path + ": no colliders")
	if player == null:
		return
	if kind == "talk":
		_check_talk(scene as SceneBase, player, path)
	elif kind == "kneel":
		(scene as SceneBase)._on_action()
		_expect(player.kneeling, path + ": kneeling did not start")
	print("SMOKE ok: ", path)


func _check_talk(scene: SceneBase, player: Player, path: String) -> void:
	_expect(not scene.talk.people.is_empty(), path + ": no people")
	if scene.talk.people.is_empty():
		return
	var someone: Npc = scene.talk.people[0]
	player.global_position = someone.global_position + Vector2(0, 20)
	_expect(scene.talk.talk(player.global_position) == someone, path + ": talking to the nearest person failed")


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
