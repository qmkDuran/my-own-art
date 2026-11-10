class_name SceneBase
extends Node2D
## Common skeleton of every playable scene: loads the scene's data, builds a y-sorted world with the player
## and the people in it, the caption UI, talk, audio and camera, and routes input (Esc = menu).
## Subclasses override the hooks (`_build_background`, `_build_world`, `_start_audio`, `_on_action`, `_tick`, `_begin`).

const VIEW := Vector2(960, 540)
const MENU: String = "res://menu.tscn"

var data: Dictionary
var player: Player
var world: Node2D
var captions: CaptionBar
var talk: TalkSystem
var camera: CameraRig
var args: PackedStringArray


## Path of this scene's data file (res://data/*.json).
func _data_path() -> String:
	return ""


func _ready() -> void:
	args = OS.get_cmdline_user_args()
	data = SceneData.load_json(_data_path())
	InputSetup.ensure()
	_build_background()
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_world()
	_spawn_player()
	_spawn_people()
	_build_overlay()
	captions = CaptionBar.new(float(data["caption_y"]), data["hint"])
	add_child(captions)
	talk = TalkSystem.new(captions)
	for n: Node in world.get_children():
		if n is Npc:
			talk.add(n)
	camera = CameraRig.new()
	camera.bounds = _map_bounds()
	camera.target = player
	for r: Array in data.get("rooms", []):
		camera.rooms.append(SceneData.rect(r))
	add_child(camera)
	_setup_captions()
	_start_audio()
	_begin()


func _spawn_player() -> void:
	player = Player.new()
	player.position = SceneData.vec(data["player_start"])
	world.add_child(player)
	if data.has("player_face"):
		player.face(data["player_face"])


## People from data: "people": [[person, x, y, mode, facing, verse], ...], "walkers": [{sheet, loop, verse, steps}, ...]
func _spawn_people() -> void:
	for p: Array in data.get("people", []):
		world.add_child(Npc.standing(int(p[0]), Vector2(float(p[1]), float(p[2])), p[3], p[4], p[5]))
	for w: Dictionary in data.get("walkers", []):
		var start: Vector2 = SceneData.vec(w["start"]) if w.has("start") else Vector2.INF
		world.add_child(Npc.walker(w["sheet"], SceneData.points(w["loop"]), w["verse"], w.get("steps", ""),
			w.get("procession", false), start))


func _setup_captions() -> void:
	var t: Dictionary = data["title"]
	captions.show_title(t["text"], float(t["y"]))
	captions.zone_resolver = CaptionBar.zone_lookup(data.get("zones", []), data.get("default_zone", ""))


func _unhandled_input(event: InputEvent) -> void:
	if InputSetup.is_escape(event):
		get_tree().change_scene_to_file(MENU)
	elif event.is_action_pressed("zoom_in"):
		camera.step(1)
	elif event.is_action_pressed("zoom_out"):
		camera.step(-1)
	elif event.is_action_pressed("zoom_cycle"):
		camera.cycle()
	elif (event.is_action_pressed("talk") or event.is_action_pressed("worship")) and player.autopilot.is_empty():
		_on_action()


func _process(delta: float) -> void:
	_tick(delta)
	captions.update(player.global_position, delta)


## Run the scripted demo stored under `key` in the scene data.
func run_demo(key: String) -> void:
	DemoRecorder.run(self, player, data[key])


## Talk to whoever is nearest (also used by demo events).
func talk_nearest() -> void:
	talk.talk(player.global_position)


## Demo events: integer zoom steps (overview / normal / close).
func zoom_overview() -> void:
	camera.go_to(camera.min_scale())


func zoom_normal() -> void:
	camera.go_to(CameraRig.NORMAL)


func zoom_close() -> void:
	camera.go_to(CameraRig.SCALES[-1])


# ------------------------------------------------------------------ hooks
## The playable map in world pixels (one screen unless a scene says otherwise).
func _map_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, VIEW)



func _build_background() -> void:
	pass


func _build_world() -> void:
	pass


## Things drawn over the world (glows, particles), built after the people.
func _build_overlay() -> void:
	pass


func _start_audio() -> void:
	pass


## E pressed (talk by default).
func _on_action() -> void:
	talk_nearest()


func _tick(_delta: float) -> void:
	pass


## Arrival, demos, etc. once everything is built.
func _begin() -> void:
	pass
