class_name SetUp
extends RefCounted
## The statuses that set enemies up for a teammate (see PROJECT_B.md, "Chaining"): the one
## place that knows their names, whether an enemy has one, and how to put one on.
## Putting on a status the enemy already has stacks it: it drains extra poise, so two
## creatures applying the same status Break an enemy faster.

const BURNING := "Burning"
const SOAKED := "Soaked"
const ROOTED := "Rooted"
## Airborne: thrown up in the air (the Launched status).
const LAUNCHED := "Launched"
const POISONED := "Poisoned"
const STAGGERED := "Staggered"
const BROKEN := "Broken"
## Poise drained when a status lands on an enemy that already has it.
const STACK_POISE_DRAIN := 2
const BURN_DAMAGE := 1
const POISON_DAMAGE := 1
const POISON_TICK_SECONDS := 1.0


## True while `target` carries the status `status_name`.
static func has(target: Node, status_name: String) -> bool:
	var effect := target.get_node_or_null(status_name) as StatusEffect
	return effect != null and effect.is_active()


## Ends `status_name` on `target` at once, if it has it.
static func consume(target: Node, status_name: String) -> void:
	var effect := target.get_node_or_null(status_name) as StatusEffect
	if effect != null and effect.is_active():
		effect.consume()


## Puts `status_name` on the enemy for `seconds`. True when it took.
static func apply(target_health: Health, status_name: String, seconds: float) -> bool:
	if target_health == null or target_health.is_dead():
		return false
	if has(target_health.get_parent(), status_name):
		Poise.drain(target_health, STACK_POISE_DRAIN)
	match status_name:
		SOAKED:
			return Soaked.apply_to(target_health, seconds)
		ROOTED:
			return Rooted.apply_to(target_health, seconds)
		LAUNCHED:
			return Launched.apply_to(target_health, seconds)
		BURNING:
			Burning.apply_to(target_health, BURN_DAMAGE, seconds)
			return true
		POISONED:
			return Poisoned.apply_to(target_health, POISON_DAMAGE, POISON_TICK_SECONDS, seconds)
	return false
