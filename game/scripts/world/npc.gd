class_name Npc
extends Interactable
## A person you can talk to: an idle-animated figure with a name. What they say comes from Dialogue (it depends on
## the campaign: quests, flags, what they said before).

const FPS: float = 6.0
const FRAMES: int = 8
const SEAT_DROP: float = 16.0   ## a seated person (prop "seated") is drawn this much lower, legs hidden by the desk before them

var npc_id: String
var talked: int = 0
var _t: float = 0.0


func _ready() -> void:
	npc_id = String(prop["npc"])
	title = String(GameData.dialogue[npc_id]["name"])
	super()


func make_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = PropSprite.tex("res://art/actors/npc_%s.png" % npc_id)
	s.hframes = FRAMES
	s.offset = Vector2(0, -32 + 3 + (SEAT_DROP if bool(prop.get("seated", false)) else 0.0))
	PropSprite.add_glow(s, "res://art/actors/npc_%s_glow.png" % npc_id)
	s.add_child(PropSprite.shadow(28.0))
	return s


func _process(delta: float) -> void:
	_t += delta * FPS
	PropSprite.set_frame(sprite, int(_t) % FRAMES)
	sprite.flip_h = Game.current.player.global_position.x < global_position.x


func use(g: Game) -> void:
	var c: Campaign = Session.campaign
	var topic: Dictionary = Dialogue.pick(npc_id, c, c.said_of(npc_id))
	talked += 1
	g.hud.show_dialogue(topic["lines"], func() -> void:
		c.mark_said(npc_id, int(topic["index"]))
		var service: String = Dialogue.apply(topic, c)
		c.notify("talk", npc_id)
		if service != "":
			g.ui.open_service(service)
		g.mark_dirty())
