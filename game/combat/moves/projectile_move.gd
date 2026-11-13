class_name ProjectileMove
extends Move
## Ranged moves (Glob, Cinder Spit, Spray Jet, Seed Scatter, Mud Lob, Thorn Dart, Sticky Sap): one or more slow
## shots toward the aim point. They can miss and are stopped by trees, rocks, logs and walls. Shooting downhill from
## high ground reaches a little further.


## How far a shot aimed at this point may travel (modest bonus when the shooter stands well above it).
func reach_toward(aim: Vector3) -> float:
	var reach: float = number("reach")
	if creature.mouth_position().y - aim.y >= Tuning.f("attack_rules", "high_ground_min_drop"):
		reach *= Tuning.f("attack_rules", "high_ground_range_factor")
	return reach


func _on_release() -> void:
	var from: Vector3 = creature.mouth_position()
	var aim: Vector3 = creature.aim_point
	var count: int = int(spec.get("count", 1))
	var spread: float = deg_to_rad(float(spec.get("spread_deg", 0.0)))
	var damage: float = damage_now()
	for k: int in count:
		var turn: float = (k - (count - 1) * 0.5) * spread
		var shot := Projectile.new()
		shot.setup(self, from, (aim - from).normalized().rotated(Vector3.UP, turn), reach_toward(aim), damage)
		creature.get_parent().add_child(shot)
