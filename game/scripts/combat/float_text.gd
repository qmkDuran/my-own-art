class_name FloatText
extends Label
## Damage numbers with weight: one number per target that sums the hits landing within MERGE seconds, sized by the
## hit's share of the target's life; it punches in big, settles, then floats up and fades. Thick outline and a drop
## shadow; crits are much bigger, gold and shake; hits on you are red. A target's next numbers stack above.

const RISE: float = 22.0
const TIME: float = 0.75
const MERGE: float = 0.15
const POP: float = 1.7
const SHADOW := Vector2(2, 2)
const SIZE_MIN: int = 14
const SIZE_MAX: int = 30
const CRIT_SIZE: int = 36
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
	var share: float = dmg / maxf(float(target.get("max_life")) if target.get("max_life") != null else dmg * 5.0, 1.0)
	var f: FloatText = _make(target.global_position + Vector2(0, -_lift(id, now)), c, _size_for(share, crit), crit)
	f.target_id = id
	f._born = now
	f.add(dmg, crit)
	_open[id] = f


static func _lift(id: int, now: float) -> float:
	var st: Array = _stack.get(id, [0, -10.0])
	var n: int = int(st[0]) + 1 if now - float(st[1]) < TIME * 0.6 else 0
	_stack[id] = [n, now]
	return HEAD + STACK * (n % STACK_MAX)


## Bigger numbers for bigger shares of the target's life; crits always huge.
static func _size_for(share: float, crit: bool) -> int:
	if crit:
		return CRIT_SIZE
	return int(lerpf(SIZE_MIN, SIZE_MAX, clampf(share * 3.0, 0.0, 1.0)))


static func _settings(size: int, col: Color) -> LabelSettings:
	var ls := UiDraw.label_settings(UiDraw.TITLE if size >= UiDraw.TITLE else UiDraw.BODY, col)
	ls.font_size = size
	ls.outline_size = 5 if size >= UiDraw.TITLE else 4
	ls.shadow_color = Color(0, 0, 0, 0.6)
	ls.shadow_offset = SHADOW
	ls.shadow_size = 1
	return ls


static func _make(at: Vector2, col: Color, size: int, crit: bool) -> FloatText:
	var f := FloatText.new()
	f.label_settings = _settings(size, col)
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.size = Vector2(WIDTH, size + 8)
	f.pivot_offset = Vector2(WIDTH / 2.0, (size + 8) / 2.0)
	f.position = at + Vector2(-WIDTH / 2.0, 0)
	f.scale = Vector2.ONE * POP
	Overlay.layer.add_child(f)
	var tw := f.create_tween()
	tw.set_parallel()
	tw.tween_property(f, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if crit:                                                # a short shake, then it floats
		for k: int in 4:
			tw.tween_property(f, "rotation", (0.12 if k % 2 == 0 else -0.12) * (1.0 - k * 0.25), 0.04).set_delay(0.04 * k)
		tw.tween_property(f, "rotation", 0.0, 0.04).set_delay(0.16)
	tw.tween_property(f, "position:y", f.position.y - RISE, TIME).set_ease(Tween.EASE_OUT)
	tw.tween_property(f, "modulate:a", 0.0, TIME * 0.4).set_delay(TIME * 0.6)
	tw.chain().tween_callback(f.queue_free)
	return f


func add(dmg: float, crit: bool) -> void:
	total += dmg
	if crit and not crit_seen:
		crit_seen = true
		label_settings = _settings(CRIT_SIZE, Pal.c("gold"))
	text = str(int(total))
