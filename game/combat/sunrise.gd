class_name Sunrise
extends Node
## The Sunrise super (R, when the meter is full): the Lamplighter rises a little into the air, untouchable, the
## camera pulls back and the night warms towards dawn; a giant blazing lantern sun swells overhead, then rains
## fiery motes over the area for a few seconds (most of them seeking enemies), and finally flares and collapses in
## one big burst before the Lamplighter floats back down.

const FINALE_SHAKE: float = 6.0

enum Step { IDLE, RISE, FORM, RAIN, END }

var active: bool = false
var step: Step = Step.IDLE
var motes_fired: int = 0
var _kit: LamplighterKit
var _timer: float = 0.0
var _mote_timer: float = 0.0
var _mix: float = 0.0
var _ground: Vector3 = Vector3.ZERO
var _sun: SunFx


func setup(kit: LamplighterKit) -> void:
	name = "Sunrise"
	_kit = kit


func fire() -> bool:
	if active or not _kit.meter.is_full():
		return false
	_kit.meter.spend()
	active = true
	motes_fired = 0
	_ground = _kit.player.global_position
	_kit.health.invulnerable = true
	_kit.player.frozen = true
	_kit.heavy.release()
	_begin(Step.RISE, Tuning.number("combat", "super", "rise_seconds"))
	_kit.fx.kit.sfx.cue("super_start", _ground)
	return true


## The sun's centre (above where the super was called).
func sun_point() -> Vector3:
	return _ground + Vector3.UP * Tuning.number("combat", "super", "sun_height")


func _begin(next: Step, seconds: float) -> void:
	step = next
	_timer = seconds


func _process(delta: float) -> void:
	if not active:
		return
	_timer -= delta
	var mix_goal: float = 0.0 if step == Step.END else 1.0
	_mix = move_toward(_mix, mix_goal, delta / Tuning.number("combat", "super", "rise_seconds"))
	_kit.camera_rig.super_mix = _mix
	_kit.environment.set_sunrise(_mix)
	_move_player()
	match step:
		Step.RISE:
			if _timer <= 0.0:
				_form()
		Step.FORM:
			if _timer <= 0.0:
				_begin(Step.RAIN, Tuning.number("combat", "super", "rain_seconds"))
		Step.RAIN:
			_rain(delta)
			if _timer <= 0.0:
				_finale()
		Step.END:
			if _timer <= 0.0 and _mix == 0.0:
				_land()


func _move_player() -> void:
	var lift: float = Tuning.number("combat", "super", "rise") * (_mix if step != Step.END else minf(_mix, maxf(
		_timer, 0.0) / Tuning.number("combat", "super", "end_seconds")))
	_kit.player.global_position = _ground + Vector3.UP * lift


func _form() -> void:
	var seconds: float = Tuning.number("combat", "super", "form_seconds")
	_begin(Step.FORM, seconds)
	_sun = SunFx.new()
	_kit.fx.kit.place(_sun, sun_point())
	_sun.setup(_kit.fx.kit, _kit.fx.look("sun"), Tuning.number("combat", "super", "sun_size"))
	_sun.form(_kit.fx.kit, seconds)


func _rain(delta: float) -> void:
	_mote_timer -= delta
	while _mote_timer <= 0.0:
		_mote_timer += Tuning.number("combat", "super", "mote_every")
		var mote := SunMote.new()
		mote.launch(_kit, sun_point(), _mote_target(), motes_fired % 3 == 0)
		motes_fired += 1


## Where a mote falls: often on an enemy in the area, otherwise anywhere in it.
func _mote_target() -> Vector3:
	var area: float = Tuning.number("combat", "super", "area")
	var foes: Array[Enemy] = _kit.roster.within(_ground, area)
	if not foes.is_empty() and randf() < Tuning.number("combat", "super", "target_share"):
		return foes.pick_random().global_position
	var angle: float = randf() * TAU
	var spot: Vector3 = _ground + Vector3(cos(angle), 0.0, sin(angle)) * sqrt(randf()) * area
	return Vector3(spot.x, _kit.ground_at(spot), spot.z)


func _finale() -> void:
	_begin(Step.END, Tuning.number("combat", "super", "end_seconds"))
	_sun.collapse(_timer)
	var spec: Dictionary = _kit.fx.look("sun")
	for enemy: Enemy in _kit.roster.within(_ground, Tuning.number("combat", "super", "final_radius")):
		enemy.take_hit(Hit.new(Tuning.number("combat", "super", "final_damage"), "super", enemy.centre()))
	_kit.fx.impact_with(spec["final"], spec["final_mark"], _ground + Vector3.UP, _ground)
	_kit.fx.kit.sfx.cue("super_end", _ground)
	_kit.fx.kit.hit_feel.nudge(Tuning.number("combat", "camera", "kick") * FINALE_SHAKE, _timer)


func _land() -> void:
	active = false
	step = Step.IDLE
	_kit.player.global_position = _ground
	_kit.player.frozen = false
	_kit.health.invulnerable = false
