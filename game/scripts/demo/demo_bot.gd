class_name DemoBot
extends Node
## --demo: plays the slice for the recorded video, through the same input paths a player uses (a virtual cursor,
## clicks, skill keys). Three scenes joined by fades: the ambush at the gate (level 1), an elite pack deep in the
## forest (level 5, a few tree points spent), the Glazier (level 8, Beacon mastery). Quits when done.

const THINK: float = 0.12
const SIGHT: float = 420.0
const LOOT_RANGE: float = 200.0
const SCENES: Array[Dictionary] = [{"at": 0.0, "id": "gate"}, {"at": 15.0, "id": "elite"}, {"at": 29.0, "id": "boss"}, {"at": 46.0, "id": "end"}]
const BOSS_LIFE: float = 0.13
const DODGE: float = 140.0
const DEMO_SEED: int = 7
const READ_LINE: float = 1.4
const TOSS_LIGHT: float = 50.0
const PACK_RADIUS: float = 150.0
const CLEAR_RADIUS: float = 800.0
const SPECS: Dictionary = {"sunlash": ["quick_wrist", "quick_wrist", "sear", "sear", "kindling"], "flare": ["wide", "refuel", "wide"],
	"lantern_toss": ["long_burn", "heavy_iron", "beacon"], "moth_swarm": ["brood", "brood", "swift"]}
const PASSIVES: Array[String] = ["wick", "wick", "wick", "trimmed", "trimmed", "steady_hand", "kindler"]

var g: Game
var _t: float = 0.0
var _think: float = 0.0
var _scene: int = 0
var _read_t: float = 0.0


func _ready() -> void:
	g = get_parent() as Game
	seed(DEMO_SEED)


func _physics_process(delta: float) -> void:
	_t += delta
	if _scene < SCENES.size() and _t >= float(SCENES[_scene]["at"]):
		_enter(String(SCENES[_scene]["id"]))
		_scene += 1
	_think -= delta
	if _think <= 0.0:
		_think = THINK
		_decide()


func _enter(id: String) -> void:
	var h := ShotHelper.new(g)
	match id:
		"elite":
			g.ui.fade_through(func() -> void: _elite(h))
		"boss":
			g.ui.fade_through(func() -> void: _boss(h))
		"end":
			get_tree().quit()


func _elite(h: ShotHelper) -> void:
	h.level_up(7)
	for s: String in SPECS:
		h.spec(s, SPECS[s])
	h.place_player(_elite_spot())
	g.player.light.value = 45.0
	g.hud.caption("Deep in the Glasswood: an elite pack. Outside your light, they hit harder.")


## Beside one elite pack, with other packs around it sent away (a staged scene: one fight at a time).
func _elite_spot() -> Vector2:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.rank == "rare":
			_isolate(e)
			var c: Vector2i = g.nav.nearest_free(g.layout.cell_of(e.global_position + Vector2(-230, 40)))
			return g.layout.center_of(c)
	return g.player.global_position


func _isolate(leader: Enemy) -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var o := n as Enemy
		var d: float = o.global_position.distance_to(leader.global_position)
		if d > PACK_RADIUS and d < CLEAR_RADIUS:
			o.queue_free()


func _boss(h: ShotHelper) -> void:
	h.level_up(10)
	g.player.prog.choose_mastery("beacon")
	for id: String in PASSIVES:
		g.player.prog.add_passive(id)
	h.clear_near(100000.0)
	h.place_player(g.layout.circle_center() + Vector2(0, 80))
	g.player.light.value = 70.0
	g.player.refill_tonics()
	g.player.life = g.player.stats.max_life()
	g.start_boss()
	g.spawner.boss.life = g.spawner.boss.max_life * BOSS_LIFE


## One decision: drink, dash, a big skill if it fits the moment, else lash the nearest enemy; loot when calm.
func _decide() -> void:
	var p: Player = g.player
	if g.hud.messages.modal() and not g.hud.messages.end_card:
		_read_t += THINK
		if _read_t >= READ_LINE:
			_read_t = 0.0
			g.hud.messages.advance()
		return
	if p.dead or g.ui.blocking():
		g.input.lmb_held = false
		return
	var foes: Array[Enemy] = _foes()
	if foes.is_empty():
		g.input.lmb_held = false
		_calm()
		return
	var e: Enemy = foes[0]
	var d: float = p.global_position.distance_to(e.global_position)
	if p.life < p.stats.max_life() * 0.5:
		p.drink_tonic()
	if _dodge():
		return
	if _try_skill(foes, e, d):
		return
	g.input.cursor_override = e.global_position + Vector2(0, -12)
	if not g.input.lmb_held:
		g.input.press()


## Step out of a warning circle (away from its centre) if Wickstep is ready.
func _dodge() -> bool:
	for n: Node in get_tree().get_nodes_in_group("telegraphs"):
		var t := n as Telegraph
		if t.covers(g.player.global_position) and g.player.dash_cooldown().x <= 0.0:
			var away: Vector2 = (g.player.global_position - t.global_position).normalized()
			if t.lane != Vector2.ZERO:
				away = t.lane.normalized().orthogonal()
			if away == Vector2.ZERO:
				away = Vector2.DOWN
			g.input.lmb_held = false
			return g.player.dash(g.player.global_position + away * DODGE)
	return false


func _foes() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if not e.dead and e.global_position.distance_to(g.player.global_position) < SIGHT:
			out.append(e)
	out.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(g.player.global_position) < b.global_position.distance_squared_to(g.player.global_position))
	return out


func _try_skill(foes: Array[Enemy], e: Enemy, d: float) -> bool:
	var s: SkillSystem = g.player.skills
	var flare_r: float = (s.skill("flare") as Flare).radius()
	var close: int = foes.filter(func(f: Enemy) -> bool: return f.global_position.distance_to(g.player.global_position) < flare_r).size()
	var key: String = ""
	if close >= 3 and s.block("flare") == "":
		key = "rmb"
	elif d > 130.0 and d < 300.0 and foes.size() >= 3 and g.player.light.value > TOSS_LIGHT and s.block("lantern_toss") == "" \
			and not (s.skill("lantern_toss") as LanternToss).away():
		key = "q"
	elif d > 90.0 and d < 280.0 and s.block("moth_swarm") == "":
		key = "w"
	if key == "":
		return false
	g.input.lmb_held = false
	g.input.cursor_override = e.global_position
	return g.input.use_slot(key)


## Nothing to fight: pick up good loot nearby, talk to Nim once the Glazier is down.
func _calm() -> void:
	for n: Node in get_tree().get_nodes_in_group("ground_items"):
		var gi := n as GroundItem
		if gi.global_position.distance_to(g.player.global_position) < LOOT_RANGE and gi.item["rarity"] != "normal":
			g.input.cursor_override = gi.label_rect().get_center()
			g.input.press()
			g.input.lmb_held = false
			return
	if g.flags.has("nim_free") and not g.flags.has("slice_done"):
		for n: Node in get_tree().get_nodes_in_group("interactables"):
			if n is Npc and (n as Npc).npc_id == "nim":
				(n as Npc).use(g)
				return
