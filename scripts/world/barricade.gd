class_name Barricade
extends StaticBody2D
## A junk barricade across a road (planks, crates, a tin sheet): it blocks the way, for the
## player and enemies alike, until something opens it (e.g. RaidEncounter once the raid is
## beaten). Opening shakes it, then it slumps and fades away; the navmesh rebakes without it.
## Its origin is the middle of its base, on the ground.

## The barricade's picture (a region of the town tileset), drawn standing on the origin.
@export var texture: Texture2D
## The blocking footprint, in pixels.
@export var footprint: Vector2 = Vector2(64, 12)
@export var shake_seconds: float = 0.35
@export var fade_seconds: float = 0.5

var is_open: bool = false

var _sprite := Sprite2D.new()
var _collision := CollisionShape2D.new()


func _ready() -> void:
	add_to_group(ZoneNavigation.OBSTACLES_GROUP)
	_sprite.texture = texture
	_sprite.centered = false
	if texture != null:
		_sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	add_child(_sprite)
	var shape := RectangleShape2D.new()
	shape.size = footprint
	_collision.shape = shape
	_collision.position = Vector2(0, -footprint.y / 2.0)
	add_child(_collision)


## Clears the way: at once (`instantly`, e.g. on a later visit) or with the shake and fade.
func open(instantly: bool = false) -> void:
	if is_open:
		return
	is_open = true
	_collision.set_deferred("disabled", true)
	get_tree().call_group(ZoneNavigation.GROUP, "rebake")
	if instantly:
		hide()
		return
	var tween := create_tween()
	for step in 6:
		tween.tween_property(_sprite, "position:x", 1.0 if step % 2 == 0 else -1.0, shake_seconds / 6.0)
	tween.tween_property(_sprite, "position:x", 0.0, 0.0)
	tween.set_parallel()
	tween.tween_property(_sprite, "position:y", 3.0, fade_seconds).set_delay(shake_seconds)
	tween.tween_property(_sprite, "modulate:a", 0.0, fade_seconds).set_delay(shake_seconds)
	tween.chain().tween_callback(hide)
