class_name ZoneExit
extends Interactable
## The way to another zone (a road gate, a cave mouth, Tallow's gate). Using it travels there; arriving from that
## zone, you stand just in front of it.

const ARRIVE_GAP: float = 40.0

var to: String


func _ready() -> void:
	to = String(prop["to"])
	title = "To " + String(GameData.zone(to)["name"])
	super()


func make_sprite() -> Sprite2D:
	var art: String = String(prop.get("sprite", ""))
	return PropSprite.make(art) if art != "" and GameData.props.has(art) else null


func pick_rect() -> Rect2:
	if sprite != null:
		return super()
	return Rect2(global_position - Vector2(36, 70), Vector2(72, 80))


## Some ways out open only later in the story ("locked_until", a dialogue condition); until then they say why.
func use(g: Game) -> void:
	if prop.has("locked_until") and not Dialogue.holds(prop["locked_until"], Session.campaign):
		g.hud.caption(String(prop.get("locked_text", "Not yet.")))
		return
	g.ui.fade_through(func() -> void: Session.travel(g, to))


func stand_point() -> Vector2:
	return Game.current.layout.free_spot_near(global_position + Vector2(0, ARRIVE_GAP), Game.current.player.radius)
