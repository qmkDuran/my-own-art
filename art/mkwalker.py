# mkwalker.py NAME people_index "description"  -> 4-dir character + template walk (south, north, west)
import sys, json, time, os; sys.path.insert(0, 'tools')
from plh import *
name, idx, desc = sys.argv[1], int(sys.argv[2]), sys.argv[3]
im = Image.open(f'art/raw/people_{idx:02d}.png').convert('RGBA')
body = {"description": desc, "reference_image": b64(im), "n_directions": 4, "view": "low top-down",
        "template_id": "mannequin", "no_background": True, "image_size": {"width": 64, "height": 64}}
r = guard.paid_post("/create-character-v3", body, 2, f"char_{name}")
cid = (r.get("last_response") or {}).get("character_id") or r.get("character_id")
print(name, cid)
open(RAW + f'{name}_id.txt', 'w').write(cid)
body = {"character_id": cid, "animation_name": "walk", "directions": ["south", "north", "west"], "mode": "template",
        "template_animation_id": "walking-8-frames"}
r = guard.paid_post("/characters/animations", body, 3, f"anim_{name}_walk")
for jid in r.get("background_job_ids") or []:
    for i in range(150):
        j = guard.get("/background-jobs/" + jid)
        if j.get("status") in ("completed", "failed", "error", "cancelled"): break
        time.sleep(6)
    print(jid, j.get("status"))
g, u = guard.balance(); open(guard.LOG, "a").write(f"  (after jobs of {name}) total_used={guard.START - g}\tusd={u}\n")
os.system(f"{sys.executable} tools/fetchchar.py {name} {cid}")
