class_name FloatText
extends Label
## Damage numbers: one number per target that sums the hits landing within MERGE seconds (so a bolt, a burst and
## a burn on the same enemy read as one growing number), then rises and fades; a target's next numbers stack
## above the last ones instead of on top. Crits are bigger and gold; hits on you are red.

const RISE: float = 22.0
const TIME: float = 0.75
const MERGE: float = 0.15
const POP: float = 1.3
const WIDTH: float = 120.0
const HEAD: float = 46.0
const STACK: float = 11.0
const STACK_MAX: int = 3

static var enabled: bool = true
static var _open: Dictionary = {}          ## target id -> FloatText still merging
static var _stack: Dictionary = {}         ## target id -> [count, time of last]

var total: float = 0.0
var target_id: int
var crit_seen: bool = false
var _born: float


## A hit on `target`: merge into its open number or start a new one stacked above the previous.
static func hit(target: Node2D, dmg: float, crit: bool, dot: bool, col: Color = Color.TRANSPARENT) -> void:
	if not enabled or Overlay.layer == null or not is_instance_valid(target):
		return
	var id: int = target.get_instance_id()
	var now: float = Time.get_ticks_msec() / 1000.0
	var held: Variant = _open.get(id)
	if is_instance_valid(held) and now - (held as FloatText)._born < MERGE:
		(held as FloatText).add(dmg, crit)
		return
	var c: Color = col if col.a > 0.0 else (Pal.c("gold") if crit else (Pal.c("flame") if dot else Pal.c("amber")))
	var f: FloatText = _make(target.global_position + Vector2(0, -_lift(id, now)), c, crit)
	f.target_id = id
	f._born = now
	f.add(dmg, crit)
	_open[id] = f


static func _lift(id: int, now: float) -> float:
	var st: Array = _stack.get(id, [0, -10.0])
	var n: int = int(st[0]) + 1 if now - float(st[1]) < TIME * 0.6 else 0
	_stack[id] = [n, now]
	return HEAD + STACK * (n % STACK_MAX)


static func _make(at: Vector2, col: Color, big: bool) -> FloatText:
	var f := FloatText.new()
	f.label_settings = UiDraw.label_settings(UiDraw.TITLE if big else UiDraw.BODY, col)
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.size = Vector2(WIDTH, 24)
	f.pivot_offset = Vector2(WIDTH / 2.0, 12)
	f.position = at + Vector2(-WIDTH / 2.0, 0)
	f.scale = Vector2.ONE * POP
	Overlay.layer.add_child(f)
	var tw := f.create_tween()
	tw.set_parallel()
	tw.tween_property(f, "scale", Vector2.ONE, 0.12)
	tw.tween_property(f, "position:y", f.position.y - RISE, TIME).set_ease(Tween.EASE_OUT)
	tw.tween_property(f, "modulate:a", 0.0, TIME * 0.4).set_delay(TIME * 0.6)
	tw.chain().tween_callback(f.queue_free)
	return f


func add(dmg: float, crit: bool) -> void:
	total += dmg
	if crit and not crit_seen:
		crit_seen = true
		label_settings = UiDraw.label_settings(UiDraw.TITLE, Pal.c("gold"))
	text = str(int(total))
