class_name HelpPanel
extends GamePanel
## Help (H, or from the Esc menu): every key and every system in a few words, in two columns. The game pauses
## while it is open.

const COL_GAP: float = 16.0
const ROW: float = 13.0
const KEY_W: float = 64.0
const KEYS: Array = [
	["Left click", "walk, Wickbolt an enemy, use a thing"], ["Hold Shift", "stand still and cast"],
	["Right click", "Flare (RMB slot)"], ["Q W E R", "your other skills"], ["Space", "Wickstep (dash)"],
	["1", "drink a tonic"], ["F", "talk, read, continue"], ["Alt", "show item names"],
	["I", "inventory"], ["C", "character"], ["K", "skill trees"], ["P", "passives (from level 2)"],
	["J", "quests"], ["L", "loot filter"], ["M / Tab", "zone map"], ["H", "this help"], ["Esc", "close, or the menu"],
]
const SYSTEMS: Array = [
	["Light", "Your lantern's Light is your radius. Enemies outside it are Shrouded: they take less and hit harder. Hits dim it; kills feed it."],
	["Oil", "Skills cost Oil. It refills slowly. Out of Oil? Drink a tonic (1)."],
	["Skills", "Each skill levels as you use it. Specialise up to five (K) and spend their points on real changes."],
	["Passives", "From level 2, one point per level (P). A mastery opens a second tree."],
	["Waylamps", "Relight them (hold your ground while they catch). A lit lamp refills tonics and lets you travel."],
	["Loot", "Rarer items show a coloured name. Hover for the tooltip and a comparison with what you wear."],
]


func _content() -> void:
	var col_w: float = (size.x - SIDE * 2.0 - COL_GAP) / 2.0
	var y: float = CONTENT_Y + 6.0
	UiDraw.text(self, Vector2(SIDE + 4.0, y + 8.0), "Keys", UiDraw.GOLD, UiDraw.BODY)
	y += ROW + 4.0
	for k: Array in KEYS:
		UiDraw.text(self, Vector2(SIDE + 4.0, y + 8.0), String(k[0]), UiDraw.GOLD, UiDraw.SMALL)
		UiDraw.text(self, Vector2(SIDE + KEY_W, y + 8.0), String(k[1]), UiDraw.TEXT, UiDraw.SMALL)
		y += ROW
	var x: float = SIDE + col_w + COL_GAP
	y = CONTENT_Y + 6.0
	UiDraw.text(self, Vector2(x, y + 8.0), "How it works", UiDraw.GOLD, UiDraw.BODY)
	y += ROW + 4.0
	for s: Array in SYSTEMS:
		UiDraw.text(self, Vector2(x, y + 8.0), String(s[0]), UiDraw.GOLD, UiDraw.SMALL)
		y += ROW
		for line: String in UiDraw.wrap(self, String(s[1]), col_w - 4.0, UiDraw.SMALL):
			UiDraw.text(self, Vector2(x, y + 8.0), line, UiDraw.TEXT, UiDraw.SMALL)
			y += ROW - 1.0
		y += 4.0


func layout_rects() -> Array[Rect2]:
	var col_w: float = (size.x - SIDE * 2.0 - COL_GAP) / 2.0
	var widest: float = 0.0
	for k: Array in KEYS:                                       # each key's description must end inside its column
		widest = maxf(widest, KEY_W + UiDraw.text_width(self, String(k[1]), UiDraw.SMALL))
	return [Rect2(SIDE, CONTENT_Y, maxf(col_w, widest), ROW * (KEYS.size() + 1) + 10.0),
		Rect2(SIDE + col_w + COL_GAP, CONTENT_Y, col_w, _systems_height(col_w))]


func _systems_height(col_w: float) -> float:
	var h: float = ROW + 10.0
	for s: Array in SYSTEMS:
		h += ROW + 4.0 + (ROW - 1.0) * UiDraw.wrap(self, String(s[1]), col_w - 4.0, UiDraw.SMALL).size()
	return h


func toggle() -> void:
	super()
	get_tree().paused = visible
