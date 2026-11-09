class_name ShardFoundToast
extends BossDefeatedBanner
## The top-centre card shown when a Glimmer Shard is picked up, saying exactly what it
## gave, e.g. "GLIMMER SHARD: +1 chip slot" (see ShardReward).


func _init() -> void:
	text_color = ApolloPalette.SKY


func _ready() -> void:
	super._ready()
	ShardInventory.collected.connect(_on_shard_collected)


func _on_shard_collected(shard_id: String) -> void:
	var reward := ShardInventory.reward_of(shard_id)
	if reward != ShardInventory.NO_REWARD:
		announce(ShardReward.toast_text(reward))
