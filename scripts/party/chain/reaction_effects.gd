class_name ReactionEffects
extends RefCounted
## What each element reaction does (the table is in Reactions). Reaction damage goes
## straight through CritRoll, so a reaction never sets off another reaction.

const STEAM_RADIUS := 36.0
const STEAM_DAMAGE := 3
const STEAM_KNOCKBACK := 170.0
const WILDFIRE_RADIUS := 52.0
const WILDFIRE_DAMAGE := 2
const WILDFIRE_BURN_SECONDS := 4.0
const DROWN_DAMAGE := 6
const KINDLING_DAMAGE := 3
const KINDLING_BURN_DAMAGE := 2
const KINDLING_BURN_SECONDS := 5.0
const BLAZE_RADIUS := 30.0
const BLAZE_DAMAGE := 2
const BLAZE_BURN_SECONDS := 3.0
const BODY_OFFSET := Vector2(0, -7)


## Plays reaction `reaction_id` on the enemy with `target_health`. `is_shown` is false for
## the 2nd+ copy in the same beat (smaller show, same damage).
static func play(reaction_id: String, attacker: Node2D, target_health: Health, is_shown: bool) -> void:
	var target := target_health.get_parent() as Node2D
	var at := target.global_position
	var world := target.get_parent()
	match reaction_id:
		Reactions.STEAM_BURST:
			var caught := AbilityTargets.within(attacker, at, STEAM_RADIUS)
			_hurt(attacker, caught, STEAM_DAMAGE)
			AbilityTargets.knock_back_all(caught, at, STEAM_KNOCKBACK)
			var steam: Array[Color] = [ApolloPalette.WHITE, ApolloPalette.SILVER, ApolloPalette.SKY_LIGHT]
			_burst(world, at, steam, 26, STEAM_RADIUS, ApolloPalette.WHITE)
		Reactions.WILDFIRE:
			_hurt(attacker, _single(target_health), WILDFIRE_DAMAGE)
			for other_health in AbilityTargets.within(attacker, at, WILDFIRE_RADIUS):
				Burning.apply_to(other_health, SetUp.BURN_DAMAGE, WILDFIRE_BURN_SECONDS)
				var streak := EmberStreak.new()
				world.add_child(streak)
				streak.play(at + BODY_OFFSET, (other_health.get_parent() as Node2D).global_position + BODY_OFFSET)
			var fire: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.GREEN_LIGHT]
			_burst(world, at, fire, 18, WILDFIRE_RADIUS * 0.6, ApolloPalette.ORANGE)
		Reactions.DROWN:
			_hurt(attacker, _single(target_health), DROWN_DAMAGE)
			var water: Array[Color] = [ApolloPalette.BLUE, ApolloPalette.SKY, ApolloPalette.SKY_LIGHT, ApolloPalette.WHITE]
			var column := PixelDebris.spray(world, at, water, 30, Vector2.UP, 40.0)
			column.speed_range = Vector2(80, 170)
			_burst(world, at, water, 10, 22.0, ApolloPalette.SKY)
		Reactions.KINDLING:
			_hurt(attacker, _single(target_health), KINDLING_DAMAGE)
			Burning.apply_to(target_health, KINDLING_BURN_DAMAGE, KINDLING_BURN_SECONDS)
			var flame := FlameArc.new()
			world.add_child(flame)
			flame.global_position = at + Vector2(0, 2)
			flame.play(Vector2.UP, 24.0, 160.0)
			var embers: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.RED_LIGHT, ApolloPalette.GREEN_DARK]
			_burst(world, at, embers, 16, 20.0, ApolloPalette.ORANGE)
		Reactions.TOXIC_BLAZE:
			var caught := AbilityTargets.within(attacker, at, BLAZE_RADIUS)
			_hurt(attacker, caught, BLAZE_DAMAGE)
			for other_health in caught:
				Burning.apply_to(other_health, SetUp.BURN_DAMAGE, BLAZE_BURN_SECONDS)
			var blaze: Array[Color] = [ApolloPalette.GREEN_LIGHT, ApolloPalette.LIME_PALE, ApolloPalette.ORANGE]
			_burst(world, at, blaze, 20, BLAZE_RADIUS, ApolloPalette.GREEN_LIGHT)
	var spots: Array[Vector2] = [at]
	HitFeel.land(attacker, spots, ElementColors.for_element(ElementStrike.element_of(attacker)),
			HitFeel.Weight.FINISHER if is_shown else HitFeel.Weight.HEAVY)


## What reaction `reaction_id` does, in one plain line with its real numbers (for the chain
## guide), worked out from the constants above so the two can't drift apart.
static func describe(reaction_id: String) -> String:
	match reaction_id:
		Reactions.STEAM_BURST:
			return "%d dmg to every enemy within %d px, knocks them back." % [STEAM_DAMAGE, STEAM_RADIUS]
		Reactions.DROWN:
			return "%d dmg to that enemy." % DROWN_DAMAGE
		Reactions.KINDLING:
			return "%d dmg, then a big burn: %d dmg/s for %d s." % [KINDLING_DAMAGE, KINDLING_BURN_DAMAGE, KINDLING_BURN_SECONDS]
		Reactions.WILDFIRE:
			return "%d dmg; Burning jumps to every enemy within %d px." % [WILDFIRE_DAMAGE, WILDFIRE_RADIUS]
		Reactions.TOXIC_BLAZE:
			return "%d dmg within %d px; all of them catch fire (%d s)." % [BLAZE_DAMAGE, BLAZE_RADIUS, BLAZE_BURN_SECONDS]
	return ""


static func _hurt(attacker: Node2D, targets: Array[Health], damage: int) -> void:
	for target_health in targets:
		CritRoll.deal_damage(attacker, target_health, damage)


## A spray of pixels and a ring the size of the reaction.
static func _burst(world: Node, at: Vector2, palette: Array[Color], amount: int, radius: float, ring_color: Color) -> void:
	var spray := PixelDebris.spray(world, at + BODY_OFFSET, palette, amount, Vector2.UP, 300.0)
	spray.gravity = 120.0
	spray.speed_range = Vector2(30, radius * 3.0)
	Shockwave.spawn(HitFeel.RING_SCENE, world, at, radius, 0.32, ring_color)


static func _single(target_health: Health) -> Array[Health]:
	var one: Array[Health] = [target_health]
	return one
