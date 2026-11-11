class_name EvolutionScene
extends Control
## A bond form: the creature glows, flickers between its two shapes, and grows into its new form.

const FLICKERS: int = 8
const SPRITE_POS: Vector2 = Vector2(-40, -70)

var _sprite: TextureRect
var _dialog: DialogueBox


func run(c: Creature, into: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.c("ink2")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var centre: Vector2 = get_viewport_rect().size / 2
	add_child(UiKit.panel(Rect2(centre + Vector2(-48, -76), Vector2(96, 90)), "plum0", "plum2"))
	_sprite = TextureRect.new()
	_sprite.texture = UiKit.creature_tex(c.species_id, "front")
	_sprite.position = centre + SPRITE_POS
	add_child(_sprite)
	_dialog = DialogueBox.new()
	add_child(_dialog)
	var old_name: String = c.display_name()
	await _dialog.say(PackedStringArray(["Oh? %s is glowing with all the time you've spent together..." % old_name]))
	await _flicker(c.species_id, into)
	Bond.evolve(c, into)
	Audio.sfx("evolve")
	add_child(Sparkles.new().setup(_points(centre)))
	await _dialog.say(PackedStringArray(["%s grew into %s!" % [old_name, c.display_name()]]))
	Game.journal.befriend(into)


func _flicker(from: String, into: String) -> void:
	for i: int in FLICKERS:
		_sprite.texture = UiKit.creature_tex(into if i % 2 == 0 else from, "front")
		await Game.wait(0.32 - i * 0.03)
	_sprite.texture = UiKit.creature_tex(into, "front")


func _points(centre: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i: int in 16:
		out.append(centre + Vector2(Game.rng.randi_range(-40, 40), Game.rng.randi_range(-70, 10)))
	return out
