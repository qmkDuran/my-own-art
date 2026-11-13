class_name BotStates
## The bot's actions by option name (the names data/ai.json scores), plus the "notice" reaction beat.


static func all(brain: BotBrain) -> Dictionary:
	return {
		"patrol": PatrolState.new(brain), "notice": NoticeState.new(brain), "chase": ChaseState.new(brain),
		"melee": FightState.new(brain, "melee"), "ranged": FightState.new(brain, "ranged"),
		"area": FightState.new(brain, "area"), "cover": CoverState.new(brain), "flank": FlankState.new(brain),
		"stalk": StalkState.new(brain), "ambush": AmbushState.new(brain), "retreat": RetreatState.new(brain),
		"search": SearchState.new(brain), "buff": UseMoveState.new(brain, "buff"),
		"debuff": UseMoveState.new(brain, "debuff"), "defend": UseMoveState.new(brain, "defend"),
		"sense": UseMoveState.new(brain, "sense"), "high_ground": HighGroundState.new(brain),
		"burrow_ambush": BurrowAmbushState.new(brain), "climb_hide": ClimbHideState.new(brain),
		"burn_grass": BurnGrassState.new(brain),
	}
