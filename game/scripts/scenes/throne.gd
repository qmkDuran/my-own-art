extends SceneBase
## The throne room of heaven (Revelation 4-5). Geometry from res://art/throne/layout.json, content from
## res://data/throne.json. The One on the throne is shown only as light (Rev 4:2-3); no figure is drawn.

const ART: String = "res://art/throne/"
const LAMB_OFFSET := Vector2(-24, -41)
const LAMB_GLOW_SCALE := Vector2(0.14, 0.16)
const BOLT_MIN: float = 1.8
const BOLT_MAX: float = 4.2
const LAMPS_HEAR: float = 300.0
const KNEEL_FADE_IN: float = 0.8
const KNEEL_FADE_OUT: float = 0.6

var _layout: Dictionary
var _rng := RandomNumberGenerator.new()
var _host: HeavenlyHost
var _light: ThroneLight
var _creatures: LivingCreatures
var _elders: ElderCircle
var _time: float = 0.0
var _next_bolt: float = 1.5
var _next_worship: float = 0.0
var _lamps_sound: AudioStreamPlayer
var _holy: AudioStreamPlayer


func _data_path() -> String:
	return "res://data/throne.json"


func _build_background() -> void:
	_layout = SceneData.load_json(ART + "layout.json")
	_rng.seed = int(data["rng_seed"])
	_next_worship = float(data["worship"]["first"])
	SpriteFactory.sprite(self, ART + "tbg.png", Vector2.ZERO, -20)
	_host = HeavenlyHost.new()
	add_child(_host)
	_host.build(data["angel_rows"], float(_layout["throne"][0]), _rng)
	_light = ThroneLight.new()
	add_child(_light)
	_light.build(SceneData.vec(_layout["light"]), SceneData.vec(_layout["throne"]), _layout["lamps"], _rng)


func _build_world() -> void:
	_creatures = LivingCreatures.new()
	add_child(_creatures)
	_creatures.build(_layout["creatures"], world)
	_add_lamb()
	_elders = ElderCircle.new()
	add_child(_elders)
	_elders.build(_layout["elders"], _layout["crown_slots"], world)
	_add_colliders()


## The Lamb, standing in the midst (Rev 5:6).
func _add_lamb() -> void:
	var lamb_pos: Vector2 = SceneData.vec(_layout["lamb"])
	var lamb := SpriteFactory.sprite(world, ART + "lamb.png", lamb_pos)
	lamb.offset = LAMB_OFFSET
	SpriteFactory.glow(self, ART + "throne_glow.png", lamb_pos + Vector2(0, -14), LAMB_GLOW_SCALE, -11)


## Solid ground truth: dais + throne, the lamp row, the horizon of light, screen edges.
func _add_colliders() -> void:
	var dais: Array = _layout["dais"]
	Blockers.add(self, Rect2(dais[0], 0, int(dais[1]) - int(dais[0]), int(dais[3]) + 2))
	var lamps: Array = _layout["lamps"]
	Blockers.add(self, Rect2(int(lamps[0][0]) - 8, int(lamps[0][1]) - 8, int(lamps[-1][0]) - int(lamps[0][0]) + 16, 12))
	Blockers.add(self, Rect2(-40, -100, VIEW.x + 80, int(_layout["horizon"]) + 150))
	Blockers.add(self, Rect2(-40, 0, 40, VIEW.y))
	Blockers.add(self, Rect2(VIEW.x, 0, 40, VIEW.y))
	Blockers.add(self, Rect2(0, VIEW.y - 2, VIEW.x, 40))


func _build_overlay() -> void:
	Fx.sparkles(self, VIEW / 2.0, VIEW / 2.0, 90)
	Fx.sparkles(self, SceneData.vec(_layout["throne"]) + Vector2(0, 30), Vector2(120, 90), 40)


func _setup_captions() -> void:
	super()
	captions.zone_resolver = _zone_caption


