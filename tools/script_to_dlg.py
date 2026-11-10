#!/usr/bin/env python3
"""Converts the story script (docs/CHAPTER_1_SCRIPT.md, YAML blocks) into the game's .dlg format.

    python3 tools/script_to_dlg.py [docs/CHAPTER_1_SCRIPT.md] [data/dialogue/c1_script.dlg]

The output is generated: do not edit it by hand. Game-flow glue (zones, cinematic beats, fights)
lives in data/dialogue/ch1.dlg and calls into these nodes with "~ call c1_script#<node>".

Node naming
  <SCENE>.<list key>   every list of lines or choices in a scene, e.g. C1_S03.dialogue, C1_S03.choices
  <LINE_ID>            any line that something jumps to starts its own node (fall-through is kept)
  <OBJECT_ID>          examine text of an object, e.g. C1_OBJ_LAPTOP
  <LINE_ID>            lines in bark-style lists (barks, task_lines, search_calls) are also single nodes
  <TARGET>             a jump to something that is not dialogue (COMBAT_C1_WADE, C1_S07, ...) becomes a
                       stub node that sets the flag C1_NEXT to the target and ends.
"""
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs" / "CHAPTER_1_SCRIPT.md"
OUTPUT = ROOT / "data" / "dialogue" / "c1_script.dlg"

# Script sound ids -> files under res://audio/ (see audio/AUDIO_LIST.md). Unknown ids are lower-cased
# without the SFX_ prefix; the AudioManager logs missing names once and carries on.
SFX = {
    "SFX_PHONE_BUZZ": "phone_buzz",
    "SFX_DOOR_CHIME": "store_door_chime",
    "SFX_DOOR_CHIME_SLAM": "store_door_chime",
    "SFX_SCANNER_BEEP": "register_beep",
    "SFX_DOOR_OPEN": "door_open",
    "SFX_DOG_BARK_SMALL": "dog_bark",
    "SFX_EMERGENCY_TONE": "emergency_broadcast_tone",
    "SFX_CRASH_BIG": "car_crash",
    "SFX_SCREAM_DISTANT": "scream_distant",
    "SFX_SHELF_SWEEP": "glass_break",
    "SFX_CAR_FIRE_WHOOSH": "fire_crackle_loop",
    "SFX_ENGINE_FIRE_START": "fire_crackle_loop",
    "SFX_SMOKE_CHIRP_DISTANT": "smoke_chirp",
    "SFX_CHAIR_SCRAPE": "cutlery_clink",
}

# Script emotes -> portrait moods (portrait_<speaker>_<mood> in data/art.json).
MOOD = {
    "smile": "happy", "laugh": "happy", "amused": "happy", "grin": "happy", "wink": "happy",
    "soft": "sad", "watches": "sad", "guilty": "sad", "crumbling": "sad", "dazed": "sad",
    "shaking": "afraid", "freezes": "afraid", "coughing_on_lawn": "afraid",
}

BARK_LISTS = ("barks", "task_lines", "search_calls", "wade_background", "ambient_barks", "stranger_barks")


def speaker_of(line):
    who = line.get("who")
    if who:
        return str(who).lower()
    style = str(line.get("style", ""))
    if style.startswith("handwritten") or style.startswith("scripture"):
        return "letter"
    return "caption"


def condition(text):
    text = str(text).strip()
    match = re.fullmatch(r"(\w+) heard", text)
    if match:
        return "heard_" + match.group(1)
    return text


def value(v):
    if v is True:
        return "true"
    if v is False:
        return "false"
    return str(v)


def one_line(text):
    return str(text).replace("\n", "\\n").strip()


def is_line(item):
    return isinstance(item, dict) and "text" in item and "options" not in item


def is_choice(item):
    return isinstance(item, dict) and "options" in item


def is_object(item):
    return isinstance(item, dict) and "examine" in item and "id" in item


