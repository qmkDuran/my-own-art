class_name HybridControl
extends Node
## Hybrid control: hold the control key (Shift) to steer your creature directly; let go to hand back to the
## trainer, and it goes back to following. Whoever you steer wears the gold outline; the camera eases over to them
## (a focus point blended between the two, so movement itself never lags) while the trainer waits where they stand.
## The creature cannot wander past a leash. If it is knocked out you are handed back at once.

signal toggled(on: bool)

var g: TamerGame
var focus: Node2D                       ## what the camera follows: eases between the trainer and the creature
var on: bool = false
var blend: float = 0.0                  ## 0: the camera is on the trainer, 1: on the creature
var _brain: ControlledBrain


func setup(game: TamerGame) -> void:
	g = game
	focus = Node2D.new()
	g.add_child(focus)
	focus.global_position = g.trainer.global_position
	g.field.partner_changed.connect(func(_c: Creature) -> void:
		if on:
			release())
	g.trainer.set_highlight(true)


func controlled() -> Combatant:
	return g.field.partner if on else g.trainer


func take() -> bool:
	var c: Creature = g.field.partner
	if on or c == null or not c.alive() or not g.trainer.alive():
		return false
	on = true
	g.trainer.stop()
	_brain = ControlledBrain.new(c)
	c.brain = _brain
	c.view.set_highlight(true)
	g.trainer.set_highlight(false)
	Audio.sfx("ui_click", -6.0, 1.3)
	toggled.emit(true)
	return true


func release() -> void:
	if not on:
		return
	on = false
	var c: Creature = g.field.partner
	if c != null and is_instance_valid(c):
		c.brain = PartnerBrain.new(c)
		c.view.set_highlight(false)
	_brain = null
	g.trainer.set_highlight(true)
	Audio.sfx("ui_click", -8.0, 0.9)
	toggled.emit(false)


func brain() -> ControlledBrain:
	return _brain


func _physics_process(delta: float) -> void:
	var c: Creature = g.field.partner
	var has: bool = c != null and is_instance_valid(c)
	var k: float = minf(1.0, float(TamerData.rule("control.camera_ease")) * delta)
	blend = lerpf(blend, 1.0 if on and has else 0.0, k)
	var other: Vector2 = c.global_position if has else g.trainer.global_position
	focus.global_position = g.trainer.global_position.lerp(other, smoothstep(0.0, 1.0, blend))
	if on and has:
		_leash(c)


## Past the leash the creature is held at its edge (it can circle you, not run away).
func _leash(c: Creature) -> void:
	var limit: float = float(TamerData.rule("control.leash"))
	var off: Vector2 = c.global_position - g.trainer.global_position
	if off.length() > limit:
		c.global_position = g.trainer.global_position + off.limit_length(limit)
