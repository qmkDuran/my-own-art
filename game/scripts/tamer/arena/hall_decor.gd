class_name HallDecor
extends Node2D
## What the Gate Hall shows: an arch over each gate with a sign naming its arena and listing what to try, the lever
## (with the current difficulty), the opponent switch, the team station, the lens stand and the route door, each
## labelled with "F" when you stand next to it.

const SIGN_W: float = 176.0
const LINE: float = 10.0
const SIGN_Z: int = -5                  ## above the floor, under everyone walking past

var hall: GateHall


func setup(h: GateHall) -> HallDecor:
	hall = h
	z_index = SIGN_Z
	z_as_relative = false
	return self


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for i: int in hall.data["gates"].size():
		_gate(i)
	_station(hall.spot("lever"), "Difficulty: %s" % hall.tier_id().capitalize(), Pal.c("amber"))
	_station(hall.spot("switch"), "Opponent: %s" % ("Trainer 3v3" if hall.trainer_battle else "Wild 1v1"), Pal.c("rose"))
	_station(hall.spot("station"), "Team station", Pal.c("leaf_lt"))
	_station(hall.spot("lens"), TamerData.rule("sync.lenses." + hall.g.lens.tier + ".name"), Pal.c("glint"))
	var door: Vector2 = hall.door_spot()
	draw_rect(Rect2(door - Vector2(14, 30), Vector2(28, 40)), Pal.c("earth_dk"))
	UiDraw.text(self, door + Vector2(-110, -36), "To the route", UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, 120.0)


func _gate(i: int) -> void:
	var id: String = String(hall.data["gates"][i][0])
	var a: Dictionary = TamerData.arenas["arenas"][id]
	var at: Vector2 = hall.gate_spot(i)
	draw_rect(Rect2(at - Vector2(34, 44), Vector2(68, 50)), Pal.c("void"))
	draw_rect(Rect2(at - Vector2(38, 50), Vector2(76, 8)), Pal.c("stone_lt"))
	draw_rect(Rect2(at - Vector2(38, 50), Vector2(6, 56)), Pal.c("stone_lt"))
	draw_rect(Rect2(at + Vector2(32, -50), Vector2(6, 56)), Pal.c("stone_lt"))
	var sign_at: Vector2 = at + Vector2(-SIGN_W * 0.5, 28)
	var lines: PackedStringArray = []
	for item: String in a["checklist"]:
		var wrapped: PackedStringArray = UiDraw.wrap(self, item, SIGN_W - 14.0, UiDraw.SMALL)
		for k: int in wrapped.size():
			lines.append(("- " if k == 0 else "  ") + wrapped[k])
	var box := Rect2(sign_at, Vector2(SIGN_W, 18 + lines.size() * LINE))
	draw_rect(box, Color(Pal.c("ink"), 0.85))
	draw_rect(box, Pal.c("earth_lt"), false, 1.0)
	UiDraw.text(self, sign_at + Vector2(0, 11), String(a["name"]).to_upper(), UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, SIGN_W)
	for k: int in lines.size():
		UiDraw.text(self, sign_at + Vector2(4, 22 + k * LINE), lines[k], UiDraw.TEXT, UiDraw.SMALL)


func _station(at: Vector2, label: String, col: Color) -> void:
	draw_rect(Rect2(at - Vector2(10, 22), Vector2(20, 22)), Pal.c("stone"))
	draw_rect(Rect2(at - Vector2(8, 26), Vector2(16, 6)), col)
	draw_rect(Rect2(at - Vector2(10, 22), Vector2(20, 22)), Pal.c("void"), false, 1.0)
	var near: bool = hall.g.trainer.global_position.distance_to(at) < GateHall.USE_RANGE
	UiDraw.text(self, at + Vector2(-70, -32), ("[F] " if near else "") + label, Pal.c("gold") if near else UiDraw.TEXT,
		UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, 140.0)
