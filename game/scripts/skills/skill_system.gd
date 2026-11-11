class_name SkillSystem
extends Node
## Owns the Lamplighter's skills: cooldowns, Oil costs, using a skill (face, hold the pose, effect), and the
## hooks some skills and uniques need (dash trails, Dark Adept's speed, guardian moths catching shots).

signal used(skill: String)


var player: Player
var all: Dictionary = {}
var cooldowns: Dictionary = {}


func _ready() -> void:
	var kinds: Dictionary = {"sunlash": Sunlash, "flare": Flare, "lantern_toss": LanternToss, "moth_swarm": MothSwarm}
	for id: String in kinds:
		all[id] = (kinds[id] as GDScript).new().setup(id, player)


func skill(id: String) -> Skill:
	return all.get(id)


## Why a skill can't be used right now ("" if it can).
func block(id: String) -> String:
	if not all.has(id) or not player.prog.skills.has(id):
		return "not learned"
	if player.dead:
		return "dead"
	if player.busy_t > 0.0:
		return "busy"
	if float(cooldowns.get(id, 0.0)) > 0.0 and not _recast_allowed(id):
		return "cooldown"
	if player.oil < skill(id).cost() and not _recast_allowed(id):
		return "oil"
	return ""


func _recast_allowed(id: String) -> bool:
	return id == "lantern_toss" and (skill(id) as LanternToss).away()


func try_use(id: String, target: Vector2) -> bool:
	if block(id) != "":
		if block(id) == "oil":
			Game.current.hud.notice("Not enough Oil")
		return false
	var s: Skill = skill(id)
	if _recast_allowed(id):
		(s as LanternToss).recall()
		return true
	player.face(target)
	player.act(s.pose(), s.cast_time())
	player.oil -= s.cost()
	cooldowns[id] = s.cooldown()
	s.use(target)
	used.emit(id)
	return true


func cooldown_left(id: String) -> Vector2:
	var s: Skill = skill(id)
	return Vector2(float(cooldowns.get(id, 0.0)), s.cooldown() if s != null else 0.0)


func _process(delta: float) -> void:
	for id: String in cooldowns:
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)


func move_mult() -> float:
	var lt: LanternToss = skill("lantern_toss") as LanternToss
	return 1.0 + (lt.val("move_pct") / 100.0 if lt.away() else 0.0)


## Extra damage multiplier while the lantern is thrown (Dark Adept).
func dark_more() -> float:
	var lt: LanternToss = skill("lantern_toss") as LanternToss
	return 1.0 + (lt.val("more_pct") / 100.0 if lt.away() else 0.0)


func on_dash(from: Vector2, dir: Vector2) -> void:
	if player.stats.has_special("glass_dash"):
		GlassTrail.lay(Game.current.fx_layer, from, dir, player)
