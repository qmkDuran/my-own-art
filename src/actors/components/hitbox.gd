class_name Hitbox
extends Area2D
## An attack's damaging area. Enable it for the active frames of a swing; each Hurtbox is hit
## at most once per activation.

var damage := 1
var knockback := 200.0
var attacker: Node2D
var _hit_this_swing: Array[Hurtbox] = []
var _shape: CollisionShape2D


func setup(owner_node: Node2D, target_layer: int, radius: float) -> void:
	attacker = owner_node
	collision_layer = 0
	collision_mask = target_layer
	monitorable = false
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape = CollisionShape2D.new()
	_shape.shape = circle
	_shape.disabled = true
	add_child(_shape)
	area_entered.connect(_on_area_entered)


func set_radius(radius: float) -> void:
	(_shape.shape as CircleShape2D).radius = radius


func activate() -> void:
	_hit_this_swing.clear()
	_shape.set_deferred("disabled", false)


func deactivate() -> void:
	_shape.set_deferred("disabled", true)


func _physics_process(_delta: float) -> void:
	if _shape.disabled:
		return
	for area: Area2D in get_overlapping_areas():
		_on_area_entered(area)


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if _hit_this_swing.has(hurtbox) or hurtbox.receiver == attacker:
		return
	_hit_this_swing.append(hurtbox)
	hurtbox.receive_hit(self)
