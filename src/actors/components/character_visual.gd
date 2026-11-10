class_name CharacterVisual
extends Node2D
## Draws a character from an art id. The origin is at the character's feet so y-sorting lines up.
##
## Two sheet kinds:
## - Engine sheet (art entry "sheet"): columns = walk frames, rows = directions (down/up/side).
## - Full sheet (art entry "full" -> another art id whose "sheet" has a "layout" JSON): one row per
##   animation and direction (idle, walk, run, swing, roll, hurt, down, windup, attack, ...),
##   each with its own frame count, fps and loop flag. Used whenever the art and every layer
##   have one; otherwise the engine sheet is used.
## Extra layers (e.g. the hero's hair) use the same frame layout and are drawn over the body in
## lockstep for every animation. Art marked "skin_swap" gets the skin palette shader.
## Side rows face right and are mirrored for left.

const DEFAULT_FPS := 8.0
const RUN_THRESHOLD := 1.35

var facing := Vector2.DOWN
var moving := false
var speed_scale := 1.0
## Optional resting animation instead of idle (e.g. "trapped", "sit"); holds its last frame.
var rest_anim := ""

var _body: Sprite2D
var _layers: Array[Sprite2D] = []
var _shadow: Sprite2D
var _sheet: Dictionary = {}
var _anim_time := 0.0
var _flash_tween: Tween

var _layout: Dictionary = {}     # anim -> dir -> {row, frames, fps, loop}
var _action := ""
var _action_time := 0.0
var _action_fps := 0.0
var _action_hold := false
var _last_anim := ""


func setup(art_id: String) -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = Art.texture("shadow")
	_shadow.position = Vector2(0, -2)
	add_child(_shadow)
	var full_id := String(Art.entry(art_id).get("full", ""))
	if not full_id.is_empty() and Art.has_real_texture(full_id):
		_layout = Art.layout(full_id)
	if not _layout.is_empty():
		_body = _make_sprite(full_id)
		_sheet = Art.sheet(full_id)
	else:
		_body = _make_sprite(art_id)
		_sheet = Art.sheet(art_id)
	add_child(_body)
	_layers = [_body]


## Adds a layer drawn over the body (same frame layout). Empty ids are ignored.
func add_layer(art_id: String) -> void:
	if art_id.is_empty():
		return
	var layer_id := art_id
	if is_full():
		var full_id := String(Art.entry(art_id).get("full", ""))
		if full_id.is_empty() or not Art.has_real_texture(full_id):
			push_warning("Layer '%s' has no full sheet; its body uses one, so the layer is skipped." % art_id)
			return
		layer_id = full_id
	var layer := _make_sprite(layer_id)
	add_child(layer)
	_layers.append(layer)


func is_full() -> bool:
	return not _layout.is_empty()


func has_anim(anim: String) -> bool:
	return _layout.has(anim)


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
	_anim_time += delta * maxf(speed_scale, 0.35)
	if not _action.is_empty():
		_action_time += delta
	_update_frame()


# --- Actions (one-shot animations; full sheets only) -------------------------------

## Plays a one-shot animation over `duration` seconds (0 = the sheet's own fps). With `hold`
## the last frame stays until clear_action(). Returns false when the sheet has no such animation.
func play_action(anim: String, duration: float = 0.0, hold: bool = false) -> bool:
	if not has_anim(anim):
		return false
	_action = anim
	_action_time = 0.0
	_action_hold = hold
	var spec := _spec(anim, _direction_name())
	var frames := int(spec.get("frames", 1))
	_action_fps = float(frames) / duration if duration > 0.0 else float(spec.get("fps", 10.0))
	_update_frame()
	return true


func clear_action() -> void:
	_action = ""


func current_action() -> String:
	return _action


# --- Frame selection ----------------------------------------------------------------

func _update_frame() -> void:
	if is_full():
		_update_full_frame()
	else:
		_update_engine_frame()


func _update_full_frame() -> void:
	var direction := _direction_name()
	var anim := _action
	var time := _action_time
	var fps := _action_fps
	var looping := false
	if not anim.is_empty():
		var frames_now := int(_spec(anim, direction).get("frames", 1))
		if not _action_hold and time * fps >= float(frames_now):
			_action = ""
			anim = ""
	if anim.is_empty():
		if moving:
			anim = "run" if speed_scale > RUN_THRESHOLD and has_anim("run") else "walk"
		elif not rest_anim.is_empty() and has_anim(rest_anim):
			anim = rest_anim
		else:
			anim = "idle"
		if anim != _last_anim:
			_anim_time = 0.0
		time = _anim_time
		var base_spec := _spec(anim, direction)
		fps = float(base_spec.get("fps", 8.0))
		looping = base_spec.get("loop", false) and anim != rest_anim
	_last_anim = anim
	var spec := _spec(anim, direction)
	if spec.is_empty():
		return
	var frames := int(spec.get("frames", 1))
	var index := int(time * fps)
	index = index % frames if looping else mini(index, frames - 1)
	var flip := facing.x < -0.1 and _dir_for(anim, direction) == "side"
	var frame := int(spec.get("row", 0)) * _body.hframes + index
	for sprite: Sprite2D in _layers:
		sprite.flip_h = flip
		sprite.position.y = 0.0
		if frame < sprite.hframes * sprite.vframes:
			sprite.frame = frame


func _update_engine_frame() -> void:
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


## The direction row an animation has for a facing; one-direction animations (Mom's sit, the
## dog's lunge) fall back to whichever direction they have.
func _dir_for(anim: String, direction: String) -> String:
	var dirs: Dictionary = _layout.get(anim, {})
	if dirs.has(direction):
		return direction
	for fallback: String in ["side", "down", "up"]:
		if dirs.has(fallback):
			return fallback
	return direction


func _spec(anim: String, direction: String) -> Dictionary:
	var dirs: Dictionary = _layout.get(anim, {})
	return dirs.get(_dir_for(anim, direction), {})


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


## Dodge roll: the sheet's "roll" row when there is one, else a quick crouch-squash.
func play_roll(duration: float) -> void:
	if play_action("roll", duration):
		return
	var tween := create_tween().set_parallel()
	for sprite: Sprite2D in _layers:
		tween.tween_property(sprite, "scale", Vector2(1.25, 0.55), duration * 0.3)
		tween.tween_property(sprite, "scale", Vector2.ONE, duration * 0.7).set_delay(duration * 0.3)


func play_hurt(duration: float) -> void:
	if not play_action("hurt", duration):
		play_action("yelp", duration)


## Knocked down: the "down" row (held), else the sprite tips over. Then it fades if asked.
func play_fall(fade: bool = true) -> void:
	var tween := create_tween()
	if not play_action("down", 0.7, true):
		tween.tween_property(self, "rotation", PI / 2.0, 0.25)
	if fade:
		tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.6)
	else:
		tween.tween_interval(0.01)


## Height of the drawn character (for things placed above the head).
func frame_height() -> float:
	return -_body.offset.y - (16.0 if is_full() else 0.0)
