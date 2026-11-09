class_name PartyMemberSwitch
extends RefCounted
## Puts a team member on the field or takes it off. Only the member on the field is the
## player (the "player" group that enemies, pickups and the HUD look for), shows, moves and
## collides. A benched member is frozen as it was: its health, cooldowns and status effects
## wait until it comes back.


static func bring_in(member: PlayableCreature, at: Vector2) -> void:
	member.global_position = at
	member.velocity = Vector2.ZERO
	member.visible = true
	member.process_mode = Node.PROCESS_MODE_INHERIT
	member.add_to_group(PlayerFinder.GROUP)


static func bench(member: PlayableCreature) -> void:
	member.interrupt()
	member.velocity = Vector2.ZERO
	var orders := member.get_node_or_null("MouseOrders") as MouseOrders
	if orders != null:
		orders.clear()
	member.remove_from_group(PlayerFinder.GROUP)
	member.visible = false
	member.process_mode = Node.PROCESS_MODE_DISABLED
