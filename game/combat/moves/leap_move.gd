class_name LeapMove
extends Move
## Jumps: Leap (onto rocks, logs, low ledges), Spring (high standing jump), Glide (a hop into a long slow glide).
## The creature flies in the direction it is steering (or facing); landing makes a noise.


func _on_release() -> void:
	var steering: bool = creature.move_intent.length() > 0.0
	var heading: Vector3 = creature.move_intent.normalized() if steering else creature.forward()
	creature.launch(heading * number("forward") + Vector3.UP * number("up"))
	if spec.has("glide"):
		creature.effects.add("glide", 1.0, number("glide"))
