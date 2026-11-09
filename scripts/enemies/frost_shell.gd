class_name FrostShell
extends HitShield
## A Rimoth's frost shell on an ally: a ring of ice around it that soaks the next `soak_left`
## damage. Fire breaks it in one hit (it soaks that hit, then shatters), and so does a burn
## tick. Drawn as a ring of ice pixels around the body; it cracks as it wears thin and
## shatters outward when it breaks.
##
## Added at runtime by `FrostShell.apply_to`, as a child named NODE_NAME (one per body).

## The child name a body's shell goes by.
const NODE_NAME := "FrostShell"
## Pixels the ring stands clear of the body (it is centred on the body's middle and sized to
## the body, see CreatureBody).
const CLEARANCE := 3.0
## Seconds the shatter takes, and how far the shards fly out, in pixels.
const SHATTER_TIME := 0.2
const SHATTER_SPREAD := 6.0
const ICE_COLOR := ApolloPalette.SKY_LIGHT
const SHINE_COLOR := ApolloPalette.WHITE

## Damage it can still soak.
var soak_left: int = 0
var _soak_full: int = 0
var _seconds_shattering: float = -1.0


## Shells `body` (an enemy with a Health) to soak `damage`. False if it has one already or can't.
static func apply_to(body: Node2D, damage: int) -> bool:
	var body_health := Health.of(body)
	if body_health == null or body_health.is_dead() or has_shell(body):
		return false
	var shell := FrostShell.new()
	shell.name = NODE_NAME
	shell.soak_left = damage
	shell._soak_full = damage
	shell.health = body_health
	shell.z_index = 1
	body.add_child(shell)
	return true


## True while `body` has an unbroken shell.
static func has_shell(body: Node) -> bool:
	var shell := body.get_node_or_null(NODE_NAME) as FrostShell
	return shell != null and shell.soak_left > 0


func soak(amount: int, kind: Health.HitKind) -> int:
	if soak_left <= 0:
		return amount
	var soaked := mini(amount, soak_left)
	soak_left = 0 if kind == Health.HitKind.FIRE else soak_left - soaked
	if soak_left <= 0:
		_shatter()
	return amount - soaked


func _shatter() -> void:
	_seconds_shattering = 0.0
	stop_guarding()  # soaks no more at once; the shards still play
	name = "Shattering" + NODE_NAME  # a new shell may take the name meanwhile


func _process(delta: float) -> void:
	if _seconds_shattering >= 0.0:
		_seconds_shattering += delta
		if _seconds_shattering >= SHATTER_TIME:
			queue_free()
	queue_redraw()


func _draw() -> void:
	var shattered := _seconds_shattering / SHATTER_TIME if _seconds_shattering >= 0.0 else 0.0
	var host := get_parent() as Node2D
	var body_radius := maxf(CreatureBody.half_width_of(host), absf(CreatureBody.height_of(host))) + CLEARANCE
	var centre := Vector2(0, CreatureBody.height_of(host))
	var radius := body_radius + shattered * SHATTER_SPREAD
	var pixels := roundi(TAU * body_radius)
	var is_cracked := soak_left < _soak_full
	for pixel in pixels:
		# Cracked: gaps in the ring. Shattering: it breaks up as it flies out.
		if (is_cracked or shattered > 0.0) and pixel % 3 == 0:
			continue
		if shattered > 0.0 and (pixel * 7) % 10 < shattered * 10.0:
			continue
		var angle := TAU * pixel / pixels
		var at := Vector2(cos(angle), sin(angle)) * radius + centre
		var color := SHINE_COLOR if pixel % 5 == 0 else ICE_COLOR
		draw_rect(Rect2(at.round(), Vector2.ONE), Color(color, 1.0 - shattered))
