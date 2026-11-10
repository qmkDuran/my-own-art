class_name Enemy
extends CharacterBody2D
## Data-driven melee enemy (data/enemies.json): idle -> approach -> wind-up telegraph -> lunge
## attack -> recover, with knockback on hit and flight at low health. Defeat (death or escape)
## sets the entity's "defeat_flag" so the zone remembers it.

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, FLEE, DEAD }

const HURT_TIME := 0.22
const FLEE_TIME := 2.5
const SEPARATION := 26.0

var entity_id := ""
var defeat_flag := ""
var on_defeat_ref := ""
var stats: Dictionary = {}
var state := State.IDLE
var visual: CharacterVisual
var health: Health

var _hitbox: Hitbox
var _telegraph: Label
var _state_time := 0.0
var _attack_direction := Vector2.DOWN
var _target: Player
var _defeated := false


func setup(enemy_type: String, id: String, flag: String, defeat_ref: String = "") -> void:
	stats = DB.enemies.get(enemy_type, {})
	entity_id = id
	defeat_flag = flag
	on_defeat_ref = defeat_ref


func _ready() -> void:
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD | Layers.PLAYER | Layers.ENEMY
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body_size := Tiles.vec2(stats.get("body"), Vector2(18, 10))
	var rect := RectangleShape2D.new()
	rect.size = body_size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, -body_size.y / 2.0)
	add_child(shape)
	visual = CharacterVisual.new()
	add_child(visual)
	visual.setup(String(stats.get("art", "looter")))
	health = Health.new()
	health.setup(int(stats.get("hp", 6)))
	health.died.connect(_on_died)
	add_child(health)
	var hurtbox := Hurtbox.new()
	add_child(hurtbox)
	var hurt_size := Tiles.vec2(stats.get("hurtbox"), Vector2(20, 40))
	hurtbox.setup(self, Layers.ENEMY_HURTBOX, hurt_size, Vector2(0, -hurt_size.y / 2.0))
	_hitbox = Hitbox.new()
	add_child(_hitbox)
	_hitbox.setup(self, Layers.PLAYER_HURTBOX, float(stats.get("hit_radius", 14.0)))
	_hitbox.damage = int(stats.get("damage", 1))
	_hitbox.knockback = float(stats.get("knockback", 200.0))
	_telegraph = _make_telegraph(visual.frame_height())
	add_child(_telegraph)


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_state_time += delta
	_target = _find_player()
	if Router.is_gameplay_paused() and state != State.DEAD:
		velocity = Vector2.ZERO
		visual.moving = false
		return
	match state:
		State.IDLE:
			_process_idle()
		State.CHASE:
			_process_chase()
		State.WINDUP:
			_process_windup()
		State.ATTACK:
			_process_attack()
		State.RECOVER:
			_process_recover(delta)
		State.HURT:
			_process_hurt(delta)
		State.FLEE:
			_process_flee()
			if _defeated:
				return
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	visual.moving = velocity.length() > 8.0
	if velocity.length() > 8.0 and state != State.FLEE:
		visual.facing = velocity.normalized()
	elif state == State.FLEE:
		visual.facing = velocity.normalized() if velocity.length() > 1.0 else visual.facing


# --- States --------------------------------------------------------------------

func _process_idle() -> void:
	velocity = Vector2.ZERO
	if _target and _distance_to_target() < float(stats.get("aggro_radius", 160.0)):
		AudioManager.play_sfx(String(stats.get("sfx_alert", "enemy_alert")), -2.0, 0.05)
		_change_state(State.CHASE)


func _process_chase() -> void:
	if _target == null or _target.state == Player.State.DEAD:
		_change_state(State.IDLE)
		return
	var to_target := _target.global_position - global_position
	if to_target.length() <= float(stats.get("attack_range", 34.0)):
		_attack_direction = to_target.normalized()
		visual.facing = _attack_direction
		_change_state(State.WINDUP)
		return
	velocity = to_target.normalized() * float(stats.get("speed", 70.0))


