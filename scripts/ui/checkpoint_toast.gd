class_name CheckpointToast
extends BossDefeatedBanner
## The top-centre "CHECKPOINT" card shown when the player reaches a new checkpoint, also used
## for short world messages. Callers reach it through the static functions (a group call), so
## they need no reference to the HUD.

const GROUP := "checkpoint_toast"
const TEXT := "CHECKPOINT"


## Shows the toast on the HUD of `asker`'s level.
static func announce_reached(asker: Node) -> void:
	show_message(asker, TEXT)


## Shows `text` in the same card, e.g. "PATH BLOCKED (COMING SOON)" at a closed zone exit.
static func show_message(asker: Node, text: String) -> void:
	asker.get_tree().call_group(GROUP, "announce", text)


func _init() -> void:
	text_color = ApolloPalette.GOLD


func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
