class_name SilhouetteRim
extends Node2D
## A 1px outer rim of one flat colour around an AnimatedSprite2D's silhouette (see
## silhouette_rim.gdshader). A child of the sprite, drawn behind it: it moves, lifts,
## scales and fades with the sprite and redraws the current frame and flip every frame.
## The sprite's modulate (fades, StatusTint) reaches it; its self_modulate (HitFlash) does
## not, so a hit flash stays on the body and the rim keeps its colour.

const SHADER := preload("res://scripts/shaders/silhouette_rim.gdshader")
## How far the rim reaches past the frame on each side, in pixels.
const RIM_WIDTH := 1.0

var _sprite: AnimatedSprite2D


func _init(color: Color) -> void:
	show_behind_parent = true
	var rim_material := ShaderMaterial.new()
	rim_material.shader = SHADER
	rim_material.set_shader_parameter("rim_color", color)
	material = rim_material


func _enter_tree() -> void:
	_sprite = get_parent() as AnimatedSprite2D


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var frame := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame) as AtlasTexture
	if frame == null:
		return
	var region := frame.region
	var sheet_size := frame.atlas.get_size()
	var uv_corner := region.position / sheet_size
	var uv_size := region.size / sheet_size
	(material as ShaderMaterial).set_shader_parameter("frame_region", Vector4(uv_corner.x, uv_corner.y, uv_size.x, uv_size.y))
	draw_texture_rect_region(frame.atlas, _target_rect(region.size), region.grow(RIM_WIDTH))


## Where the sprite draws its frame, grown by the rim. A negative size flips the texture
## in place, exactly as the sprite's own flip_h / flip_v do.
func _target_rect(frame_size: Vector2) -> Rect2:
	var corner := _sprite.offset - (frame_size / 2.0 if _sprite.centered else Vector2.ZERO)
	var rect := Rect2(corner, frame_size).grow(RIM_WIDTH)
	if _sprite.flip_h:
		rect.size.x = -rect.size.x
	if _sprite.flip_v:
		rect.size.y = -rect.size.y
	return rect
