class_name LinkMeter
extends Node
## The team's Link meter (see PROJECT_B.md, "The Link meter"): it fills from hits landed,
## reactions and Signal Skills. When it's full, the next Signal Skill is a Link Finisher
## (double damage, slow-mo) and the meter empties. Lives under the Party; the HUD's
## LinkMeterBar draws it.

const GROUP := "link_meter"
const FULL := 100.0
const PER_HIT := 1.0
const PER_REACTION := 8.0
const PER_SIGNAL := 8.0

var charge: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)


## Adds `amount` to the level's Link meter, if it has one.
static func add_from(asker: Node, amount: float) -> void:
	var meter := asker.get_tree().get_first_node_in_group(GROUP) as LinkMeter
	if meter != null:
		meter.add(amount)


func add(amount: float) -> void:
	charge = minf(FULL, charge + amount)


func is_full() -> bool:
	return charge >= FULL


func share() -> float:
	return charge / FULL


func spend() -> void:
	charge = 0.0
