class_name Rockfall
extends ShalendrillAttack
## Phase 2's Rockfall: the Shalendrill rears up and pounds its chest, and shale breaks loose
## from the walls above: red circles mark where each boulder will land (one on the player,
## the rest scattered around them), filling as the rocks fall. Keep moving out of the
## circles. It stands catching its breath while they fall: a chance to hit it if you're clear.

## It calls the rocks down when the player is within this distance, in pixels.
@export var trigger_distance: float = 200.0
@export var boulder_count: int = 4
## How far from the player the other boulders land, in pixels (closest, farthest).
@export var scatter_distance: Vector2 = Vector2(22, 60)
## Boulders land at least this far apart, in pixels.
@export var spacing: float = 20.0
@export var boulder_radius: float = 13.0
@export var fall_time: float = 1.1
@export var damage: int = 2
@export var screen_shake: ScreenShake
@export var dust_scene: PackedScene

## Tries per boulder at finding a spot far enough from the others.
const PLACEMENT_TRIES := 8


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player <= trigger_distance


func _release() -> void:
	if screen_shake != null:
		screen_shake.shake(2.0, 0.4)
	var player := PlayerFinder.find(self)
	if player == null:
		return
	for spot in _landing_spots(player.global_position):
		var boulder := FallingBoulder.spawn(captain.get_parent(), spot)
		boulder.radius = boulder_radius
		boulder.fall_time = fall_time
		boulder.damage = damage
		boulder.dust_scene = dust_scene
		boulder.screen_shake = screen_shake


## One spot on the player, the rest scattered around them, none too close together.
func _landing_spots(player_position: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = [player_position]
	while spots.size() < boulder_count:
		spots.append(_spot_apart_from(spots, player_position))
	return spots


func _spot_apart_from(spots: Array[Vector2], around: Vector2) -> Vector2:
	var candidate := around
	for attempt in PLACEMENT_TRIES:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(scatter_distance.x, scatter_distance.y)
		candidate = around + offset
		if spots.all(func(other: Vector2) -> bool: return other.distance_to(candidate) >= spacing):
			break
	return candidate
