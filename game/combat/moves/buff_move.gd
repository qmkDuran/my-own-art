class_name BuffMove
extends Move
## Moves that change the user for a while (Quickening, Bristle, Steady Eye, Scamper, Bark Skin, Ward, Tuck) or heal
## it (Lick Wounds). Each has a cost in its data: slower, louder, rooted, or a long still wind-up.


func _on_release() -> void:
	for effect: Dictionary in spec.get("effects", []):
		creature.effects.add(effect["effect"], float(effect["value"]), float(effect["duration"]))
	if spec.has("heal"):
		creature.health.heal(number("heal"))
