class_name MudPatch
extends MeshInstance3D
## A puddle of mud left where a jet of water hits the ground: anyone walking through it is slowed. Dries up.

const LIFT: float = 0.04
const MUD: Color = Color(0.28, 0.2, 0.12, 0.85)
const SLOW_REFRESH: float = 0.3
const WET: float = 0.2

var _radius: float = 1.0


func setup(at: Vector3) -> void:
	_radius = Tuning.f("terrain_effects", "mud_radius")
	var disc := CylinderMesh.new()
	disc.top_radius = _radius
	disc.bottom_radius = _radius
	disc.height = LIFT
	mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = MUD
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = WET
	material_override = material
	position = at + Vector3.UP * LIFT
	var fade: Tween = create_tween()
	fade.tween_interval(Tuning.f("terrain_effects", "mud_life"))
	fade.tween_callback(queue_free)


func _physics_process(_delta: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("creatures"):
		var creature := node as Creature
		var offset: Vector3 = creature.global_position - global_position
		if Vector2(offset.x, offset.z).length() <= _radius and creature.is_on_floor():
			creature.effects.add("slow", Tuning.f("terrain_effects", "mud_slow"), SLOW_REFRESH)
