class_name LevelUpBoost
extends Node
## The small automatic "ding" boost the creature gets each level: more max health,
## a "LEVEL UP!" shout and two golden rings.
##
## Levels live on Progression (which survives a restart), so the boosts for levels
## already reached are given again whenever the creature spawns.

## Max health gained per level.
const HEALTH_PER_LEVEL := 1
## Height of the rings above the creature's feet, in pixels (negative is up).
const RING_HEIGHT := Creature.BODY_HEIGHT

@export var health: Health
@export var speech_bubble: SpeechBubble
## The ring effect shown on a level up.
@export var ring_scene: PackedScene

@onready var creature: Node2D = get_parent()


func _ready() -> void:
	_apply_reached_levels()
	Progression.leveled_up.connect(_on_leveled_up)


func _apply_reached_levels() -> void:
	health.max_health += HEALTH_PER_LEVEL * (Progression.level - 1)
	health.current_health = health.max_health


func _on_leveled_up(_new_level: int) -> void:
	health.max_health += HEALTH_PER_LEVEL
	health.heal(HEALTH_PER_LEVEL)
	speech_bubble.say("LEVEL UP!", 1.0)
	if ring_scene == null:
		return
	for ring_size in [18.0, 28.0]:
		Shockwave.spawn(ring_scene, creature.get_parent(), creature.global_position + Vector2(0, RING_HEIGHT), ring_size, 0.45, Color(ApolloPalette.GOLD, 0.9))
