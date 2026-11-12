class_name CreatureTag
extends Node2D
## Words and bars over a wild creature, on the overlay so they stay crisp: a life bar once it is hurt (with a notch
## where it can be befriended), its name and level when you point at it, a star if it is shiny, and "Hold F" once it
## is dazed and you stand close enough. Name and level also show for any creature in a fight with you, and the
## tag is on the overlay, so it reads above tree canopies. Starters in the opening meeting show their kind, element and role.

const BAR := Vector2(30, 3)
const ABOVE: float = 8.0
const PROMPT_GAP: float = 12.0
const NAME_W: float = 140.0

static var hovered: Creature

var c: Creature


static func attach(creature: Creature) -> CreatureTag:
	var t := CreatureTag.new()
	t.c = creature
	Overlay.follower(creature).add_child(t)
	return t


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(c) or c.fainted_now:
		return
	var top: float = -c.view.body_height() - ABOVE
	if c.side == StarterMeeting.SIDE:
		_meet_label(top)
		return
	var hurt: bool = c.rec.life_frac() < 0.999
	if hurt or hovered == c:
		_bar(Vector2(-BAR.x / 2.0, top))
	var fighting: bool = c.brain is WildBrain and (c.brain as WildBrain).awake
	if hovered == c or c.rec.shiny or fighting:
		var label: String = "%s  Lv %d" % [c.rec.display_name(), c.rec.level]
		var col: Color = Pal.c("gold") if c.rec.shiny else UiDraw.TEXT
		UiDraw.text(self, Vector2(-NAME_W / 2.0, top - 4.0), label, col, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, NAME_W)
	if c.dazed and _trainer_near():
		UiDraw.text(self, Vector2(-NAME_W / 2.0, top - 4.0 - PROMPT_GAP), "Press F to befriend", Pal.c("rose"), UiDraw.SMALL,
			HORIZONTAL_ALIGNMENT_CENTER, NAME_W)


## A starter in the meeting: its kind, element and role, brighter when you point at it.
func _meet_label(top: float) -> void:
	var d: Dictionary = c.rec.data()
	var col: Color = Pal.c("gold") if hovered == c else UiDraw.TEXT
	UiDraw.text(self, Vector2(-NAME_W / 2.0, top - 10.0), String(d["name"]), col, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, NAME_W)
	var sub: String = "%s  -  %s" % [TamerData.element(c.element_id())["name"], d["role"]]
	UiDraw.text(self, Vector2(-NAME_W / 2.0, top + 1.0), sub, TamerData.color(c.element_id(), "light"), UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_CENTER, NAME_W)


func _bar(at: Vector2) -> void:
	draw_rect(Rect2(at - Vector2.ONE, BAR + Vector2.ONE * 2.0), UiDraw.INK)
	draw_rect(Rect2(at, Vector2(BAR.x * c.rec.life_frac(), BAR.y)), TamerData.color(c.element_id(), "core"))
	var notch: float = BAR.x * float(c.rec.data()["befriend_at"])
	draw_rect(Rect2(at + Vector2(notch, -1), Vector2(1, BAR.y + 2)), Pal.c("rose"))


func _trainer_near() -> bool:
	var tr: Trainer = TamerGame.current.trainer
	return tr.global_position.distance_to(c.global_position) < float(TamerData.rule("befriend.range")) * 1.6
