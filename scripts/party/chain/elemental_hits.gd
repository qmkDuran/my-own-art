class_name ElementalHits
extends Node
## Makes a MeleeAttack's hits (Emberoo's jabs and hook, which deal their own damage) count
## as element hits: hit feel, poise, cooldown shaving, the Link meter and reactions
## (see ElementStrike).

@export var melee_attack: MeleeAttack
## Poise each landed jab drains.
@export var poise_damage: int = 1


func _ready() -> void:
	melee_attack.target_hit.connect(_on_target_hit)


func _on_target_hit(target_health: Health) -> void:
	ElementStrike.after_damage(get_parent() as Node2D, target_health, poise_damage)
