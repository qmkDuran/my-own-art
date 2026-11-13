class_name WoodsSpawner
extends RefCounted
## What moves add to or change in the woods while fighting: smoke clouds and sprouted grass to hide in, bramble
## walls, mud puddles, and fire (grass alight, walls burnt down) and water putting fire out.

var _woods: Woods
var _rng := RandomNumberGenerator.new()


func _init(woods: Woods) -> void:
	_woods = woods


func spawn_smoke(at: Vector3, size: float, lifetime: float) -> void:
	_temporary_spot(Foliage.smoke_cloud(at, size, _rng), lifetime)


func spawn_grass(at: Vector3, size: float, lifetime: float) -> void:
	var patch: HidingSpot = Foliage.tall_grass(at, size, float(Tuning.woods["grass_blades_per_m2"]), _rng, _woods.shape)
	_temporary_spot(patch, lifetime)


func spawn_wall(at: Vector3, facing: Vector3, width: float, lifetime: float) -> void:
	var wall := BrambleWall.new()
	_woods.add_child(wall)
	wall.setup(_woods.ground_at(Vector2(at.x, at.z)), facing, width, lifetime)


func spawn_mud(at: Vector3) -> void:
	var mud := MudPatch.new()
	_woods.add_child(mud)
	mud.setup(_woods.ground_at(Vector2(at.x, at.z)))


func ignite_at(point: Vector3) -> void:
	for spot: HidingSpot in _woods.hiding_spots:
		if spot.burnable() and spot.contains(point):
			spot.ignite()
	_burn_walls(point, Tuning.f("fire", "douse_radius"))


func ignite_around(centre: Vector3, radius: float) -> void:
	for spot: HidingSpot in _woods.hiding_spots:
		if spot.burnable() and spot.global_position.distance_to(centre) <= radius + spot.radius:
			spot.ignite()
	_burn_walls(centre, radius)


func douse_at(point: Vector3) -> void:
	for spot: HidingSpot in _woods.hiding_spots:
		if spot.global_position.distance_to(point) <= spot.radius + Tuning.f("fire", "douse_radius"):
			spot.extinguish()


func _burn_walls(point: Vector3, radius: float) -> void:
	for node: Node in _woods.get_tree().get_nodes_in_group("walls"):
		if (node as Node3D).global_position.distance_to(point) <= radius:
			(node as BrambleWall).burn_down()


func _temporary_spot(spot: HidingSpot, lifetime: float) -> void:
	_woods.add_hiding_spot(spot)
	spot.get_tree().create_timer(lifetime).timeout.connect(func() -> void: _woods.remove_hiding_spot(spot))
