class_name SkillAction
extends Node
## What a skill does when it fires. Each skill has its own action node under the SkillBar.
##
## The SkillBar handles keys, slots, Heat and cooldowns; an action only plays the move.
## While an action is casting, the creature stands still (or moves as `caster_velocity` says)
## and shows `animation_name` instead of walking or jabbing.

## The skill's data (name, icon, cost, cooldown).
@export var skill: Skill
## Which skill-bar slot holds this skill (0 = Q, 1 = W, 2 = E, 3 = R).
@export_range(0, 3) var slot_index: int = 0
## The creature animation shown while casting (see CreatureAnimator.ANIMATION_SETTINGS).
@export var animation_name: String = "jab"

var is_casting: bool = false


## Starts the move. `caster` is the creature using it; `aim_direction` is a unit vector.
func start(_caster: Node2D, _aim_direction: Vector2) -> void:
	is_casting = true


## Stops the move right away. Safe to call when not casting.
func cancel() -> void:
	is_casting = false


## Whether pressing the skill's key again while it plays ends it (e.g. dropping Ash Guard).
func ends_on_second_press() -> bool:
	return false


## Whether a dodge may cut the move short right now.
func can_be_cancelled() -> bool:
	return true


## How the caster moves while casting, in pixels per second (zero = rooted).
func caster_velocity() -> Vector2:
	return Vector2.ZERO


## How far the caster's sprite is lifted off the ground right now, in pixels.
func caster_lift() -> float:
	return 0.0


## Whether enemy attacks pass through the caster right now (e.g. mid-leap or mid-dash).
func makes_caster_invulnerable() -> bool:
	return false


## What the skill does, in one plain line with its real numbers (for the chain guide, Tab).
## Each action fills it in from its own exported values, so the guide can't drift.
func guide_line() -> String:
	return ""


## The status (a SetUp name) this skill puts on enemies, "" for none. The chain guide shows
## its icon next to the skill, so set-ups are easy to spot.
func set_up_status() -> String:
	return ""
