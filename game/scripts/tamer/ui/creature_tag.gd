class_name CreatureTag
extends Node2D
## Words and bars over a creature, on the overlay so they stay crisp above tree canopies. A wild one on the route:
## its name and level when you point at it (gold and starred if shiny), and the red eye glint of an aggressive
## one (it will chase you). In battle,
## over both creatures: life and stagger bars (with the mark where a wild one is weakened enough to sync), name and
## level, and the buff and debuff icons with their timers. A hidden foe shows nothing; "Hold F" once it can be synced.

const BAR := Vector2(30, 3)
const STAGGER_H: float = 2.0
const ABOVE: float = 8.0
const NAME_W: float = 140.0
const EFFECT: float = 10.0

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
	if not is_instance_valid(c) or c.fainted_now or (c.side != Combatant.SIDE_TEAM and c.hidden()):
		return
	var top: float = -c.view.body_height() - ABOVE
	var battle: bool = TamerGame.current.battle.on
	if battle:
		_bar(Vector2(-BAR.x / 2.0, top))
		EffectIcons.draw_row(self, Vector2(-BAR.x / 2.0, top - 26.0), c.effects, EFFECT, false)
	if c.side == Combatant.SIDE_TEAM:
		return
	if c.brain is RouteBrain and (c.brain as RouteBrain).temperament == "aggressive":
		_glint(top)
	if battle or hovered == c or c.rec.shiny:
		var label: String = "%s%s  Lv %d" % ["* " if c.rec.shiny else "", c.rec.display_name(), c.rec.level]
		var col: Color = Pal.c("gold") if c.rec.shiny else UiDraw.TEXT
		UiDraw.text(self, Vector2(-NAME_W / 2.0, top - 4.0), label, col, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, NAME_W)
	if battle and SyncLens.syncable(c):
		UiDraw.text(self, Vector2(-NAME_W / 2.0, top - 30.0), "Hold F: Sync Lens", Pal.c("rose"), UiDraw.SMALL,
			HORIZONTAL_ALIGNMENT_CENTER, NAME_W)


## Two red eyes that flicker: this one chases.
func _glint(top: float) -> void:
	var eye: Vector2 = Vector2(c.facing.x * c.hit_radius() * 0.5, top + ABOVE + c.view.body_height() * 0.3)
	var a: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.012)
	for k: int in 2:
		draw_circle(eye + Vector2((k - 0.5) * 4.0, 0), 1.6, Pal.c("blood", a))
		draw_circle(eye + Vector2((k - 0.5) * 4.0, 0), 3.5, Pal.c("rose", a * 0.3))


func _bar(at: Vector2) -> void:
	draw_rect(Rect2(at - Vector2.ONE, BAR + Vector2.ONE * 2.0), UiDraw.INK)
	draw_rect(Rect2(at, Vector2(BAR.x * c.rec.life_frac(), BAR.y)), TamerData.color(c.element_id(), "core"))
	if c.catchable and c.side == Combatant.SIDE_WILD:
		var notch: float = BAR.x * float(c.rec.data()["sync_at"])
		draw_rect(Rect2(at + Vector2(notch, -1), Vector2(1, BAR.y + 2)), Pal.c("rose"))
	var st := at + Vector2(0, BAR.y + 2.0)                 # the stagger bar, gold, under the life bar
	draw_rect(Rect2(st - Vector2.ONE, Vector2(BAR.x + 2.0, STAGGER_H + 2.0)), UiDraw.INK)
	var fill: float = 1.0 if c.stagger.is_staggered() else c.stagger.frac()
	var col: Color = Pal.c("sun") if c.stagger.is_staggered() else Pal.c("gold")
	draw_rect(Rect2(st, Vector2(BAR.x * fill, STAGGER_H)), col)

