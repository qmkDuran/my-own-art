class_name Moonbeam
extends Attack
## Beams of cool moonlight that strike random spots around the player: a pale column flashes down after a short
## warning ring, and everything inside it is hurt.

const SPOT_SHARE: float = 0.3
const BEAM_HEIGHT: float = 9.0
const BEAM_SECONDS: float = 0.35
const BEAM_ENERGY: float = 4.0
const FLASH_ENERGY: float = 3.0
const FLASH_REACH: float = 3.0


func fire() -> void:
	for index: int in int(stat("count")):
		var spread: float = area_stat("spread")
		var target: Creature = horde.nearest(player.global_position, spread) if index == 0 else null
		var spot: Vector3 = player.global_position + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread,
			spread)) * SPOT_SHARE * 2.0
		if target != null:
			spot = target.global_position
		_strike(Vector3(spot.x, 0.0, spot.z))


func _strike(spot: Vector3) -> void:
	var warning: MeshInstance3D = RingMesh.make(colour())
	get_tree().current_scene.add_child(warning)
	warning.global_position = spot + Vector3.UP * RingMesh.LIFT
	warning.scale = Vector3(area_stat("radius"), RingMesh.LIFT, area_stat("radius"))
	await get_tree().create_timer(stat("delay"), false).timeout
	warning.queue_free()
	if not is_inside_tree():
		return
	for creature: Creature in horde.within(spot, area_stat("radius")):
		creature.hurt(stat("damage"))
	var beam: Node3D = _beam()
	get_tree().current_scene.add_child(beam)
	beam.global_position = spot
	get_tree().create_timer(BEAM_SECONDS, false).timeout.connect(beam.queue_free)


func _beam() -> Node3D:
	var holder := Node3D.new()
	var column := CylinderMesh.new()
	column.top_radius = area_stat("radius")
	column.bottom_radius = area_stat("radius")
	column.height = BEAM_HEIGHT
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = colour() * SPOT_SHARE * BEAM_ENERGY
	column.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = column
	mesh.position.y = BEAM_HEIGHT * 0.5
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mesh)
	var flash := OmniLight3D.new()
	flash.light_color = colour()
	flash.light_energy = FLASH_ENERGY
	flash.omni_range = area_stat("radius") * FLASH_REACH
	flash.position.y = 1.0
	holder.add_child(flash)
	return holder
