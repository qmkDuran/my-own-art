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

const ESCAPE: float = 560.0             ## dazed creatures this close are listed in the Victory summary
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
var ring := BattleRing.new()
var rival: RivalTrainer                 ## set in a trainer battle
var _grace: float = 0.0                 ## after a battle, a few seconds when nothing can start a new one


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
	g.fx_layer.add_child(ring)
	ring.visible = false


## Can this creature join in? Outside a battle anyone can start one (after the grace); during one only those in it.
func may_join(c: Creature) -> bool:
	if on:
		return ring.inside.has(c)
	return _grace <= 0.0


func controlled() -> Node2D:
	return g.field.partner if on and g.field.partner != null else g.trainer


func brain() -> ControlledBrain:
	return _brain


## A wild creature engages (it noticed you, or you right-clicked it). Starts a battle if none is on.
func engage(foe: Creature) -> void:
	var c: Creature = g.field.partner
	if on or c == null or not c.alive() or g.retreating or _grace > 0.0:
		if on and _brain != null and _brain.target == null and foe != null and ring.inside.has(foe):
			_brain.target = foe
		return
	on = true
	_raise_ring(c, foe)
	_tally = {"defeated": 0, "materials": g.team.materials.duplicate(), "bond": c.rec.bond, "rec": c.rec}
	_take(c)
	_brain.target = foe
	_beat(c, foe)
	started.emit()


## A rival trainer's battle: the same, with their creatures coming and going inside the ring.
func engage_rival(r: RivalTrainer, first: Creature) -> void:
	_grace = 0.0
	engage(first)
	rival = r
	add_fighter(first)


func add_fighter(c: Creature) -> void:
	if not ring.inside.has(c):
		ring.inside.append(c)
	if c.brain is WildBrain:
		(c.brain as WildBrain).wake(g.field.partner)
	if _brain != null:
		_brain.target = c


func remove_fighter(c: Creature) -> void:
	ring.inside.erase(c)


## The ring forms around your creature and the foe; the foe's pack-mates near it are in the fight too.
func _raise_ring(c: Creature, foe: Creature) -> void:
	var R: Dictionary = TamerData.rule("ring")
	var at: Vector2 = c.global_position if foe == null else c.global_position.lerp(foe.global_position, 0.5)
	var fighters: Array[Creature] = []
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var w := n as Creature
		var b := w.brain as WildBrain
		if w == foe or (foe != null and b != null and b.pack >= 0 and b.pack == (foe.brain as WildBrain).pack and
				w.global_position.distance_to(at) < float(R["radius"])):
			fighters.append(w)
	ring.raise(at, float(R["radius"]), fighters)
	for w: Creature in fighters:
		if w != foe and w.brain is WildBrain:
			(w.brain as WildBrain).wake(c)


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
	_grace -= delta
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
	for w: Creature in ring.inside:
		if is_instance_valid(w) and w.alive() and not w.dazed:
			out.append(w)
	return out


func _check_end(c: Creature) -> void:
	if c == null:
		if g.team.all_out():
			end(false)
		return
	var foes: Array[Creature] = awake_foes(c)
	if foes.is_empty() and (rival == null or not rival.has_more()):
		end(true)



## Back to exploring: the trainer leads again, the camera eases back, and a summary of what the fight earned.
func end(won: bool) -> void:
	if not on:
		return
	on = false
	ring.dissolve()
	if rival != null:
		rival.finish(won)
		rival = null
	_grace = float(TamerData.rule("ring.grace"))
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
