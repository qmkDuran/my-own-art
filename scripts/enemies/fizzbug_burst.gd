class_name FizzbugBurst
extends Node
## A Fizzbug's attack, which is also its end: it glows, flashing faster and faster (with the
## burst's reach shown on the ground), then pops in a ring of sparks. A player inside takes the
## hit and is jolted (Jolted: their next jab comes out a beat late); a dodge passes through.
## Other enemies inside take a hit too, so luring it into a pack pays off.
##
## The Fizzbug decides when to start it and plays the poses; this does the timing, the
## telegraph, the ring and the hits.

## It stops rushing and starts to glow once the player is this close, in pixels.
@export var trigger_distance: float = 20.0
## Seconds it glows before bursting (the player's warning).
@export var glow_time: float = 0.8
## How far the burst reaches, in pixels.
@export var burst_radius: float = 32.0
@export var player_damage: int = 2
## Damage to every other enemy in the ring.
@export var enemy_damage: int = 1
## A jolted player's next jab within `jolt_time` seconds is late by `jolt_delay` seconds.
@export var jolt_delay: float = 0.15
@export var jolt_time: float = 1.0
## Flashes at the start of the glow and right before the burst, this many in all.
@export var glow_flashes: int = 4
@export var glow_color: Color = ApolloPalette.WHITE
@export var hit_flash: HitFlash
@export var reach_marker: ReachMarker

var _flashes_done: int = 0

@onready var fizzbug: Node2D = get_parent()


## True once the player is close enough to start glowing.
func is_player_close() -> bool:
	var player := PlayerFinder.find(self)
	return player != null and fizzbug.global_position.distance_to(player.global_position) <= trigger_distance


func start() -> void:
	_flashes_done = 0
	reach_marker.show_reach(burst_radius, StatusColors.JOLT)


## Call every frame of the glow with the seconds since it started. The flashes come quicker
## toward the end (each falls at a growing share of the glow).
func update(seconds_glowing: float) -> void:
	var progress := seconds_glowing / glow_time
	reach_marker.set_progress(progress)
	var next_flash_at := sqrt(float(_flashes_done) / glow_flashes)
	if _flashes_done < glow_flashes and progress >= next_flash_at:
		_flashes_done += 1
		hit_flash.flash(glow_color)


## Pops: the ring, and a hit on the player and on every other enemy inside it.
func burst() -> void:
	reach_marker.hide_reach()
	SparkBurst.spawn(fizzbug.get_parent(), fizzbug.global_position + Vector2(0, -4), burst_radius)
	_hit_player()
	_hit_other_enemies()


func cancel() -> void:
	reach_marker.hide_reach()


func _hit_player() -> void:
	var player := PlayerFinder.find(self)
	if player == null or not _is_in_ring(player):
		return
	if PlayerHit.try_to_hurt(player, player_damage, fizzbug.global_position):
		Jolted.apply_to(PlayerHit.health_of(player), jolt_delay, jolt_time)


func _hit_other_enemies() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		if enemy == fizzbug or not _is_in_ring(enemy):
			continue
		var enemy_health := enemy.get_node_or_null("Health") as Health
		if enemy_health != null:
			# A ring all round: it gets round a shell guard like a sweep does.
			enemy_health.take_damage(enemy_damage, fizzbug.global_position, false, Health.HitKind.SWEEP)


func _is_in_ring(body: Node2D) -> bool:
	return fizzbug.global_position.distance_to(body.global_position) <= burst_radius
