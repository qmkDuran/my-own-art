class_name Lure
extends Node2D
## The Saltmarsh's false lights: a warm glow over the reeds that looks like a lamp. Come close and the things
## that grow it rise out of the mud around you. Each lure springs once; afterwards it is dark.

const SPRING: float = 110.0
const RING: float = 70.0
const LIGHT_RANGE: float = 90.0

var count: int = 3
var _light: PointLight2D
var _sprung: bool = false
var _t: float = 0.0


static func make(parent: Node, at: Vector2, n: int) -> Lure:
	var l := Lure.new()
	l.position = at
	l.count = n
	parent.add_child(l)
	return l


func _ready() -> void:
	_light = PointLight2D.new()
	_light.texture = LightTex.soft(128)
	_light.color = Pal.c("gold")
	_light.texture_scale = LIGHT_RANGE / 64.0
	_light.energy = 0.9
	_light.position = Vector2(0, -20)
	add_child(_light)
	var glow := Sprite2D.new()
	glow.texture = PropSprite.tex("res://art/fx/spark.png")
	glow.scale = Vector2(3, 3)
	glow.material = Fx.glow_material()
	glow.modulate = Pal.c("gold")
	glow.position = Vector2(0, -20)
	glow.name = "Glow"
	add_child(glow)


func _process(delta: float) -> void:
	_t += delta
	if _sprung:
		return
	_light.energy = 0.8 + sin(_t * 3.0) * 0.15
	var g: Game = Game.current
	if g.player.global_position.distance_to(global_position) < SPRING:
		_spring(g)


func _spring(g: Game) -> void:
	_sprung = true
	_light.energy = 0.0
	(get_node("Glow") as Sprite2D).visible = false
	g.hud.caption("It was never a lamp.")
	Audio.sfx("hiss", -4.0, 0.7)
	var lvl: int = g.spawner.level_at(g.progress_at(global_position))
	for k: int in count:
		var at: Vector2 = g.layout.free_spot_near(global_position + Vector2.RIGHT.rotated(TAU * k / count) * RING, 12.0)
		g.spawner.spawn("lurker", at, "normal", [], lvl).wake()
		Fx.burst(g.fx_layer, at, 10, Vector2(20, 70), 0.5, [Pal.c("moss_lt"), Pal.c("moss_dk", 0.0)], Vector2.UP, 50.0, Vector2(2, 3), false)
