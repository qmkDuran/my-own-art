class_name TrainerLook
extends Resource
## How the trainer looks: which hair and top styles to wear, and which colour ramp
## (a preset name from data/trainer/presets.json) each layer is recoloured with.
##
## The default look stays close to the original trainer: chestnut hair, an orange top
## with the satchel strap (matching Emberoo), dark trousers and warm skin.

const HAIR_STYLE_COUNT := 3
const TOP_STYLE_COUNT := 2

## Index of the hair style, 0 to HAIR_STYLE_COUNT - 1 (sheet "hair_<index + 1>").
@export_range(0, HAIR_STYLE_COUNT - 1) var hair_style: int = 0
## Index of the top style, 0 to TOP_STYLE_COUNT - 1 (sheet "top_<index + 1>").
@export_range(0, TOP_STYLE_COUNT - 1) var top_style: int = 0
## A "hair" preset.
@export var hair_ramp: StringName = &"chestnut"
## An "outfit" preset.
@export var top_ramp: StringName = &"ember_orange"
## An "outfit" preset.
@export var bottom_ramp: StringName = &"navy"
## An "outfit" preset.
@export var shoes_ramp: StringName = &"deep_red"
## A "skin" preset.
@export var skin_ramp: StringName = &"warm"


## A look with every choice picked at random.
static func random() -> TrainerLook:
	var look := TrainerLook.new()
	look.hair_style = randi() % HAIR_STYLE_COUNT
	look.top_style = randi() % TOP_STYLE_COUNT
	look.hair_ramp = TrainerPresets.ramp_names(TrainerPresets.HAIR).pick_random()
	look.top_ramp = TrainerPresets.ramp_names(TrainerPresets.OUTFIT).pick_random()
	look.bottom_ramp = TrainerPresets.ramp_names(TrainerPresets.OUTFIT).pick_random()
	look.shoes_ramp = TrainerPresets.ramp_names(TrainerPresets.OUTFIT).pick_random()
	look.skin_ramp = TrainerPresets.ramp_names(TrainerPresets.SKIN).pick_random()
	return look
