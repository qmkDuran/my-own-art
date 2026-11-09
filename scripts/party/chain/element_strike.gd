class_name ElementStrike
extends RefCounted
## Every hit a team creature lands goes through here, so every hit plays the same game:
## damage (with crits), the hit feel, poise drained (Break), cooldowns shaved, the Link
## meter filled, and any element reaction the target's statuses allow.

## Seconds every one of the attacker's cooldowns loses per landed hit ("keep hitting").
const COOLDOWN_SHAVE_PER_HIT := 0.15
const BREAK_WORD := "BREAK!"
const WORD_HEIGHT := -22.0


## Hits each target for `damage` with the attacker's element, then everything above.
static func hit(attacker: Node2D, targets: Array[Health], damage: int,
		weight: HitFeel.Weight = HitFeel.Weight.LIGHT, poise_damage: int = 1) -> void:
	var element := element_of(attacker)
	var spots: Array[Vector2] = []
	for target_health in targets:
		var reaction := Reactions.find_for(target_health.get_parent(), element)
		CritRoll.deal_damage(attacker, target_health, damage)
		spots.append((target_health.get_parent() as Node2D).global_position)
		after_hit(attacker, target_health, poise_damage, reaction)
	HitFeel.land(attacker, spots, ElementColors.for_element(element), weight)


## The rest of a hit whose damage was already dealt elsewhere (e.g. Emberoo's jabs).
static func after_hit(attacker: Node2D, target_health: Health, poise_damage: int, reaction: Dictionary) -> void:
	LinkMeter.add_from(attacker, LinkMeter.PER_HIT)
	var skill_bar := attacker.get_node_or_null("SkillBar") as SkillBar
	if skill_bar != null:
		skill_bar.shave_cooldowns(COOLDOWN_SHAVE_PER_HIT)
	if Poise.drain(target_health, poise_damage):
		var target := target_health.get_parent() as Node2D
		WordBurst.pop(target.get_parent(), target.global_position + Vector2(0, WORD_HEIGHT), BREAK_WORD, ApolloPalette.CREAM)
	if not reaction.is_empty():
		Reactions.trigger(reaction, attacker, target_health)


## The element of a team creature ("" for anything else).
static func element_of(attacker: Node) -> String:
	var member := attacker as PlayableCreature
	return member.element if member != null else ""
