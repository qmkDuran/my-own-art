class_name HitShield
extends Node2D
## Something that stands between hits and a Health (e.g. a Brinelob's shell turning front hits
## away, or a Rimoth's frost shell soaking damage). It joins `health.shields` while it is in the
## tree, and Health asks it about every hit (and every tick) before the damage lands.
## A Node2D so a shield can draw itself on its body.
##
## Each shield overrides:
##   deflects(source_position, kind) -> true turns the whole hit away (no damage, no reaction)
##   soak(amount, kind)              -> the damage it lets through after soaking what it can

## The Health it guards; set before it enters the tree (or found on its parent).
var health: Health


func _enter_tree() -> void:
	if health == null:
		health = get_parent().get_node_or_null("Health") as Health
	if health != null and not health.shields.has(self):
		health.shields.append(self)


func _exit_tree() -> void:
	stop_guarding()


## Stops standing between hits and its Health at once (e.g. a shell that just broke but is
## still playing its shatter).
func stop_guarding() -> void:
	if health != null:
		health.shields.erase(self)


func deflects(_source_position: Vector2, _kind: Health.HitKind) -> bool:
	return false


func soak(amount: int, _kind: Health.HitKind) -> int:
	return amount
