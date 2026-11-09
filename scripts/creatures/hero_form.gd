class_name HeroForm
extends Resource
## One of Emberoo's evolution forms (Art direction v2, DESIGN.md): his sprite sheets and the
## body and reach numbers that go with that body. Each Awakening stage has its own form (the
## joey, Emberoo, the final form); HeroFormSwitch puts the current one on the creature.
##
## Lengths are in world pixels; heights are measured from the feet (negative is up).

@export_group("Art")
## Folder of this form's sheets ("emberoo_<view>_<action>_sheet.png", see SpriteSheetLoader).
@export_dir var sheet_folder: String = "res://art/emberoo_v2/stage1"
## Width and height of one frame (every frame of a form has the same square canvas).
@export var frame_size: int = 64
## The centred sprite's offset that puts the frames' baseline row on the creature's feet:
## -(baseline - frame_size / 2) - 1 (art/emberoo_v2/README.md).
@export var sprite_offset_y: float = -27.0
## Where each fist sits in each view's idle pose (facing right), from the feet, for the
## sparks rising off them (FistEmbers). A view with one spot shows only one fist.
@export var fist_spots: Dictionary[String, Array] = {}

@export_group("Body")
## How much wider than the base oval his shadow is drawn (it sits under his feet).
@export var shadow_scale: float = 1.4
## Radius of the feet's collision circle (what walls and enemies bump into).
@export var body_radius: float = 5.0
## Height of the middle of the body: where punches are aimed from and rings are centred.
@export var body_height: float = -14.0
## Height of the top of the head: speech bubbles sit just above it.
@export var head_height: float = -38.0

@export_group("Reach")
## The jab: how far it reaches, how close to its line an enemy must be, and the height of
## the fist (where the impact is drawn). See MeleeAttack.
@export var jab_reach: float = 24.0
@export var jab_hit_radius: float = 13.0
@export var fist_height: float = -14.0
## How far the jab's wind-up snaps him forward.
@export var jab_lunge: float = 6.0
## The Spinning Hook's circle around him.
@export var hook_radius: float = 36.0
## How far Flame Uppercut's flame fan reaches.
@export var uppercut_reach: float = 40.0
## How close a click-to-attack walks him to the enemy before jabbing (inside the jab's reach).
@export var attack_approach_distance: float = 22.0

@export_group("Dodge")
## Speed of the dodge's bound; times Dodge.dodge_duration it is the distance covered.
@export var dodge_speed: float = 180.0
