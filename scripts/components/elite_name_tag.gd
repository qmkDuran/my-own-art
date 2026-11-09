class_name EliteNameTag
extends Node2D
## An elite's name above its head in the tiny pixel font (e.g. "BRISTLING TOXLOP"). It shows
## only while the player is near, so a quiet pocket stays quiet until you walk in.

const VISIBLE_Z := 10

@export var text: String = ""
## How close the player must be for the tag to show, in pixels (about half a screen).
@export var show_distance: float = 150.0
@export var text_color: Color = ApolloPalette.GOLD
## Seconds to fade in or out.
@export var fade_seconds: float = 0.3


func _ready() -> void:
	z_index = VISIBLE_Z
	modulate.a = 0.0


func _process(delta: float) -> void:
	var player := PlayerFinder.find(self)
	var is_near := player != null and player.global_position.distance_to(global_position) <= show_distance
	modulate.a = move_toward(modulate.a, 1.0 if is_near else 0.0, delta / fade_seconds)


func _draw() -> void:
	var left := -floorf(PixelFont.width_of(text) / 2.0)
	PixelFont.draw_text(self, text, Vector2(left, 0), text_color, ApolloPalette.OUTLINE)
