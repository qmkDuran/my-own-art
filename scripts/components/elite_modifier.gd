class_name EliteModifier
extends Node
## Turns the enemy it is attached to into an elite: more health, more light (XP) when it
## falls, a quiet aura at its feet and a name tag such as "BRISTLING TOXLOP".
## Elites are never scaled up (sprites keep their pixel size); the aura marks them instead
## (see DESIGN.md, "Visual hierarchy"). Attach it as a child of an enemy in a zone scene;
## the enemy's own scripts stay unchanged.

## How much health the elite has compared to a normal one (rounded up).
@export var health_multiplier: float = 3.0
## How many times the normal number of light motes it frees on death.
@export var mote_multiplier: int = 3
## The word in front of the species name on its tag.
@export var title: String = "Bristling"
## The whole name on its tag instead of title + species (e.g. "Quarry Bull" for a stand-in boss).
@export var name_override: String = ""
## Used when the enemy has no `display_name` of its own.
@export var fallback_name: String = "Glimra"
## Height of the name tag above the feet, in pixels (above the sprite and its health bar).
@export var name_tag_height: float = 36.0
## Size of the aura's ground pulse, in pixels (width, height).
@export var aura_size: Vector2 = Vector2(22, 7)

@onready var enemy: Node2D = get_parent()


func _ready() -> void:
	var health: Health = Health.of(enemy)
	health.change_max_health(ceili(health.max_health * health_multiplier) - health.max_health)
	var light_drop := enemy.get_node_or_null("LightDrop") as LightDrop
	if light_drop != null:
		light_drop.mote_count *= mote_multiplier
	_add_aura(health)
	_add_name_tag(health)


func elite_name() -> String:
	if name_override != "":
		return name_override
	var species_name: Variant = enemy.get("display_name")
	if not species_name is String or (species_name as String).is_empty():
		species_name = fallback_name
	return "%s %s" % [title, species_name]


func _add_aura(health: Health) -> void:
	var aura := EliteAura.new()
	aura.name = "EliteAura"
	aura.pulse_size = aura_size
	enemy.add_child.call_deferred(aura)
	# First child, so it draws under the shadow and sprite.
	enemy.move_child.call_deferred(aura, 0)
	health.died.connect(aura.queue_free)


func _add_name_tag(health: Health) -> void:
	var tag := EliteNameTag.new()
	tag.name = "EliteNameTag"
	tag.text = elite_name().to_upper()
	tag.position = Vector2(0, -name_tag_height)
	enemy.add_child.call_deferred(tag)
	health.died.connect(tag.queue_free)
