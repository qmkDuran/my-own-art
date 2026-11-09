class_name WorldReset
extends RefCounted
## What the zone does while the screen is dark after the player falls: forgiving, like a
## campaign checkpoint. Enemies already killed stay dead; the ones still alive heal to full
## and go back to their spawn points, unaware again; summoned creatures vanish; a boss fight
## starts over (full health, gates open; see BossArena and WardenCaptain).


static func after_player_fell(asker: Node) -> void:
	var tree := asker.get_tree()
	for summoned in tree.get_nodes_in_group(EnemyReactions.SUMMONED_GROUP):
		summoned.remove_from_group(EnemyReactions.ENEMIES_GROUP)
		summoned.remove_from_group(EnemyReactions.SUMMONED_GROUP)
		summoned.queue_free()
	for enemy in tree.get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		if enemy is Enemy:
			(enemy as Enemy).return_to_spawn()
	tree.call_group(BossArena.GROUP, "start_over")
