class_name Roster
extends Node3D
## Every enemy in the fight: spawns them (with a violet puff), answers "who is near here?" and "what does this shot
## hit?", passes their hits and deaths on (the super meter and the HUD listen), and is the one door through which
## enemies hurt the player, so every hurt is logged with the warning it had (for the telegraph checks).

signal died(enemy: Enemy)
signal dealt(enemy: Enemy, amount: float, hit: Hit)
signal shield_broken(enemy: Enemy)
signal boss_phase_changed(enemy: Enemy, phase: int)
signal player_struck(amount: float)

const GROUND_PROBE: float = 6.0

var enemies: Array[Enemy] = []
var player: Player
var health: PlayerHealth
var fx: CombatFx
var ward: Ward
## Every enemy attack that landed or resolved: { "warned": seconds of warning, "hit": true if it hurt }.
var strikes: Array[Dictionary] = []
## The fight's own clock (seconds of game time) and when the last wind-up warning sounded on it, so a shot can
## be timed against its warning.
var clock: float = 0.0
var last_warned: float = 0.0
var _library: AssetLibrary


func setup(library: AssetLibrary, owner_player: Player, player_health: PlayerHealth, effects: CombatFx) -> void:
	name = "Roster"
	_library = library
	player = owner_player
	health = player_health
	fx = effects


func spawn(kind: String, at: Vector3) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(kind, _library, self)
	add_child(enemy)
	enemy.global_position = Vector3(at.x, ground_at(at), at.z)
	enemy.rotation.y = randf() * TAU
	enemy.died.connect(_on_died)
	enemy.damaged.connect(func(who: Enemy, amount: float, hit: Hit) -> void: dealt.emit(who, amount, hit))
	enemy.shield_broken.connect(func(who: Enemy) -> void: shield_broken.emit(who))
	enemies.append(enemy)
	fx.spawn_puff(enemy)
	return enemy


func count_of(kind: String) -> int:
	return enemies.filter(func(enemy: Enemy) -> bool: return enemy.kind == kind).size()


func boss() -> Enemy:
	for enemy: Enemy in enemies:
		if enemy.role == "boss":
			return enemy
	return null


## Enemies whose body overlaps a ball (flat distance on the ground, so height does not matter).
func within(at: Vector3, reach: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for enemy: Enemy in enemies:
		var flat := Vector2(enemy.global_position.x - at.x, enemy.global_position.z - at.z)
		if flat.length() < reach + enemy.radius:
			out.append(enemy)
	return out


## The first enemy a moving ball of a radius touches between two points: { "enemy", "point", "share" } or empty.
func sweep(from: Vector3, to: Vector3, ball: float) -> Dictionary:
	var best: Dictionary = {}
	var segment: Vector3 = to - from
	var length_squared: float = maxf(segment.length_squared(), Hit.TINY)
	for enemy: Enemy in enemies:
		var share: float = clampf((enemy.centre() - from).dot(segment) / length_squared, 0.0, 1.0)
		var closest: Vector3 = from + segment * share
		if closest.distance_to(enemy.centre()) <= enemy.hit_radius() + ball and (best.is_empty() or share <
				float(best["share"])):
			best = { "enemy": enemy, "point": closest, "share": share }
	return best


## The ground height under a point (the floor, a ramp or the ruins' rise).
func ground_at(at: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * GROUND_PROBE, at + Vector3.DOWN * GROUND_PROBE,
		Layers.WORLD)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit["position"].y) if not hit.is_empty() else at.y


## Adds an effect or projectile to the fight (it is cleared with the fight).
func add_effect(node: Node3D, at: Vector3) -> void:
	add_child(node)
	node.global_position = at


func hurt_player(amount: float, warned: float, ground: bool = false) -> void:
	var landed: bool = health.hurt(amount)
	strikes.append({ "warned": warned, "hit": landed, "ground": ground })
	if landed:
		player_struck.emit(amount)
		cue("player_hurt", player.global_position)


## A swarmer's bite (its wind-up crouch is the warning).
func strike(_enemy: Enemy, amount: float, warned: float) -> void:
	hurt_player(amount, warned)


## A ground attack that landed where the player wasn't.
func log_warning(warned: float) -> void:
	strikes.append({ "warned": warned, "hit": false, "ground": true })


## The chime as an enemy starts to wind up a shot.
func warn(enemy: Enemy) -> void:
	last_warned = clock
	cue("telegraph", enemy.centre())


func warn_at(at: Vector3) -> void:
	cue("telegraph", at)


func land_effect(telegraph: Telegraph) -> void:
	fx.telegraph_lands(telegraph)


func cue(sound: String, at: Vector3) -> void:
	fx.kit.sfx.cue(sound, at)


func _physics_process(delta: float) -> void:
	clock += delta


## Removes every enemy, shot and telegraph (a fight ends or the mission resets).
func clear() -> void:
	for child: Node in get_children():
		child.queue_free()
	enemies.clear()


## A beaten enemy stops, dissolves into light, then pops into sparkles.
func _on_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
	died.emit(enemy)
	enemy.set_physics_process(false)
	enemy.collision_layer = 0
	cue("enemy_die", enemy.centre())
	Dissolve.run(enemy.model(), Tuning.doc("vfx")["lantern_flare"]["dissolve"], _pop.bind(enemy))


func _pop(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	fx.defeat_pop(enemy)
	enemy.queue_free()
