class_name Npc
extends Interactable
## A person you can talk to: an idle-animated figure with a name; lines come one at a time from story.json, then
## a short repeat line.

const FPS: float = 4.0

var npc_id: String
var talked: int = 0
var _t: float = 0.0


func _ready() -> void:
	npc_id = String(prop["npc"])
	title = String(GameData.story["npcs"][npc_id]["name"])
	super()


func make_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = PropSprite.tex("res://art/actors/npc_%s.png" % npc_id)
	s.hframes = 4
	s.offset = Vector2(0, -32 + 3)
	PropSprite.add_glow(s, "res://art/actors/npc_%s_glow.png" % npc_id)
	s.add_child(PropSprite.shadow(28.0))
	return s


func _process(delta: float) -> void:
	_t += delta * FPS
	PropSprite.set_frame(sprite, int(_t) % 4)
	sprite.flip_h = Game.current.player.global_position.x < global_position.x


func use(g: Game) -> void:
	var d: Dictionary = GameData.story["npcs"][npc_id]
	g.hud.show_dialogue(d["lines"] if talked == 0 else [d["repeat"]])
	talked += 1
	g.mark_dirty()
