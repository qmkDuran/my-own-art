class_name HidingSpot
extends Area3D
## A bush or tall-grass patch you can hide in. It keeps track of the creatures inside (their Stealth reads it) and
## sways while someone moves through it: the visible "rustle" that warns of an unseen creature close by. While the
## player's own creature is inside, it turns see-through so you can still read your creature and the fight.

const SWAY_ANGLE: float = 0.07
const SWAY_SPEED: float = 14.0
const SWAY_SETTLE: float = 5.0
const SWAY_WOBBLE: float = 0.8
const MOVING_SPEED: float = 0.5
const DETECT_HEIGHT: float = 4.0
const BODY_INSET: float = 0.45
const SEE_THROUGH_ALPHA: float = 0.35

var kind: String = "bush"
## Stable index in the woods (the layout is seeded), so the bot's memory of favourite spots survives restarts.
var spot_id: int = -1
var radius: float = 1.5
var sway_root: Node3D
var occupants: Array[Creature] = []
var fade_materials: Array[StandardMaterial3D] = []
var _sway: float = 0.0
var _time: float = 0.0
var _see_through: bool = false


func setup(spot_kind: String, spot_radius: float) -> void:
	kind = spot_kind
	radius = spot_radius
	name = spot_kind.capitalize()
	collision_layer = Layers.HIDING
	collision_mask = Layers.CREATURE
	monitorable = false
	var shape := CylinderShape3D.new()
	shape.radius = maxf(spot_radius - BODY_INSET, BODY_INSET)
	shape.height = DETECT_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	sway_root = Node3D.new()
	add_child(sway_root)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func is_rustling() -> bool:
	for creature: Creature in occupants:
		if creature.horizontal_speed() > MOVING_SPEED:
			return true
	return false


func _physics_process(delta: float) -> void:
	_time += delta
	var target: float = 1.0 if is_rustling() else 0.0
	_sway = move_toward(_sway, target, SWAY_SETTLE * delta)
	sway_root.rotation = Vector3(sin(_time * SWAY_SPEED), 0, cos(_time * SWAY_SPEED * SWAY_WOBBLE)) * SWAY_ANGLE * _sway
	_update_see_through()


func _update_see_through() -> void:
	var wanted: bool = occupants.any(func(creature: Creature) -> bool: return creature.see_through_cover)
	if wanted == _see_through:
		return
	_see_through = wanted
	for material: StandardMaterial3D in fade_materials:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if wanted else BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color.a = SEE_THROUGH_ALPHA if wanted else 1.0


func _on_body_entered(body: Node3D) -> void:
	if body is Creature and not occupants.has(body):
		occupants.append(body)
		(body as Creature).stealth.enter(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Creature:
		occupants.erase(body)
		(body as Creature).stealth.leave(self)
