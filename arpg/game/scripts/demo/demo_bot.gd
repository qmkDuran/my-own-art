class_name DemoBot
extends Node
## --demo: plays the game for the recording through the same controls a player uses: a virtual cursor that glides to
## its target, the left button held to walk or clicked on an enemy, Shift held to stand and strike when surrounded,
## RMB and Q W E R for skills. Picks up items, answers a prayer, spends its points, shows the inventory once.

const SEEK: float = 420.0
const LOOT_GRAB: float = 240.0
const SAFE: float = 110.0
const START_XP: float = 1250.0
const QUIT_AFTER: float = 46.0
const DASH_EVERY: float = 2.6             # the --dash-demo shows Dash often
const CURSOR_SPEED: float = 1100.0
const WALK_LEAD: float = 140.0          # a player holds the cursor a little ahead of Michael, not at the destination
const TIMELINE: Array = [[17.0, "open_inventory"], [18.4, "equip"], [19.8, "close"], [27.0, "open_skills"], [29.5, "close"],
	[31.0, "open_travel"], [32.5, "travel_rift"]]
const GIVE_UP: float = 3.0                # an item it cannot reach is left

var g: Game
var m: Michael
var _t: float = 0.0
var _step: int = 0
var _think: float = 0.0
var _cursor_goal: Vector2
var _clicked: Demon
var _taking: GroundItem
var _taking_t: float = 0.0
var _skip: Array = []
var _dash_t: float = 3.0


func setup(game: Game) -> void:
	g = game
	m = game.michael
	seed(4)
	m.prog.leveled.connect(func(_l: int) -> void: _spend_points())
	m.prog.add_xp(START_XP)                     # the recording starts a few levels in, so every skill is shown
	m.life = m.stats.v("life")
	_cursor_goal = m.global_position + Vector2(60, -20)
	g.cursor_override = _cursor_goal


func _physics_process(delta: float) -> void:
	_t += delta
	g.cursor_override = g.cursor_override.move_toward(_cursor_goal, CURSOR_SPEED * delta)
	if _step < TIMELINE.size() and _t >= float(TIMELINE[_step][0]):
		_do(String(TIMELINE[_step][1]))
		_step += 1
	if _t > (21.0 if OS.get_cmdline_user_args().has("--dash-demo") else QUIT_AFTER) and not OS.get_cmdline_user_args().has("--shots"):   # the screenshot pass quits by itself
		get_tree().quit()
	if (g.panels_open() and not OS.get_cmdline_user_args().has("--shots")) or _t < 2.0:
		g.lmb = false
		m.stop()
		return
	_think -= delta
	_dash_t -= delta
	if OS.get_cmdline_user_args().has("--dash-demo") and _dash_t <= 0.0 and m.dodge_ready() <= 0.0:
		_dash_t = DASH_EVERY
		var d: Demon = _nearest_demon(220.0)
		var away: Vector2 = (m.global_position - d.global_position).normalized() if d != null else Vector2(1, 0)
		g.cursor_override = m.global_position + away.rotated(randf_range(-0.6, 0.6)) * 120.0 + Vector2(0, -20)
		_cursor_goal = g.cursor_override
		m.stop()
		m.aim_at(g.cursor_override)
		m.dodge()
		g.hud.flash("dash")
		return
	if _think > 0.0:
		return
	_think = 0.1
	_act()


## Aim the cursor; true once it has arrived (a click only lands where the cursor is).
func _point(at: Vector2) -> bool:
	_cursor_goal = at
	return g.cursor_override.distance_to(at) < 6.0


func _act() -> void:
	g.stand = false
	var close_item: GroundItem = _nearest_item(LOOT_GRAB)
	if close_item != _taking:
		_taking = close_item
		_taking_t = 0.0
	_taking_t += 0.1
	if close_item != null and _taking_t > GIVE_UP:
		_skip.append(close_item)
		close_item = null
	if close_item != null and _nearest_demon(SAFE) == null:
		_take(close_item)
		return
	var target: Demon = _nearest_demon(SEEK)
	if target != null:
		_fight(target)
		return
	_clicked = null
	for p: Dictionary in g.objective.points:
		if int(p["state"]) == PrayerObjective.STATE_WAITING:
			_walk(p["at"])
			return
	_walk(SceneData.vec(GameData.zone["final_pack"]["at"]))


## Click an item's name (only names pick items up).
func _take(it: GroundItem) -> void:
	_clicked = null
	g.lmb = false
	if _point(it.label_rect().get_center()) and g.get("_pickup_target") != it:
		g.lmb_down()
		g.lmb = false


## Hold the left button with the cursor a little ahead of Michael toward the goal.
func _walk(to: Vector2) -> void:
	_clicked = null
	var lead: Vector2 = m.global_position + (to - m.global_position).limit_length(WALK_LEAD)
	_point(lead)
	if not g.lmb:
		g.lmb_down(false)                         # walking: the cursor may pass over a crate or a stone


