class_name BossTestLoadout
extends Node
## For a boss's test arena (which never loads or writes the save): makes Emberoo the level,
## Awakening and Ember Tree build a player would bring to that boss, so the fight can be
## tried on its own. Runs in `_enter_tree`, before Emberoo readies (place it above him).
## Does nothing if Emberoo is already at least that level (e.g. the arena was reloaded).

@export var level: int = 11
## Ember Tree node ids to learn, in order (each needs the one before it on its branch).
@export var learned_nodes: Array[String] = [
	"searing_jab", "flame_uppercut", "hot_knuckles",
	"ash_guard", "counter_punch", "thick_hide",
	"spinning_hook", "ember_hop", "quick_hands",
	"unshakable", "wildfire",
]


func _enter_tree() -> void:
	if Progression.level >= level:
		return
	Progression.level = level
	Progression.xp = 0
	Progression.skill_points = level
	Awakening.set_stage(AwakeningStage.for_level(level), false)
	for node_id in learned_nodes:
		if not EmberTree.learn(node_id):
			push_warning("BossTestLoadout: couldn't learn %s" % node_id)
