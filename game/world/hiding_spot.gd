class_name HidingSpot
extends Area3D
## A place to hide: a bush, a tall-grass patch, a smoke cloud or a hollow log. It keeps track of the creatures inside
## (their Stealth reads it) and sways gently in the wind only, so it never gives away who is inside. While the
## player's own creature is inside, it turns see-through so you can still read your creature and the fight. Tall grass
## burns (it then hides no one) and regrows.

enum Burn { GREEN, BURNING, SCORCHED }

const WIND_ANGLE: float = 0.035
const WIND_SPEED: float = 1.7
const DETECT_HEIGHT: float = 4.0
const BODY_INSET: float = 0.45
const SEE_THROUGH_ALPHA: float = 0.35
const WIND_DRIFT: float = 0.1
const WIND_WOBBLE: float = 0.8

var kind: String = "bush"
## Stable index in the woods (the layout is seeded), so the bot's memory of favourite spots survives restarts.
var spot_id: int = -1
var radius: float = 1.5
var sway_root: Node3D
var occupants: Array[Creature] = []
var fade_materials: Array[StandardMaterial3D] = []
var burn: Burn = Burn.GREEN
var _time: float = 0.0
var _burn_left: float = 0.0
var _see_through: bool = false
var _flames: GrassFire


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


## Does it hide anyone right now? (Burning or burnt grass does not.)
func conceals() -> bool:
	return burn == Burn.GREEN


func burnable() -> bool:
	return kind == "grass" and burn == Burn.GREEN


func contains(point: Vector3) -> bool:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length() <= radius


func ignite() -> void:
	if not burnable():
		return
	burn = Burn.BURNING
	_burn_left = Tuning.f("fire", "burn_time")
	_flames = GrassFire.new()
	add_child(_flames)
	_flames.setup(radius)


func extinguish() -> void:
	if burn == Burn.BURNING:
		_scorch()


func _physics_process(delta: float) -> void:
	_time += delta
	var phase: float = _time * WIND_SPEED + global_position.x * WIND_DRIFT
	sway_root.rotation = Vector3(sin(phase), 0, cos(phase * WIND_WOBBLE)) * WIND_ANGLE
	_update_see_through()
	_tick_fire(delta)


func _tick_fire(delta: float) -> void:
	if burn == Burn.GREEN:
		return
	_burn_left -= delta
	if burn == Burn.BURNING:
		for creature: Creature in occupants:
			creature.take_hit(Tuning.f("fire", "damage_per_second") * delta, null, false, "fire")
		if _burn_left <= 0.0:
			_scorch()
	elif _burn_left <= 0.0:
		_regrow()


func _scorch() -> void:
	burn = Burn.SCORCHED
	_burn_left = Tuning.f("fire", "regrow_time")
	if is_instance_valid(_flames):
		_flames.queue_free()
	sway_root.scale = Vector3(1.0, Tuning.f("fire", "stubble_height"), 1.0)
	for material: StandardMaterial3D in fade_materials:
		material.albedo_color = material.albedo_color.darkened(Tuning.f("fire", "char"))


func _regrow() -> void:
	burn = Burn.GREEN
	for material: StandardMaterial3D in fade_materials:
		var green: Color = material.albedo_color.lightened(Tuning.f("fire", "char"))
		material.albedo_color = Color(green, material.albedo_color.a)
	create_tween().tween_property(sway_root, "scale", Vector3.ONE, Tuning.f("fire", "regrow_grow_time"))


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
