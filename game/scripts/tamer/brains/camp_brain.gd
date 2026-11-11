class_name CampBrain
extends CreatureBrain
## At camp: the creature that was out walks to its seat by the fire and settles there, facing the flames.

var seat: Vector2
var fire: Vector2


func _init(creature: Creature, at: Vector2, fire_at: Vector2) -> void:
	super(creature)
	seat = at
	fire = fire_at


func think(delta: float) -> Vector2:
	var dir: Vector2 = c.steer_to(seat, delta)
	if dir == Vector2.ZERO:
		c.face(fire)
	return dir * c.rec.speed() * 0.6
