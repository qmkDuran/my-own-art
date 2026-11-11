class_name MaterialDrop
extends Node2D
## A forge material on the ground: a small glowing ember of its colour that drifts to the Lamplighter and is
## taken when he walks near (no click; materials never clutter the ground).

const TAKE: float = 34.0
const ATTRACT: float = 90.0
const SPEED: float = 260.0

var id: String
var _sprite: Sprite2D


static func spawn(parent: Node, at: Vector2, mat: String) -> MaterialDrop:
	var m := MaterialDrop.new()
	m.id = mat
	m.position = at
	parent.add_child(m)
	return m


## Rolls materials for a source (kill, elite, chest, boss) and scatters them around `at`.
static func roll(parent: Node, at: Vector2, source: String) -> void:
	var D: Dictionary = GameData.crafting["drop"]
	var n: int = 0
	match source:
		"normal", "magic":
			n = 1 if randf() < float(D["kill_chance"]) else 0
		"rare":
			n = 1 + int(D["elite_extra"])
		"chest", "boss":
			n = randi_range(int(D[source][0]), int(D[source][1]))
	for k: int in n:
		spawn(parent, at + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(12, 30), _weighted(D["weights"]))


static func _weighted(w: Dictionary) -> String:
	var total: float = 0.0
	for k: String in w:
		total += float(w[k])
	var r: float = randf() * total
	for k: String in w:
		r -= float(w[k])
		if r <= 0.0:
			return k
	return String(w.keys()[0])


func _ready() -> void:
	var col: Color = Pal.c(String(GameData.crafting["materials"][id]["color"]))
	_sprite = Sprite2D.new()
	_sprite.texture = PropSprite.tex("res://art/fx/spark.png")
	_sprite.scale = Vector2(2.5, 2.5)
	_sprite.modulate = col
	_sprite.material = Fx.glow_material()
	add_child(_sprite)
	var l := PointLight2D.new()
	l.texture = LightTex.soft(64)
	l.color = col
	l.energy = 0.7
	add_child(l)


func _process(delta: float) -> void:
	var p: Player = Game.current.player
	var d: float = global_position.distance_to(p.global_position + Vector2(0, -16))
	_sprite.position.y = -6.0 + sin(Time.get_ticks_msec() / 200.0 + position.x) * 2.0
	if d < ATTRACT:
		global_position = global_position.move_toward(p.global_position + Vector2(0, -16), SPEED * delta)
	if d < TAKE:
		p.inv.add_material(id)
		Audio.sfx("pickup", -10.0, 1.4)
		Game.current.hud.notice("+1 " + String(GameData.crafting["materials"][id]["name"]))
		queue_free()
