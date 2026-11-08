class_name Skill
extends Resource
## What a skill is, as data: its name, icon, Heat cost and cooldown.
##
## Content only, so the HUD and the Ember Tree can show it without knowing how it plays.
## What the skill does when it fires lives in its SkillAction node (e.g. FlameUppercut).
## What it does in words lives on its Ember Tree node (EmberTreeData), shown by the tree and
## the HUD tooltip alike.

@export var display_name: String = ""
## 14×14 pixel-art icon (art/skills/<node id>_icon.png), shown in the skill bar; the Ember
## Tree draws the same file on the skill's node.
@export var icon: Texture2D
## Heat spent each time the skill fires. It is refused (nothing spent) without enough.
@export var heat_cost: int = 0
## Seconds after firing before the skill can fire again.
@export var cooldown: float = 0.0
