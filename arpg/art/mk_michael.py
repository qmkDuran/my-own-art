"""PAID: Michael as a 4-direction character (create-character-v3, ~1-2 gens) from arpg_michael_01, then animations:
walk (template walking-8-frames, 1/dir) and a sword slash (pixminimax, 64 px x 8 frames = 1/dir). Run from heaven/.
Downloads everything with tools/fetchchar.py into art/raw/anim/michael/."""
import sys, time, subprocess; sys.path.insert(0, 'tools')
from plh import *
DIRS = ["south", "east", "north", "west"]
im = Image.open('art/raw/arpg_michael_01.png').convert('RGBA')
body = {"description": "archangel warrior with large white feathered wings, silver and gold armour, white tunic, a drawn longsword",
        "reference_image": b64(im), "n_directions": 4, "view": "low top-down", "template_id": "mannequin",
        "no_background": True, "image_size": {"width": 64, "height": 64}}
r = guard.paid_post("/create-character-v3", body, 2, "arpg_char4_michael")
cid = (r.get("last_response") or {}).get("character_id") or r.get("character_id")
open(RAW + 'arpg_michael_cid.txt', 'w').write(cid)
for k in range(80):
    c = guard.get(f"/characters/{cid}"); ru = c.get("rotation_urls") or {}
    if all(ru.get(d) for d in DIRS): break
    time.sleep(6)


def anim(body, est, label):
    r = guard.paid_post("/characters/animations", body, est, label)
    for jid in r.get("background_job_ids") or []:
        for i in range(200):
            j = guard.get("/background-jobs/" + jid)
            if j.get("status") in ("completed", "failed", "error", "cancelled"): break
            time.sleep(6)
        print(label, jid, j.get("status"))


anim({"character_id": cid, "animation_name": "walk", "directions": DIRS, "mode": "template",
      "template_animation_id": "walking-8-frames"}, 4, "arpg_michael_walk")
anim({"character_id": cid, "animation_name": "slash", "directions": DIRS, "mode": "pixminimax", "frame_count": 8,
      "action_description": "swings the longsword in one powerful wide horizontal slash in front of him, then returns to guard"},
     4, "arpg_michael_slash")
subprocess.run([sys.executable, 'tools/fetchchar.py', 'michael', cid])
