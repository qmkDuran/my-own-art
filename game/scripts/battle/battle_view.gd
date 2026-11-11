class_name BattleView
extends Control
## The creatures on the battle stage and their motion: sending out, lunging, getting hit (blink and shake),
## fainting, joining you, and floating numbers. Front sprites are the foe's, back sprites yours; both are
## mirrored so they face each other across the stage.

const LUNGE: float = 10.0
const MOVE_TIME: float = 0.12
const BLINKS: int = 3
const FLOAT_RISE: float = 14.0
const FLOAT_TIME: float = 0.7
const HEART_COLOURS: Array[String] = ["rose2", "rose3", "cream"]

var foe_sprite: TextureRect
var ally_sprite: TextureRect


func _ready() -> void:
	size = BattleLayout.STAGE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	foe_sprite = _sprite()
	ally_sprite = _sprite()


func _sprite() -> TextureRect:
	var t := TextureRect.new()
	t.size = BattleLayout.SPRITE
	t.flip_h = true
	t.visible = false
	add_child(t)
	return t


func sprite(ally: bool) -> TextureRect:
	return ally_sprite if ally else foe_sprite


func _home(ally: bool) -> Vector2:
	return BattleLayout.base(ally) - Vector2(BattleLayout.SPRITE.x / 2, BattleLayout.SPRITE.y)


func send_in(ally: bool, c: Creature) -> void:
	var s: TextureRect = sprite(ally)
	s.texture = UiKit.creature_tex(c.species_id, "back" if ally else "front")
	s.position = _home(ally) + Vector2(0, 6)
	s.modulate.a = 0.0
	s.visible = true
	var tw: Tween = s.create_tween().set_parallel()
	tw.tween_property(s, "position", _home(ally), _t(0.25))
	tw.tween_property(s, "modulate:a", 1.0, _t(0.25))
	await tw.finished


func withdraw(ally: bool) -> void:
	var s: TextureRect = sprite(ally)
	var tw: Tween = s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, _t(0.2))
	await tw.finished
	s.visible = false


func lunge(ally: bool) -> void:
	var s: TextureRect = sprite(ally)
	var toward: Vector2 = (BattleLayout.base(not ally) - BattleLayout.base(ally)).normalized() * LUNGE
	var tw: Tween = s.create_tween()
	tw.tween_property(s, "position", _home(ally) + toward, _t(MOVE_TIME))
	tw.tween_property(s, "position", _home(ally), _t(MOVE_TIME))
	await tw.finished


func hurt(ally: bool) -> void:
	var s: TextureRect = sprite(ally)
	for i: int in BLINKS:
		s.visible = false
		await Game.wait(0.05)
		s.visible = true
		s.position = _home(ally) + Vector2(2 if i % 2 == 0 else -2, 0)
		await Game.wait(0.05)
	s.position = _home(ally)


func faint(ally: bool) -> void:
	var s: TextureRect = sprite(ally)
	var tw: Tween = s.create_tween().set_parallel()
	tw.tween_property(s, "position:y", _home(ally).y + 24, _t(0.35))
	tw.tween_property(s, "modulate:a", 0.0, _t(0.35))
	await tw.finished
	s.visible = false


## A little double hop: happy, or deciding to come along.
func hop(ally: bool) -> void:
	var s: TextureRect = sprite(ally)
	for i: int in 2:
		var tw: Tween = s.create_tween()
		tw.tween_property(s, "position:y", _home(ally).y - 6, _t(0.1))
		tw.tween_property(s, "position:y", _home(ally).y, _t(0.1))
		await tw.finished


func float_text(ally: bool, text: String, colour: String) -> void:
	var l := UiKit.label(text, colour)
	l.add_theme_color_override("font_outline_color", UiKit.c("ink"))
	l.add_theme_constant_override("outline_size", 3)
	l.position = BattleLayout.base(ally) + Vector2(-UiKit.text_width(text) / 2, -BattleLayout.SPRITE.y * 0.6)
	add_child(l)
	var tw: Tween = l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - FLOAT_RISE, _t(FLOAT_TIME))
	tw.tween_callback(l.queue_free)


func sparkle(ally: bool, colours_heart: bool = false) -> void:
	var pts: Array[Vector2] = []
	for i: int in 10:
		pts.append(BattleLayout.base(ally) + Vector2(Game.rng.randi_range(-30, 30), Game.rng.randi_range(-70, -10)))
	var colours: Array[String] = Sparkles.COLOURS
	if colours_heart:
		colours = HEART_COLOURS
	add_child(Sparkles.new().setup(pts, colours))


func _t(seconds: float) -> float:
	return 0.01 if Game.fast else seconds
