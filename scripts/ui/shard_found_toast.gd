class_name ShardFoundToast
extends BossDefeatedBanner
## The top-centre card shown when a Glimmer Shard is picked up. Shards can't be socketed
## yet, so it says so.

const TEXT := "GLIMMER SHARD FOUND (shards coming soon)"


func _init() -> void:
	text_color = ApolloPalette.SKY


func _ready() -> void:
	super._ready()
	ShardInventory.collected.connect(_on_shard_collected)


func _on_shard_collected(_shard_id: String) -> void:
	announce(TEXT)
