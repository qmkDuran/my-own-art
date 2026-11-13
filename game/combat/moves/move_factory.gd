class_name MoveFactory
## Builds the right move class for a library entry, by its archetype.


static func create(owner: Creature, move_id: String) -> Move:
	match String(MoveLibrary.spec(move_id)["archetype"]):
		"melee":
			return MeleeMove.new(owner, move_id)
		"projectile":
			return ProjectileMove.new(owner, move_id)
		"area":
			return AreaMove.new(owner, move_id)
		"leap":
			return LeapMove.new(owner, move_id)
		"buff":
			return BuffMove.new(owner, move_id)
		"sidestep":
			return SidestepMove.new(owner, move_id)
		"burrow":
			return BurrowMove.new(owner, move_id)
		"climb":
			return ClimbMove.new(owner, move_id)
		"submerge":
			return SubmergeMove.new(owner, move_id)
		"sense":
			return SenseMove.new(owner, move_id)
	return SpawnMove.new(owner, move_id)
