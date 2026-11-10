class_name DemoBot
extends Node
## --demo: plays the game for the recording. Fights the nearest packs with the sword and skills, picks up items,
## answers a prayer, spends its points, and opens the inventory, skills and stars panels on a timeline.

const SEEK: float = 420.0
const LOOT_GRAB: float = 240.0
const SAFE: float = 110.0
const START_XP: float = 1250.0
const QUIT_AFTER: float = 47.0
const TIMELINE: Array = [   # [seconds, action]
	[21.0, "open_inventory"], [23.5, "equip"], [25.5, "close"], [31.0, "open_skills"], [33.5, "close"],
	[34.0, "open_hosts"], [36.5, "close"],
]

var g: Game
var m: Michael
var _t: float = 0.0
var _step: int = 0
var _think: float = 0.0


func setup(game: Game) -> void:
	g = game
	m = game.michael
	seed(4)
	m.prog.leveled.connect(func(_l: int) -> void: _spend_points())
	m.prog.add_xp(START_XP)                     # the recording starts a few levels in, so every skill is shown
	m.life = m.stats.v("life")


func _physics_process(delta: float) -> void:
	_t += delta
	if _step < TIMELINE.size() and _t >= float(TIMELINE[_step][0]):
		_do(String(TIMELINE[_step][1]))
		_step += 1
	if _t > QUIT_AFTER:
		get_tree().quit()
	if g.panels_open() or _t < 2.0:
		m.stop()
		return
	_think -= delta
	if _think > 0.0:
		return
	_think = 0.1
	_act()


func _act() -> void:
	var close_item: GroundItem = _nearest_item(LOOT_GRAB)
	if close_item != null and _nearest_demon(SAFE) == null:
		m.move_to(close_item.global_position)
		return
	var target: Demon = _nearest_demon(SEEK)
	if target != null:
		_fight(target)
		return
	var item: GroundItem = _nearest_item(SEEK)
	if item != null:
		m.move_to(item.global_position)
		return
	for p: Dictionary in g.objective.points:
		if int(p["state"]) == PrayerObjective.STATE_WAITING:
			m.move_to(p["at"])
			return
	m.move_to(SceneData.vec(GameData.zone["final_pack"]["at"]))


func _fight(d: Demon) -> void:
	var dist: float = m.global_position.distance_to(d.global_position)
	var near3: int = _count_within(150.0)
	var sk: SkillSystem = m.skills
	if m.life < m.stats.v("life") * 0.55 or (_bolt_near() and sk.can_use("shield")):
		sk.use("shield", d.global_position)
	if _count_within(200.0) >= 4 and sk.can_use("trumpet"):
		sk.use("trumpet", d.global_position)
	elif near3 >= 3 and sk.can_use("rebuke"):
		sk.use("rebuke", d.global_position)
	elif dist > 130.0 and dist < 240.0 and sk.can_use("descent"):
		sk.use("descent", d.global_position)
		return
	if sk.learned("radiance") and not sk.radiance_on and near3 >= 2 and m.glory > 50.0:
		sk.use("radiance", d.global_position)
	if dist > float(GameData.skill("strike")["radius"]) * 0.75:
		m.move_to(d.global_position)
	else:
		m.stop()
		m.strike(d.global_position + Vector2(0, -16))


func _count_within(r: float) -> int:
	var n: int = 0
	for x: Node in get_tree().get_nodes_in_group("demons"):
		if (x as Demon).global_position.distance_to(m.global_position) < r:
			n += 1
	return n


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
		if it != null and it.global_position.distance_to(m.global_position) < bd:
			bd = it.global_position.distance_to(m.global_position)
			best = it
	return best


## Mastery to open each tier, the skills of that tier, then modifiers and ranks; then stars.
func _spend_points() -> void:
	var p: Progression = m.prog
	while p.mastery < 4 and p.add_mastery():
		pass
	for sk: String in ["rebuke", "shield"]:
		if p.rank(sk) == 0:
			p.add_rank(sk)
	while p.mastery < 8 and p.add_mastery():
		pass
	for sk: String in ["trumpet", "radiance"]:
		if p.rank(sk) == 0:
			p.add_rank(sk)
	for mod: Array in [["strike", "heavy_blow"], ["rebuke", "echo"], ["descent", "wingbeat"], ["trumpet", "resound"]]:
		p.add_mod(mod[0], mod[1])
	var cycle: Array = ["strike", "rebuke", "trumpet", "descent"]
	var i: int = 0
	while p.skill_points() > 0 and i < 40:
		p.add_rank(cycle[i % cycle.size()])
		i += 1
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
		"open_hosts": g.hosts_panel.visible = true
		"close":
			for p: GamePanel in [g.inventory_panel, g.skill_panel, g.hosts_panel]:
				p.visible = false
