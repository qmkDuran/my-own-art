class_name BotStates
## The bot's actions by option name (the names data/ai.json scores), plus the "notice" reaction beat.


static func all(brain: BotBrain) -> Dictionary:
	return {
		"patrol": PatrolState.new(brain), "notice": NoticeState.new(brain), "chase": ChaseState.new(brain),
		"spit": FightState.new(brain, "spit"), "bite": FightState.new(brain, "bite"), "cover": CoverState.new(brain),
		"flank": FlankState.new(brain), "stalk": StalkState.new(brain), "snare": SnareState.new(brain),
		"ambush": AmbushState.new(brain), "retreat": RetreatState.new(brain), "search": SearchState.new(brain),
		"bait": BaitState.new(brain),
	}
