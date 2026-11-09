class_name GlimmerShard
extends Node2D
## A hand-placed Glimmer Shard: a small glowing crystal that floats over its spot. Walking
## over it gives its permanent upgrade (`reward`, see ShardReward) and records it in
## ShardInventory, which shows the toast and keeps it from appearing (or paying) again.

## Height the crystal floats above its spot, and how far it bobs, in pixels.
const FLOAT_HEIGHT := 10.0
const BOB_PIXELS := 2.0
const BOB_SPEED := 2.5
## Seconds for one slow pulse of the glow under it.
const PULSE_SECONDS := 1.6
const GLOW_RADIUS := 7.0
const SPARKLE_COUNT := 3
const SPARKLE_REACH := 8.0

## Unique across the game (e.g. "ruins_edge_shrine"): the save remembers shards by this ID.
@export var shard_id: String = ""
## The permanent upgrade it gives (see ShardReward).
@export var reward: ShardReward.Kind = ShardReward.Kind.CHIP_SLOT
## How close the player must be to pick it up, in pixels.
@export var pickup_radius: float = 10.0

var _age: float = 0.0

@onready var crystal: Sprite2D = $Crystal


func _ready() -> void:
	if shard_id.is_empty():
		push_warning("GlimmerShard at %s has no shard_id; it can't be saved." % global_position)
	if ShardInventory.has_found(shard_id):
		# Found in an older save, before shards gave upgrades: it pays out now, once.
		ShardInventory.fill_in_reward(shard_id, reward)
		set_process(false)
		queue_free()


func _process(delta: float) -> void:
	_age += delta
	crystal.position.y = roundf(-FLOAT_HEIGHT + sin(_age * BOB_SPEED) * BOB_PIXELS)
	_try_pickup()
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 - 0.5 * cos(TAU * _age / PULSE_SECONDS)
	draw_circle(Vector2(0, 1), 4.0, Color(ApolloPalette.OUTLINE, 0.35))  # ground shadow
	draw_circle(Vector2(0, -FLOAT_HEIGHT), GLOW_RADIUS, Color(ApolloPalette.SKY, 0.10 + 0.12 * pulse))
	for index in SPARKLE_COUNT:
		var phase := fmod(_age * 0.7 + float(index) / SPARKLE_COUNT, 1.0)
		var angle := TAU * (float(index) / SPARKLE_COUNT) + _age * 0.5
		var at := Vector2(cos(angle), sin(angle) * 0.6) * SPARKLE_REACH + Vector2(0, -FLOAT_HEIGHT - phase * 6.0)
		draw_rect(Rect2(at.round(), Vector2.ONE), Color(ApolloPalette.WHITE, sin(PI * phase)))


func _try_pickup() -> void:
	var player := PlayerFinder.find(self)
	if player == null or player.global_position.distance_to(global_position) > pickup_radius:
		return
	if ShardInventory.collect(shard_id, reward):
		ShardReward.apply_live(player, reward)
	queue_free()
