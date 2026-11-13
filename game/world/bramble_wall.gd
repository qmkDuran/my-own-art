class_name BrambleWall
extends StaticBody3D
## A wall of brambles grown by a move: it blocks movement, sight and shots for a while, then withers. Fire burns it
## down at once.

const HEIGHT: float = 1.7
const THICKNESS: float = 0.6
const KNOTS: int = 7
const KNOT_SIZE: float = 0.55
const GROW_TIME: float = 0.4
const BRAMBLE: String = "bush"
const KNOT_LOW: float = 0.3
const KNOT_HIGH: float = 0.8
const SPROUT_SHARE: float = 0.05


func setup(at: Vector3, facing: Vector3, width: float, lifetime: float) -> void:
	name = "BrambleWall"
	collision_layer = Layers.OBSTACLE
	collision_mask = 0
	position = at
	look_at_from_position(at, at + facing, Vector3.UP)
	add_to_group("walls")
	var box := BoxShape3D.new()
	box.size = Vector3(width, HEIGHT, THICKNESS)
	var collider := CollisionShape3D.new()
	collider.shape = box
	collider.position.y = HEIGHT * 0.5
	add_child(collider)
	var rng := RandomNumberGenerator.new()
	for k: int in KNOTS:
		var knot := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = KNOT_SIZE
		ball.height = KNOT_SIZE * 2.0
		knot.mesh = FlatMesh.lumpy(ball, rng, KNOT_SIZE * 0.5)
		knot.material_override = WoodsMaterials.solid(BRAMBLE)
		var along: float = lerpf(-width * 0.5, width * 0.5, float(k) / (KNOTS - 1))
		knot.position = Vector3(along, HEIGHT * rng.randf_range(KNOT_LOW, KNOT_HIGH), 0)
		add_child(knot)
	scale = Vector3(1, SPROUT_SHARE, 1)
	var life: Tween = create_tween()
	life.tween_property(self, "scale", Vector3.ONE, GROW_TIME)
	life.tween_interval(lifetime)
	life.tween_callback(queue_free)


func burn_down() -> void:
	queue_free()
