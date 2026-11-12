class_name BattleMode
extends Node
## Exploring or in battle. Exploring, you are the trainer and your creature follows. A battle starts when you
## right-click a wild creature or one notices your team: a short beat ("Go, Name!", your creature leaps in, a camera
## punch and a vignette), then you control the creature directly while the trainer keeps to a safe spot behind the
## fight on their own. It ends when no awake wild creature is left near your creature (defeated, befriended, dazed or
## fled) or you run your creature out of range; control returns to the trainer and a Victory summary shows what you
## won. The camera follows a focus point blended between trainer and creature, so the change of control is smooth.

signal started
signal ended(won: bool)

const RANGE: float = 420.0              ## awake wild creatures this close to your creature keep the battle going
const ESCAPE: float = 560.0             ## your creature this far from every awake foe: you got away
const SAFE_BEHIND: float = 110.0        ## the trainer stands this far behind your creature, away from the foes
const SAFE_EVERY: float = 0.4
const SAFE_SLACK: float = 40.0
const LEAP: float = 70.0
const LEAP_TIME: float = 0.18
const END_CHECK: float = 0.3
const SUMMARY_DELAY: float = 1.0

var g: TamerGame
var focus: Node2D                       ## what the camera follows
var on: bool = false
var blend: float = 0.0                  ## 0: the camera is on the trainer, 1: on the creature
var _brain: ControlledBrain
var _safe_t: float = 0.0
var _end_t: float = 0.0
var _tally: Dictionary = {}             ## defeated, materials and bond at the start of the battle


func setup(game: TamerGame) -> void:
	g = game
	focus = Node2D.new()
	g.add_child(focus)
	focus.global_position = g.trainer.global_position
	g.field.partner_changed.connect(_on_partner_changed)
	g.spawner.defeated.connect(func(_c: Creature) -> void:
		if on:
			_tally["defeated"] = int(_tally.get("defeated", 0)) + 1)
	g.trainer.set_highlight(true)


func controlled() -> Node2D:
	return g.field.partner if on and g.field.partner != null else g.trainer


func brain() -> ControlledBrain:
	return _brain


## A wild creature engages (it noticed you, or you right-clicked it). Starts a battle if none is on.
func engage(foe: Creature) -> void:
	var c: Creature = g.field.partner
	if on or c == null or not c.alive() or g.retreating:
		if on and _brain != null and _brain.target == null and foe != null:
			_brain.target = foe
		return
	on = true
	_tally = {"defeated": 0, "materials": g.team.materials.duplicate(), "bond": c.rec.bond, "rec": c.rec}
	_take(c)
	_brain.target = foe
	_beat(c, foe)
	started.emit()


func _take(c: Creature) -> void:
	_brain = ControlledBrain.new(c)
	c.brain = _brain
	c.view.set_highlight(true)
	g.trainer.set_highlight(false)


## The battle-start beat: under a second and never blocking.
func _beat(c: Creature, foe: Creature) -> void:
	TamerFx.word(c.global_position, "Go, %s!" % c.rec.data()["name"], TamerData.color(c.element_id(), "light"), UiDraw.TITLE)
	if foe != null:
		var dir: Vector2 = (foe.global_position - c.global_position).normalized()
		c.dash(dir * LEAP / LEAP_TIME, LEAP_TIME)
		CameraRig.punch(dir * 8.0)
	CameraRig.shake(0.2)
	g.hud.vignette(true)
	Audio.sfx("slam", -8.0, 1.3)


func _on_partner_changed(c: Creature) -> void:
	if on and c != null:
		_take(c)                                           # a swap-in comes under your control at once


func _physics_process(delta: float) -> void:
	var c: Creature = g.field.partner
	var has: bool = c != null and is_instance_valid(c)
	var k: float = minf(1.0, float(TamerData.rule("control.camera_ease")) * delta)
	blend = lerpf(blend, 1.0 if on and has else 0.0, k)
	var other: Vector2 = c.global_position if has else g.trainer.global_position
	focus.global_position = g.trainer.global_position.lerp(other, smoothstep(0.0, 1.0, blend))
	if not on:
		return
	_safe_t -= delta
	if _safe_t <= 0.0 and has:
		_safe_t = SAFE_EVERY
		_keep_trainer_safe(c)
	_end_t -= delta
	if _end_t <= 0.0:
		_end_t = END_CHECK
		_check_end(c if has else null)


## The trainer walks (on their own) to a spot behind your creature, on the far side from the foes.
func _keep_trainer_safe(c: Creature) -> void:
	var foes: Array[Creature] = awake_foes(c)
	if foes.is_empty() or g.befriend.target != null:
		return
	var mid: Vector2 = Vector2.ZERO
	for f: Creature in foes:
		mid += f.global_position
	mid /= foes.size()
	var away: Vector2 = (c.global_position - mid).normalized()
	var spot: Vector2 = g.layout.free_spot_near(c.global_position + away * SAFE_BEHIND, g.trainer.hit_radius())
	if g.trainer.global_position.distance_to(spot) > SAFE_SLACK:
		g.trainer.walk_to(spot)


func awake_foes(c: Creature) -> Array[Creature]:
	var out: Array[Creature] = []
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var w := n as Creature
		var b := w.brain as WildBrain
		if b != null and b.awake and not w.dazed and w.global_position.distance_to(c.global_position) < ESCAPE:
			out.append(w)
	return out


func _check_end(c: Creature) -> void:
	if c == null:
		if g.team.all_out():
			end(false)
		return
	var foes: Array[Creature] = awake_foes(c)
	if foes.is_empty():
		end(true)
	elif foes.all(func(f: Creature) -> bool: return f.global_position.distance_to(c.global_position) > RANGE) and \
			_brain != null and _brain.target == null:
		end(false)


## Back to exploring: the trainer leads again, the camera eases back, and a summary of what the fight earned.
func end(won: bool) -> void:
	if not on:
		return
	on = false
	var c: Creature = g.field.partner
	if c != null and is_instance_valid(c):
		c.brain = PartnerBrain.new(c)
		c.view.set_highlight(false)
	_brain = null
	g.trainer.set_highlight(true)
	g.trainer.attack_target = null
	g.hud.vignette(false)
	if won:                                                 # drops fly to the trainer first, then the summary
		get_tree().create_timer(SUMMARY_DELAY).timeout.connect(func() -> void: g.hud.victory(_summary()))
	elif not g.retreating:
		g.hud.notice("You got away.")
	ended.emit(won)


func _summary() -> Array[String]:
	var out: Array[String] = ["Defeated %d" % int(_tally.get("defeated", 0))]
	var before: Dictionary = _tally.get("materials", {})
	for id: String in g.team.materials:
		var gained: int = g.team.count(id) - int(before.get(id, 0))
		if gained > 0:
			out.append("+%d %s" % [gained, TamerData.rule("materials." + id + ".name")])
	var dazed: int = get_tree().get_nodes_in_group(Combatant.SIDE_WILD).filter(func(n: Node) -> bool:
		return (n as Creature).dazed and (n as Creature).global_position.distance_to(g.trainer.global_position) < ESCAPE).size()
	if dazed > 0:
		out.append("%d dazed: press F to befriend" % dazed)
	var rec: CreatureRecord = _tally.get("rec")
	if rec != null:
		out.append("Bond +%d (%s)" % [roundi(rec.bond - float(_tally.get("bond", rec.bond))), rec.data()["name"]])
	return out
