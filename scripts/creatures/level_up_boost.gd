class_name LevelUpBoost
extends Node
## The small automatic "ding" boost the creature gets each level: more max health,
## a "LEVEL UP!" shout and two golden rings.
##
## Levels live on Progression (which survives a restart), so the boosts for levels
## already reached are given again whenever the creature spawns.

## Max health gained per level (level 0 is the base, with no bonus).
const HEALTH_PER_LEVEL := 1
## The two golden rings' sizes (pixels), how long they spread, and their colour.
const RING_SIZES: Array[float] = [18.0, 28.0]
const RING_SECONDS := 0.45
const RING_COLOR := Color(ApolloPalette.GOLD, 0.9)
const SHOUT := "LEVEL UP!"
const SHOUT_SECONDS := 1.0

@export var health: Health
@export var speech_bubble: SpeechBubble
## The ring effect shown on a level up.
@export var ring_scene: PackedScene

@onready var creature: Creature = get_parent()


func _ready() -> void:
	_apply_reached_levels()
	Progression.leveled_up.connect(_on_leveled_up)


func _apply_reached_levels() -> void:
	health.max_health += HEALTH_PER_LEVEL * Progression.level
	health.current_health = health.max_health


func _on_leveled_up(_new_level: int) -> void:
	health.max_health += HEALTH_PER_LEVEL
	health.heal(HEALTH_PER_LEVEL)
	speech_bubble.say(SHOUT, SHOUT_SECONDS)
	if ring_scene == null:
		return
	for ring_size in RING_SIZES:
		# Round the middle of his body, whatever his evolution form.
		var ring_centre := creature.global_position + Vector2(0, creature.body_height())
		Shockwave.spawn(ring_scene, creature.get_parent(), ring_centre, ring_size, RING_SECONDS, RING_COLOR)
