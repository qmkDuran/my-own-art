class_name ChipFoundToast
extends BossDefeatedBanner
## The top-centre card shown when a hacked chip is picked up ("HACKED CHIP WR-007  (C)"),
## or when the Link Rod's storage is full and the chip stays on the ground.

const FOUND_FORMAT := "HACKED CHIP %s  (C: Link Rod)"
const FULL_TEXT := "CHIP STORAGE FULL: salvage one (C)"


func _init() -> void:
	text_color = ApolloPalette.SKY_LIGHT


func _ready() -> void:
	super._ready()
	LinkRod.chip_added.connect(func(chip: Chip) -> void: announce(FOUND_FORMAT % chip.display_name()))
	LinkRod.storage_full.connect(announce.bind(FULL_TEXT))
