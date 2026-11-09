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

const STEAM_COLORS: Array[Color] = [ApolloPalette.WHITE, ApolloPalette.SILVER, ApolloPalette.SKY_LIGHT]
const STEAM_PIXELS := 26
const WILDFIRE_COLORS: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.GREEN_LIGHT]
const WILDFIRE_PIXELS := 18
## Wildfire's own burst is smaller than the reach of its spread.
const WILDFIRE_BURST_SHARE := 0.6
const DROWN_COLORS: Array[Color] = [ApolloPalette.BLUE, ApolloPalette.SKY, ApolloPalette.SKY_LIGHT, ApolloPalette.WHITE]
const DROWN_COLUMN_PIXELS := 30
const DROWN_BURST_PIXELS := 10
const DROWN_BURST_RADIUS := 22.0
const KINDLING_COLORS: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.RED_LIGHT, ApolloPalette.GREEN_DARK]
const KINDLING_PIXELS := 16
const KINDLING_BURST_RADIUS := 20.0
## Kindling's flame: where it rises from (from the feet), how high and how wide (degrees).
const KINDLING_FLAME_OFFSET := Vector2(0, 2)
const KINDLING_FLAME_REACH := 24.0
const KINDLING_FLAME_ARC_DEGREES := 160.0
const BLAZE_COLORS: Array[Color] = [ApolloPalette.GREEN_LIGHT, ApolloPalette.LIME_PALE, ApolloPalette.ORANGE]
const BLAZE_PIXELS := 20
## Every burst's spray: pull down and how wide it fans out (degrees).
const BURST_GRAVITY := 120.0
const BURST_SPREAD_DEGREES := 300.0
const BURST_RING_SECONDS := 0.32


## Plays reaction `reaction_id` on the enemy with `target_health`. `is_shown` is false for
## the 2nd+ copy in the same beat (smaller show, same damage).
static func play(reaction_id: String, attacker: Node2D, target_health: Health, is_shown: bool) -> void:
	var target := target_health.get_parent() as Node2D
	var at := target.global_position
	var world := target.get_parent()
	match reaction_id:
		Reactions.STEAM_BURST:
			_steam_burst(attacker, world, at)
		Reactions.WILDFIRE:
			_wildfire(attacker, target_health, world, at)
		Reactions.DROWN:
			_drown(attacker, target_health, world, at)
		Reactions.KINDLING:
			_kindling(attacker, target_health, world, at)
		Reactions.TOXIC_BLAZE:
			_toxic_blaze(attacker, world, at)
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


## Fire on Soaked: a blast of steam hurts and throws back everything around.
static func _steam_burst(attacker: Node2D, world: Node, at: Vector2) -> void:
	var caught := AbilityTargets.within(attacker, at, STEAM_RADIUS)
	_hurt(attacker, caught, STEAM_DAMAGE)
	AbilityTargets.knock_back_all(caught, at, STEAM_KNOCKBACK)
	_burst(world, at, STEAM_COLORS, STEAM_PIXELS, STEAM_RADIUS, ApolloPalette.WHITE)


## Bloom on Burning: the burn leaps to every enemy around, each one streaked to.
static func _wildfire(attacker: Node2D, target_health: Health, world: Node, at: Vector2) -> void:
	_hurt(attacker, AbilityTargets.single(target_health), WILDFIRE_DAMAGE)
	for other_health in AbilityTargets.within(attacker, at, WILDFIRE_RADIUS):
		Burning.apply_to(other_health, SetUp.BURN_DAMAGE, WILDFIRE_BURN_SECONDS)
		var streak := EmberStreak.new()
		world.add_child(streak)
		streak.play(at + BODY_OFFSET, (other_health.get_parent() as Node2D).global_position + BODY_OFFSET)
	_burst(world, at, WILDFIRE_COLORS, WILDFIRE_PIXELS, WILDFIRE_RADIUS * WILDFIRE_BURST_SHARE, ApolloPalette.ORANGE)


## Tide on Rooted: a column of water crushes the held enemy.
static func _drown(attacker: Node2D, target_health: Health, world: Node, at: Vector2) -> void:
	_hurt(attacker, AbilityTargets.single(target_health), DROWN_DAMAGE)
	var column := PixelDebris.spray(world, at, DROWN_COLORS, DROWN_COLUMN_PIXELS, Vector2.UP, 40.0)
	column.speed_range = Vector2(80, 170)
	_burst(world, at, DROWN_COLORS, DROWN_BURST_PIXELS, DROWN_BURST_RADIUS, ApolloPalette.SKY)


## Fire on Rooted: the vines catch, a flame shoots up and the enemy burns hard.
static func _kindling(attacker: Node2D, target_health: Health, world: Node, at: Vector2) -> void:
	_hurt(attacker, AbilityTargets.single(target_health), KINDLING_DAMAGE)
	Burning.apply_to(target_health, KINDLING_BURN_DAMAGE, KINDLING_BURN_SECONDS)
	var flame := FlameArc.new()
	world.add_child(flame)
	flame.global_position = at + KINDLING_FLAME_OFFSET
	flame.play(Vector2.UP, KINDLING_FLAME_REACH, KINDLING_FLAME_ARC_DEGREES)
	_burst(world, at, KINDLING_COLORS, KINDLING_PIXELS, KINDLING_BURST_RADIUS, ApolloPalette.ORANGE)


## Fire on Poisoned: the toxin flares, hurting and setting alight everything around.
static func _toxic_blaze(attacker: Node2D, world: Node, at: Vector2) -> void:
	var caught := AbilityTargets.within(attacker, at, BLAZE_RADIUS)
	_hurt(attacker, caught, BLAZE_DAMAGE)
	for other_health in caught:
		Burning.apply_to(other_health, SetUp.BURN_DAMAGE, BLAZE_BURN_SECONDS)
	_burst(world, at, BLAZE_COLORS, BLAZE_PIXELS, BLAZE_RADIUS, ApolloPalette.GREEN_LIGHT)


static func _hurt(attacker: Node2D, targets: Array[Health], damage: int) -> void:
	for target_health in targets:
		CritRoll.deal_damage(attacker, target_health, damage)


## A spray of pixels and a ring the size of the reaction.
static func _burst(world: Node, at: Vector2, palette: Array[Color], amount: int, radius: float, ring_color: Color) -> void:
	var spray := PixelDebris.spray(world, at + BODY_OFFSET, palette, amount, Vector2.UP, BURST_SPREAD_DEGREES)
	spray.gravity = BURST_GRAVITY
	spray.speed_range = Vector2(30, radius * 3.0)
	Shockwave.spawn(HitFeel.RING_SCENE, world, at, radius, BURST_RING_SECONDS, ring_color)
