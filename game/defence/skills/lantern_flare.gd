class_name LanternFlare
extends Attack
## The starter, and the showcase effect: for each target, light gathers at the lantern (a quick wind-up with a
## soft whoosh), then a flame-wisp bolt flies at the creature (see LightBolt and data/vfx.json).

const CHEST_HEIGHT: float = 1.1


func fire() -> void:
	var from: Vector3 = player.global_position + Vector3.UP * CHEST_HEIGHT
	var targets: Array[Creature] = horde.within(player.global_position, stat("range"))
	targets.sort_custom(func(a: Creature, b: Creature) -> bool:
		return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	for index: int in mini(int(stat("count")), targets.size()):
		cast(targets[index])


## One flare at one creature: wind-up at the lantern, then the bolt.
func cast(target: Creature) -> void:
	var look: Dictionary = Tuning.doc("vfx")["lantern_flare"]
	var hand: Vector3 = _lantern_position()
	if kit != null:
		var gather := WindupGather.new()
		kit.place(gather, hand)
		gather.play(kit, look["windup"])
		kit.sfx.play("flare_whoosh", hand)
		await get_tree().create_timer(float(look["windup"]["seconds"]), false).timeout
	if not is_instance_valid(target) or not is_inside_tree():
		return
	var bolt := LightBolt.new()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = _lantern_position()
	bolt.setup(self, bolt.global_position, target.centre())


func _lantern_position() -> Vector3:
	var lantern: Node3D = (player as Player).lantern if player is Player else null
	return lantern.global_position if lantern != null else player.global_position + Vector3.UP * CHEST_HEIGHT
