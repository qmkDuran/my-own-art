class_name HeroFormSwitch
extends Node
## Keeps Emberoo in the evolution form of his Awakening stage (see HeroForm): stage 1, then
## Emberoo from Awakening I, then his final form from Awakening II. The new art is the
## evolution, so a form change swaps the sprite sheets and resizes everything tied to his
## body: the feet's collision circle and shadow, the jab's reach, the Spinning Hook's circle, Flame
## Uppercut's flame, the dodge, the fist sparks and where speech bubbles sit.
##
## Follows every change of stage at once (loading, the debug key), except while the
## awakening moment plays: AwakeningMoment then calls `show_stage` at its flare.

## One form per Awakening stage, in order (AwakeningStage.NONE first).
@export var forms: Array[HeroForm] = []

@export_group("Parts")
@export var animator: CreatureAnimator
@export var shadow: Node2D
@export var collision_shape: CollisionShape2D
@export var melee_attack: MeleeAttack
@export var spinning_hook: SpinningHook
@export var flame_uppercut: FlameUppercut
@export var dodge: Dodge
@export var mouse_orders: MouseOrders
@export var fist_embers: FistEmbers
@export var speech_bubble: Node2D
@export var awakening_moment: AwakeningMoment

## The form shown right now.
var current_form: HeroForm


func _ready() -> void:
	show_stage(Awakening.stage)
	Awakening.stage_changed.connect(_on_stage_changed)


## Puts on the form of Awakening `stage`.
func show_stage(stage: int) -> void:
	current_form = form_for(stage)
	_apply_art(current_form)
	_apply_body(current_form)
	_apply_reach(current_form)


func form_for(stage: int) -> HeroForm:
	return forms[clampi(stage, 0, forms.size() - 1)]


func _apply_art(form: HeroForm) -> void:
	animator.use_sheets(form.sheet_folder, form.frame_size, form.sprite_offset_y)
	fist_embers.fist_spots = form.fist_spots


func _apply_body(form: HeroForm) -> void:
	# Each form gets its own shape, so the scene's shared resource is never changed.
	var feet := CircleShape2D.new()
	feet.radius = form.body_radius
	collision_shape.shape = feet
	shadow.scale = Vector2.ONE * form.shadow_scale
	speech_bubble.position = Vector2(0, form.head_height)


func _apply_reach(form: HeroForm) -> void:
	melee_attack.reach = form.jab_reach
	melee_attack.hit_radius = form.jab_hit_radius
	melee_attack.fist_height = form.fist_height
	melee_attack.lunge_distance = form.jab_lunge
	spinning_hook.radius = form.hook_radius
	spinning_hook.fist_height = form.fist_height
	flame_uppercut.reach = form.uppercut_reach
	flame_uppercut.fist_height = form.fist_height
	dodge.dodge_speed = form.dodge_speed
	mouse_orders.attack_approach_distance = form.attack_approach_distance


func _on_stage_changed(stage: int) -> void:
	if not awakening_moment.is_playing:
		show_stage(stage)
