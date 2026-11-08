class_name PlayerHealthBar
extends Control
## The player's health, shown in the corner of the screen.
##
## Finds the player when the level starts and redraws whenever they take damage.

@export var border_color: Color = Color(0.035, 0.039, 0.078)
@export var empty_color: Color = Color(0.255, 0.114, 0.192)
@export var fill_color: Color = Color(0.812, 0.341, 0.235)
@export var shine_color: Color = Color(0.871, 0.62, 0.255)

var _health: Health


func _ready() -> void:
	# Wait one frame so the player has been added to the level.
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_health = player.get_node_or_null("Health")
	if _health != null:
		_health.damaged.connect(func(_amount: int, _from: Vector2) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	if _health == null:
		return
	var outer := Rect2(Vector2.ZERO, size)
	var inner := outer.grow(-1)
	draw_rect(outer, border_color)
	draw_rect(inner, empty_color)

	var share_left := float(_health.current_health) / float(_health.max_health)
	var filled := Rect2(inner.position, Vector2(roundf(inner.size.x * share_left), inner.size.y))
	draw_rect(filled, fill_color)
	# A one-pixel highlight along the top of the fill.
	draw_rect(Rect2(filled.position, Vector2(filled.size.x, 1)), shine_color)
