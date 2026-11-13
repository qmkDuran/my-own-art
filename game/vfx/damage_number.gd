class_name DamageNumber
extends Label3D
## A damage number that pops up where a hit landed, rises and fades (bigger and hotter for a critical hit, blue for
## a hit on a shield). Always drawn on top so it never hides behind the enemy.

const POP_SCALE: float = 1.5
const POP_SECONDS: float = 0.08
const DRIFT: float = 0.35


static func pop_up(parent: Node, at: Vector3, amount: float, critical: bool, on_shield: bool) -> void:
	var spec: Dictionary = Tuning.doc("combat")["damage_numbers"]
	var number := DamageNumber.new()
	number.text = str(roundi(amount)) + ("!" if critical else "")
	number.font_size = int(spec["crit_size" if critical else "size"])
	number.pixel_size = float(spec["pixel_size"])
	var key: String = "shield_color" if on_shield else ("crit_color" if critical else "color")
	number.modulate = Tuning.color(spec[key])
	number.outline_modulate = Tuning.color(Tuning.doc("vfx")["combat"]["damage"]["outline"])
	number.outline_size = number.font_size / 6
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.no_depth_test = true
	number.fixed_size = false
	parent.add_child(number)
	number.global_position = at + Vector3(randf_range(-DRIFT, DRIFT), 0.0, randf_range(-DRIFT, DRIFT))
	number._play(float(spec["rise"]), float(spec["seconds"]))


func _play(rise: float, seconds: float) -> void:
	scale = Vector3.ONE * POP_SCALE
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3.ONE, POP_SECONDS)
	tween.tween_property(self, "position:y", position.y + rise, seconds).set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, seconds * 0.5).set_delay(seconds * 0.5)
	tween.chain().tween_callback(queue_free)
