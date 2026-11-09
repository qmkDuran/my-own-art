class_name ChipDrop
extends Node
## What a human enemy (a Warden, the Warden Captain, later Warden types) leaves for the Link
## Rod when it dies: sometimes a hacked chip, and always a little scrap from its broken rod.
## Glimra never carry one (see DESIGN.md, "Loot: hacked chips"): only human scenes get this.
##
## Listens to its body's Health, so the enemy script needs no changes.

enum Quality { WARDEN, CAPTAIN }

## Chance (0 to 1) of dropping a chip: about 1 in 4 for a Warden, 1 for the Captain.
@export_range(0.0, 1.0, 0.01) var chip_chance: float = 0.25
## How good its chips are (see ChipRoller's qualities).
@export var quality: Quality = Quality.WARDEN
## The act this enemy belongs to: its chips' tier (Ruins Edge is Act 1).
@export_range(1, 3) var act: int = 1
## Scrap it always drops, as that many little bits.
@export var scrap_min: int = 2
@export var scrap_max: int = 4
## Where on the body the drops pop out, relative to its feet.
@export var burst_offset: Vector2 = Vector2(0, -8)

const QUALITIES := {Quality.WARDEN: ChipRoller.WARDEN_QUALITY, Quality.CAPTAIN: ChipRoller.CAPTAIN_QUALITY}

## Seeded by a test driver to check the drop rate; random otherwise.
static var rng := RandomNumberGenerator.new()

@onready var _body: Node2D = get_parent()


static func _static_init() -> void:
	rng.randomize()


func _ready() -> void:
	(_body.get_node("Health") as Health).died.connect(drop)


## Drops the scrap and maybe a chip. Returns the chip dropped, or null.
func drop() -> Chip:
	var world := _body.get_parent()
	var at := _body.global_position
	for bit in rng.randi_range(scrap_min, scrap_max):
		var scrap := ScrapPickup.new()
		world.add_child.call_deferred(scrap)
		scrap.set_deferred("global_position", at + burst_offset)
	if rng.randf() >= chip_chance:
		return null
	var pickup := ChipPickup.new()
	pickup.chip = LinkRod.roll_chip(act, QUALITIES[quality])
	world.add_child.call_deferred(pickup)
	pickup.set_deferred("global_position", at)
	return pickup.chip
