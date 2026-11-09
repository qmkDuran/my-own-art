class_name PlayableCreature
extends CharacterBody2D
## What every creature the player can control has in common, so a team can hold different
## kinds side by side: Emberoo (Creature, 5 views) and the front-view Glimra
## (FrontViewCreature, e.g. Toxlop and Zephoot).
##
## The SkillBar, enemy attacks (PlayerHit, Staggered) and the Party only talk to this.
## Each kind fills in the methods below; the team card fields describe it on the HUD.

## The name shown on the team card.
@export var display_name: String = ""
## Its element (see PROJECT_B.md, "Elements"); picks its colour on the team card and swap burst.
@export var element: String = ""
## A small picture of it (one sprite frame) for the team card.
@export var team_icon: Texture2D
## Whether its defeat restarts the level. A Party turns this off and swaps in the next creature.
@export var restarts_level_on_death: bool = true

## Seconds left of the brief untouchable moment after being swapped in (the Party sets it).
var entrance_shield_left: float = 0.0

@onready var player_input: PlayerInput = $PlayerInput
@onready var mouse_orders: MouseOrders = $MouseOrders
@onready var health: Health = $Health
@onready var hit_flash: HitFlash = $HitFlash
@onready var skill_bar: SkillBar = $SkillBar


## Where its attacks go: a unit vector toward the mouse cursor.
func aim_direction() -> Vector2:
	return Vector2.DOWN


## Whether a skill may start now (not mid-leap, shoved, staggered or defeated).
func can_start_skill() -> bool:
	return true


## Shoves it: it slides with this velocity for `duration` seconds without player control.
func push(_push_velocity: Vector2, _duration: float) -> void:
	pass


## Cuts off whatever it is doing (an attack or a skill), e.g. a stagger or a team swap.
func interrupt() -> void:
	pass


## Counts down the swap-in shield; each kind calls this every physics frame.
func count_down_entrance_shield(delta: float) -> void:
	entrance_shield_left = maxf(0.0, entrance_shield_left - delta)


func has_entrance_shield() -> bool:
	return entrance_shield_left > 0.0


## Shows its "leaving" pose right before a swap takes it off the field (the swap's flash
## copies that frame).
func show_exit_pose() -> void:
	pass


## Plays its entrance pose as a swap brings it in.
func play_entrance_pose() -> void:
	pass


## Its Health, which every playable creature has (also before it is ready, unlike `health`).
func health_component() -> Health:
	return get_node("Health") as Health


## A defeat restarts the level, unless a Party handles it.
func _on_defeated() -> void:
	if restarts_level_on_death:
		get_tree().reload_current_scene.call_deferred()
