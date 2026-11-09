class_name RangeKeeping
extends RefCounted
## Keeping a distance band from the player (ranged enemies: Zephoot, Rimoth, the Warden
## Marksman): back away when they're too close (turning aside from walls), close in along
## the path when they're too far, and hold still in between.


## Which way `body` should walk to stay between `band.x` and `band.y` pixels from `player`:
## away, toward, or zero when it's in the band (or pinned with nowhere to back away to).
static func direction(path_mover: PathMover, body: Node2D, player: Node2D, band: Vector2) -> Vector2:
	var distance := body.global_position.distance_to(player.global_position)
	if distance < band.x:
		return path_mover.direction_away_from(player.global_position)
	if distance > band.y:
		return path_mover.direction_toward(player.global_position)
	return Vector2.ZERO


## True when `body` is between `band.x` and `band.y` pixels from `player`.
static func is_in_band(body: Node2D, player: Node2D, band: Vector2) -> bool:
	var distance := body.global_position.distance_to(player.global_position)
	return distance >= band.x and distance <= band.y
