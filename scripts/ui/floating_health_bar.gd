class_name FloatingHealthBar
extends Node2D
## A small health bar above an enemy. Hidden until the enemy is first hit,
## so a crowd of untouched enemies doesn't clutter the screen.
##
## It's UI, not part of the world, so the night darkness and lights never touch it.

@export var health: Health
## Width of the bar, in pixels.
@export var bar_width: float = 14.0
@export var border_color: Color = Color(0.035, 0.039, 0.078)
@export var empty_color: Color = Color(0.255, 0.114, 0.192)
@export var fill_color: Color = Color(0.812, 0.341, 0.235)

const UNSHADED := preload("res://scenes/effects/unshaded_material.tres")


func _ready() -> void:
	material = UNSHADED
	visible = false
	health.damaged.connect(_on_damaged)
	health.died.connect(hide)


func _on_damaged(_amount: int, _source_position: Vector2) -> void:
	visible = not health.is_dead()
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(Vector2(-bar_width / 2.0 - 1.0, 0), Vector2(bar_width + 2.0, 4))
	var inner := outer.grow(-1)
	draw_rect(outer, border_color)
	draw_rect(inner, empty_color)
	var share_left := float(health.current_health) / float(health.max_health)
	draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * share_left), inner.size.y)), fill_color)
