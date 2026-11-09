class_name WardenCaptain
extends SpeciesEnemy
## The Warden Captain: the first mini-boss, an elite Warden who leads the others.
##
## Unlike a Warden he fights: he walks the player down and picks one of his attacks (child
## CaptainAttack nodes, tried in scene order): a rod sweep up close, a shockwave slam with a gap,
## summoning toads (and in phase 2 a Zephoot), and in phase 2 the chip pulse. Every attack is
## telegraphed and has super armour while it winds up; afterwards he recovers for a moment
## (the punish window) and a hit can stagger him. At half health CaptainPhaseTwo starts:
## faster wind-ups and new moves. His death plays out in CaptainDefeat; the boss bar on the HUD
## shows his health once the fight starts. If the player falls, the fight starts over
## (`_on_returned_to_spawn`): full health, phase 1, the bar hidden.
##
## States:
##   WAITING    -> stands (hasn't noticed the player, or enemies are paused)
##   CHASING    -> walks toward the player (along the path around obstacles) until close enough to attack
##   ATTACKING  -> an attack in progress (a hit never interrupts it; super armour while winding up)
##   RECOVERING -> just attacked: the punish window
##   STAGGERED  -> flinching from a hit
##   DYING      -> CaptainDefeat plays out

signal fight_started

enum State { WAITING, CHASING, ATTACKING, RECOVERING, STAGGERED, DYING }

@export_group("Fighting")
@export var walk_speed: float = 24.0
## He stops walking once the player is this close, in pixels.
@export var stop_distance: float = 22.0

@export_group("Getting hit")
## Seconds a hit staggers him (only outside his attacks), and how long before he can be staggered again.
@export var stagger_time: float = 0.35
@export var stagger_cooldown: float = 2.0
## Share of a big knockback (e.g. Flame Uppercut) that moves him: he's heavy.
@export var knockback_share: float = 0.35

var _attack: CaptainAttack = null
var _attacks: Array[CaptainAttack] = []
var _seconds_until_staggerable: float = 0.0
var _has_started_fight: bool = false

@onready var phase_two: CaptainPhaseTwo = $PhaseTwo
@onready var defeat: CaptainDefeat = $Defeat


func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is CaptainAttack:
			_attacks.append(child)
	_timer.enter(State.WAITING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	_seconds_until_staggerable = maxf(0.0, _seconds_until_staggerable - delta)
	var is_alert := _is_alert()
	if is_alert and not _has_started_fight and not _is_dying:
		_start_fight()
	var can_act := _can_act(is_alert)
	if can_act and not _is_dying:
		_count_down_attacks(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.WAITING, State.CHASING:
			_chase_or_attack(can_act)
		State.ATTACKING:
			_continue_attack()
		State.RECOVERING, State.STAGGERED, State.DYING:
			_slide(delta)
	move_and_slide()


## Throws him a little (e.g. Flame Uppercut): he's heavy, and super armour holds.
func knock_back(push_velocity: Vector2) -> void:
	if not _has_super_armour() and not _is_dying:
		velocity = push_velocity * knockback_share


# --- States ---------------------------------------------------------------

func _start_fight() -> void:
	_has_started_fight = true
	BossHealthBar.show_boss(self, display_name, health)
	fight_started.emit()


## Phase-2 moves only start counting down once phase 2 has begun.
func _count_down_attacks(delta: float) -> void:
	for attack in _attacks:
		if phase_two.is_active or not attack.phase_two_only:
			attack.count_down(delta)


func _chase_or_attack(can_act: bool) -> void:
	var player := PlayerFinder.find(self)
	if not can_act or player == null:
		_stand()
		return
	var distance := global_position.distance_to(player.global_position)
	for attack in _attacks:
		if attack.is_ready(phase_two.is_active, distance):
			_start_attack(attack)
			return
	if distance <= stop_distance:
		_stand()
		return
	velocity = path_mover.direction_toward(player.global_position) * walk_speed * phase_two.current_speed_scale()
	sprite.show_animation("walk")
	_timer.state = State.CHASING


func _stand() -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("idle")
	_timer.state = State.WAITING


func _start_attack(attack: CaptainAttack) -> void:
	_attack = attack
	velocity = Vector2.ZERO
	var wind_up_scale := phase_two.current_wind_up_scale()
	attack.start(wind_up_scale)
	sprite.replay_animation(attack.animation)
	# The pose keeps time with the faster phase-2 wind-up.
	sprite.speed_scale = 1.0 / wind_up_scale
	_timer.enter(State.ATTACKING, attack.duration())


func _continue_attack() -> void:
	velocity = Vector2.ZERO
	_attack.update(_timer.elapsed)
	if not _timer.is_over():
		return
	var recovery := _attack.recovery_time * phase_two.current_recovery_scale()
	sprite.replay_animation(_attack.recovery_animation)
	_end_attack()
	_timer.enter(State.RECOVERING, recovery)


func _end_attack() -> void:
	sprite.speed_scale = 1.0
	if _attack != null:
		_attack.finish()
	_attack = null


func _slide(delta: float) -> void:
	_slow_down_by(knockback_friction, delta)
	if _timer.state != State.DYING and _timer.is_over():
		_timer.enter(State.WAITING, 0.0)


## Debug (enemies passive): an attack in progress is called off and he just stands.
func _stop_acting() -> void:
	if _timer.state == State.ATTACKING:
		_end_attack()
		_stand()


# --- Reactions ------------------------------------------------------------

func _has_super_armour() -> bool:
	return _timer.state == State.ATTACKING and _attack != null and _attack.is_winding_up()


## A hit never interrupts an attack. Otherwise it can stagger him, but not again straight
## away (no stun-lock).
func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state == State.ATTACKING or _seconds_until_staggerable > 0.0:
		return
	_seconds_until_staggerable = stagger_cooldown
	_knock_back_from(source_position)
	sprite.replay_animation("stagger")
	var still_recovering_for := _timer.seconds_left() if _timer.state == State.RECOVERING else 0.0
	_timer.enter(State.STAGGERED, maxf(stagger_time, still_recovering_for))


func _on_returned_to_spawn() -> void:
	_end_attack()
	_has_started_fight = false
	phase_two.reset()
	for attack in _attacks:
		attack.start_over()
	BossHealthBar.hide_boss(self)


func _die() -> void:
	_end_attack()
	velocity = Vector2.ZERO
	_timer.enter(State.DYING, 0.0)
	defeat.play()
