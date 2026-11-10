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

const TRANSITION_FRAMES: int = 330
## [scene to start in, put the player here, expected scene after, expected arrival spot (or none), label]
const TRANSITIONS: Array = [
	["res://main.tscn", Vector2(6, 308), "ThroneRoom", Vector2(480, 500), "garden river light -> throne"],
	["", Vector2(480, 532), "Main", Vector2(34, 308), "throne -> back to the garden riverside"],
	["res://main.tscn", Vector2(30, 836), "ThroneRoom", Vector2(480, 500), "great street light -> throne"],
	["", Vector2(480, 532), "Main", Vector2(96, 840), "throne -> back to the great street"],
	["res://main.tscn", Vector2(482, 130), "NewEarth", Vector2(960, 198), "pearl gate -> new earth"],
	["", Vector2(960, 130), "Main", Vector2(482, 186), "new earth gate -> city"],
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
	await _check_transitions()
	if _failures.is_empty():
		print("SMOKE PASS: ", SCENES.size(), " scenes + ", TRANSITIONS.size(), " transitions")
		get_tree().quit(0)
	else:
		for f: String in _failures:
			print("SMOKE FAIL: ", f)
		get_tree().quit(1)


## Walk through each way between scenes: put the player in the way, wait for the fade, check where they arrive.
func _check_transitions() -> void:
	for t: Array in TRANSITIONS:
		if t[0] != "":
			get_tree().change_scene_to_file(t[0])
			for i: int in 30:
				await get_tree().process_frame
		var player: Player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			_failures.append(t[4] + ": no player")
			continue
		player.global_position = t[1]
		for i: int in TRANSITION_FRAMES:
			await get_tree().process_frame
		var scene: Node = get_tree().current_scene
		var arrived: Player = get_tree().get_first_node_in_group("player") as Player
		var ok: bool = scene != null and scene.name == t[2] and arrived != null and arrived.global_position.distance_to(t[3]) < 4.0
		_expect(ok, "%s: ended in %s at %s" % [t[4], scene.name if scene else "?", arrived.global_position if arrived else "?"])
		if ok:
			print("SMOKE ok: ", t[4])


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
