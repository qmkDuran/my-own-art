class_name Player
extends CharacterBody2D
## The hero: 8-direction movement, run, dodge roll with i-frames, melee swing, interaction.
## Health is mirrored into GameState so it carries across zones and saves.

enum State { MOVE, ATTACK, DODGE, HURT, DEAD }

const WALK_SPEED := 105.0
const RUN_SPEED := 170.0
const ACCELERATION := 1300.0
const DODGE_SPEED := 290.0
const DODGE_TIME := 0.28
const DODGE_COOLDOWN := 0.45
const HURT_TIME := 0.25
const INVULNERABLE_TIME := 0.7
const INTERACT_REACH := 22.0
const FALLBACK_WEAPON := "fists"

var state := State.MOVE
var facing := Vector2.DOWN
var visual: CharacterVisual
var health: Health
var camera: ShakeCamera

var _hitbox: Hitbox
var _hurtbox: Hurtbox
var _interactor: Area2D
var _focused: Interactable
var _state_time := 0.0
var _dodge_cooldown := 0.0
var _attack_phase := 0
var _weapon: Dictionary = {}
var _footstep_time := 0.0


func _ready() -> void:
	collision_layer = Layers.PLAYER
	collision_mask = Layers.WORLD | Layers.ENEMY
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_add_body_shape()
	visual = CharacterVisual.new()
	add_child(visual)
	visual.setup(GameState.hero_art("body"))
	visual.add_layer(GameState.hair_art())
	health = Health.new()
	health.setup(GameState.max_hp, GameState.hp)
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	add_child(health)
	_hurtbox = Hurtbox.new()
	add_child(_hurtbox)
	_hurtbox.setup(self, Layers.PLAYER_HURTBOX, Vector2(18, 40), Vector2(0, -22))
	_hitbox = Hitbox.new()
	add_child(_hitbox)
	_hitbox.setup(self, Layers.ENEMY_HURTBOX, 14.0)
	_interactor = _make_interactor()
	camera = ShakeCamera.new()
	add_child(camera)
	Events.player_health_changed.emit(health.current, health.maximum)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	match state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge()
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
	move_and_slide()
	visual.facing = facing
	visual.moving = velocity.length() > 10.0 and state == State.MOVE
	visual.speed_scale = velocity.length() / WALK_SPEED
	_update_focus()


# --- States --------------------------------------------------------------------

func _process_move(delta: float) -> void:
	if Router.is_gameplay_paused():
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity = velocity.move_toward(input * speed, ACCELERATION * delta)
	if input.length() > 0.2:
		facing = _snap_to_eight(input)
		_play_footsteps(delta, speed)
	if Input.is_action_just_pressed("interact") and _focused:
		velocity = Vector2.ZERO
		_focused.interact(self)
	elif Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_pressed("dodge") and _dodge_cooldown <= 0.0:
		_start_dodge(input)


func _start_attack() -> void:
	_weapon = _current_weapon()
	_change_state(State.ATTACK)
	_attack_phase = 0
	velocity *= 0.3
	AudioManager.play_sfx(String(_weapon.get("sfx_swing", "swing")), -4.0, 0.08)


func _process_attack(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
	var windup := float(_weapon.get("windup", 0.07))
	var active := float(_weapon.get("active", 0.12))
	var recover := float(_weapon.get("recover", 0.16))
	if _attack_phase == 0 and _state_time >= windup:
		_attack_phase = 1
		var reach := float(_weapon.get("reach", 22.0))
		_hitbox.position = Vector2(0, -18) + facing * reach
		_hitbox.set_radius(float(_weapon.get("radius", 14.0)))
		_hitbox.damage = int(_weapon.get("damage", 1))
		_hitbox.knockback = float(_weapon.get("knockback", 180.0))
		_hitbox.activate()
		visual.flash(Color(1.4, 1.3, 1.1), active)
	elif _attack_phase == 1 and _state_time >= windup + active:
		_attack_phase = 2
		_hitbox.deactivate()
	elif _attack_phase == 2 and _state_time >= windup + active + recover:
		_change_state(State.MOVE)


func _start_dodge(input: Vector2) -> void:
	var direction := input.normalized() if input.length() > 0.2 else facing
	_change_state(State.DODGE)
	velocity = direction * DODGE_SPEED
	health.invulnerable = true
	_dodge_cooldown = DODGE_COOLDOWN + DODGE_TIME
	visual.play_roll(DODGE_TIME)
	AudioManager.play_sfx("whoosh", -3.0, 0.05)


func _process_dodge() -> void:
	if _state_time >= DODGE_TIME:
		health.invulnerable = false
		velocity *= 0.35
		_change_state(State.MOVE)


func _process_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * 0.8 * delta)
	if _state_time >= HURT_TIME:
		_change_state(State.MOVE)


