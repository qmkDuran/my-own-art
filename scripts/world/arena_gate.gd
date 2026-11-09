class_name ArenaGate
extends StaticBody2D
## An energy gate across an arena entrance: open, it's just two dim emitter studs on the
## ground; closed, cyan energy bars rise between them and a barrier blocks the way (for the
## player and enemies alike). A BossArena closes it when a fight starts and opens it on victory.
## Its origin is the middle of the gate, on the ground.

## Width of the entrance, in pixels.
@export var width: float = 32.0
## Depth of the barrier, in pixels (top to bottom on the ground).
@export var depth: float = 12.0
## How tall the bars stand, in pixels.
@export var bar_height: float = 18.0
## Pixels between neighbouring bars.
@export var bar_spacing: float = 4.0
## Seconds the bars take to rise or sink.
@export var move_seconds: float = 0.4
@export var bar_color: Color = ApolloPalette.SKY
@export var tip_color: Color = ApolloPalette.SKY_LIGHT
@export var stud_color: Color = ApolloPalette.STONE_LIGHT

var is_closed: bool = false

## 0 when open (bars sunk), 1 when closed (bars up).
var _raised: float = 0.0
var _elapsed: float = 0.0
var _collision := CollisionShape2D.new()


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, depth)
	_collision.shape = shape
	_collision.disabled = true
	add_child(_collision)


func close() -> void:
	_move_to(true)


func open() -> void:
	_move_to(false)


func _move_to(closed: bool) -> void:
	is_closed = closed
	_collision.set_deferred("disabled", not closed)
	var bars := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bars.tween_property(self, "_raised", 1.0 if closed else 0.0, move_seconds)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var left := -roundf(width / 2.0)
	var right := left + width - 1.0
	for stud_x in [left, right]:
		draw_rect(Rect2(stud_x - 1.0, -2.0, 3.0, 3.0), ApolloPalette.OUTLINE)
		draw_rect(Rect2(stud_x, -1.0, 1.0, 1.0), tip_color if _raised > 0.0 else stud_color)
	if _raised <= 0.0:
		return
	var height := roundf(bar_height * _raised)
	var bar_x := left + 2.0
	var bar_index := 0
	while bar_x < right - 1.0:
		# Each bar hums: its brightness wavers on its own beat.
		var hum := 0.55 + 0.35 * sin(_elapsed * 6.0 + bar_index * 1.7)
		draw_rect(Rect2(bar_x, -height, 1.0, height), Color(bar_color, hum * _raised))
		draw_rect(Rect2(bar_x, -height, 1.0, 1.0), Color(tip_color, _raised))
		bar_x += bar_spacing
		bar_index += 1
	# A faint cross-beam the bars hang from.
	draw_rect(Rect2(left, -height, width, 1.0), Color(bar_color, 0.35 * _raised))
