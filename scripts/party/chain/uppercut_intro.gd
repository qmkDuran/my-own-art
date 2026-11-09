class_name UppercutIntro
extends SwapMove
## Emberoo's Intro: coming in while enemies hang in the air (Launched), he bursts in with a
## flaming uppercut that hits every launched enemy within `reach` for big bonus damage, with
## a screen flash, a hard shake and a moment of hit-stop. No launched enemies: no Intro.

@export var reach: float = 90.0
@export var damage: int = 4
@export var knockback_speed: float = 260.0
@export var screen_shake: ScreenShake
@export var impact_scene: PackedScene


func is_armed_at(spot: Vector2) -> bool:
	return not _launched_targets_near(spot).is_empty()


func play(member: PlayableCreature) -> void:
	var launched_targets := _launched_targets_near(member.global_position)
	if launched_targets.is_empty():
		return
	for target_health in launched_targets:
		_strike(member, target_health.get_parent() as Node2D)
	AbilityTargets.hurt_all(member, launched_targets, damage)
	AbilityTargets.knock_back_all(launched_targets, member.global_position, knockback_speed)
	if screen_shake != null:
		screen_shake.shake(3.0, 0.25)
	ScreenFlash.play(member, ApolloPalette.GOLD)
	HitStop.play(member.get_tree())


## A fan of flame and a fire impact on each launched enemy.
func _strike(member: PlayableCreature, enemy: Node2D) -> void:
	var flame := FlameArc.new()
	member.get_parent().add_child(flame)
	flame.global_position = enemy.global_position + Vector2(0, 4)
	flame.play(Vector2.UP, 22.0, 120.0)
	if impact_scene != null:
		var impact := impact_scene.instantiate() as Node2D
		member.get_parent().add_child(impact)
		impact.global_position = enemy.global_position + Vector2(0, -10)


func _launched_targets_near(spot: Vector2) -> Array[Health]:
	var launched_targets: Array[Health] = []
	for target_health in AbilityTargets.within(self, spot, reach):
		if Launched.is_launched(target_health.get_parent()):
			launched_targets.append(target_health)
	return launched_targets
