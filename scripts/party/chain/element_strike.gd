class_name ElementStrike
extends RefCounted
## Every hit a team creature lands goes through here, so every hit plays the same game:
## damage (with crits), the hit feel, poise drained (Break), cooldowns shaved, the Link
## meter filled, and any element reaction the target's statuses allow.

## Seconds every one of the attacker's cooldowns loses per landed hit ("keep hitting").
const COOLDOWN_SHAVE_PER_HIT := 0.15
## The wordless Break cue: a cream burst this wide.
const BREAK_BURST_RADIUS := 26.0


## Hits each target for `damage` with the attacker's element, then everything above.
static func hit(attacker: Node2D, targets: Array[Health], damage: int,
		weight: HitFeel.Weight = HitFeel.Weight.LIGHT, poise_damage: int = 1) -> void:
	var element := element_of(attacker)
	var spots: Array[Vector2] = []
	for target_health in targets:
		var reaction := Reactions.find_for(target_health.get_parent(), element)
		CritRoll.deal_damage(attacker, target_health, damage)
		spots.append(_feet_of(target_health))
		_after_hit(attacker, target_health, poise_damage, reaction)
	HitFeel.land(attacker, spots, ElementColors.for_element(element), weight)


## Everything but the damage, for a light hit that already dealt its own (Emberoo's jabs).
static func after_damage(attacker: Node2D, target_health: Health, poise_damage: int) -> void:
	var element := element_of(attacker)
	_after_hit(attacker, target_health, poise_damage, Reactions.find_for(target_health.get_parent(), element))
	var spots: Array[Vector2] = [_feet_of(target_health)]
	HitFeel.land(attacker, spots, ElementColors.for_element(element), HitFeel.Weight.LIGHT)


## The element of a team creature ("" for anything else).
static func element_of(attacker: Node) -> String:
	var member := attacker as PlayableCreature
	return member.element if member != null else ""


static func _after_hit(attacker: Node2D, target_health: Health, poise_damage: int, reaction: Reactions.Reaction) -> void:
	LinkMeter.add_from(attacker, LinkMeter.PER_HIT)
	var member := attacker as PlayableCreature
	if member != null:
		member.skill_bar.shave_cooldowns(COOLDOWN_SHAVE_PER_HIT)
	if Poise.drain(target_health, poise_damage):
		var target := target_health.get_parent() as Node2D
		HitFeel.burst(target.get_parent(), target.global_position, ApolloPalette.CREAM, BREAK_BURST_RADIUS)
	if reaction != null:
		Reactions.trigger(reaction, attacker, target_health)


static func _feet_of(target_health: Health) -> Vector2:
	return (target_health.get_parent() as Node2D).global_position
