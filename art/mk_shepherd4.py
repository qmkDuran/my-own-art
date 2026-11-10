"""Paid: 4-direction rotations of the chosen Shepherd picture (create-character-v3, ~1 gen). Idle only, no walk."""
import sys, time; sys.path.insert(0, 'tools')
from plh import *
im = Image.open('art/raw/shepherd_01.png').convert('RGBA')
body = {"description": "gentle shepherd in a long white robe with a golden sash, white hair, holding a wooden staff",
        "reference_image": b64(im), "n_directions": 4, "view": "low top-down", "template_id": "mannequin",
        "no_background": True, "image_size": {"width": 64, "height": 64}}
r = guard.paid_post("/create-character-v3", body, 2, "char4_shepherd")
cid = (r.get("last_response") or {}).get("character_id") or r.get("character_id")
for k in range(60):
    c = guard.get(f"/characters/{cid}"); ru = c.get("rotation_urls") or {}
    if all(ru.get(d) for d in ("south", "east", "north", "west")): break
    time.sleep(5)
for d in ("south", "east", "north", "west"):
    fetch(ru[d]).save(RAW + f'ch_shepherd_rot_{d}.png')
print('shepherd', cid)
