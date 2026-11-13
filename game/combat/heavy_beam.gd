class_name HeavyBeam
extends Node
## The heavy: hold to charge (a visible build-up at the lantern, a rising hum, a chime when full), release to fire
## a beam along the crosshair that pierces every enemy in its path. Damage and width scale with the charge (from
## min_share of a full charge up), and it knocks enemies back. Shields crack fast under it.

const KICK_BASE: float = 2.0
const KICK_CHARGE: float = 4.0

var charging: bool = false
var _kit: LamplighterKit
var _charge: float = 0.0
var _glow: ChargeGlow
var _rang: bool = false


func setup(kit: LamplighterKit) -> void:
	name = "HeavyBeam"
	_kit = kit


func begin() -> bool:
	if charging or _kit.busy() or not (_kit.cooldowns["heavy"] as Cooldown).is_ready():
		return false
	charging = true
	_charge = 0.0
	_rang = false
	_glow = ChargeGlow.new()
	_kit.player.lantern.light.add_child(_glow)
	_glow.setup(_kit.fx.kit, _kit.fx.look("heavy")["charge"])
	_kit.fx.kit.sfx.cue("charge_start", _kit.aim.muzzle())
	return true


func share() -> float:
	return _charge / Tuning.number("combat", "heavy", "full_charge")


## The beam's damage at a share of a full charge.
static func damage_for(charge_share: float) -> float:
	var at: float = clampf(maxf(charge_share, Tuning.number("combat", "heavy", "min_share")), 0.0, 1.0)
	return lerpf(Tuning.number("combat", "heavy", "damage_min"), Tuning.number("combat", "heavy", "damage_max"), at)


func _process(delta: float) -> void:
	if not charging:
		return
	_charge = minf(_charge + delta, Tuning.number("combat", "heavy", "full_charge"))
	_glow.set_share(share())
	_kit.aim.engage()
	if share() >= 1.0 and not _rang:
		_rang = true
		_kit.fx.kit.sfx.cue("charge_full", _kit.aim.muzzle())


## Fires the beam; returns the damage it carried (0 when it wasn't charging).
func release() -> float:
	if not charging:
		return 0.0
	charging = false
	_glow.queue_free()
	var charge_share: float = share()
	var damage: float = damage_for(charge_share)
	var width: float = lerpf(Tuning.number("combat", "heavy", "width_min"), Tuning.number("combat", "heavy",
		"width_max"), charge_share)
	var from: Vector3 = _kit.aim.muzzle()
	var direction: Vector3 = _kit.aim.direction_from(from)
	var end: Vector3 = _end_of(from, direction)
	for enemy: Enemy in _struck(from, end, width):
		var contact: Vector3 = enemy.centre() - direction * enemy.radius
		enemy.take_hit(Hit.new(damage, "heavy", contact, direction * Tuning.number("combat", "heavy", "knockback")))
		_kit.fx.impact("heavy", contact, Vector3(contact.x, enemy.global_position.y, contact.z))
	var spec: Dictionary = _kit.fx.look("heavy")
	BeamFx.new().play(_kit.fx.kit, spec["beam"], from, end, width, Tuning.number("combat", "heavy", "beam_seconds"))
	_kit.fx.impact("heavy", end, Vector3(end.x, _kit.ground_at(end), end.z))
	_kit.fx.kit.sfx.cue("heavy_release", from)
	_kit.camera_rig.kick(Tuning.number("combat", "camera", "kick") * (KICK_BASE + charge_share * KICK_CHARGE))
	_kit.fx.kit.hit_feel.nudge(float(spec["beam"]["shake"]) * charge_share, Tuning.number("combat", "heavy",
		"beam_seconds"))
	(_kit.cooldowns["heavy"] as Cooldown).start()
	_kit.aim.engage()
	return damage


func _end_of(from: Vector3, direction: Vector3) -> Vector3:
	var far: Vector3 = from + direction * Tuning.number("combat", "heavy", "range")
	var query := PhysicsRayQueryParameters3D.create(from, far, Layers.WORLD, [_kit.player.get_rid()])
	var wall: Dictionary = _kit.player.get_world_3d().direct_space_state.intersect_ray(query)
	return wall["position"] if not wall.is_empty() else far


## Every enemy the beam passes through (its ball within the beam's half width of the line).
func _struck(from: Vector3, to: Vector3, width: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var segment: Vector3 = to - from
	for enemy: Enemy in _kit.roster.enemies.duplicate():
		var share_along: float = clampf((enemy.centre() - from).dot(segment) / segment.length_squared(), 0.0, 1.0)
		if (from + segment * share_along).distance_to(enemy.centre()) <= width * 0.5 + enemy.hit_radius():
			out.append(enemy)
	return out