func _process_windup() -> void:
	velocity = Vector2.ZERO
	var windup := float(stats.get("windup", 0.5))
	var pulse := 1.0 + 0.8 * absf(sin(_state_time * 30.0))
	visual.set_tint(Color(pulse, 0.7, 0.6))
	_telegraph.visible = true
	if _state_time >= windup:
		_telegraph.visible = false
		visual.set_tint(Color.WHITE)
		_hitbox.position = Vector2(0, -16) + _attack_direction * float(stats.get("reach", 20.0))
		_hitbox.activate()
		velocity = _attack_direction * float(stats.get("lunge_speed", 220.0))
		AudioManager.play_sfx(String(stats.get("sfx_attack", "swing")), -4.0, 0.1)
		_change_state(State.ATTACK)


func _process_attack() -> void:
	_hitbox.position = Vector2(0, -16) + _attack_direction * float(stats.get("reach", 20.0))
	if _state_time >= float(stats.get("attack_time", 0.18)):
		_hitbox.deactivate()
		_change_state(State.RECOVER)


func _process_recover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
	if _state_time >= float(stats.get("recover", 0.6)):
		_change_state(State.CHASE)


func _process_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	if _state_time < HURT_TIME:
		return
	if health.ratio() <= float(stats.get("flee_below", 0.0)):
		AudioManager.play_sfx(String(stats.get("sfx_flee", "")), -2.0)
		_change_state(State.FLEE)
	else:
		_change_state(State.CHASE)


func _process_flee() -> void:
	var away := Vector2.RIGHT
	if _target:
		away = (global_position - _target.global_position).normalized()
	velocity = away * float(stats.get("flee_speed", 120.0))
	modulate.a = clampf(1.0 - (_state_time - FLEE_TIME + 0.8) / 0.8, 0.0, 1.0)
	if _state_time >= FLEE_TIME:
		_defeat()


func _change_state(new_state: State) -> void:
	if state == State.ATTACK or state == State.WINDUP:
		_hitbox.deactivate()
		_telegraph.visible = false
		visual.set_tint(Color.WHITE)
	state = new_state
	_state_time = 0.0
	match new_state:
		State.WINDUP:
			if not visual.play_action("windup", float(stats.get("windup", 0.5)), true):
				visual.play_action("growl", float(stats.get("windup", 0.5)), true)
		State.ATTACK:
			var attack_time := float(stats.get("attack_time", 0.18)) + 0.12
			if not visual.play_action("attack", attack_time):
				visual.play_action("lunge", attack_time)
		State.HURT:
			visual.play_hurt(HURT_TIME + 0.1)
		State.DEAD:
			pass
		_:
			if visual.current_action() != "hurt":
				visual.clear_action()


# --- Combat --------------------------------------------------------------------

## Called by our Hurtbox when the player's Hitbox connects.
func take_hit(hitbox: Hitbox) -> void:
	if state == State.DEAD or state == State.FLEE:
		return
	var away := (global_position - hitbox.attacker.global_position).normalized()
	velocity = away * hitbox.knockback * float(stats.get("knockback_taken", 1.0))
	visual.flash(Color(3.0, 3.0, 3.0), 0.12)
	AudioManager.play_sfx(String(stats.get("sfx_hurt", "hit_heavy")), 0.0, 0.1)
	Events.shake_requested.emit(3.0, 0.15)
	HitStop.apply(get_tree(), 0.06)
	health.take_damage(hitbox.damage, hitbox.attacker)
	if state != State.DEAD:
		_change_state(State.HURT)


func is_defeated() -> bool:
	return state == State.DEAD or state == State.FLEE


func _on_died() -> void:
	_change_state(State.DEAD)
	visual.play_fall()
	AudioManager.play_sfx(String(stats.get("sfx_death", "")))
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.3
	timer.timeout.connect(_defeat)
	add_child(timer)
	timer.start()


func _defeat() -> void:
	if not is_inside_tree() or _defeated:
		return
	_defeated = true
	Events.enemy_defeated.emit(entity_id)
	if defeat_flag.is_empty():
		queue_free()
	else:
		GameState.flags.set_flag(defeat_flag)
	if not on_defeat_ref.is_empty():
		Dialogue.run(on_defeat_ref)


# --- Helpers -------------------------------------------------------------------

func _find_player() -> Player:
	if Router.game and Router.game.player and is_instance_valid(Router.game.player):
		return Router.game.player
	return null


func _distance_to_target() -> float:
	return global_position.distance_to(_target.global_position) if _target else INF


func _make_telegraph(height: float) -> Label:
	var label := Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("ff5040"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-4, -height - 26)
	label.visible = false
	return label
