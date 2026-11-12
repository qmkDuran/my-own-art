class_name WallMove
extends MoveKind
## Bloom's vine wall: a short wall of vines across the aim, square to it, that blocks movement and shots for a while
## and can be broken or burnt. Only an arena has ground to grow it in.


func cast(user: Creature, m: Dictionary, at: Vector2, _strength: float = 1.0) -> void:
	var a: Arena = TerrainRules.arena()
	if a == null:
		return
	var center: Vector2 = clamp_aim(user, m, at)
	var across: Vector2 = dir_to(user, at).orthogonal()
	var half: int = int(m["width"]) / 2
	for k: int in range(-half, half + 1):
		a.grow_vine(center + across * k * a.layout.cell, float(m["duration"]), float(m["life"]))
	TamerFx.blast(center, 40.0, element(user, m))
	Audio.sfx("step", -4.0, 0.7)
