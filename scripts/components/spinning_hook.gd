class_name SpinningHook
extends Node
## The Spinning Hook: the last punch of a jab combo, a full turn on the spot that hits
## every enemy around the attacker and throws them outward.
##
## MeleeAttack plays it as its combo finisher (it owns the timing, buffering and cancel
## rules); this node holds the hook's numbers and lands the hit when told to.
## Damage goes through CritRoll, so the attacker's critical hits apply.
## Keep the turn's look (SpinTurn) roughly in step with `hit_delay` and `attack_duration`.
## It only ends the combo once its Ember Tree node ("spinning_hook") is learned.

## Animation the attacker plays while spinning (posed view by view, see SpinTurn).
@export var animation_name: String = "spin"
## Seconds from starting the spin to the hook landing.
@export var hit_delay: float = 0.18
## Seconds the whole spin takes, start to recovery.
@export var attack_duration: float = 0.5
## How far from the attacker's fist height an enemy's body centre may be to get hit, in pixels.
@export var radius: float = 24.0
## Damage dealt to each enemy in the circle.
@export var damage: int = 2
## Speed enemies are thrown outward at, in pixels per second (Flame Uppercut uses 260).
@export var knockback_speed: float = 170.0
## Height of the fists above the attacker's feet, where the circle is centred (negative is up).
@export var fist_height: float = -7.0
## Height of a target's body centre above its feet, in pixels (negative is up).
@export var target_body_height: float = -6.0
## Group whose members the hook can hurt (each needs a child node named "Health").
@export var target_group: String = "enemies"

@export_group("Feel")
@export var screen_shake: ScreenShake
## Camera shake when the hook lands: strength in pixels and length in seconds.
@export var shake_strength: float = 1.0
@export var shake_duration: float = 0.1


## Whether the hook is learned in the Ember Tree (this node's name is its skill action).
func is_unlocked() -> bool:
	return EmberTree.is_skill_unlocked(name)


## Lands the hook all around `attacker`: the fire ring, a small shake, and damage plus
## knockback to every target in the circle. Returns the Health of every target hit.
func strike(attacker: Node2D) -> Array[Health]:
	var centre := attacker.global_position + Vector2(0, fist_height)
	_spawn_fire_ring(attacker, centre)
	if screen_shake != null:
		screen_shake.shake(shake_strength, shake_duration)
	var struck: Array[Health] = []
	for target: Node2D in get_tree().get_nodes_in_group(target_group):
		var body_centre := target.global_position + Vector2(0, target_body_height)
		if body_centre.distance_to(centre) > radius:
			continue
		var target_health: Health = target.get_node_or_null("Health")
		if target_health == null:
			continue
		# A sweep: it comes round a shell guard (see BrinelobShellGuard).
		CritRoll.deal_damage(attacker, target_health, damage, Health.HitKind.SWEEP)
		_knock_back(target, attacker)
		struck.append(target_health)
	return struck


func _spawn_fire_ring(attacker: Node2D, centre: Vector2) -> void:
	var ring := FireRing.new()
	# Added to the world, not the attacker, so the ring stays where the hook landed.
	attacker.get_parent().add_child(ring)
	ring.global_position = centre.round()
	ring.play(radius)


## Enemies that know how (a `knock_back(velocity)` method) are thrown straight away from
## the attacker. Others keep their normal hit reaction.
func _knock_back(target: Node2D, attacker: Node2D) -> void:
	if not target.has_method("knock_back"):
		return
	var away := target.global_position - attacker.global_position
	if away.length() < 0.1:
		away = Vector2.DOWN
	target.call("knock_back", away.normalized() * knockback_speed)
