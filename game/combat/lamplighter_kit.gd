class_name LamplighterKit
extends Node
## The Lamplighter's whole kit, and the one place the abilities find what they need (the player, the aim, the
## camera, the enemies, the effects, health and the super meter): the primary bolt, the charged heavy beam, the
## lantern bomb, the ward, the blink and the Sunrise super. Every point of damage the player deals fills the super
## meter, shows a damage number and flashes the crosshair's hit marker.

signal hit_landed(critical: bool, killed: bool)

var player: Player
var camera_rig: CameraRig
var aim: Aim
var roster: Roster
var fx: CombatFx
var health: PlayerHealth
var meter := SuperMeter.new()
var environment: NightEnvironment
var cooldowns: Dictionary = {}
var primary: PrimaryFire
var heavy: HeavyBeam
var bomb: LanternBomb
var ward: Ward
var blink: Blink
var sunrise: Sunrise


func setup(owner_player: Player, rig: CameraRig, enemies: Roster, effects: CombatFx, player_health: PlayerHealth,
		night: NightEnvironment) -> void:
	name = "LamplighterKit"
	player = owner_player
	camera_rig = rig
	roster = enemies
	fx = effects
	health = player_health
	environment = night
	aim = Aim.new()
	add_child(aim)
	aim.setup(player, rig, roster)
	for ability: String in ["heavy", "bomb", "ward", "blink"]:
		cooldowns[ability] = Cooldown.new(Tuning.number("combat", ability, "cooldown"))
	primary = _add(PrimaryFire.new())
	heavy = _add(HeavyBeam.new())
	bomb = _add(LanternBomb.new())
	blink = _add(Blink.new())
	sunrise = _add(Sunrise.new())
	ward = Ward.new()
	player.add_child(ward)
	ward.setup(self)
	roster.ward = ward
	roster.dealt.connect(_on_dealt)


func _add(ability: Node) -> Node:
	add_child(ability)
	ability.call("setup", self)
	return ability


## True while the super is playing (the other attacks wait).
func busy() -> bool:
	return sunrise.active


## The ground height under a point.
func ground_at(at: Vector3) -> float:
	return roster.ground_at(at)


func _process(delta: float) -> void:
	for cooldown: Cooldown in cooldowns.values():
		cooldown.tick(delta)
	var stance: bool = aim.in_stance() or aim.target != null
	camera_rig.aiming = stance
	player.face_yaw = camera_rig.yaw if stance and not busy() else NAN


func _on_dealt(enemy: Enemy, amount: float, hit: Hit) -> void:
	if amount <= 0.0:
		return
	if hit.kind != "super":
		meter.add(amount)
	fx.damage_number(hit.point if hit.point != Vector3.ZERO else enemy.centre(), amount, hit.critical, hit.on_shield)
	hit_landed.emit(hit.critical, not enemy.is_alive())
	if not enemy.is_alive() or hit.critical:
		fx.kit.hit_feel.hit_stop(int(Tuning.doc("vfx")["lantern_flare"]["hit_feel"]["stop_frames"]), Hit.STOP_SCALE)
