class_name PlayerAwareness
extends RefCounted
## Whether an enemy has noticed the player yet.
##
## Enemies placed around a zone wait, unaware, until the player comes within their notice
## distance. Once they notice, they stay alert, and they alert their pack: every enemy close
## by that can notice the player (has a `notice_player()` method) notices too.
## Noticing is also when the player meets the species: an enemy with `creature_info()` is
## recorded in the CreatureLog (the first of its kind brings up the discovery card).

## Enemies this close to the one that noticed the player are alerted with it, in pixels.
const PACK_ALERT_RADIUS := 64.0

var has_noticed: bool = false


## True once the player has come within `notice_distance` of `body` (and from then on).
func has_noticed_player(body: Node2D, notice_distance: float) -> bool:
	if not has_noticed:
		var player := PlayerFinder.find(body)
		if player != null and body.global_position.distance_to(player.global_position) <= notice_distance:
			notice(body)
	return has_noticed


## Notices the player now (e.g. when hit, or when summoned) and alerts the rest of the pack.
func notice(body: Node2D) -> void:
	if has_noticed:
		return
	has_noticed = true
	if body.has_method("creature_info"):
		CreatureLog.discover(body.creature_info())
	for enemy in body.get_tree().get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		var other := enemy as Node2D
		if other == null or other == body or not other.has_method("notice_player"):
			continue
		if body.global_position.distance_to(other.global_position) <= PACK_ALERT_RADIUS:
			other.notice_player()
