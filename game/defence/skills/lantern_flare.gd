class_name LanternFlare
extends Attack
## The starter: light bolts at the nearest creatures (more bolts and piercing with levels).

const CHEST_HEIGHT: float = 1.1
const BOLT_ENERGY: float = 1.5


func fire() -> void:
	var from: Vector3 = player.global_position + Vector3.UP * CHEST_HEIGHT
	var targets: Array[Creature] = horde.within(player.global_position, stat("range"))
	targets.sort_custom(func(a: Creature, b: Creature) -> bool:
		return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	for index: int in mini(int(stat("count")), targets.size()):
		var bolt := LightBolt.new()
		bolt.setup(self, from, targets[index].centre())
		bolt.add_child(glow_ball(area_stat("size"), BOLT_ENERGY))
		get_tree().current_scene.add_child(bolt)
		bolt.global_position = from
