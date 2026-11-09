class_name Machine
extends SpeciesEnemy
## A trash enemy: one of the AI God's machines, running on light drained from the wild Glimra.
## Front view only; the sprite is mirrored to face the player's side once it is alert.
##
## Every machine dies the same way: it blows apart (MachineDeath) and the stolen light in its
## eye or core bursts out as XP motes (its LightDrop), maybe leaving a berry (DeathDrops, when
## it has one). An elite's blast gives the camera a small shake. Each machine script only says
## what to call off when it dies (`_call_off_attacks`).

## Closer than this to the player's side, in pixels, it keeps facing the way it was (no flicker).
const FACING_DEAD_ZONE := 4.0
## The camera shake when an elite machine blows up, in pixels and seconds.
const ELITE_SHAKE_STRENGTH := 2.0
const ELITE_SHAKE_SECONDS := 0.2

@export_group("Blowing up")
## The stolen light glowing in its eye or core; the flecks that burst out match it.
@export var light_color: Color = ApolloPalette.SKY_LIGHT
## Where the blast is centred, relative to its feet (about the middle of its body).
@export var core_offset: Vector2 = Vector2(0, -12)
## About half the machine's width, in pixels: the size of the blast.
@export var blast_size: float = 10.0
## Off for a machine that never turns (it looks the same both ways).
@export var mirrors_toward_player: bool = true

@onready var death_drops: DeathDrops = get_node_or_null("DeathDrops")


func _process(_delta: float) -> void:
	if mirrors_toward_player and not _is_dying and _is_alert():
		_face_player()


## Blows it apart and takes it out of play at once. `frees_light` is false when it wasn't
## beaten (a Zapmite's own burst): no light flecks then (and its LightDrop never fires).
func blow_up(frees_light: bool) -> void:
	_is_dying = true
	MachineDeath.spawn(get_parent(), global_position + core_offset, blast_size, light_color, frees_light)
	if _is_elite():
		_shake_camera()
	EnemyReactions.take_out_of_play(self, collision_shape)
	set_physics_process(false)
	visible = false
	queue_free()


func _die() -> void:
	_call_off_attacks()
	if death_drops != null:
		death_drops.drop()
	blow_up(true)


## Each machine calls off whatever attack it has under way (its telegraph, a tongue, a beam).
func _call_off_attacks() -> void:
	pass


func _face_player() -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var side := player.global_position.x - global_position.x
	if absf(side) > FACING_DEAD_ZONE:
		sprite.flip_h = side < 0.0


func _is_elite() -> bool:
	for child in get_children():
		if child is EliteModifier:
			return true
	return false


func _shake_camera() -> void:
	var player := PlayerFinder.find(self)
	var shake := player.get_node_or_null("ScreenShake") as ScreenShake if player != null else null
	if shake != null:
		shake.shake(ELITE_SHAKE_STRENGTH, ELITE_SHAKE_SECONDS)
