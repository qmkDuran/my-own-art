class_name FxSprite
extends Sprite2D
## A looping (or one-shot) effect strip: N frames in one row, played at a fixed rate.
## Art entries describe it with "fx": {"frames": 8, "ms": 90, "origin": [x, y], "loop": true};
## the origin is the frame pixel that sits on the entity's position (e.g. the foot of a flame).

var frame_time := 0.09
var looping := true
var _time := 0.0


static func create(art_id: String, fx: Dictionary) -> FxSprite:
	var sprite := FxSprite.new()
	sprite.texture = Art.texture(art_id)
	sprite.centered = false
	sprite.hframes = int(fx.get("frames", 1))
	sprite.frame_time = float(fx.get("ms", 90)) / 1000.0
	sprite.looping = fx.get("loop", true)
	var origin := Tiles.vec2(fx.get("origin"), Vector2(sprite.texture.get_width() / float(sprite.hframes) / 2.0, sprite.texture.get_height()))
	sprite.offset = -origin
	sprite._time = randf() * sprite.frame_time * sprite.hframes   # neighbouring fires do not pulse in sync
	return sprite


func _process(delta: float) -> void:
	_time += delta
	var index := int(_time / frame_time)
	frame = index % hframes if looping else mini(index, hframes - 1)
