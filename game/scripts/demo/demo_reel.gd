class_name DemoReel
extends Node
## --demo / --demo2: the staged scenes of a recorded video, joined by fades, with a DemoBot playing each one.
## Reel 1 (pass 1): the gate ambush, an elite pack, the Glazier. Reel 2 (pass 2): Ottilie in Tallow, relighting a
## road lamp on the Ember Road, the Moth Matron. Scenes that change zone wait for the new zone before setting up.
## Quits at the end.

const DEMO_SEED: int = 7
const REELS: Dictionary = {
	"act1": [[0.0, "gate"], [15.0, "elite"], [29.0, "boss"], [46.0, "end"]],
	"act2": [[0.0, "hub"], [10.5, "road"], [25.0, "hollow"], [45.0, "end"]],
}
const BOSS_LIFE: float = 0.13
const MATRON_LIFE: float = 0.22
const PACK_RADIUS: float = 150.0
const CLEAR_RADIUS: float = 800.0
const ROAD_PROGRESS: float = 0.5
const HOVER_SETTLE: float = 0.3
const ROAD_LEVEL: int = 11
const SPECS: Dictionary = {"sunlash": ["quick_wrist", "quick_wrist", "sear", "sear", "kindling"], "flare": ["wide", "refuel", "wide"],
	"lantern_toss": ["long_burn", "heavy_iron", "beacon"], "moth_swarm": ["brood", "brood", "swift"]}
const PASSIVES: Array[String] = ["wick", "wick", "wick", "trimmed", "trimmed", "steady_hand", "kindler"]

var _reel: Array
var _t: float = 0.0
var _i: int = 0
var _pending: String = ""
var _left: Game


func _ready() -> void:
	seed(DEMO_SEED)
	_reel = REELS["act2" if OS.get_cmdline_user_args().has("--demo2") else "act1"]
	add_child(DemoBot.new())


func _physics_process(delta: float) -> void:
	_t += delta
	var g: Game = Game.current
	if _pending != "" and g != null and g != _left:
		_setup(_pending, g)
		_pending = ""
	if _i < _reel.size() and _t >= float(_reel[_i][0]) and g != null:
		_enter(String(_reel[_i][1]), g)
		_i += 1


func _enter(id: String, g: Game) -> void:
	match id:
		"end":
			get_tree().quit()
		"gate", "hub":
			_setup(id, g)
		"road", "hollow":
			_left = g
			_pending = id
			var to: String = "ember_road" if id == "road" else "moth_hollow"
			g.ui.fade_through(func() -> void: Session.travel(g, to))
		_:
			g.ui.fade_through(func() -> void: _setup(id, g))


func _setup(id: String, g: Game) -> void:
	var h := ShotHelper.new(g)
	match id:
		"elite": _elite(g, h)
		"boss": _boss(g, h, 8, "beacon", BOSS_LIFE)
		"hub": _hub(g, h)
		"road": _road(g, h)
		"hollow": _boss(g, h, 14, "mothwright", MATRON_LIFE)


func _build(g: Game, h: ShotHelper, level: int) -> void:
	h.level_up(level)
	h.gear_up(level)
	for s: String in SPECS:
		h.spec(s, SPECS[s])
	g.player.refill_tonics()
	g.player.life = g.player.stats.max_life()


func _elite(g: Game, h: ShotHelper) -> void:
	_build(g, h, 7)
	h.place_player(_elite_spot(g))
	g.player.light.value = 45.0
	g.hud.caption("Deep in the Glasswood: an elite pack. Outside your light, they hit harder.")


## Beside one elite pack, with other packs around it sent away (a staged scene: one fight at a time).
func _elite_spot(g: Game) -> Vector2:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.rank == "rare":
			_isolate(e)
			return e.global_position + Vector2(-230, 40)
	return g.player.global_position


func _isolate(leader: Enemy) -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var o := n as Enemy
		var d: float = o.global_position.distance_to(leader.global_position)
		if d > PACK_RADIUS and d < CLEAR_RADIUS:
			o.queue_free()


func _boss(g: Game, h: ShotHelper, level: int, mastery: String, life: float) -> void:
	_build(g, h, level)
	g.player.prog.choose_mastery(mastery)
	for id: String in PASSIVES:
		g.player.prog.add_passive(id)
	h.clear_near(100000.0)
	h.place_player(g.layout.circle_center() + Vector2(0, 80))
	g.player.light.value = 70.0
	g.start_boss()
	g.spawner.boss.life = g.spawner.boss.max_life * life


## Home: Nim is back, and Mother Ottilie has something to say about it.
func _hub(g: Game, h: ShotHelper) -> void:
	var c: Campaign = Session.campaign
	while c.step_index("seven_heartbeats") < 4 and not c.is_done("seven_heartbeats"):
		c._advance("seven_heartbeats")
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		if n is Npc and (n as Npc).npc_id == "ottilie":
			h.place_player((n as Npc).global_position + Vector2(120, 160))
			g.input.cursor_override = (n as Npc).global_position + Vector2(0, -20)
			get_tree().create_timer(HOVER_SETTLE).timeout.connect(func() -> void:
				g.input.press()
				g.input.lmb_held = false)


## The road: relight a lamp while the Husks come for it.
func _road(g: Game, h: ShotHelper) -> void:
	_build(g, h, ROAD_LEVEL)
	g.player.prog.choose_mastery("beacon")
	for id: String in PASSIVES:
		g.player.prog.add_passive(id)
	var lamp: Waylamp = g.lamps[0]
	h.clear_near(100000.0)
	h.place_player(lamp.stand_point() + Vector2(40, 30))
	g.player.light.value = 65.0
	lamp.use(g)
	lamp.progress = ROAD_PROGRESS
