class_name AllyMarker
extends Node2D
## A thin ring at a team creature's feet in its element's colour, so a playable Toxlop or
## Zephoot never reads as one of the enemy Toxlops or Zephoots (they share the same sprites).

## Half-width and half-height of the flat ring, in pixels.
const RING_RADII := Vector2(7, 3)
const RING_POINTS := 16
const RING_ALPHA := 0.8


func _draw() -> void:
	var member := get_parent() as PlayableCreature
	var color := ElementColors.for_element(member.element) if member != null else ApolloPalette.WHITE
	var points := PackedVector2Array()
	for step in RING_POINTS + 1:
		var angle := TAU * step / RING_POINTS
		points.append(Vector2(cos(angle) * RING_RADII.x, sin(angle) * RING_RADII.y))
	draw_polyline(points, Color(color, RING_ALPHA), 1.0)
