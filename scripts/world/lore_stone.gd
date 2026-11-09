class_name LoreStone
extends Node2D
## A carved stone that tells a line of the world's story when the player walks up to it.
## The stone itself is a tile (Obstacles layer); this node sits on it and does the talking.

@export_multiline var text: String = ""
## How close the player must come, in pixels.
@export var reach: float = 30.0
## Seconds the line stays up.
@export var show_seconds: float = 4.0
## Where the line appears, above the stone's feet.
@export var bubble_offset: Vector2 = Vector2(0, -34)

var _was_near: bool = false
var _bubble: SpeechBubble


func _ready() -> void:
	_bubble = SpeechBubble.new()
	_bubble.position = bubble_offset
	_bubble.z_index = 10
	add_child(_bubble)


func _process(_delta: float) -> void:
	var player := PlayerFinder.find(self)
	var is_near := player != null and player.global_position.distance_to(global_position) <= reach
	if is_near and not _was_near:
		_bubble.say(text, show_seconds)
	_was_near = is_near
