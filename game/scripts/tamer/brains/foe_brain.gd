class_name FoeBrain
extends CreatureBrain
## The opposing creature in an arena (wild or a trainer's), at a difficulty tier (tamer.json "ai_tiers"). It fights
## the way its species does (FightStyle) and every attack has a tell (a wind-up with a red warning) and an opening
## after. The tier decides how well it plays (FoeTactics): reaction time, dodging your wind-ups, leading its shots,
## cover and grass, saving its gauge, channelling its status move. It loses track of you when you are hidden.

const DAZED_SPEED: float = 0.25

var tier: Dictionary
var style: FightStyle
var tactics: FoeTactics
var _target: Creature
var _windup: float = 0.0                ## > 0: winding up `_pending` toward `_aim` (a telegraph shows where)
var _pending: String = ""
var _aim: Vector2
var _opening: float = 0.0               ## after an attack it stands still this long: the moment to punish it
var _next_opening: float = 0.0
var _channel_left: float = 0.0


func _init(creature: Creature, tier_id: String = "normal") -> void:
	super(creature)
	tier = TamerData.rule("ai_tiers." + tier_id)
	style = FightStyle.new(self)
	tactics = FoeTactics.new(self)


func think(delta: float) -> Vector2:
	if c.dazed:
		_windup = 0.0
		return c.steer_to(c.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), delta) * c.speed() * DAZED_SPEED
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_fire()
		return Vector2.ZERO
	if _opening > 0.0:
		_opening -= delta
		return Vector2.ZERO
	if _channel_left > 0.0:
		return Vector2.ZERO
	_target = TamerGame.current.partner()
	if _target == null or not _target.alive():
		return Vector2.ZERO
	var tact: Vector2 = tactics.think(_target, delta)
	if tact != Vector2.INF:
		return tact
	if TerrainRules.hidden_from(_target, c):
		return style.search(_target, delta)
	return style.think(_target, delta)


func tick(delta: float) -> void:
	if _channel_left > 0.0:
		_channel_left -= delta
		if _channel_left <= 0.0 or c.channel_id == "":
			c.release_channel(_target.global_position if _target != null and is_instance_valid(_target) else c.global_position)
			_channel_left = 0.0


func _fire() -> void:
	var m: Dictionary = TamerData.move(_pending)
	var at: Vector2 = _aim
	if _target != null and is_instance_valid(_target) and m["kind"] == "bolt":
		at = tactics.lead(_target, m)
	if String(m.get("type", "physical")) == "special":
		c.gauge = maxf(0.0, c.gauge - float(m.get("cost", 0)))
	c.cast(_pending, at)
	_opening = _next_opening


## Every attack is telegraphed: it stops, a warning shows where it will land, then it strikes there. Status moves are
## channelled instead (no warning: you see it standing still and can punish it).
func attack_with(a: Dictionary, target: Creature) -> bool:
	var id: String = String(a["move"])
	var m: Dictionary = TamerData.move(id)
	if _windup > 0.0 or not c.move_ready(id) or not tactics.may_use(m, target):
		return false
	if String(m["type"]) == "status":
		if c.begin_channel(id):
			_channel_left = float(m["channel"]) * float(tier["channel"])
			_next_opening = float(a.get("opening", 0.0))
		return true
	_pending = id
	_target = target
	_aim = target.global_position
	_windup = float(a["windup"]) * float(tier["tell_mult"])
	_next_opening = float(a.get("opening", 0.0))
	Telegraphs.show_for(c, m, _aim, target, _windup)
	c.view.windup(_windup)
	return true
