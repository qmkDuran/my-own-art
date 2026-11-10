class_name CharacterVisual
extends Node2D
## Draws a character from an art id. Works with a sprite sheet (columns = walk frames,
## rows = directions; layout from the art entry's "sheet") or a single image.
## Extra layers (e.g. the hero's hair) use the same frame layout and are drawn over the body
## in lockstep for every animation. Art marked "skin_swap" gets the skin palette shader.
## The origin is at the character's feet so y-sorting lines up.

const DEFAULT_FPS := 8.0

var facing := Vector2.DOWN
var moving := false
var speed_scale := 1.0

var _body: Sprite2D
var _layers: Array[Sprite2D] = []
var _shadow: Sprite2D
var _sheet: Dictionary = {}
var _anim_time := 0.0
var _flash_tween: Tween


func setup(art_id: String) -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = Art.texture("shadow")
	_shadow.position = Vector2(0, -2)
	add_child(_shadow)
	_body = _make_sprite(art_id)
	_sheet = Art.sheet(art_id)
	add_child(_body)
	_layers = [_body]


## Adds a layer drawn over the body (same frame layout). Empty ids are ignored.
func add_layer(art_id: String) -> void:
	if art_id.is_empty():
		return
	var layer := _make_sprite(art_id)
	add_child(layer)
	_layers.append(layer)


func _make_sprite(art_id: String) -> Sprite2D:
	var sheet := Art.sheet(art_id)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = Art.texture(art_id)
	sprite.hframes = int(sheet.get("hframes", 1))
	sprite.vframes = int(sheet.get("vframes", 1))
	sprite.material = Art.material_for(art_id)
	var frame_size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
	sprite.offset = Vector2(-roundf(frame_size.x / 2.0), -frame_size.y)
	return sprite


func _process(delta: float) -> void:
	_anim_time += delta * speed_scale
	_update_frame()


func _update_frame() -> void:
	var rows: Dictionary = _sheet.get("rows", {})
	var row_name := _direction_name()
	var flip := facing.x < -0.1 and (row_name == "side" or not rows.has("side"))
	var animated := _body.hframes * _body.vframes > 1
	var frame := 0
	if animated:
		var column := 0
		if moving:
			column = int(_anim_time * float(_sheet.get("fps", DEFAULT_FPS))) % _body.hframes
		frame = int(rows.get(row_name, 0)) * _body.hframes + column
	var bob := -1.0 if not animated and moving and fmod(_anim_time, 0.3) < 0.15 else 0.0
	for sprite: Sprite2D in _layers:
		sprite.flip_h = flip
		sprite.position.y = bob
		if animated and frame < sprite.hframes * sprite.vframes:
			sprite.frame = frame


func _direction_name() -> String:
	if absf(facing.x) > absf(facing.y) * 1.2:
		return "side"
	return "up" if facing.y < 0.0 else "down"


## Briefly tints every layer (hit flash, attack telegraph).
func flash(color: Color, duration: float = 0.12) -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	set_tint(color)
	_flash_tween = create_tween().set_parallel()
	for sprite: Sprite2D in _layers:
		_flash_tween.tween_property(sprite, "modulate", Color.WHITE, duration)


func set_tint(color: Color) -> void:
	for sprite: Sprite2D in _layers:
		sprite.modulate = color


## Placeholder roll: a quick crouch-squash (real art can replace with a "roll" row).
func play_roll(duration: float) -> void:
	var tween := create_tween().set_parallel()
	for sprite: Sprite2D in _layers:
		tween.tween_property(sprite, "scale", Vector2(1.25, 0.55), duration * 0.3)
		tween.tween_property(sprite, "scale", Vector2.ONE, duration * 0.7).set_delay(duration * 0.3)


func play_fall() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation", PI / 2.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.5)


func frame_height() -> float:
	return -_body.offset.y
