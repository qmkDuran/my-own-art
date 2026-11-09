class_name Dialogue
extends Resource
## What a townsperson says: a few short lines shown one at a time in the DialogueBox
## (2–4 lines, Last Epoch light). Kept as data (`data/dialogue/*.tres`), so writing a
## conversation never touches code.

## The lines, in order; a click (or F, E, Space, Enter) shows the next.
@export_multiline var lines: PackedStringArray = []
## A StoryFlags flag set once the last line has been read ("" = none).
@export var sets_flag: String = ""
## A short HUD message after the conversation, e.g. "LINK ROD: PRESS C" ("" = none).
@export var announcement: String = ""
