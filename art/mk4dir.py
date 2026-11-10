# mk4dir.py idx [idx...] -> 4-direction rotations for standing people (no animations; ~1 gen each)
import sys, time, os; sys.path.insert(0, 'tools')
from plh import *
for idx in map(int, sys.argv[1:]):
    name = f'p{idx:02d}'
    if os.path.exists(RAW + f'ch_{name}_rot_west.png'): print('have', name); continue
    im = Image.open(f'art/raw/people_{idx:02d}.png').convert('RGBA')
    body = {"description": "person in a long white linen robe" + (" holding a green palm branch" if idx in (0, 2, 4, 6, 10, 14) else ""),
            "reference_image": b64(im), "n_directions": 4, "view": "low top-down", "template_id": "mannequin",
            "no_background": True, "image_size": {"width": 64, "height": 64}}
    r = guard.paid_post("/create-character-v3", body, 2, f"char4_{name}")
    cid = (r.get("last_response") or {}).get("character_id") or r.get("character_id")
    open(RAW + f'{name}_id.txt', 'w').write(cid)
    for k in range(40):
        c = guard.get(f"/characters/{cid}"); ru = c.get("rotation_urls") or {}
        if all(ru.get(d) for d in ("south", "east", "north", "west")): break
        time.sleep(5)
    for d in ("south", "east", "north", "west"):
        fetch(ru[d]).save(RAW + f'ch_{name}_rot_{d}.png')
    print(name, cid)
