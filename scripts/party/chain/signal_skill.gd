class_name SignalSkill
extends SwapMove
## A team creature's Intro: an entrance every time it is swapped in, plus a Signal Skill
## (a big burst) when an enemy near the swap spot carries one of its `trigger_statuses`.
## The team card glows with that status's icon only then (Party.armed_status), so pressing
## a lit card is the payoff. With a full Link meter the Signal Skill is a Link Finisher.
## No words pop up: the strike ends in a burst of rings in the creature's element colour
## (gold rings too for a Link Finisher). The chain guide (Tab) names and explains it.
##
## Each creature fills in its entrance (`_arrive`, `_touch_down`), its strike visuals and
## its `guide_line`.

const LINK_DAMAGE_MULTIPLIER := 2
const SIGNAL_BURST_RADIUS := 40.0
const LINK_BURST_RADIUS := 64.0

## The Signal Skill's name, shown in the chain guide (never on the battlefield).
@export var signal_name: String = ""
## The statuses (SetUp names) that fire the Signal Skill, in priority order.
@export var trigger_statuses: Array[String] = []
## How far from the swap spot it looks for set-up enemies, in pixels.
@export var reach: float = 80.0
@export var damage: int = 3
@export var poise_damage: int = 4
## Seconds from the swap to the entrance landing (and the Signal Skill hitting).
@export var arrival_seconds: float = 0.16

## The Party sets this right before `play` when the Link meter is full and this fires.
var is_link_finisher: bool = false


func armed_status_at(spot: Vector2) -> String:
	var nearby := AbilityTargets.within(self, spot, reach)
	for status_name in trigger_statuses:
		for target_health in nearby:
			if SetUp.has(target_health.get_parent(), status_name):
				return status_name
	return ""


func entrance_seconds() -> float:
	return arrival_seconds


func guide_line() -> String:
	return "%d dmg to each set-up enemy within %d px." % [damage, reach]


func play(member: PlayableCreature, _partner: PlayableCreature) -> void:
	var is_armed := is_armed_at(member.global_position)
	_arrive(member, _set_up_targets(member.global_position))
	await member.get_tree().create_timer(arrival_seconds).timeout
	if not is_instance_valid(member) or not member.visible or member.health_component().is_dead():
		is_link_finisher = false
		return
	_touch_down(member)
	if is_armed:
		_fire(member)
	is_link_finisher = false


## Every enemy within reach of `spot` carrying one of the conditions.
func _set_up_targets(spot: Vector2) -> Array[Health]:
	var found: Array[Health] = []
	for target_health in AbilityTargets.within(self, spot, reach):
		for status_name in trigger_statuses:
			if SetUp.has(target_health.get_parent(), status_name):
				found.append(target_health)
				break
	return found


func _fire(member: PlayableCreature) -> void:
	var targets := _strike_targets(member)
	if targets.is_empty():
		return
	if is_link_finisher:
		# Spent only now: a finisher that hits nothing keeps the meter full for the next one.
		LinkMeter.spend_from(member)
	var strike_damage := damage * (LINK_DAMAGE_MULTIPLIER if is_link_finisher else 1)
	_before_strike(member, targets)
	ElementStrike.hit(member, targets, strike_damage, HitFeel.Weight.HEAVY, poise_damage)
	_after_strike(member, targets)
	var world := member.get_parent()
	HitFeel.burst(world, member.global_position, ElementColors.for_element(member.element), SIGNAL_BURST_RADIUS)
	LinkMeter.add_from(member, LinkMeter.PER_SIGNAL)
	if is_link_finisher:
		HitFeel.link_slow_mo(member)
		ImpactFrame.play(member)
		ScreenFlash.play(member, ApolloPalette.GOLD)
		HitFeel.burst(world, member.global_position, ApolloPalette.GOLD, LINK_BURST_RADIUS)


# --- For each creature to fill in ----------------------------------------------

## The entrance starts (the sprite flies, drops or surfaces in). `targets` are the set-up
## enemies near the spot (may be empty).
func _arrive(_member: PlayableCreature, _targets: Array[Health]) -> void:
	pass


## The entrance lands, armed or not (dust, rings, a shake).
func _touch_down(_member: PlayableCreature) -> void:
	pass


## Who the Signal Skill hits (by default every set-up enemy within reach).
func _strike_targets(member: PlayableCreature) -> Array[Health]:
	return _set_up_targets(member.global_position)


func _before_strike(_member: PlayableCreature, _targets: Array[Health]) -> void:
	pass


## After the damage: extra statuses, flames, the creature's pose.
func _after_strike(_member: PlayableCreature, _targets: Array[Health]) -> void:
	pass
