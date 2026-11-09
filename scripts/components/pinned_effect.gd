class_name PinnedEffect
extends ImpairingEffect
## A status that holds its target to the spot (Rooted, Broken): each physics frame, after
## the target has moved, it is put back where the effect started. Being a child of the
## target, this runs after the target's own movement, so it works on any enemy without
## the enemy knowing. Hard shoves (a bowling Rolling Thicket) consume it first.

var _anchor: Vector2


func start(seconds: float) -> void:
	super.start(seconds)
	if is_inside_tree():
		_anchor = (target() as Node2D).global_position


func _enter_tree() -> void:
	_anchor = (get_parent() as Node2D).global_position


func _advance(delta: float) -> void:
	super._advance(delta)
	var body := target() as Node2D
	body.global_position = _anchor
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO
