class_name Walker
extends Node2D
## A person on the grid (the player or an NPC): 16x32 sprite sheet, a cell, a facing, and a tweened step to
## the next cell with a two-foot walk cycle. Its position is the bottom centre of its cell (for y-sorting).

signal stepped(cell: Vector2i)

const T: int = 16
const STEP_TIME: float = 0.2
const FRAME_W: int = 16
const FRAME_H: int = 32
const ROW_OF: Dictionary = {Vector2i.DOWN: 0, Vector2i.UP: 3, Vector2i.LEFT: 6, Vector2i.RIGHT: 6}

var cell: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.DOWN
var moving: bool = false
var person: String = ""
var _sprite: Sprite2D
var _grass_front: Sprite2D
var _foot: int = 1


func setup(who: String, at: Vector2i, dir: Vector2i) -> Walker:
	person = who
	_sprite = Sprite2D.new()
	_sprite.texture = UiKit.tex("res://art/people/%s.png" % who)
	_sprite.hframes = 9
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME_W / 2, -FRAME_H)
	add_child(_sprite)
	_grass_front = Sprite2D.new()
	_grass_front.centered = false
	_grass_front.offset = Vector2(-T / 2, -T)
	_grass_front.visible = false
	add_child(_grass_front)
	place(at, dir)
	return self


func place(at: Vector2i, dir: Vector2i) -> void:
	cell = at
	position = cell_bottom(at)
	face(dir)


static func cell_bottom(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2, c.y * T + T)


func face(dir: Vector2i) -> void:
	facing = dir
	_set_frame(0)


func _set_frame(phase: int) -> void:
	_sprite.frame = int(ROW_OF[facing]) + phase
	_sprite.flip_h = facing == Vector2i.RIGHT


## Grass blades drawn over the feet while standing in tall grass.
func set_in_grass(on: bool, tex: Texture2D) -> void:
	_grass_front.visible = on
	_grass_front.texture = tex


## Walks one cell in a direction (the caller has checked it is free).
func step(dir: Vector2i) -> void:
	facing = dir
	moving = true
	cell += dir
	_foot = 3 - _foot
	_set_frame(_foot)
	var tw: Tween = create_tween()
	tw.tween_property(self, "position", cell_bottom(cell), STEP_TIME)
	tw.parallel().tween_callback(func() -> void: _set_frame(0)).set_delay(STEP_TIME * 0.5)
	await tw.finished
	moving = false
	stepped.emit(cell)


## A little hop in place (surprise, or bumping into a wall).
func hop() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_sprite, "position:y", -3.0, 0.08)
	tw.tween_property(_sprite, "position:y", 0.0, 0.08)
	await tw.finished
