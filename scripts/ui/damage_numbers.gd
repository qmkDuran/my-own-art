class_name DamageNumbers
extends Node
## Pops a DamageNumber over every enemy that takes a hit (toads, Wardens, the training dummy)
## and over the player for each status tick.
##
## Lives once in the level and watches the scene tree: any enemy (a member of `target_group`
## with a child "Health") gets numbers as soon as it appears, including ones summoned later,
## so new enemies need nothing extra. The player's hits show on its heart instead, but its
## status ticks (e.g. poison) pop numbers here too, so the player sees what is hurting them.
## Numbers are added to the world, not the enemy, so they finish rising after a kill.
## Status ticks get numbers in their element's colour (see DamageNumber).

## Enemies in this group get damage numbers.
@export var target_group: String = "enemies"
## Members of this group (the player) get numbers for status ticks only, never for hits.
@export var ticks_only_group: String = "player"
## Pixels above the top of the enemy's sprite where numbers start.
@export var gap_above_sprite: float = 2.0
## Height used when an enemy has no "Sprite" child to measure, in pixels above its feet.
@export var fallback_height: float = 16.0
## Numbers start up to this many pixels left or right, so quick hits don't overlap.
@export var horizontal_spread: int = 4
## Draw order over the world (creatures sit at 1, speech bubbles at 3).
@export var number_z_index: int = 3


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	for group in [target_group, ticks_only_group]:
		for target in get_tree().get_nodes_in_group(group):
			_watch(target.get_node_or_null("Health") as Health)


## Catches targets that join after the level started (e.g. toads a Warden summons).
func _on_node_added(node: Node) -> void:
	if node is Health and node.get_parent() != null:
		_watch(node as Health)


## Watches a target's hits, if it is in one of the groups.
func _watch(health: Health) -> void:
	if health == null:
		return
	var target := health.get_parent()
	var ticks_only := not target.is_in_group(target_group)
	if ticks_only and not target.is_in_group(ticks_only_group):
		return
	var on_hit := _on_hit.bind(target, ticks_only)
	if not health.hit_taken.is_connected(on_hit):
		health.hit_taken.connect(on_hit)


func _on_hit(amount: int, is_critical: bool, damage_type: Health.DamageType, target: Node2D, ticks_only: bool) -> void:
	if ticks_only and damage_type == Health.DamageType.DIRECT:
		return
	var world := target.get_parent()
	if world == null:
		return
	var number := DamageNumber.new()
	number.z_index = number_z_index
	world.add_child(number)
	var spread := randi_range(-horizontal_spread, horizontal_spread)
	number.global_position = (target.global_position + Vector2(spread, -_number_height(target))).round()
	number.pop(amount, is_critical, damage_type)


## How far above the target's feet its numbers start: just over the top of its sprite.
func _number_height(target: Node2D) -> float:
	var sprite := target.get_node_or_null("Sprite") as Node2D
	var sprite_top := _sprite_top(sprite)
	if is_nan(sprite_top):
		return fallback_height
	return -sprite_top + gap_above_sprite


## The top edge of a Sprite2D or AnimatedSprite2D, relative to its parent; NAN if unknown.
func _sprite_top(sprite: Node2D) -> float:
	if sprite is Sprite2D and (sprite as Sprite2D).texture != null:
		return sprite.position.y + (sprite as Sprite2D).get_rect().position.y
	if sprite is AnimatedSprite2D:
		var animated := sprite as AnimatedSprite2D
		var frames := animated.sprite_frames
		if frames == null or not frames.has_animation(animated.animation):
			return NAN
		var texture := frames.get_frame_texture(animated.animation, animated.frame)
		if texture == null:
			return NAN
		var half_height := texture.get_height() / 2.0 if animated.centered else 0.0
		return sprite.position.y + animated.offset.y - half_height
	return NAN
