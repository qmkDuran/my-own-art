extends Node
## The Glimmer Shards the player has found (registered as the "ShardInventory" autoload).
##
## Shards are hand-placed (see DESIGN.md, "Drops and progression resources"), each with its
## own ID, so a shard that was picked up never shows again, even after loading a save.
## Each shard gives one permanent upgrade (ShardReward); this remembers which one every
## found shard gave, so the upgrades (chip slots, max Heat, Aid charges) come back on load.

signal collected(shard_id: String)

const NO_REWARD := -1

## Shard ID -> the ShardReward.Kind it gave, or NO_REWARD (an older save's placeholder shard,
## found before shards gave anything; its shard fills it in, see `fill_in_reward`).
var _found: Dictionary[String, int] = {}


func has_found(shard_id: String) -> bool:
	return _found.has(shard_id)


## The reward the shard gave, or NO_REWARD.
func reward_of(shard_id: String) -> int:
	return _found.get(shard_id, NO_REWARD)


## How many found shards gave this reward (e.g. extra chip slots).
func count_of(kind: ShardReward.Kind) -> int:
	return _found.values().count(kind)


## Records a shard and gives its reward. Returns false (and does nothing) if it was already
## found, so a reward is never given twice.
func collect(shard_id: String, reward: ShardReward.Kind) -> bool:
	if has_found(shard_id):
		return false
	_found[shard_id] = reward
	ShardReward.grant_once(reward)
	collected.emit(shard_id)
	return true


## A shard found in an older save (before shards gave upgrades) gets its reward now, once.
func fill_in_reward(shard_id: String, reward: ShardReward.Kind) -> void:
	if reward_of(shard_id) != NO_REWARD or not has_found(shard_id):
		return
	_found[shard_id] = reward
	ShardReward.grant_once(reward)
	collected.emit(shard_id)


## What SaveGame writes: the IDs of the shards found, and what each one gave.
func to_save_data() -> Dictionary:
	var rewards := {}
	for shard_id in _found:
		if _found[shard_id] != NO_REWARD:
			rewards[shard_id] = ShardReward.SAVE_NAMES[_found[shard_id]]
	return {"found": _found.keys(), "rewards": rewards}


## Restores a save (an empty one means none found).
func load_save_data(data: Dictionary) -> void:
	_found.clear()
	var rewards := SaveData.read_section(data, "rewards")
	for shard_id in SaveData.read_strings(data, "found"):
		var reward_name: Variant = rewards.get(shard_id)
		_found[shard_id] = ShardReward.from_save_name(reward_name) if reward_name is String else NO_REWARD
