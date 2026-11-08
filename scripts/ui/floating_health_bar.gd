class_name FloatingHealthBar
extends Node2D
## A small health bar above an enemy. Hidden until the enemy is first hit,
## so a crowd of untouched enemies doesn't clutter the screen.

@export var health: Health
## Width of the bar, in pixels.
@export var bar_width: float = 14.0
@export var border_color: Color = ApolloPalette.OUTLINE
@export var empty_color: Color = ApolloPalette.PLUM_DARK
@export var fill_color: Color = ApolloPalette.RED_LIGHT


func _ready() -> void:
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
