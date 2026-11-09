class_name PlayerGuard
extends RefCounted
## Whether the player has Ash Guard up right now, for attacks that react to being blocked
## (the Shalendrill's knuckles crack on a guard).

const ASH_GUARD_PATH := AshGuard.NODE_PATH


static func is_guarding(player: Node) -> bool:
	var guard := player.get_node_or_null(ASH_GUARD_PATH) as AshGuard
	return guard != null and guard.is_casting
