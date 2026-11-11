class_name LoreObject
extends Interactable
## Optional reading: Teague's cairn, Brennick in glass, the order's rules, the road sign. Short, never required.

var note_id: String = ""
var read: bool = false


func _ready() -> void:
	note_id = String(prop.get("note", ""))
	if note_id != "":
		title = String(GameData.story["notes"][note_id]["title"])
	elif prop.has("sign"):
		title = "Signpost"
	super()


func use(g: Game) -> void:
	if note_id != "":
		var n: Dictionary = GameData.story["notes"][note_id]
		g.hud.show_note(String(n["title"]), n["lines"])
	elif prop.has("sign"):
		g.hud.caption(String(GameData.story["signs"][prop["sign"]]))
	if not read:
		read = true
		g.mark_dirty()
