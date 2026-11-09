class_name SetPiece
extends Sprite2D
## A big piece of the world placed by hand: an elder tree, a large tree, the gate, the
## Colossus's head, a ruin wall, a pillar (art/world/ruins_edge_v3). One sprite that stands on
## its foot: the node's position is the piece's foot (the base of the trunk, wall or tower) and
## its y-sort point, and the sprite is drawn uncentred at `offset = -origin`. Under a y-sorted
## parent the hero walks in front of it south of the foot and behind it north of the foot.
## A mirrored piece is drawn with `flip_h`, its offset measured from its mirrored origin.
##
## Its collision is a StaticBody2D child (a flat box at the base), and its parent sits in the
## zone's navigation_obstacles group, so the navmesh carves it out like any wall.
##
## A piece tall enough to hide the hero (a canopy, a gate tower) fades while he stands behind
## it, so a fight is never hidden. Its light comes from the parent's material (LightPools), so
## it dims with the ground around it.

## Alpha of a faded piece: the hero shows through, the piece still reads.
const FADED_ALPHA := 0.42
## How fast the alpha moves, per second.
const FADE_SPEED := 5.0
## The middle of the hero's body above his foot: he is covered when that point is over the piece.
const PLAYER_BODY_MIDDLE := 20.0
## The piece's outer few pixels (the canopy's ragged edge) don't count as covering him.
const BOUNDS_MARGIN := 12.0

## Fades while the player stands behind the piece (its top covers him).
@export var fades_over_player: bool = false

var _bounds: Rect2


func _ready() -> void:
	centered = false
	if not fades_over_player:
		set_process(false)
		return
	_bounds = get_rect().grow(-BOUNDS_MARGIN)


func _process(delta: float) -> void:
	var player := PlayerFinder.find(self)
	var target := 1.0
	if player != null and _covers(player.global_position):
		target = FADED_ALPHA
	self_modulate.a = move_toward(self_modulate.a, target, FADE_SPEED * delta)


## True when the player, standing at `foot`, is behind the piece and under its art.
func _covers(foot: Vector2) -> bool:
	if foot.y >= global_position.y:
		return false
	return _bounds.has_point(to_local(foot + Vector2.UP * PLAYER_BODY_MIDDLE))