func _fight(d: Demon) -> void:
	var aim: Vector2 = d.global_position + Vector2(0, -20)
	if not _point(aim):
		return
	var dist: float = m.global_position.distance_to(d.global_position)
	var sk: SkillSystem = m.skills
	if m.life < m.stats.v("life") * 0.55 or (_bolt_near() and sk.can_use("shield")):
		g.press_skill("shield")
	if _count_within(200.0) >= 4 and sk.can_use("trumpet"):
		g.press_skill("trumpet")
		return
	if _count_within(150.0) >= 3 and sk.can_use("rebuke"):
		g.press_skill("rebuke")
		return
	if dist > 130.0 and dist < 240.0 and sk.can_use("descent"):
		g.press_skill("descent")
		return
	if sk.learned("radiance") and not sk.radiance_on and _count_within(150.0) >= 2 and m.glory > 50.0:
		g.press_skill("radiance")
	if _count_within(95.0) >= 2 and sk.can_use("whirl"):
		g.press_skill("whirl")
		return
	if _count_within(220.0) >= 3 and sk.can_use("silence") and _casters_near():
		g.press_skill("silence")
		return
	if _count_within(80.0) >= 2:                 # surrounded: hold Shift and strike where he stands
		g.stand = true
		g.lmb = true
		_clicked = null
		return
	if _clicked != d:                            # click the enemy: Michael goes to it and strikes
		_clicked = d
		g.lmb = false
		g.lmb_down()
		g.lmb = false

func _count_within(r: float) -> int:
	var n: int = 0
	for x: Node in get_tree().get_nodes_in_group("demons"):
		if (x as Demon).global_position.distance_to(m.global_position) < r:
			n += 1
	return n


func _casters_near() -> bool:
	for x: Node in get_tree().get_nodes_in_group("demons"):
		if (x as Demon).data["behaviour"] == "ranged" and (x as Demon).global_position.distance_to(m.global_position) < 220.0:
			return true
	return false


func _bolt_near() -> bool:
	for x: Node in g.world.get_children():
		if x is Bolt and (x as Bolt).global_position.distance_to(m.global_position) < 150.0:
			return true
	return false


func _nearest_demon(r: float) -> Demon:
	return g.demon_near(m.global_position - Vector2(0, 24), r)


func _nearest_item(r: float) -> GroundItem:
	var best: GroundItem = null
	var bd: float = r
	for x: Node in g.world.get_children():
		var it := x as GroundItem
		if it != null and not _skip.has(it) and it.global_position.distance_to(m.global_position) < bd:
			bd = it.global_position.distance_to(m.global_position)
			best = it
	return best


## The demo build: Sword + Voice ("Captain"). Mastery points open the tiers, then the skills, modifiers and ranks;
## attribute points into Might; stars into any open group.
func _spend_points() -> void:
	var p: Progression = m.prog
	if p.can_choose_mastery():
		p.choose_mastery("voice")
	while int(p.mastery_points.get("sword", 0)) < 4 and p.add_mastery("sword"):
		pass
	while int(p.mastery_points.get("voice", 0)) < 8 and p.add_mastery("voice"):
		pass
	for sk: String in ["rebuke", "whirl", "trumpet", "silence"]:
		if p.rank(sk) == 0:
			p.add_rank(sk)
	for mod: Array in [["strike", "heavy_blow"], ["rebuke", "echo"], ["trumpet", "resound"], ["whirl", "momentum"]]:
		p.add_mod(mod[0], mod[1])
	var cycle: Array = ["strike", "whirl", "rebuke", "trumpet"]
	var i: int = 0
	while p.skill_points() > 0 and i < 40:
		p.add_rank(cycle[i % cycle.size()])
		i += 1
	while p.add_attribute("might"):
		pass
	for gid: String in GameData.hosts["groups"]:
		while p.take_star(gid):
			pass


func _do(action: String) -> void:
	match action:
		"open_inventory": g.inventory_panel.visible = true
		"equip":
			var i: int = m.inv.best_upgrade()
			while i >= 0:
				m.inv.equip(i)
				i = m.inv.best_upgrade()
			Audio.sfx("pickup", -10.0, 0.8)
		"open_skills": g.skill_panel.visible = true
		"open_travel":
			for st: Interactable in g.stones:
				st.notice_michael_force()
			g.travel_panel.visible = true
		"travel_rift":
			g._travel(g.stones.size() - 1)
		"open_hosts": g.hosts_panel.visible = true
		"close":
			for p: GamePanel in [g.inventory_panel, g.skill_panel, g.hosts_panel, g.travel_panel]:
				p.visible = false