func _change_state(new_state: State) -> void:
	if state == State.ATTACK and new_state != State.ATTACK:
		_hitbox.deactivate()
	state = new_state
	_state_time = 0.0


# --- Combat --------------------------------------------------------------------

## Called by a Hurtbox when an enemy Hitbox connects.
func take_hit(hitbox: Hitbox) -> void:
	if health.invulnerable or state == State.DEAD:
		return
	var away := (global_position - hitbox.attacker.global_position).normalized()
	velocity = away * hitbox.knockback
	health.take_damage(hitbox.damage, hitbox.attacker)
	if state == State.DEAD:
		return
	_change_state(State.HURT)
	visual.flash(Color(2.0, 0.6, 0.6), 0.3)
	AudioManager.play_sfx("hurt", 0.0, 0.05)
	Events.shake_requested.emit(5.0, 0.25)
	HitStop.apply(get_tree(), 0.08)
	_grant_invulnerability()


func _grant_invulnerability() -> void:
	health.invulnerable = true
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = INVULNERABLE_TIME
	timer.timeout.connect(_end_invulnerability.bind(timer))
	add_child(timer)
	timer.start()


func _end_invulnerability(timer: Timer) -> void:
	timer.queue_free()
	if state != State.DODGE and state != State.DEAD:
		health.invulnerable = false


func _current_weapon() -> Dictionary:
	var weapon_id := GameState.inventory.equipped_weapon
	if weapon_id.is_empty():
		weapon_id = FALLBACK_WEAPON
	return DB.item(weapon_id).get("weapon", {})


func _on_health_changed(current: int, _maximum: int) -> void:
	GameState.set_hp(current)


func _on_died() -> void:
	_change_state(State.DEAD)
	visual.play_fall()
	AudioManager.play_sfx("hurt", 2.0)
	Events.player_died.emit()


## Restores health to the current GameState value (after eating, healing, etc.).
func sync_health() -> void:
	health.current = GameState.hp
	health.maximum = GameState.max_hp


# --- Interaction ---------------------------------------------------------------

func focused_interactable() -> Interactable:
	return _focused


func _update_focus() -> void:
	_interactor.position = Vector2(0, -12) + facing * INTERACT_REACH
	var best: Interactable = null
	var best_distance := INF
	if state == State.MOVE:
		for area: Area2D in _interactor.get_overlapping_areas():
			var candidate := area as Interactable
			if candidate == null or not candidate.is_visible_in_tree():
				continue
			var distance := candidate.global_position.distance_squared_to(_interactor.global_position)
			if distance < best_distance:
				best = candidate
				best_distance = distance
	if best != _focused:
		_focused = best
		Events.interact_prompt_changed.emit(best.prompt() if best else "")


func _make_interactor() -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = Layers.INTERACTABLE
	area.monitorable = false
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	return area


# --- Helpers -------------------------------------------------------------------

func _add_body_shape() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 10)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, -5)
	add_child(shape)


func _play_footsteps(delta: float, speed: float) -> void:
	_footstep_time -= delta * speed / WALK_SPEED
	if _footstep_time <= 0.0:
		_footstep_time = 0.38
		var zone: Zone = Router.game.zone if Router.game else null
		var surface := zone.surface_at(global_position) if zone else "wood"
		AudioManager.play_sfx("footstep_" + surface, -14.0, 0.08)


static func _snap_to_eight(direction: Vector2) -> Vector2:
	var angle := snappedf(direction.angle(), PI / 4.0)
	return Vector2.from_angle(angle)
