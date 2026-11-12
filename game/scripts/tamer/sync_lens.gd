class_name SyncLens
extends Node2D
## Catching is the trainer's job, with a handheld scanner: once a wild creature is weakened (dazed) or STAGGERED,
## press F and the trainer walks into range and raises the Sync Lens; HOLD F while the scan beam plays and the ring
## around the creature fills. Your creature being hit, the target being hit (it breaks free), letting go, walking
## off or the target fainting stops it. On success the creature dissolves into light and is synced to your team
## (the first three) or your Sanctuary.

signal synced(rec: CreatureRecord)

const RING_R: float = 22.0
const RING_W: float = 3.0
const JOIN_LIFE: float = 0.5
const FIND_RANGE: float = 420.0         ## F looks this far around the trainer for a creature to sync
const REWALK: float = 0.3
const DEVICE := Vector2(10, 7)          ## the scanner held up beside the trainer (px)
const HAND := Vector2(9, -26)
const BEAM_W: float = 3.0
const SCAN_LINES: int = 3

var g: TamerGame
var target: Creature
var progress: float = 0.0
var scanning: bool = false
var _walk_t: float = 0.0
var _t: float = 0.0


func setup(game: TamerGame) -> void:
	g = game
	z_index = Fx.FX_Z
	material = Fx.glow_material()
	g.field.partner_changed.connect(_watch_partner)


func _watch_partner(c: Creature) -> void:
	if c != null and not c.struck.is_connected(_on_partner_hit):
		c.struck.connect(_on_partner_hit)


func held() -> bool:
	return Input.is_action_pressed("interact") or bool(get_meta("held", false))


func range_px() -> float:
	return float(TamerData.rule("sync.range"))


## Can this creature be synced now (weakened or staggered, wild, not a rival's)?
static func syncable(c: Creature) -> bool:
	return is_instance_valid(c) and c.alive() and c.catchable and c.side == Combatant.SIDE_WILD and \
		(c.dazed or c.stagger.is_staggered())


## F: the trainer goes to the nearest creature that can be synced. Returns whether there was one.
func request() -> bool:
	cancel()
	target = _nearest()
	if target == null:
		g.hud.notice("Nothing to sync. Weaken a creature (the pink mark on its life bar) or stagger it first.")
		return false
	target.struck.connect(_on_target_hit)
	g.trainer.walk_to(target.global_position)
	return true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if target == null:
		return
	if not syncable(target) or g.trainer.rolling():
		cancel()
		return
	var tr: Trainer = g.trainer
	if tr.global_position.distance_to(target.global_position) > range_px():
		scanning = false
		_walk_t -= delta
		if _walk_t <= 0.0:
			_walk_t = REWALK
			tr.walk_to(target.global_position)
		return
	tr.stop()
	scanning = held()
	if not scanning:
		progress = 0.0
		return
	progress += delta / float(TamerData.rule("sync.hold"))
	if progress >= 1.0:
		_win(target)


func _nearest() -> Creature:
	var best: Creature = null
	var best_d: float = FIND_RANGE
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var c := n as Creature
		var d: float = c.global_position.distance_to(g.trainer.global_position)
		if syncable(c) and d < best_d:
			best = c
			best_d = d
	return best


func _on_target_hit(c: Creature, _by: Combatant) -> void:
	if c == target:
		cancel()
		g.hud.notice("It broke free! Don't hit it while you sync.")


func _on_partner_hit(_c: Creature, _by: Combatant) -> void:
	if scanning:
		cancel()
		g.hud.notice("Your creature was hit: the scan broke off.")


func cancel() -> void:
	if target != null and is_instance_valid(target) and target.struck.is_connected(_on_target_hit):
		target.struck.disconnect(_on_target_hit)
	progress = 0.0
	scanning = false
	target = null


## Synced: the creature dissolves into light that streams to the trainer's lens.
func _win(c: Creature) -> void:
	var rec: CreatureRecord = c.rec
	cancel()
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -12), 40, Vector2(40, 160), 0.8, TamerData.sparks(rec.element()), Vector2.UP)
	Fx.ring(g.fx_layer, c.global_position, 6.0, 60.0, Pal.c("glint"), 0.4)
	TamerFx.streak(c.global_position, g.trainer.global_position + HAND, rec.element())
	TamerFx.word(c.global_position, "Synced!", Pal.c("glint"), UiDraw.TITLE)
	Audio.sfx("lamp_lit", -4.0, 1.5)
	if rec.shiny:
		Fx.burst(g.fx_layer, c.global_position + Vector2(0, -16), 40, Vector2(60, 220), 0.9, [Pal.c("sun"), Pal.c("gold"), Pal.c("amber", 0.0)])
		Audio.sfx("lamp_lit", -2.0, 1.8)
	c.remove_from_group(Combatant.SIDE_WILD)
	c.fainted_now = true
	c.view.fade_out(0.5)
	c.get_tree().create_timer(0.5).timeout.connect(c.queue_free)
	rec.wild = false
	rec.life = rec.max_life() * JOIN_LIFE
	rec.add_bond(float(TamerData.rule("bond.per_befriend")))
	var to_party: bool = g.team.sync(rec)
	g.hud.notice(("%s joined your team!" if to_party else "%s was synced to your Sanctuary (camp).") % rec.display_name())
	synced.emit(rec)


## The scanner in the trainer's hand, the beam to the creature, scan lines and the filling ring.
func _draw() -> void:
	if target == null or not is_instance_valid(target):
		return
	var dev: Vector2 = g.trainer.global_position + HAND - global_position
	var to: Vector2 = target.global_position + Vector2(0, -10) - global_position
	draw_rect(Rect2(dev - DEVICE * 0.5, DEVICE), Pal.c("stone_lt"))
	draw_rect(Rect2(dev - DEVICE * 0.5, DEVICE), Pal.c("ink"), false, 1.0)
	draw_circle(dev + Vector2(2, 0), 2.5, Pal.c("glint"))
	draw_line(dev + Vector2(-3, 3), dev + Vector2(-3, 8), Pal.c("stone"), 2.0)
	if not scanning:
		return
	var flick: float = 0.7 + 0.3 * sin(_t * 30.0)
	draw_line(dev, to, Pal.c("glint", 0.5 * flick), BEAM_W * 2.0)
	draw_line(dev, to, Pal.c("sun", flick), 1.0)
	for k: int in SCAN_LINES:
		var y: float = fmod(_t * 30.0 + k * 9.0, 26.0) - 13.0
		draw_line(to + Vector2(-12, y), to + Vector2(12, y), Pal.c("glint", 0.6), 1.0)
	draw_arc(to, RING_R, 0.0, TAU, 32, Color(Pal.c("ink"), 0.7), RING_W + 2.0)
	draw_arc(to, RING_R, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Pal.c("glint"), RING_W)
