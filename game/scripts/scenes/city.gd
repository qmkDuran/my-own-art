extends SceneBase
## One screen of the New Jerusalem (Revelation 21-22): the street of gold, the river of the water of life
## flowing from the throne's light, the trees of life, the jasper wall and the gate of one pearl.
## Content lives in res://data/city.json; art numbers mirror art/build_scene.py.

const RIPPLE_W: float = 240.0
const RIPPLE_SPEED_A: float = 14.0
const RIPPLE_SPEED_B: float = 23.0
const RIPPLE_B_OFFSET: float = 60.0
const TREE_OFFSET := Vector2(-64, -112)       # tree sprites: trunk base at (64, 112)
const TREE_TRUNK := Vector2(28, 10)
const TREE_FADE_ALPHA: float = 0.55
const RIVER_HEAR: float = 220.0
const EARTH_SCENE: String = "res://earth.tscn"

var _trees: Array[Sprite2D] = []
var _water_a: Sprite2D
var _water_b: Sprite2D
var _throne_glow: Sprite2D
var _gate_glow: Sprite2D
var _river_sound: AudioStreamPlayer
var _in_light: bool = false
var _time: float = 0.0


func _data_path() -> String:
	return "res://data/city.json"


func _build_background() -> void:
	SpriteFactory.sprite(self, "res://art/bg.png", Vector2.ZERO, -10)
	_water_a = _water_layer("res://art/water_a.png", 1.0)
	_water_b = _water_layer("res://art/water_b.png", 0.8)
	_throne_glow = SpriteFactory.sprite(self, "res://art/glow_throne.png", Vector2(-40, 80), -8, true)
	SpriteFactory.sprite(self, "res://art/bridge.png", Vector2(424, 268), -7)
	_gate_glow = SpriteFactory.sprite(self, "res://art/glow_gate.png", Vector2(380, 20), 5, true)


func _water_layer(path: String, alpha: float) -> Sprite2D:
	var river: Array = data["river"]
	var s := SpriteFactory.sprite(self, path, Vector2(0, float(river[0])), -9)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, VIEW.x, float(river[1]) - float(river[0]))
	s.modulate.a = alpha
	return s


func _build_world() -> void:
	for t: Array in data["trees"]:
		var s := Sprite2D.new()
		s.texture = load("res://art/%s.png" % t[0]) as Texture2D
		s.centered = false
		s.flip_h = t[3]
		s.offset = TREE_OFFSET
		s.position = Vector2(float(t[1]), float(t[2]))
		world.add_child(s)
		_trees.append(s)
		Blockers.footprint(self, s.position, TREE_TRUNK, 3.0)
	Blockers.add_all(self, data["colliders"])


func _build_overlay() -> void:
	for m: Array in data["motes"]:
		Fx.motes(self, SceneData.rect(m), int(m[4]), Vector2(float(m[5]), float(m[6])), SceneData.color(m[7]))


func _setup_captions() -> void:
	super()
	if Travel.arriving == "earth" or args.has("--earth-demo"):
		captions.title.modulate.a = 0.0


func _start_audio() -> void:
	# Warm pads and harp, calm air, and the river (louder the nearer you are).
	Audio.play_music("city_music", -11.0)
	Audio.loop_player(self, "air", -27.0)
	_river_sound = Audio.loop_player(self, "river", -40.0)
	player.stepped.connect(_on_step)


func _on_step(at: Vector2) -> void:
	if _on_grass(at):
		Audio.sfx("step_grass%d" % randi_range(0, 1), -20.0, randf_range(0.9, 1.1))
	else:
		Audio.sfx("step_gold%d" % randi_range(0, 2), -22.0, randf_range(0.97, 1.03))


func _on_grass(at: Vector2) -> bool:
	var street: Array = data["street_x"]
	if at.x >= float(street[0]) and at.x <= float(street[1]):
		return false
	for bank: Array in data["banks"]:
		if at.y > float(bank[0]) and at.y < float(bank[1]):
			return true
	return false


func _begin() -> void:
	if Travel.arriving == "earth":
		_arrive_from_earth()
	elif args.has("--earth-demo"):
		Travel.demo = true
		run_demo("earth_demo")
	elif args.has("--demo"):
		run_demo("demo")


func _tick(delta: float) -> void:
	_time += delta
	# The river flows out of the throne (off-screen left) toward the right; ripples step in whole pixels.
	_water_a.region_rect.position.x = -floorf(fmod(_time * RIPPLE_SPEED_A, RIPPLE_W))
	_water_b.region_rect.position.x = -floorf(fmod(_time * RIPPLE_SPEED_B, RIPPLE_W)) + RIPPLE_B_OFFSET
	_throne_glow.modulate.a = 0.85 + 0.15 * sin(_time * 0.9)
	_gate_glow.modulate.a = 0.8 + 0.2 * sin(_time * 1.3 + 1.0)
	_update_tree_fade(delta)
	_update_river_sound()
	if not _in_light and _in_passage(player.global_position):
		_enter_light()


func _update_tree_fade(delta: float) -> void:
	# A canopy turns see-through while the man walks behind it, so he is never lost from view.
	for t: Sprite2D in _trees:
		var rel: Vector2 = player.global_position - t.position
		var behind: bool = rel.y < -2.0 and rel.y > -100.0 and absf(rel.x) < 54.0
		t.modulate.a = move_toward(t.modulate.a, TREE_FADE_ALPHA if behind else 1.0, delta * 3.0)


func _update_river_sound() -> void:
	var river: Array = data["river"]
	var y: float = player.global_position.y
	var dist: float = maxf(0.0, maxf(float(river[0]) - y, y - float(river[1])))
	_river_sound.volume_db = lerpf(-13.0, -34.0, clampf(dist / RIVER_HEAR, 0.0, 1.0))


func _in_passage(p: Vector2) -> bool:
	var g: Dictionary = data["gate"]
	return p.y < float(g["passage_end"]) + 2.0 and p.x > float(g["passage"][0]) and p.x < float(g["passage"][1])


func _enter_light() -> void:
	# The gates are never shut (Rev 21:25): through the open pearl lies the new earth (Rev 21:24-26).
	_in_light = true
	captions.suppressed = true
	Audio.sfx("gate_chime", -7.0)
	player.frozen = true
	player.autopilot.clear()
	var g: Dictionary = data["gate"]
	captions.show_verse(g["verse"], float(g["verse_y"]), 1.2)
	var tw := create_tween()
	tw.tween_property(captions.fade, "color:a", 1.0, 1.2)
	tw.tween_interval(2.2)
	tw.tween_callback(func() -> void:
		Travel.arriving = "city"
		get_tree().change_scene_to_file(EARTH_SCENE))


func _arrive_from_earth() -> void:
	# Coming back in through the pearl gate: start just inside it, out of the light.
	Travel.arriving = ""
	player.global_position = SceneData.vec(data["gate"]["respawn"])
	player.face("down")
	captions.fade.color.a = 1.0
	create_tween().tween_property(captions.fade, "color:a", 0.0, 1.2)
