class_name Chest
extends Interactable
## A chest left where someone lived or camped. Opens once and drops loot on open ground around it.

const LOOT_LEVEL_BONUS: int = 1
var opened: bool = false


func _ready() -> void:
	title = String(GameData.story["chests"].get(prop.get("chest", ""), "Chest"))
	super()


func use(g: Game) -> void:
	if opened:
		return
	open(g, true)


func open(g: Game, with_loot: bool) -> void:
	opened = true
	PropSprite.set_frame(sprite, 1)
	title = ""
	if not with_loot:
		return
	Audio.sfx("chest", -4.0)
	Fx.flash(g.fx_layer, global_position, 90.0, Pal.c("gold"), 1.2, 0.4)
	var source: String = "rare" if prop.get("chest", "") == "secret" else "chest"
	var D: Dictionary = GameData.items["drop"]
	g.spawner.drop_items(global_position, int(D["count"]["chest"]) + (1 if source == "rare" else 0), source,
		g.spawner.level_at(g.progress_at(global_position)) + LOOT_LEVEL_BONUS)
	g.mark_dirty()
