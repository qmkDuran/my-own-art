class_name Loadouts
## The four moves each creature takes into the fight and the level both creatures fight at (Baby or Grown). Both are
## built by the same rules from the same library: the player picks on the loadout screen; the bot takes its species'
## default four for that level. Kept across restarts.

static var level: String = "grown"
static var player_moves: Array[String] = []


static func for_player() -> Array[String]:
	if player_moves.size() != MoveLibrary.SLOTS or not player_moves.all(func(id: String) -> bool:
			return MoveLibrary.allowed(id, level)):
		player_moves = MoveLibrary.default_loadout("player", level)
	return player_moves


static func for_bot() -> Array[String]:
	return MoveLibrary.default_loadout("bot", level)


## Puts a move in a slot; if it is already in another slot the two swap.
static func assign(slot: int, move_id: String) -> void:
	var moves: Array[String] = for_player()
	var other: int = moves.find(move_id)
	if other >= 0:
		moves[other] = moves[slot]
	moves[slot] = move_id


static func set_level(next: String) -> void:
	level = next
	for_player()
