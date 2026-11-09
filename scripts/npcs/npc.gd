class_name Npc
extends StaticBody2D
## A townsperson you can talk to: walk up and press F or E, or click them (Emberoo walks
## over first). The conversation is data (a Dialogue resource) shown in the DialogueBox; a
## second Dialogue can take over once its flag is set (e.g. after the Tinkerer hands over
## the rod she says something new).
##
## The sprite is a 16×24 sheet with a 2-frame idle (the second frame is the breath); the
## node's origin is at the feet. They block the way like a crate and never fight.

const FRAME_SIZE := Vector2i(16, 24)
## Seconds per idle frame: the normal pose holds, the breath is short.
const POSE_SECONDS := 0.9
const BREATH_SECONDS := 0.35
## The feet's collision box, in pixels.
const FEET_SIZE := Vector2(10, 5)
## The soft shadow under the feet.
const SHADOW_RADIUS := Vector2(6, 2)

@export var display_name: String = ""
## The 32×24 idle sheet (two 16×24 frames).
@export var sprite_sheet: Texture2D
@export var dialogue: Dialogue
## Said instead of `dialogue` once `later_flag` is set (e.g. the Tinkerer's own flag).
@export var later_dialogue: Dialogue
@export var later_flag: String = ""
## Talking only works once this flag is set ("" = always), e.g. not mid-raid.
@export var talk_flag: String = ""
## How close Emberoo must be to talk, in pixels.
@export var talk_radius: float = 28.0

var _sprite := Sprite2D.new()
var _prompt := TalkPrompt.new()
var _speech := SpeechBubble.new()
var _idle_left: float = 0.0
## Clicked from afar: talk as soon as Emberoo gets close.
var _wants_to_talk: bool = false
var _is_talking: bool = false


func _ready() -> void:
	_sprite.texture = sprite_sheet
	_sprite.hframes = 2
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME_SIZE.x / 2.0, -FRAME_SIZE.y)
	add_child(_sprite)
	_prompt.position = Vector2(0, -FRAME_SIZE.y - 3)
	add_child(_prompt)
	_speech.position = Vector2(0, -FRAME_SIZE.y - 2)
	add_child(_speech)
	var shape := RectangleShape2D.new()
	shape.size = FEET_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -FEET_SIZE.y / 2.0)
	add_child(collision)
	_idle_left = randf_range(0.0, POSE_SECONDS)


func _exit_tree() -> void:
	TalkFocus.release(self)


func _process(delta: float) -> void:
	_idle_left -= delta
	if _idle_left <= 0.0:
		_sprite.frame = 1 - _sprite.frame
		_idle_left = BREATH_SECONDS if _sprite.frame == 1 else POSE_SECONDS


func _physics_process(_delta: float) -> void:
	var in_reach := can_talk() and _is_player_in_reach()
	if in_reach:
		TalkFocus.offer(self)
	else:
		TalkFocus.release(self)
	_prompt.visible = TalkFocus.is_focused(self) and not _is_talking
	if in_reach and _wants_to_talk:
		talk()


func _draw() -> void:
	var points := PackedVector2Array()
	for step in 12:
		points.append(Vector2.from_angle(TAU * step / 12.0) * SHADOW_RADIUS)
	draw_colored_polygon(points, Color(ApolloPalette.OUTLINE, 0.3))


func _unhandled_input(event: InputEvent) -> void:
	if _is_talking or event.is_echo() or not event.is_pressed():
		return
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT:
		_wants_to_talk = can_talk() and _is_under_cursor()
		return
	if TalkFocus.is_focused(self):
		for action in TalkFocus.TALK_ACTIONS:
			if event.is_action_pressed(action):
				get_viewport().set_input_as_handled()
				talk()
				return


## True once nothing stops a conversation (e.g. the raid is over).
func can_talk() -> bool:
	return talk_flag == "" or StoryFlags.has(talk_flag)


## A short line in a speech bubble over the head (no conversation, the game goes on).
func say(text: String, seconds: float = 2.5) -> void:
	_speech.say(text, seconds)


## Opens the conversation in the DialogueBox; sets its flag and shows its message after.
func talk() -> void:
	_wants_to_talk = false
	var box := DialogueBox.find(self)
	var current := _current_dialogue()
	if _is_talking or box == null or box.is_open or current == null:
		return
	_is_talking = true
	_prompt.visible = false
	box.play(display_name, current.lines, _portrait())
	await box.finished
	_is_talking = false
	StoryFlags.set_flag(current.sets_flag)
	if current.announcement != "":
		CheckpointToast.show_message(self, current.announcement)


func _current_dialogue() -> Dialogue:
	if later_dialogue != null and later_flag != "" and StoryFlags.has(later_flag):
		return later_dialogue
	return dialogue


func _portrait() -> Texture2D:
	var frame := AtlasTexture.new()
	frame.atlas = sprite_sheet
	frame.region = Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))
	return frame


func _is_player_in_reach() -> bool:
	var player := PlayerFinder.find(self)
	return player != null and global_position.distance_squared_to(player.global_position) <= talk_radius * talk_radius


func _is_under_cursor() -> bool:
	var body := Rect2(global_position + _sprite.offset, Vector2(FRAME_SIZE)).grow(2.0)
	return body.has_point(get_global_mouse_position())
