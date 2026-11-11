class_name SkillSystem
extends Node
## Owns the Lamplighter's skills: cooldowns, Oil costs, using a skill (face, hold the pose, effect), and the
## hooks some skills and uniques need (dash trails, Dark Adept's speed, guardian moths catching shots).

signal used(skill: String)

const UNDIMMED_NEEDS: float = 25.0
const STRIDER_BELOW: float = 40.0
const STRIDER_MORE: float = 1.4
const STRIDER_MOVE: float = 1.15
const BROOD_CHANCE: float = 0.25


var player: Player
var all: Dictionary = {}
var cooldowns: Dictionary = {}


func _ready() -> void:
	var kinds: Dictionary = {"wickbolt": Wickbolt, "flare": Flare, "lantern_toss": LanternToss, "moth_swarm": MothSwarm,
		"eclipse": Eclipse, "noon": Noon, "kindle": Kindle, "tether": Tether, "glass_ward": GlassWard, "cinder_rain": CinderRain,
		"wick_trap": WickTrap, "lull": Lull}
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
	if player.oil < cost_of(id) and not _recast_allowed(id):
		return "oil"
	if id == "flare" and player.stats.has_special("undimmed") and player.light.value < UNDIMMED_NEEDS:
		return "light"
	return ""


## Oil a skill costs right now (Pitch Dark and Undimmed make some free).
func cost_of(id: String) -> float:
	var ecl: Eclipse = skill("eclipse") as Eclipse
	if ecl.active() and ecl.rank("pitch") > 0 and (id == "flare" or id == "lantern_toss"):
		return 0.0
	if id == "flare" and player.stats.has_special("undimmed"):
		return 0.0
	return skill(id).cost()


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
	player.oil -= cost_of(id)
	cooldowns[id] = s.cooldown()
	player.act(s.pose(), s.cast_time(), func() -> void:     # lands on the animation's strike / release frame
		if not player.dead:
			s.use(target))
	used.emit(id)
	return true


func cooldown_left(id: String) -> Vector2:
	var s: Skill = skill(id)
	return Vector2(float(cooldowns.get(id, 0.0)), s.cooldown() if s != null else 0.0)


func _process(delta: float) -> void:
	for id: String in cooldowns:
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
	(skill("eclipse") as Eclipse).tick(delta)
	(skill("kindle") as Kindle).tick(delta)
	(skill("glass_ward") as GlassWard).tick(delta)


func move_mult() -> float:
	var lt: LanternToss = skill("lantern_toss") as LanternToss
	var m: float = 1.0 + (lt.val("move_pct") / 100.0 if lt.away() else 0.0)
	return m * (skill("eclipse") as Eclipse).move_mult() * (STRIDER_MOVE if striding() else 1.0)


## Shroud Strider (keystone): stronger and quicker while the lantern burns low.
func striding() -> bool:
	return player.stats.has_special("shroud_strider") and player.light.value < STRIDER_BELOW


## Extra damage multiplier while the lantern is thrown (Dark Adept).
func dark_more() -> float:
	var lt: LanternToss = skill("lantern_toss") as LanternToss
	return (1.0 + (lt.val("more_pct") / 100.0 if lt.away() else 0.0)) * (STRIDER_MORE if striding() else 1.0)


## Something died: Eclipse's Umbra and New Moon, Brood of Embers' moths.
func on_kill(e: Enemy) -> void:
	(skill("eclipse") as Eclipse).on_kill(e)
	(skill("kindle") as Kindle).on_kill(e)
	if player.stats.has_special("brood_kill") and randf() < BROOD_CHANCE:
		(skill("moth_swarm") as MothSwarm).loose_from(e.global_position)


func on_dash(from: Vector2, dir: Vector2) -> void:
	if player.stats.has_special("glass_dash"):
		GlassTrail.lay(Game.current.fx_layer, from, dir, player)
