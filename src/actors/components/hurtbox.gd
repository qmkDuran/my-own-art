class_name Hurtbox
extends Area2D
## The area of a body that can be hit. Forwards hits to its receiver (must implement take_hit).

var receiver: Node2D


func setup(owner_node: Node2D, own_layer: int, size: Vector2, offset: Vector2) -> void:
	receiver = owner_node
	collision_layer = own_layer
	collision_mask = 0
	monitoring = false
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = offset
	add_child(shape)


func receive_hit(hitbox: Hitbox) -> void:
	if receiver and receiver.has_method("take_hit"):
		receiver.call("take_hit", hitbox)
