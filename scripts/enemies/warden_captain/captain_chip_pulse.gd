class_name CaptainChipPulse
extends BossAttack
## Phase 2's chip pulse: the Captain raises his rod, cyan energy gathers at its tip, then he
## fires three orbs in a spread toward the player (the Zephoot's gust orbs, sped up). Step
## between them or dodge through.

## The orb he fires.
@export var orb_scene: PackedScene
## He fires when the player is between these distances, in pixels (closest, farthest).
@export var firing_range: Vector2 = Vector2(40, 170)
## Orbs per pulse.
@export var orb_count: int = 3
## Angle between neighbouring orbs, in degrees.
@export var spread_degrees: float = 22.0
## Orb speed, in pixels per second (faster than a Zephoot's).
@export var orb_speed: float = 75.0
## Where the orbs leave, relative to his feet.
@export var muzzle_offset: Vector2 = Vector2(0, 2)
@export var charge_particles: ChargeParticles


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player >= firing_range.x and distance_to_player <= firing_range.y


func _on_start() -> void:
	if charge_particles != null:
		charge_particles.start_charging()


func _release() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()
	var player := PlayerFinder.find(self)
	if orb_scene == null or player == null:
		return
	var muzzle := boss.global_position + muzzle_offset
	var aim := (player.global_position - muzzle).angle()
	for orb_number in orb_count:
		var orb: GustOrb = orb_scene.instantiate()
		orb.speed = orb_speed
		boss.get_parent().add_child(orb)
		orb.global_position = muzzle
		var spread_step := orb_number - (orb_count - 1) / 2.0
		orb.launch(Vector2.from_angle(aim + deg_to_rad(spread_degrees) * spread_step))


func _on_finish() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()
