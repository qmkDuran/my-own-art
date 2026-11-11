class_name QuestPanel
extends GamePanel
## The quest log: each quest with its steps (done ones dimmed, the current one gold, later ones unknown yet).

const ROW: float = 13.0
const X: float = 14.0


func _content() -> void:
	var c: Campaign = Session.campaign
	var y: float = CONTENT_Y + 18.0
	var ids: Array[String] = c.active()
	for id: String in c.quests:
		if c.is_done(id):
			ids.append(id)
	if ids.is_empty():
		UiDraw.text(self, Vector2(X, y), "No quests yet.", UiDraw.DIM)
	for id: String in ids:
		y = _quest(id, y) + 6.0


func _quest(id: String, y: float) -> float:
	var c: Campaign = Session.campaign
	var q: Dictionary = GameData.quests[id]
	var head: String = String(q["title"]) + ("   (done)" if c.is_done(id) else "")
	UiDraw.text(self, Vector2(X, y), head, UiDraw.GOLD if bool(q["main"]) else Color("9fc4ff"))
	y += ROW
	var cur: int = c.step_index(id)
	for i: int in (q["steps"] as Array).size():
		if not c.is_done(id) and i > cur:
			UiDraw.text(self, Vector2(X + 10.0, y), "...", UiDraw.LOCKED)
			return y + ROW
		var col: Color = UiDraw.TEXT if i == cur else UiDraw.DIM
		UiDraw.text(self, Vector2(X + 10.0, y), ("> " if i == cur else "- ") + String(q["steps"][i]["text"]), col)
		y += ROW
	return y