class Converter:
    def __init__(self, scenes):
        self.scenes = scenes
        self.out = []
        self.defined = set()
        self.targets = set()
        self.heard = set()

    # --- discovery ----------------------------------------------------------------

    def collect(self, node):
        if isinstance(node, dict):
            if "goto" in node and isinstance(node["goto"], str):
                self.targets.add(node["goto"])
            if "cond" in node:
                c = condition(node["cond"])
                if c.startswith("heard_"):
                    self.heard.add(c[len("heard_"):])
            for v in node.values():
                self.collect(v)
        elif isinstance(node, list):
            for v in node:
                self.collect(v)

    def collect_defined(self, node):
        if isinstance(node, dict):
            if "id" in node and ("text" in node or "examine" in node):
                self.defined.add(str(node["id"]))
            for v in node.values():
                self.collect_defined(v)
        elif isinstance(node, list):
            for v in node:
                self.collect_defined(v)

    # --- emitting -----------------------------------------------------------------

    def emit(self, text=""):
        self.out.append(text)

    def header(self, name):
        self.emit("")
        self.emit("== %s" % name)

    def line(self, item):
        if item.get("beat"):
            self.emit("~ wait %s" % item["beat"])
        if item.get("sfx"):
            sfx = str(item["sfx"])
            self.emit("~ sfx %s" % SFX.get(sfx, sfx.lower().removeprefix("sfx_")))
        prefix = "{%s} " % condition(item["cond"]) if item.get("cond") else ""
        who = speaker_of(item)
        mood = MOOD.get(str(item.get("emote", "")), "")
        mood_part = "(%s)" % mood if mood else ""
        suffix = " >>" if item.get("typing_interrupt") else ""
        text = one_line(item["text"]) or "..."
        self.emit("%s%s%s: %s%s" % (prefix, who, mood_part, text, suffix))
        if str(item.get("id", "")) in self.heard:
            self.emit("~ set heard_%s" % item["id"])
        for key, v in (item.get("set") or {}).items():
            self.emit("~ set %s %s" % (key, value(v)))
        if item.get("goto"):
            self.emit("-> %s" % item["goto"])

    def line_list(self, name, items):
        self.header(name)
        previous_was_jump = False
        for item in items:
            if is_line(item):
                item_id = str(item.get("id", ""))
                if item_id in self.targets:
                    if not previous_was_jump:
                        self.emit("-> %s" % item_id)
                    self.header(item_id)
                self.line(item)
                previous_was_jump = bool(item.get("goto"))
            elif isinstance(item, dict) and set(item.keys()) == {"goto"}:
                self.emit("-> %s" % item["goto"])
                previous_was_jump = True

    def choice(self, name, item):
        self.header(name)
        for option in item["options"]:
            cond = "{%s} " % condition(option["cond"]) if option.get("cond") else ""
            flags = " ".join("+%s=%s" % (k, value(v)) for k, v in (option.get("set") or {}).items())
            text = one_line(option["text"])
            self.emit("* %s%s -> %s %s" % (cond, text, option.get("goto", ""), flags))

    def obj(self, item):
        self.header(str(item["id"]))
        name = str(item.get("name", "")).replace("]", ")")
        speaker = "examine[%s]" % name if name else "examine"
        after = item.get("examine_after")
        if isinstance(after, dict):
            cond = condition(after.get("cond", ""))
            self.emit("{%s} %s: %s" % (cond, speaker, one_line(after["text"])))
            self.emit("~ if %s end" % cond)
        self.emit("%s: %s" % (speaker, one_line(item["examine"])))

    def section(self, prefix, key, items):
        name = "%s.%s" % (prefix, key)
        if all(is_object(i) for i in items):
            for i in items:
                self.obj(i)
            return
        if items and all(isinstance(i, dict) and "lines" in i and "id" in i for i in items):
            items = [line for page in items for line in page["lines"]]
        choices = [i for i in items if is_choice(i)]
        for index, c in enumerate(choices):
            self.choice(name if len(choices) == 1 else str(c["id"]), c)
            if len(choices) == 1:
                self.defined.add(name)
        lines = [i for i in items if is_line(i) or (isinstance(i, dict) and set(i.keys()) == {"goto"})]
        if lines and not any("examine" in i for i in lines):
            if all("text" in i and "who" not in i and "style" not in i and "id" in i for i in lines if is_line(i)) \
                    and any(str(i.get("id", "")).startswith("C1_OBJ") for i in lines):
                for i in lines:   # {id, text} examine lists (e.g. backyard_route.examine)
                    self.obj({"id": i["id"], "examine": i["text"]})
                return
            self.line_list(name, lines)
            if key in BARK_LISTS or any("trigger" in i or "room" in i for i in lines):
                for i in lines:
                    if is_line(i) and i.get("id"):
                        self.header("%s.single" % i["id"])
                        self.line({k: v for k, v in i.items() if k != "goto"})

    def walk(self, prefix, data):
        for key, v in data.items():
            if isinstance(v, list) and v and isinstance(v[0], dict):
                self.section(prefix, key, v)
            elif isinstance(v, dict) and key not in ("set_on_enter", "animal"):
                inner = str(v.get("id", "%s.%s" % (prefix, key)))
                self.walk(inner, v)
            elif key == "set_on_enter" and isinstance(v, dict):
                self.header("%s.enter" % prefix)
                for k, val in v.items():
                    self.emit("~ set %s %s" % (k, value(val)))

    def run(self):
        for scene in self.scenes:
            self.collect(scene)
            self.collect_defined(scene)
        self.emit("# GENERATED by tools/script_to_dlg.py from docs/CHAPTER_1_SCRIPT.md. Do not edit.")
        self.emit("# Regenerate after the script changes. Game-flow glue lives in ch1.dlg.")
        for index, scene in enumerate(self.scenes):
            prefix = str(scene.get("scene") or "C1_BLOCK%02d" % index)
            self.emit("")
            self.emit("# ---- %s: %s" % (prefix, scene.get("name", "")))
            self.walk(prefix, scene)
        stubs = sorted(t for t in self.targets if t not in self.defined)
        self.emit("")
        self.emit("# ---- Jumps out of dialogue (fights, minigames, next scenes): ch1.dlg reads C1_NEXT.")
        for target in stubs:
            self.header(target)
            self.emit("~ set C1_NEXT %s" % target)
            self.emit("~ end")
        return "\n".join(self.out) + "\n"


def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else SOURCE
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else OUTPUT
    blocks = re.findall(r"```yaml\n(.*?)```", source.read_text(encoding="utf-8"), re.S)
    scenes = [yaml.safe_load(b) for b in blocks]
    scenes = [s for s in scenes if isinstance(s, dict)]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(Converter(scenes).run(), encoding="utf-8")
    print("wrote %s (%d scenes)" % (output, len(scenes)))


if __name__ == "__main__":
    main()
