class_name BombArc
extends RefCounted
## The lantern bomb's flight, worked out once and used by both the preview and the bomb itself, so the bomb lands
## exactly where the preview showed: a ballistic arc from the lantern to a target (flight time grows with
## distance), followed in short steps until the first thing it would hit.

const STEPS: int = 48

var from: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var gravity: float = 0.0
var landing: Vector3 = Vector3.ZERO
var landing_time: float = 0.0


## The arc from a point to a target, stopped by the world (the player excluded).
static func toward(start: Vector3, target: Vector3, world: World3D, exclude: Array[RID]) -> BombArc:
	var arc := BombArc.new()
	arc.from = start
	arc.gravity = Tuning.number("combat", "bomb", "gravity")
	var flight: float = maxf(Tuning.number("combat", "bomb", "flight_min"), start.distance_to(target) *
		Tuning.number("combat", "bomb", "flight_per_metre"))
	arc.velocity = (target - start + Vector3.UP * 0.5 * arc.gravity * flight * flight) / flight
	arc._land(world, exclude, flight)
	return arc


func point_at(time: float) -> Vector3:
	return from + velocity * time + Vector3.DOWN * 0.5 * gravity * time * time


func _land(world: World3D, exclude: Array[RID], flight: float) -> void:
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	var end_time: float = flight * 2.0
	for index: int in STEPS:
		var a: float = end_time * index / STEPS
		var b: float = end_time * (index + 1) / STEPS
		var query := PhysicsRayQueryParameters3D.create(point_at(a), point_at(b), Layers.WORLD, exclude)
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			landing = hit["position"]
			var share: float = point_at(a).distance_to(landing) / maxf(point_at(a).distance_to(point_at(b)), Hit.TINY)
			landing_time = lerpf(a, b, share)
			return
	landing_time = end_time
	landing = point_at(end_time)
