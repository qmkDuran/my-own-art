class_name Creature
extends Combatant
## A creature on the field, yours or wild, made from its CreatureRecord. Its brain (partner, wild or your direct
## control in battle) says where to go; moves (MoveBook) run on cooldowns; hits shove and stun it. A partner never blocks the
## trainer (they do not collide); creatures keep a little personal space from each other instead.

signal fainted(c: Creature)
signal struck(c: Creature, attacker: Combatant)

const TEAM_LAYER: int = 8
const WILD_LAYER: int = 16
const SEPARATION: float = 0.7
const PERSONAL_SPACE: float = 1.25
const FAINT_TIME: float = 0.6
const FACE_MIN: float = 4.0

var rec: CreatureRecord
var brain: CreatureBrain
var view: CreatureSprite
var cooldowns: Dictionary = {}
var facing: Vector2 = Vector2.RIGHT
var busy_t: float = 0.0                 ## a move is moving the body (a lunge): the brain waits
var dash_vel: Vector2 = Vector2.ZERO
var dash_t: float = 0.0
var guard_left: float = 0.0             ## damage a ward still soaks
var guard_t: float = 0.0
var dodge_cd: float = 0.0
var dazed: bool = false                 ## weak enough to sync: it stops fighting
var stagger: StaggerBar
var catchable: bool = true              ## a rival trainer's creature is never dazed (it can't be caught)
var combo_scale: float = 1.0            ## the current basic hit's share of the combo (the last hit is the big one)
var commit_t: float = 0.0               ## a move's wind-up and recovery: no moving, no dodging
var _combo_i: int = 0
var _combo_quiet: float = 0.0
var fainted_now: bool = false


func setup(r: CreatureRecord, s: String) -> Creature:
	rec = r
	side = s
	return self


func _ready() -> void:
	add_to_group(side)
	add_to_group("creatures")
	collision_layer = TEAM_LAYER if side == SIDE_TEAM else WILD_LAYER
	collision_mask = WORLD_MASK
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = rec.radius()
	cs.shape = shape
	add_child(cs)
	view = CreatureSprite.new().setup(rec)
	add_child(view)
	stagger = StaggerBar.new(self)
	if rec.life < 0.0:
		rec.life = rec.max_life()


func hit_radius() -> float:
	return rec.radius()


func element_id() -> String:
	return rec.element()


func alive() -> bool:
	return not fainted_now and is_inside_tree()


func max_life_value() -> float:
	return rec.max_life()


var max_life: float:                    ## read by FloatText to size the numbers
	get:
		return rec.max_life()


func power() -> float:
	return rec.power()




func move_ready(id: String) -> bool:
	return float(cooldowns.get(id, 0.0)) <= 0.0 and busy_t <= 0.0 and commit_t <= 0.0 and stun_t <= 0.0 and alive()


func is_basic(id: String) -> bool:
	return id == String(rec.data()["basic"])


func is_basic_move(m: Dictionary) -> bool:
	return m == TamerData.move(String(rec.data()["basic"]))


func cooldown_frac(id: String) -> float:
	var cd: float = float(TamerData.move(id)["cooldown"])
	return clampf(float(cooldowns.get(id, 0.0)) / maxf(cd, 0.01), 0.0, 1.0)


## Uses move `id` toward `at` if it is ready. Returns whether it went off. Your creature's basic is a combo (no
## cooldown, just the rhythm of its hits); its moves commit it: a wind-up, the move, a recovery (no dodging).
func cast(id: String, at: Vector2) -> bool:
	if not move_ready(id) or dazed:
		return false
	var m: Dictionary = TamerData.move(id)
	face(at)
	if side == SIDE_TEAM and is_basic(id):
		_combo_step(id)
	elif side == SIDE_TEAM:
		cooldowns[id] = float(TamerData.rule("combat.lockout"))
		_commit(id, m, at)
		_first_use(id, m)
		return true
	else:
		cooldowns[id] = float(m["cooldown"])
	view.act()
	MoveBook.cast(self, id, at)
	return true


func _combo_step(id: String) -> void:
	var C: Dictionary = TamerData.rule("combat.combo")
	if _combo_quiet <= 0.0:
		_combo_i = 0
	combo_scale = float(C["scale"][_combo_i])
	cooldowns[id] = float(C["gap"][_combo_i])
	_combo_i = (_combo_i + 1) % int(C["hits"])
	_combo_quiet = float(C["reset"])


## Wind-up (it rears back), the move, then recovery; the whole time it can neither move nor dodge.
func _commit(id: String, m: Dictionary, at: Vector2) -> void:
	var wind: float = float(m.get("windup", 0.0))
	commit_t = wind + float(m.get("recovery", 0.0))
	view.windup(wind)
	get_tree().create_timer(wind, false).timeout.connect(func() -> void:
		if alive() and stun_t <= 0.0:
			view.act()
			MoveBook.cast(self, id, at))


func _first_use(id: String, m: Dictionary) -> void:
	if not rec.used_moves.has(id) and not bool(m.get("bond", false)):
		rec.used_moves[id] = true
		TamerGame.current.hud.callout(String(m["name"]), TamerData.color(CreatureCombat.move_element(self, m), "light"))


