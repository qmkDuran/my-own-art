class_name Befriending
extends Node2D
## Winning a wild creature over: once it is dazed (weak enough), stand near it and hold F. A ring fills around it
## over `hold` seconds; letting go, being hit, rolling, moving away or the creature fainting breaks it off. Then it
## joins your team (if there is room) with a burst of light; a shiny one sparkles and chimes.

signal befriended(rec: CreatureRecord)

const RING_R: float = 22.0
const RING_W: float = 3.0
const JOIN_LIFE: float = 0.5

var g: TamerGame
var target: Creature
var progress: float = 0.0


func setup(game: TamerGame) -> void:
	g = game
	z_index = Fx.FX_Z
	g.trainer.hurt.connect(func() -> void:
		if progress > 0.0:
			_cancel()
			g.hud.notice("Interrupted!"))


func held() -> bool:
	return Input.is_action_pressed("interact") or bool(get_meta("forced", false))


func _process(delta: float) -> void:
	var tr: Trainer = g.trainer
	if not held() or not tr.alive() or tr.rolling() or tr.walking():
		_cancel()
		return
	if target == null or not _valid(target):
		_cancel()
		target = _nearest_dazed()
		if target == null:
			return
	progress += delta / float(TamerData.rule("befriend.hold"))
	global_position = target.global_position
	queue_redraw()
	if progress >= 1.0:
		_win(target)


func _valid(c: Creature) -> bool:
	return is_instance_valid(c) and c.alive() and c.dazed and \
		c.global_position.distance_to(g.trainer.global_position) <= float(TamerData.rule("befriend.range"))


func _nearest_dazed() -> Creature:
	var best: Creature = null
	var best_d: float = INF
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var c := n as Creature
		var d: float = c.global_position.distance_to(g.trainer.global_position)
		if _valid(c) and d < best_d:
			best = c
			best_d = d
	return best


func _cancel() -> void:
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
