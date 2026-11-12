class_name CreatureTag
extends Node2D
## Words and bars over a creature, on the overlay so they stay crisp above tree canopies. A wild one on the route:
## its name and level when you point at it (gold and starred if shiny), and the red eye glint of an aggressive
## one (it will chase you). In battle,
## over both creatures: life and stagger bars (with the mark where a wild one is weakened enough to sync), name and
## level, the buff and debuff icons with their timers, and at its feet the status rings (StatusRings). A hidden foe shows nothing; "F: Sync Lens" once it can be
## synced.

const BAR := Vector2(30, 3)
const STAGGER_H: float = 2.0
const ABOVE: float = 8.0
const NAME_W: float = 140.0
const EFFECT: float = 16.0
const CHANNEL_BELOW: float = 8.0       ## the channel's name sits under its feet

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
	var top: float = -c.view.body_height() * c.size_k - ABOVE
	var battle: bool = TamerGame.current.battle.on
	if battle:
		StatusRings.draw_for(self, c)
		_bar(Vector2(-BAR.x / 2.0, top))
		EffectIcons.draw_row(self, Vector2(-BAR.x / 2.0, top - EFFECT - 18.0), c.effects, EFFECT, true)
	if c.channel_id != "":
		_channel(CHANNEL_BELOW)
	if c.side == Combatant.SIDE_TEAM:
		return
	if c.brain is RouteBrain and (c.brain as RouteBrain).temperament == "aggressive":
		_glint(top)
	if battle or hovered == c or c.rec.shiny:
		var label: String = "%s%s  Lv %d" % ["* " if c.rec.shiny else "", c.rec.display_name(), c.rec.level]
		var col: Color = Pal.c("gold") if c.rec.shiny else UiDraw.TEXT
		UiDraw.text(self, Vector2(-NAME_W / 2.0, top - 4.0), label, col, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, NAME_W)
	if battle and SyncLens.syncable(c):
		UiDraw.text(self, Vector2(-NAME_W / 2.0, top - EFFECT - 24.0), "F: Sync Lens", Pal.c("rose"), UiDraw.SMALL,
			HORIZONTAL_ALIGNMENT_CENTER, NAME_W)


## A status move being channelled: its name and strength under the filling circle (on a foe: punish it now).
func _channel(y: float) -> void:
	var s: float = c.channel_strength()
	UiDraw.text(self, Vector2(-NAME_W / 2.0, y + c.hit_radius() * 0.5), "%s %d%%" % [TamerData.move(c.channel_id)["name"], roundi(s * 100.0)],
		Pal.c("sun") if s >= 1.0 else Pal.c("glint"), UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, NAME_W)


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

