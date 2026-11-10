"""PAID test (Step 2): world art generated with MICHAEL as the style reference, to compare with the reused Project R art.
  tiles - create-tiles-pro, 16 x 32 px (10 gens): street asphalt, sidewalk concrete, night lawn
  house - generate-image-v2 at 168 px, 4 variants (15 gens): one suburban house, the straight-front 3/4 wording that
          gave usable dwellings in heaven (art/gen_district.py)
Style: Michael's approved front sprite (style_image; tile style_images = two 32 px crops of it); palette: the ARPG
world palette (art/style.py). Run from heaven/:  python3 arpg/art/gen_world_test.py tiles|house"""
import json, sys, time
sys.path.insert(0, 'tools'); sys.path.insert(0, 'arpg/art')
from plh import *
import style

MICHAEL = Image.open('arpg/game/art/michael/idle.png').convert('RGBA').crop((0, 0, 64, 64))
WORLD_PAL = {"colors": ["#" + c for c in style.WORLD], "name": "ARPG world"}

if 'tiles' in sys.argv:
    sty = [{"base64": b64(MICHAEL.crop(b))["base64"], "width": 32, "height": 32} for b in ((16, 16, 48, 48), (16, 30, 48, 62))]
    D = ("1). dark asphalt road at night, worn grey-black tarmac with small cracks and a few loose stones, top-down, seamless "
         "2). dark asphalt road, plain, slightly patched, top-down, seamless "
         "3). concrete sidewalk slab, pale grey square paving with thin joints, top-down, seamless "
         "4). concrete sidewalk, cracked grey paving slab with grit, top-down, seamless "
         "5). dark green suburban lawn grass at night, short and slightly overgrown, top-down, seamless "
         "6). dark green lawn grass with a few dry patches, top-down, seamless")
    body = {"description": D, "tile_type": "square_topdown", "tile_size": 32, "tile_view": "top-down",
            "outline_mode": "segmentation", "target_palette": WORLD_PAL, "seed": 31, "style_images": sty,
            "style_options": {"color_palette": False, "outline": True, "detail": True, "shading": True}}
    j = guard.paid_post("/create-tiles-pro", body, 10, "arpg_test_tiles")
    json.dump(j, open(RAW + "arpg_test_tiles.json", "w"))
    lr = j.get("last_response") or j
    tid = lr.get("tile_id")
    for k in range(60):
        t = guard.get(f"/tiles-pro/{tid}")
        urls = t.get("storage_urls") or {}
        if urls: break
        time.sleep(5)
    for name, u in urls.items():
        fetch(u).save(RAW + f"arpg_test_{name}.png")
    print("tiles", len(urls))

if 'house' in sys.argv:
    VIEW = ("seen straight from the front (south) in a three-quarter top-down view: the front wall faces the viewer squarely "
            "and runs parallel to the bottom edge, the roof slopes away and is seen from above, NOT isometric, NOT turned diagonally")
    gimg("arpg_test_house", "A two-storey suburban family house at night, " + VIEW + ". Wooden clapboard walls in muted grey-blue, "
         "a dark shingle roof, a front porch with steps and a single front door in the middle of the front wall at ground level, "
         "the door a little taller than a man, windows at head height, one window softly lit warm yellow, the rest dark. "
         "Quiet, a little worn. The building fills the image on a thin strip of lawn. Clean pixel art game asset, dark outline, "
         "light from top-left", 168, 168, seed=303, style='arpg/art/michael_front_ref.png')
