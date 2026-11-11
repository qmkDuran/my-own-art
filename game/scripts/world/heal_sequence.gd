class_name HealSequence
extends RefCounted
## The healing world on screen: when the Vale reaches a new stage, the ground and props cross-fade from withered
## to living with sparkles over what healed, then a message says what changed. Also small emotes ("!").

const FADE_TIME: float = 1.4
const SPARKLE_EVERY: int = 2

var world: Overworld
var _pending: Array[int] = []


func _init(w: Overworld) -> void:
	world = w


func queue_heal(stage: int) -> void:
	_pending.append(stage)


func has_pending() -> bool:
	return not _pending.is_empty()


func play_pending() -> void:
	while not _pending.is_empty():
		await _play(_pending.pop_front())


func _play(stage: int) -> void:
	world.busy = true
	Audio.sfx("restore")
	var old := Sprite2D.new()
	old.centered = false
	old.texture = world.terrain.texture
	old.z_index = -9
	world.add_child(old)
	world.refresh_terrain()
	world.props.refresh(stage)
	world.add_child(Sparkles.new().setup(_healed_points(stage)))
	var tw: Tween = old.create_tween()
	tw.tween_property(old, "modulate:a", 0.0, 0.05 if Game.fast else FADE_TIME)
	await tw.finished
	old.queue_free()
	await world.dialog.say(PackedStringArray([Restoration.message(stage)]))
	world.busy = false


func _healed_points(stage: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y: int in range(0, world.map.size.y, SPARKLE_EVERY):
		for x: int in range(0, world.map.size.x, SPARKLE_EVERY):
			if world.map.region_stage(Vector2i(x, y)) == stage:
				out.append(Vector2(x * 16 + Game.rng.randi_range(0, 15), y * 16 + Game.rng.randi_range(0, 15)))
	return out


func sparkle_on(w: Walker) -> void:
	var pts: Array[Vector2] = []
	for i: int in 8:
		pts.append(w.position + Vector2(Game.rng.randi_range(-10, 10), Game.rng.randi_range(-28, 0)))
	world.add_child(Sparkles.new().setup(pts))
	await Game.wait(0.8)


## A "!" bubble over someone's head.
func exclaim(w: Walker) -> void:
	var bubble := Label.new()
	bubble.text = "!"
	bubble.add_theme_color_override("font_color", UiKit.c("ember1"))
	bubble.add_theme_color_override("font_outline_color", UiKit.c("cream"))
	bubble.add_theme_constant_override("outline_size", 2)
	bubble.position = Vector2(-2, -46)
	w.add_child(bubble)
	await w.hop()
	await Game.wait(0.4)
	bubble.queue_free()
