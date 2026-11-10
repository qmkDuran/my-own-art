extends SceneBase
## The new earth outside the city (Isa 65:17; Rev 21:1, 24-26): the peaceable animals (Isa 11:6-7; 65:25),
## houses being built and lived in, a vineyard being harvested (Isa 65:21-22), the desert blossoming (Isa 35:1),
## trees clapping their hands (Isa 55:12). Geometry from res://art/earth/layout.json, content from res://data/earth.json.

const ART: String = "res://art/earth/"
const CITY_SCENE: String = "res://main.tscn"
const TREE_FRAMES: int = 8
const TREE_OFFSET := Vector2(-64, -112)
const TREE_TRUNK := Vector2(28, 10)
const HOUSE_FOOT_FRAC: float = 0.84
const HOUSE_FOOT := Vector2(0, 40)          # depth of a house footprint, ending 4 px above its base line
const VINE_FOOT_DEPTH: float = 8.0
const HAY_FOOT := Vector2(36, 10)
const WALL_LIGHT := Vector2(960, 70)
const GATE_GLOW := Vector2(858, 20)
const MOTES: int = 200
const WALL_LIGHT_SCALE := Vector2(1.5, 0.7)
const ARRIVAL_FADE: float = 1.4

var _layout: Dictionary
var _herd: Herd
var _builder: Builder
var _trees: Array[Sprite2D] = []
var _stream_sound: AudioStreamPlayer
var _leaving: bool = false
var _time: float = 0.0


func _data_path() -> String:
	return "res://data/earth.json"


func _map_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, SceneData.vec(SceneData.load_json(ART + "layout.json")["map_size"]))


func _build_background() -> void:
	_layout = SceneData.load_json(ART + "layout.json")
	SpriteFactory.sprite(self, ART + "ebg.png", Vector2.ZERO, -20)
	# The light of the city spills out through its open gate over the land (Rev 21:24).
	SpriteFactory.sprite(self, "res://art/glow_gate.png", GATE_GLOW, 5, true)
	var wall_light := SpriteFactory.glow(self, "res://art/throne/throne_glow.png", WALL_LIGHT, WALL_LIGHT_SCALE, -5, Vector2(0, -60))
	wall_light.modulate.a = 0.75


func _build_world() -> void:
	_build_houses()
	_build_vines()
	var hay: Vector2 = SceneData.vec(_layout["hay"])
	SpriteFactory.grounded(world, ART + "hay.png", hay)
	Blockers.footprint(self, hay, HAY_FOOT)
	_herd = Herd.new()
	add_child(_herd)
	_herd.build(_layout["animals"], world)
	_build_trees()
	Blockers.add_all(self, _layout["stream_rects"])
	Blockers.add_all(self, data["colliders"])
	_builder = Builder.new()
	add_child(_builder)
	_builder.build(data["builder"])
	SpriteFactory.grounded(world, ART + "basket.png", SceneData.vec(data["basket"]))


## Houses being built and lived in (Isa 65:21): the footprint is most of the base, so doors stay reachable.
func _build_houses() -> void:
	for h: Array in _layout["houses"]:
		var s := SpriteFactory.grounded(world, ART + "%s.png" % h[0], Vector2(h[1], h[2]))
		var w: float = s.texture.get_width() * HOUSE_FOOT_FRAC
		Blockers.add(self, Rect2(float(h[1]) - w / 2.0, float(h[2]) - HOUSE_FOOT.y - 4.0, w, HOUSE_FOOT.y))


## Rows of vines on trellises, built from repeated segments with posts at both ends.
func _build_vines() -> void:
	var tex: Texture2D = load(ART + "vines.png")
	var seg: int = tex.get_width() - 2
	var segments: int = int(_layout["vine_segments"])
	for row: Array in _layout["vine_rows"]:
		for k: int in segments:
			var v := Sprite2D.new()
			v.texture = tex
			v.centered = false
			v.offset = Vector2(0, -tex.get_height())
			v.position = Vector2(int(row[0]) + k * seg, row[1])
			world.add_child(v)
		Blockers.add(self, Rect2(row[0], float(row[1]) - VINE_FOOT_DEPTH, seg * segments, VINE_FOOT_DEPTH))


## Trees of the field that sway gently: "all the trees of the field shall clap their hands" (Isa 55:12).
func _build_trees() -> void:
	for t: Array in _layout["trees"]:
		var s := Sprite2D.new()
		s.texture = load(ART + "%s.png" % t[0])
		s.hframes = TREE_FRAMES
		s.centered = false
		s.offset = TREE_OFFSET
		s.position = Vector2(t[1], t[2])
		s.set_meta("phase", randf_range(0.0, 8.0))
		world.add_child(s)
		_trees.append(s)
		Blockers.footprint(self, s.position, TREE_TRUNK, 3.0)


func _build_overlay() -> void:
	Fx.glow_motes(self, _map_bounds(), MOTES)


func _setup_captions() -> void:
	var t: Dictionary = data["title"]
	captions.show_title(t["text"], float(t["y"]), float(t["hold"]))
	captions.zone_resolver = CaptionBar.zone_lookup(data["zones"], data["default_zone"])
	captions.wait_for_title = true


func _start_audio() -> void:
	Audio.play_music("pastoral_music", -11.0, 2.0)
	Audio.loop_player(self, "air", -28.0)
	_stream_sound = Audio.loop_player(self, "river", -40.0)
	player.stepped.connect(func(_at: Vector2) -> void:
		Audio.sfx("step_grass%d" % randi_range(0, 1), -20.0, randf_range(0.9, 1.1)))


## Out through the pearl gate, onto the land where the nations walk in the light of the city.
func _begin() -> void:
	Travel.arriving = ""
	captions.fade.color.a = 1.0
	create_tween().tween_property(captions.fade, "color:a", 0.0, ARRIVAL_FADE)
	if Travel.demo or args.has("--demo"):
		Travel.demo = false
		run_demo("demo")


func _tick(delta: float) -> void:
	_time += delta
	for t: Sprite2D in _trees:
		t.frame = int(_time * 3.0 + float(t.get_meta("phase"))) % TREE_FRAMES
	_herd.animate(_time, delta, player.global_position)
	_builder.animate(_time, player.global_position)
	var near_stream: float = player.global_position.distance_to(SceneData.vec(data["stream_centre"]))
	_stream_sound.volume_db = lerpf(-16.0, -40.0, clampf(near_stream / float(data["stream_hear"]), 0.0, 1.0))
	if not _leaving and _in_passage(player.global_position):
		_enter_city()


func _in_passage(p: Vector2) -> bool:
	var g: Dictionary = data["gate"]
	return p.y < float(g["passage_end"]) + 2.0 and p.x > float(g["passage"][0]) and p.x < float(g["passage"][1])


## Back in through the gate of one pearl.
func _enter_city() -> void:
	_leaving = true
	player.frozen = true
	Audio.sfx("gate_chime", -7.0)
	var tw := create_tween()
	tw.tween_property(captions.fade, "color:a", 1.0, 1.2)
	tw.tween_callback(func() -> void:
		Travel.arriving = "earth"
		get_tree().change_scene_to_file(CITY_SCENE))
