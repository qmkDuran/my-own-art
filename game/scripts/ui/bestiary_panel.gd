class_name BestiaryPanel
extends GamePanel
## Lio's bestiary: every creature you have killed, how many, and what the Archive knows of it.

const ROW: float = 13.0
const X: float = 14.0
const WRAP: float = 360.0


func _content() -> void:
	var y: float = CONTENT_Y + 16.0
	var kills: Dictionary = Session.campaign.kills
	if kills.is_empty():
		UiDraw.text(self, Vector2(X, y), "Nothing yet. Go and meet the Dusk.", UiDraw.DIM)
	for kind: String in kills:
		var d: Dictionary = GameData.enemy(kind)
		UiDraw.text(self, Vector2(X, y), "%s   x%d" % [d["name"], int(kills[kind])], UiDraw.GOLD)
		y += ROW
		for line: String in UiDraw.wrap(self, String(d.get("lore", "")), WRAP):
			UiDraw.text(self, Vector2(X + 8.0, y), line, UiDraw.DIM)
			y += ROW
		y += 4.0
