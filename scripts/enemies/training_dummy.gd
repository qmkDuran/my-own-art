class_name TrainingDummy
extends StaticBody2D
## A straw-and-wood training post for trying out attacks. It never dies.
##
## It's in the "enemies" group with a child "Health", so jabs, skills and click-to-attack
## treat it like any enemy. On a hit it flashes, leans away from the punch and wobbles back
## upright (its post stays planted). Its damage numbers come from the level's DamageNumbers,
## like every enemy's. Under it, the total damage of the current combo (crits included) adds
## up while hits keep coming.
## After `calm_reset_time` seconds without a hit, its health refills and the total resets.
##
## It has no creature_info() and no LightDrop, so it never shows a discovery card,
## never enters the Creature Log and never drops light motes or berries.

## Words after the combo's total damage, e.g. "TOTAL 12".
const COMBO_LABEL := "TOTAL "
## Where the combo total sits, from the dummy's feet (top centre of the text).
const COMBO_LABEL_OFFSET := Vector2(0, 4)

## Seconds without a hit before health refills and the combo total resets.
@export var calm_reset_time: float = 2.0

@export_group("Wobble")
## How hard the lean springs back upright (higher = faster wobble).
@export var wobble_stiffness: float = 180.0
## How quickly the wobble dies down (higher = fewer swings).
@export var wobble_damping: float = 8.0
## Lean speed a normal hit gives, in radians per second (about 7 degrees at the peak).
@export var hit_lean_speed: float = 1.6
## Extra lean speed per pixel-per-second of knock_back (Flame Uppercut's 260 gives about 3.4).
@export var knock_back_lean_per_speed: float = 0.013
## The furthest it can lean either way, in degrees.
@export var max_lean_degrees: float = 18.0

var _seconds_since_hit: float = 0.0
var _combo_total: int = 0
var _lean_speed: float = 0.0

@onready var health: Health = $Health
@onready var sprite: Sprite2D = $Sprite
@onready var hit_flash: HitFlash = $HitFlash


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	_seconds_since_hit = calm_reset_time


func _physics_process(delta: float) -> void:
	_update_wobble(delta)
	_count_calm_time(delta)


## Strong hits (e.g. Flame Uppercut) throw it harder: it leans further but stays planted.
func knock_back(push_velocity: Vector2) -> void:
	_lean_away(push_velocity.x, push_velocity.length() * knock_back_lean_per_speed)


func _draw() -> void:
	if _combo_total <= 0:
		return
	var text := COMBO_LABEL + str(_combo_total)
	var top_left := COMBO_LABEL_OFFSET - Vector2(floorf(PixelFont.width_of(text) / 2.0), 0)
	PixelFont.draw_text(self, text, top_left, ApolloPalette.CREAM, ApolloPalette.OUTLINE)


# --- Getting hit ----------------------------------------------------------

## Health emits `damaged` before it checks for death, so topping it up here
## means it can never reach zero and never dies.
func _on_damaged(amount: int, source_position: Vector2) -> void:
	if health.current_health <= 0:
		health.current_health = health.max_health
	hit_flash.flash()
	_lean_away(global_position.x - source_position.x, hit_lean_speed)
	_seconds_since_hit = 0.0
	_combo_total += amount
	queue_redraw()


## Leans away from the side the hit came from (`away_x` > 0 means toward the right).
func _lean_away(away_x: float, lean_speed: float) -> void:
	var lean_direction := signf(away_x)
	if lean_direction == 0.0:
		lean_direction = 1.0 if randf() < 0.5 else -1.0
	_lean_speed += lean_direction * lean_speed


# --- Over time ------------------------------------------------------------

## A damped spring: the lean is pulled back upright and overshoots a little each swing.
## The sprite pivots on the dummy's feet, so the post stays planted.
func _update_wobble(delta: float) -> void:
	var lean := sprite.rotation
	_lean_speed += (-wobble_stiffness * lean - wobble_damping * _lean_speed) * delta
	var max_lean := deg_to_rad(max_lean_degrees)
	sprite.rotation = clampf(lean + _lean_speed * delta, -max_lean, max_lean)


## After a calm spell, health refills and the combo total clears.
func _count_calm_time(delta: float) -> void:
	if _seconds_since_hit >= calm_reset_time:
		return
	_seconds_since_hit += delta
	if _seconds_since_hit >= calm_reset_time:
		health.current_health = health.max_health
		_combo_total = 0
		queue_redraw()
