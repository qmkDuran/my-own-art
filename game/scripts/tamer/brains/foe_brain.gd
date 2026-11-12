class_name FoeBrain
extends CreatureBrain
## The opposing creature in an arena (wild or a trainer's), at a difficulty tier (tamer.json "ai_tiers"). It plays
## by exactly your rules (equal footing): the same moves with the same wind-ups and warnings, the same gauge and
## costs, the same lockout. It fights the way its species does (FightStyle), and the tier only changes how well it
## decides (FoeTactics): reaction time, pace, dodging your wind-ups, leading its shots, cover, high ground and grass,
## saving its gauge, channelling its status move, the pause it takes after an attack. It loses track of you when
## you are hidden. Weakened (gold stars) it stops fighting, but while the Sync Lens scans it, it struggles.

const DAZED_SPEED: float = 0.25

var tier: Dictionary
var style: FightStyle
var tactics: FoeTactics
var _target: Creature
var _opening: float = 0.0               ## after an attack it holds still this long (its choice: punish it)
var _pace: float = 0.0                  ## and waits this long before choosing the next attack
var _channel_left: float = 0.0
var _struggle_t: float = 0.0


func _init(creature: Creature, tier_id: String = "normal") -> void:
	super(creature)
	tier = TamerData.rule("ai_tiers." + tier_id)
	style = FightStyle.new(self)
	tactics = FoeTactics.new(self)


## Who it fights: your creature, or (a bot playing your side in the balance run) the opponent.
func opponent() -> Creature:
	var g: TamerGame = TamerGame.current
	var o: Creature = g.battle.foe if c.side == Combatant.SIDE_TEAM else g.partner()
	return o if o != null and is_instance_valid(o) else null


func think(delta: float) -> Vector2:
	_pace -= delta
	if c.dazed and not TamerGame.current.lens.scanning_at(c):
		return c.steer_to(c.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), delta) * c.speed() * DAZED_SPEED
	if _opening > 0.0:
		_opening -= delta
		return Vector2.ZERO
	if _channel_left > 0.0:
		return Vector2.ZERO
	_target = opponent()
	if _target == null or not _target.alive():
		return Vector2.ZERO
	if c.dazed:
		return _struggle(delta)
	var tact: Vector2 = tactics.think(_target, delta)
	if tact != Vector2.INF:
		return tact
	if TerrainRules.hidden_from(_target, c):
		return style.search(_target, delta)
	return style.think(_target, delta)


## Being synced: it lashes out at your creature every so often, with a clear tell.
func _struggle(delta: float) -> Vector2:
	_struggle_t -= delta
	if _struggle_t <= 0.0:
		var S: Dictionary = TamerData.rule("sync")
		_struggle_t = float(S["struggle_every"])
		attack_with({"move": String(S["struggle_move"]), "opening": 0.2}, _target, true)
	return Vector2.ZERO


func tick(delta: float) -> void:
	if _channel_left > 0.0:
		_channel_left -= delta
		if _channel_left <= 0.0 or c.channel_id == "":
			c.release_channel(_target.global_position if _target != null and is_instance_valid(_target) else c.global_position)
			_channel_left = 0.0


## Uses an attack the way you would: a status move is channelled; anything else is aimed (led, for a shot), paid
## for from its own gauge and cast, so the move's own wind-up and warning play. Then it holds still for the attack's
## opening and waits its tier's pace before the next. `now` skips the pace (a struggle).
func attack_with(a: Dictionary, target: Creature, now: bool = false) -> bool:
	var id: String = String(a["move"])
	var m: Dictionary = TamerData.move(id)
	if (_pace > 0.0 and not now) or not c.move_ready(id) or not tactics.may_use(m, target):
		return false
	_target = target
	if String(m["type"]) == "status":
		if c.begin_channel(id):
			_channel_left = float(m["channel"]) * float(tier["channel"])
			_after(a)
		return true
	var aim: Vector2 = tactics.lead(target, m) if String(m["kind"]) == "bolt" else target.global_position
	if not c.cast(id, aim):
		return false
	c.pay_gauge(float(m.get("cost", 0)))
	_after(a)
	return true


func _after(a: Dictionary) -> void:
	_opening = c.commit_t + float(a.get("opening", 0.0))
	_pace = float(tier["pace"])
