class_name BellChime
extends Attack
## A ringing pulse from the lantern: a bright ring sweeps outwards and every creature inside is hurt, pushed back
## and stunned for a moment. Bosses only take the damage.

const PULSE_SECONDS: float = 0.4


func fire() -> void:
	var centre: Vector3 = player.global_position
	for creature: Creature in horde.within(centre, area_stat("radius")):
		var away: Vector3 = Vector3(creature.global_position.x - centre.x, 0.0, creature.global_position.z - centre.z)
		creature.hurt(stat("damage"), away.normalized() * stat("knockback"), stat("stun"))
	var ring: MeshInstance3D = RingMesh.make(colour())
	add_child(ring)
	ring.top_level = true
	ring.global_position = centre + Vector3.UP * RingMesh.LIFT
	var size: float = area_stat("radius")
	ring.scale = Vector3(0.0, RingMesh.LIFT, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(ring, "scale", Vector3(size, RingMesh.LIFT, size), PULSE_SECONDS)
	tween.tween_callback(ring.queue_free)
