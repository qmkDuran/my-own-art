class_name Befriending
extends Node2D
## Winning a wild creature over is the trainer's job: once one is dazed (weak enough), press F and the trainer walks
## up to it (even mid-battle; your creature keeps fighting) and calms it: a ring fills around it over `hold` seconds.
## Hitting it, rolling, walking elsewhere or it fainting breaks it off. It joins your team (if there is room) with a
## burst of light; a shiny one sparkles and chimes. The dazed creature stops fighting, so the trainer is never at risk.

signal befriended(rec: CreatureRecord)

const RING_R: float = 22.0
const RING_W: float = 3.0
const JOIN_LIFE: float = 0.5
const FIND_RANGE: float = 420.0         ## F looks this far around the trainer for a dazed creature
const REWALK: float = 0.3

var g: TamerGame
var target: Creature
var progress: float = 0.0
var _walk_t: float = 0.0


func setup(game: TamerGame) -> void:
	g = game
	z_index = Fx.FX_Z


## F: the trainer goes to calm the nearest dazed creature. Returns whether there was one.
func request() -> bool:
	cancel()
	target = _nearest_dazed()
	if target == null:
		g.hud.notice("No dazed creature nearby. Weaken one first (its life bar's pink mark).")
		return false
	target.struck.connect(_on_struck, CONNECT_ONE_SHOT)
	g.trainer.walk_to(target.global_position)
	return true


func _process(delta: float) -> void:
	if target == null:
		return
	if not _valid(target) or g.trainer.rolling():
		cancel()
		return
	var tr: Trainer = g.trainer
	if tr.global_position.distance_to(target.global_position) > float(TamerData.rule("befriend.range")):
		_walk_t -= delta
		if _walk_t <= 0.0:
			_walk_t = REWALK
			tr.walk_to(target.global_position)
		return
	tr.stop()
	progress += delta / float(TamerData.rule("befriend.hold"))
	global_position = target.global_position
	queue_redraw()
	if progress >= 1.0:
		_win(target)


func _valid(c: Creature) -> bool:
	return is_instance_valid(c) and c.alive() and c.dazed


func _nearest_dazed() -> Creature:
	var best: Creature = null
	var best_d: float = FIND_RANGE
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var c := n as Creature
		var d: float = c.global_position.distance_to(g.trainer.global_position)
		if _valid(c) and d < best_d:
			best = c
			best_d = d
	return best


## The creature is hit while you calm it: it startles and you start over.
func _on_struck(c: Creature, _by: Combatant) -> void:
	if c == target and progress > 0.0:
		cancel()
		g.hud.notice("Startled! Keep it calm: don't hit it while you befriend it.")


func cancel() -> void:
	if target != null and is_instance_valid(target) and target.struck.is_connected(_on_struck):
		target.struck.disconnect(_on_struck)
	if progress > 0.0:
		progress = 0.0
		queue_redraw()
	target = null


func _win(c: Creature) -> void:
	var rec: CreatureRecord = c.rec
	progress = 0.0
	target = null
	queue_redraw()
	if g.team.full():
		g.hud.notice(String(TamerData.rule("befriend.full_text")))
		return
	TamerFx.celebrate(c, rec.element())
	TamerFx.word(c.global_position, "Befriended!", Pal.c("rose"), UiDraw.TITLE)
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
	g.team.add(rec)
	g.hud.notice(String(TamerData.rule("befriend.join_text")) % rec.display_name())
	befriended.emit(rec)


func _draw() -> void:
	if progress <= 0.0 or target == null:
		return
	var at := Vector2(0, -8)
	draw_arc(at, RING_R, 0.0, TAU, 32, Color(Pal.c("ink"), 0.7), RING_W + 2.0)
	draw_arc(at, RING_R, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Pal.c("rose"), RING_W)
	draw_arc(at, RING_R + 2.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color(Pal.c("sun"), 0.6), 1.0)
