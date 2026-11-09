class_name Shalendrill
extends SpeciesEnemy
## The Shalendrill: Act 1's mid-act boss, a hulking shale-backed mandrill Glimra the AI God
## has bound with a chip (the cyan in its eyes, muzzle and stone is the stolen light).
##
## It knuckle-walks the player down and picks one of its attacks (child ShalendrillAttack
## nodes, tried in scene order): the knuckle barrage up close (blocked on Ash Guard, it
## reels), the quake slam (a gapless ring to dodge-leap, then its fists are stuck), the leap
## onto a player who keeps away, and in phase 2 the Rockfall and a call for Fizzbugs. Each is
## telegraphed with super armour while it winds up, then a punish window (a hit can make it
## flinch, at most every few seconds). At half health it roars (ShalendrillRoar) and
## CaptainPhaseTwo makes it faster. ShalendrillDefeat plays its death. The boss bar shows
## once the fight starts; if the player falls the fight starts over (`_on_returned_to_spawn`).
##
## States:
##   WAITING    -> stands (hasn't noticed the player, or enemies are paused)
##   CHASING    -> walks toward the player until close enough to attack
##   ATTACKING  -> an attack in progress (a hit never interrupts it)
##   RECOVERING -> just attacked: the punish window
##   STAGGERED  -> flinching from a hit
##   ROARING    -> the phase-change roar (super armour)
##   DYING      -> ShalendrillDefeat plays out

signal fight_started

enum State { WAITING, CHASING, ATTACKING, RECOVERING, STAGGERED, ROARING, DYING }

@export_group("Fighting")
@export var walk_speed: float = 22.0
## It stops walking once the player is this close, in pixels.
@export var stop_distance: float = 24.0

@export_group("Getting hit")
## Seconds a hit makes it flinch (only outside its attacks), and how long before it can flinch again.
@export var stagger_time: float = 0.3
@export var stagger_cooldown: float = 2.5
## Share of a big knockback (e.g. Flame Uppercut, Counter Punch) that moves it: it's huge.
@export var knockback_share: float = 0.25

## Any CaptainAttack works (e.g. CaptainSummon); ShalendrillAttacks can also move it and
## change the punish window that follows.
var _attack: CaptainAttack = null
var _attacks: Array[CaptainAttack] = []
var _seconds_until_staggerable: float = 0.0
var _has_started_fight: bool = false

@onready var phase_two: CaptainPhaseTwo = $PhaseTwo
@onready var roar: ShalendrillRoar = $Roar
@onready var defeat: ShalendrillDefeat = $Defeat


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
			if _should_roar():
				_start_roar()
			else:
				_chase_or_attack(can_act)
		State.ATTACKING:
			_continue_attack()
		State.RECOVERING, State.STAGGERED, State.ROARING, State.DYING:
			_slide(delta)
	move_and_slide()


## Throws it a little (e.g. Flame Uppercut): it's huge, and super armour holds.
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


func _should_roar() -> bool:
	return phase_two.is_active and not roar.has_roared and not _is_dying


func _start_roar() -> void:
	velocity = Vector2.ZERO
	sprite.replay_animation("roar")
	roar.play()
	_timer.enter(State.ROARING, roar.duration)


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
	if attack is ShalendrillAttack:
		(attack as ShalendrillAttack).is_phase_two = phase_two.is_active
	attack.start(wind_up_scale)
	sprite.replay_animation(attack.animation)
	# The pose keeps time with the faster phase-2 wind-up.
	sprite.speed_scale = 1.0 / wind_up_scale
	_timer.enter(State.ATTACKING, attack.duration())


func _continue_attack() -> void:
	var own_attack := _attack as ShalendrillAttack
	velocity = own_attack.movement_velocity(_timer.elapsed) if own_attack != null else Vector2.ZERO
	_attack.update(_timer.elapsed)
	if not _timer.is_over():
		return
	var recovery := own_attack.recovery_seconds() if own_attack != null else _attack.recovery_time
	var recovery_pose := own_attack.recovery_pose() if own_attack != null else _attack.recovery_animation
	recovery *= phase_two.current_recovery_scale()
	sprite.speed_scale = 1.0
	sprite.replay_animation(recovery_pose)
	_end_attack()
	velocity = Vector2.ZERO
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


## Debug (enemies passive): an attack in progress is called off and it just stands.
func _stop_acting() -> void:
	if _timer.state == State.ATTACKING:
		_end_attack()
		_stand()


# --- Reactions ------------------------------------------------------------

func _has_super_armour() -> bool:
	if _timer.state == State.ROARING:
		return true
	return _timer.state == State.ATTACKING and _attack != null and _attack.is_winding_up()


## A hit never interrupts an attack or the roar. Otherwise it can flinch, but not again
## straight away (no stun-lock); a flinch never cuts a punish window short.
func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state in [State.ATTACKING, State.ROARING] or _seconds_until_staggerable > 0.0:
		return
	_seconds_until_staggerable = stagger_cooldown
	_knock_back_from(source_position)
	var still_recovering_for := _timer.seconds_left() if _timer.state == State.RECOVERING else 0.0
	if still_recovering_for <= stagger_time:
		sprite.replay_animation("hurt")
	_timer.enter(State.STAGGERED, maxf(stagger_time, still_recovering_for))


func _on_returned_to_spawn() -> void:
	_end_attack()
	_has_started_fight = false
	phase_two.reset()
	roar.reset()
	for attack in _attacks:
		attack.start_over()
	BossHealthBar.hide_boss(self)


func _die() -> void:
	_end_attack()
	velocity = Vector2.ZERO
	_timer.enter(State.DYING, 0.0)
	defeat.play()