func _start_audio() -> void:
	# Wordless choir and organ pedal with harps; quiet flicker of the seven lamps.
	Audio.play_music("throne_music", -9.0)
	_lamps_sound = Audio.loop_player(self, "lamps", -22.0)
	_holy = AudioStreamPlayer.new()
	_holy.stream = load("res://audio/holy.wav") as AudioStream
	add_child(_holy)
	player.stepped.connect(func(_at: Vector2) -> void:
		Audio.sfx("step_gold%d" % randi_range(0, 2), -24.0, randf_range(1.1, 1.18)))


func _begin() -> void:
	if args.has("--closeup"):
		_start_closeup()
	elif args.has("--demo"):
		_next_worship = float(data["worship"]["first_in_demo"])
		run_demo("demo")


func _on_action() -> void:
	toggle_kneel()


func _tick(delta: float) -> void:
	_time += delta
	_light.animate(_time)
	_host.animate(_time)
	_creatures.animate(_time, player.global_position)
	_next_bolt -= delta
	if _next_bolt <= 0.0:
		_light.lightning(captions.fade)
		_next_bolt = _rng.randf_range(BOLT_MIN, BOLT_MAX)
	_next_worship -= delta
	if _next_worship <= 0.0:
		_worship()
		_next_worship = float(data["worship"]["every"])
	var lamp_dist: float = player.global_position.distance_to(Vector2(480, 236))
	_lamps_sound.volume_db = lerpf(-20.0, -32.0, clampf(lamp_dist / LAMPS_HEAR, 0.0, 1.0))


func _worship() -> void:
	captions.forced = data["worship"]["text"]
	var seconds: float = _elders.worship(_rng)
	get_tree().create_timer(seconds).timeout.connect(func() -> void: captions.forced = "")


## Kneel in worship (E): the music swells into "Holy, Holy, Holy" (NICAEA, Dykes 1861), instrumental; Rev 4:8.
func toggle_kneel() -> void:
	player.set_kneel(not player.kneeling)
	captions.suppressed = player.kneeling
	var music := create_tween()
	if player.kneeling:
		Audio.set_music_volume(-22.0, 1.5)
		_holy.volume_db = -30.0
		_holy.play()
		music.tween_property(_holy, "volume_db", -6.0, 2.0)
		captions.show_verse(data["kneel"]["text"], float(data["kneel"]["y"]), KNEEL_FADE_IN)
	else:
		Audio.restore_music(2.0)
		music.tween_property(_holy, "volume_db", -40.0, 1.8)
		music.tween_callback(_holy.stop)
		captions.hide_title(KNEEL_FADE_OUT)


## Demo event: stop walking, face the throne and kneel.
func demo_kneel() -> void:
	player.autopilot.clear()
	player.face("up")
	toggle_kneel()


func _zone_caption(p: Vector2) -> String:
	var r: Dictionary = data["zone_rules"]
	var text: Dictionary = data["zone_text"]
	var cx: float = float(r["centre_x"])
	if p.distance_to(SceneData.vec(_layout["lamb"])) < float(r["lamb_reach"]):
		return text["lamb"]
	if p.y < float(r["lamps_below_y"]) and absf(p.x - cx) < float(r["lamps_half_width"]):
		return text["lamps"]
	var kind: String = _creatures.near(p, float(r["creature_reach"]))
	if kind != "":
		return data["creature_text"][kind]
	if absf(p.x - cx) > float(r["elders_beyond_x"]):
		return text["elders"]
	if p.y > float(r["sea_below_y"]):
		return text["sea"]
	return text["throne"]


## Recording aid: a slow 3x camera tour of the wings (angel host, then the living creatures).
func _start_closeup() -> void:
	captions.caption.visible = false
	captions.title.visible = false
	var c: Dictionary = data["closeup"]
	var stops: Array[Vector2] = SceneData.points(c["stops"])
	camera.tour(stops, int(c["screen_scale"]), float(c["move"]), float(c["hold"]), get_tree().quit)
