class_name ReachMarker
extends Node2D
## A wind-up's reach drawn on the ground around an enemy (e.g. a Bramole's root snare, a
## Fizzbug's burst): a faint dotted ring where the attack will reach, and a brighter ring
## growing out to it as the wind-up runs, so the player sees both how far and how soon.
## Only shown during a wind-up (an event), never ambient. Pixel-snapped, so it stays crisp.
##
## The enemy calls `show_reach`, then `set_progress` every frame of the wind-up, then `hide_reach`.

## Pixels between the dots of the outer ring.
const DOT_SPACING := 4.0
## How opaque the dotted ring is; the growing ring is fully opaque.
const DOTTED_ALPHA := 0.55
## Squash of the ring, so it lies flat on the ground (1 = round).
const GROUND_SQUASH := 0.6

var _radius: float = 0.0
var _color: Color = ApolloPalette.WHITE
var _progress: float = 0.0


func _ready() -> void:
	z_index = -1
	visible = false


## Shows the ring for an attack reaching `radius` pixels, in `color`.
func show_reach(radius: float, color: Color) -> void:
	_radius = radius
	_color = color
	_progress = 0.0
	visible = true
	queue_redraw()


## How far through the wind-up it is, from 0 to 1 (the inner ring reaches the edge at 1).
func set_progress(progress: float) -> void:
	_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func hide_reach() -> void:
	visible = false


func _draw() -> void:
	var dots := maxi(8, roundi(TAU * _radius / DOT_SPACING))
	for dot in dots:
		_draw_pixel_at(_radius, TAU * dot / dots, Color(_color, DOTTED_ALPHA))
	var inner_radius := _radius * _progress
	var inner_pixels := maxi(8, roundi(TAU * inner_radius))
	for pixel in inner_pixels:
		_draw_pixel_at(inner_radius, TAU * pixel / inner_pixels, _color)


func _draw_pixel_at(radius: float, angle: float, color: Color) -> void:
	var at := Vector2(cos(angle) * radius, sin(angle) * radius * GROUND_SQUASH)
	draw_rect(Rect2(at.round(), Vector2.ONE), color)
