class_name PlayerAnimator
extends RefCounted
## Plays the Lamplighter's rig-drawn animations (data: sprites.json "lamplighter", built by art/build_lamplighter.py):
## eight facings, two layers (the man, and the lantern so it can be thrown), per-frame weights so a strike frame is
## held, and events on frames: an attack's "hit" fires when its strike frame shows, not on a timer. Loops (idle,
## walk, channel) run at their fps; one-shots are stretched to the time they are given (attack and cast speed).
## Every frame also says where the lantern hangs and how bright it is, so the light can swing with it.

signal event(name: String)              ## a frame event other than "hit" (e.g. "step" on a footfall)

var body: Sprite2D
var lantern: Sprite2D
var anim: String = "idle"
var dir: int = 0
var speed: float = 1.0                 ## loops only: e.g. the run follows the move speed
var _m: Dictionary
var _t: float = 0.0
var _dur: float = 0.0
var _frame: int = 0
var _on_hit: Callable = Callable()


func setup(owner: Node2D) -> void:
	_m = GameData.sprites["actors"]["lamplighter"]
	body = _layer(owner, "res://art/actors/lamplighter")
	lantern = _layer(owner, "res://art/actors/lamplighter_lantern")


func _layer(owner: Node2D, path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = PropSprite.tex(path + ".png")
	s.hframes = int(_m["cols"])
	s.vframes = s.texture.get_height() / int(_m["frame"][1])
	s.offset = Vector2(float(_m["frame"][0]) / 2.0 - float(_m["anchor"][0]), float(_m["frame"][1]) / 2.0 - float(_m["anchor"][1]))
	owner.add_child(s)
	PropSprite.add_glow(s, path + "_glow.png")
	return s


## Faces along v (screen space): one of eight directions, south first, clockwise through east.
func face(v: Vector2) -> void:
	if v.length() < 0.01:
		return
	var deg: float = fposmod(rad_to_deg(atan2(v.x, v.y)), 360.0)
	dir = int(round(deg / 45.0)) % 8


## A one-shot stretched to `seconds` (0: its own fps). `on_hit` runs on the frame that carries its "hit" event.
func play(name: String, seconds: float = 0.0, on_hit: Callable = Callable()) -> void:
	_fire()                                             # an attack is never lost to the next one
	anim = name
	_t = 0.0
	_dur = seconds
	_on_hit = on_hit


## A loop: starts it if another animation is showing, otherwise keeps its phase.
func loop(name: String) -> void:
	if anim != name:
		play(name)


func playing_one_shot() -> bool:
	return not bool(_spec()["loop"]) and _t < _length()


func tick(delta: float) -> void:
	var sp: Dictionary = _spec()
	_t += delta * (speed if bool(sp["loop"]) else 1.0)
	var w: Array = sp["weights"]
	var unit: float = _length() / _total(w)
	var pos: float = _t / unit
	if bool(sp["loop"]):
		pos = fposmod(pos, _total(w))
	var was: int = _frame
	_frame = _frame_at(w, pos)
	if sp["events"].has("hit") and _frame >= int(sp["events"]["hit"]):
		_fire()
	if _frame != was:
		_frame_events(sp)
	var f: int = (int(sp["row"]) + dir) * int(_m["cols"]) + _frame
	for s: Sprite2D in [body, lantern]:
		PropSprite.set_frame(s, f)


## Where the lantern hangs now (from his feet; the light and every bolt start there), and its brightness 0..1.
func lantern_offset() -> Vector2:
	var a: Array = _anchor()
	return Vector2(float(a[0]), float(a[1]))


func pane() -> float:
	return float(_anchor()[2])



func _anchor() -> Array:
	return _spec()["anchors"][dir][_frame]


func _frame_events(sp: Dictionary) -> void:
	for name: String in sp["events"]:
		if name != "hit" and (sp["events"][name] as Array).has(_frame):
			event.emit(name)


func _fire() -> void:
	if _on_hit.is_valid():
		var cb: Callable = _on_hit
		_on_hit = Callable()
		cb.call()


func _spec() -> Dictionary:
	return _m["anims"][anim]


func _length() -> float:
	var sp: Dictionary = _spec()
	return _dur if _dur > 0.0 and not bool(sp["loop"]) else _total(sp["weights"]) / float(sp["fps"])


static func _total(w: Array) -> float:
	var t: float = 0.0
	for x: Variant in w:
		t += float(x)
	return t


static func _frame_at(w: Array, pos: float) -> int:
	var acc: float = 0.0
	for k: int in w.size():
		acc += float(w[k])
		if pos < acc:
			return k
	return w.size() - 1