func face(at: Vector2) -> void:
	var d: Vector2 = at - global_position
	if d.length() > FACE_MIN:
		facing = d.normalized()


## A short quick hop (the creature's own dodge while you steer it).
func dodge(toward: Vector2, d: Dictionary) -> bool:
	if dodge_cd > 0.0 or busy_t > 0.0 or commit_t > 0.0 or not alive():
		return false
	var dir: Vector2 = (toward - global_position).normalized() if toward.distance_to(global_position) > 1.0 else facing
	dodge_cd = float(d["cooldown"])
	iframe_t = float(d["iframes"])
	dash(dir * float(d["distance"]) / float(d["time"]), float(d["time"]))
	Fx.burst(TamerGame.current.fx_layer, global_position + Vector2(0, -6), 10, Vector2(40, 120), 0.3,
		TamerData.sparks(element_id()), -dir, 40.0)
	Audio.sfx("dash", -10.0, 1.2)
	if side == SIDE_TEAM:
		_perfect_dodge()
	return true


## Dodging through a wild attack at the last moment: a chunk of gauge and a short slow-motion flash.
func _perfect_dodge() -> void:
	var P: Dictionary = TamerData.rule("combat.perfect_dodge")
	for n: Node in get_tree().get_nodes_in_group(SIDE_WILD):
		var b := (n as Creature).brain as WildBrain
		if b != null and b.winding_at(self) and b.windup_left() <= float(P["window"]):
			TamerGame.current.team.add_gauge(float(TamerData.rule("combat.gauge.perfect_dodge")))
			TamerFx.word(global_position, "Perfect dodge!", Pal.c("sun"), UiDraw.TITLE)
			Fx.screen_flash(Pal.c("sun"), 0.18, 0.25)
			HitStop.trigger(get_tree(), float(P["slow_real"]))
			return


## Moves the body itself for `time` seconds (lunges, dodges); the brain waits.
func dash(vel: Vector2, time: float) -> void:
	dash_vel = vel
	dash_t = time
	busy_t = time
	face(global_position + vel)


func add_guard(amount: float, time: float) -> void:
	guard_left = maxf(guard_left, amount)
	guard_t = time


func receive_hit(dmg: float, dir: Vector2, knock_px: float, stun: float, attacker: Combatant) -> void:
	if untouchable():
		return
	if guard_t > 0.0 and guard_left > 0.0:
		var soak: float = minf(guard_left, dmg)
		guard_left -= soak
		dmg -= soak
	rec.life -= dmg
	view.flash()
	shove(dir, knock_px)
	stun_t = maxf(stun_t, stun)
	struck.emit(self, attacker)
	if rec.life <= 0.0:
		faint()
	elif side == SIDE_WILD and catchable and rec.life_frac() <= float(rec.data()["befriend_at"]):
		set_dazed(true)


func set_dazed(on: bool) -> void:
	dazed = on
	view.set_dazed(on)


## Called back by a rival trainer: it fades away (not a knock-out; no drops).
func recall_quietly() -> void:
	fainted_now = true
	collision_layer = 0
	remove_from_group(side)
	view.fade_out(FAINT_TIME * 0.5)
	get_tree().create_timer(FAINT_TIME * 0.5).timeout.connect(queue_free)


func faint() -> void:
	if fainted_now:
		return
	fainted_now = true
	rec.life = 0.0
	collision_layer = 0
	remove_from_group(side)
	view.fade_out(FAINT_TIME)
	Audio.sfx("die_beast", -6.0, randf_range(1.1, 1.3))
	fainted.emit(self)
	get_tree().create_timer(FAINT_TIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	_tick(delta)
	if fainted_now:
		return
	var want: Vector2 = Vector2.ZERO
	if dash_t > 0.0:
		dash_t -= delta
		want = dash_vel
	elif stun_t <= 0.0 and commit_t <= 0.0 and brain != null:
		want = brain.think(delta)
	if want.length() > FACE_MIN and dash_t <= 0.0:
		facing = want.normalized()
	velocity = want + knock_velocity(delta) + _separation() * rec.speed() * SEPARATION
	move_and_slide()
	view.animate(delta, want, facing.x)


func _tick(delta: float) -> void:
	for id: String in cooldowns:
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
	stun_t = maxf(0.0, stun_t - delta)
	busy_t = maxf(0.0, busy_t - delta)
	commit_t = maxf(0.0, commit_t - delta)
	_combo_quiet -= delta
	stagger.tick(delta)
	iframe_t = maxf(0.0, iframe_t - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	guard_t = maxf(0.0, guard_t - delta)


## Creatures keep a little apart so a pack never reads as one blob.
func _separation() -> Vector2:
	var push: Vector2 = Vector2.ZERO
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		var o := n as Creature
		if o == self or o.fainted_now:
			continue
		var d: Vector2 = global_position - o.global_position
		var min_d: float = (rec.radius() + o.rec.radius()) * PERSONAL_SPACE
		if d.length() < min_d and d.length() > 0.01:
			push += d.normalized() * (1.0 - d.length() / min_d)
	return push
