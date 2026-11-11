class_name Pal
extends RefCounted
## The game palette (mirror of art/palette.py; tools/check_art.py keeps them equal). UI and shaders use these names.

const C: Dictionary = {
	"void": Color8(11, 10, 18), "ink": Color8(21, 19, 31), "night": Color8(29, 27, 44), "dusk1": Color8(42, 39, 64),
	"dusk2": Color8(59, 55, 87), "dusk3": Color8(85, 80, 122), "mist": Color8(122, 118, 160), "pale": Color8(180, 178, 207),
	"bone": Color8(232, 228, 216),
	"ember_dk": Color8(74, 30, 26), "rust": Color8(124, 47, 31), "ember": Color8(194, 69, 30), "flame": Color8(240, 122, 36),
	"amber": Color8(247, 176, 67), "gold": Color8(255, 215, 122), "sun": Color8(255, 246, 214),
	"glass_dp": Color8(18, 48, 58), "glass_dk": Color8(28, 74, 85), "glass": Color8(47, 125, 132), "glass_lt": Color8(87, 184, 176),
	"glint": Color8(166, 240, 224),
	"moss_dk": Color8(26, 36, 32), "moss": Color8(38, 53, 44), "moss_lt": Color8(59, 77, 58), "earth_dk": Color8(42, 32, 28),
	"earth": Color8(67, 51, 42), "earth_lt": Color8(107, 80, 64), "stone_dk": Color8(44, 43, 51), "stone": Color8(74, 72, 82),
	"stone_lt": Color8(117, 114, 126),
	"blood": Color8(184, 40, 58), "rose": Color8(232, 80, 90), "violet": Color8(106, 61, 154), "violet_lt": Color8(160, 112, 216),
	"skin_dk": Color8(122, 74, 58), "skin": Color8(176, 116, 88), "skin_lt": Color8(214, 160, 124),
	"leaf_dk": Color8(36, 84, 52), "leaf": Color8(72, 146, 70), "leaf_lt": Color8(150, 212, 104),
	"sea_dk": Color8(30, 52, 112), "sea": Color8(54, 102, 190), "sea_lt": Color8(116, 176, 238),
	"bile_dk": Color8(92, 100, 38), "bile": Color8(176, 186, 62),
}


static func c(name: String, alpha: float = 1.0) -> Color:
	return Color(C[name], alpha)
