class_name TrapFx
extends Node2D
## One wick in the ground: arms, then waits for an enemy within the trigger range; a tiny flame shows it is live.

const CHAIN_DELAY: float = 0.12

var skill: WickTrap
var _arm: float
var _tripped: bool = false


static func spawn(parent: Node, at: Vector2, s: WickTrap) -> TrapFx:
	var t := TrapFx.new()
	t.skill = s
	t.position = at
	t._arm = float(s.data["arm"])
	parent.add_child(t)
	return t


func _ready() -> void:
	var sp := Sprite2D.new()
	sp.texture = PropSprite.tex("res://art/ui/skills.png")
	sp.region_enabled = true
	sp.region_rect = Rect2(12 * 24, 0, 24, 24)
	sp.offset = Vector2(0, -10)
	add_child(sp)
	var l := PointLight2D.new()
	l.texture = LightTex.soft(64)
	l.color = Pal.c("flame")
	l.energy = 0.6
	l.texture_scale = 1.2
	add_child(l)


func trip() -> void:
	if not _tripped:
		_tripped = true
		get_tree().create_timer(CHAIN_DELAY, false).timeout.connect(func() -> void: skill.burst(self))


func _physics_process(delta: float) -> void:
	_arm -= delta
	if _arm > 0.0 or _tripped:
		return
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if (n as Enemy).global_position.distance_to(global_position) < float(skill.data["trigger"]) + (n as Enemy).radius:
			_tripped = true
			skill.burst(self)
			return
