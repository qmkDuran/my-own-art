"""Helpers for the heaven demo. ALL paid POSTs go through guard.paid_post."""
import base64, io, json, os, sys, time, urllib.request
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guard

H = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/"
RAW = H + "art/raw/"
R64 = [l.strip() for l in open("/home/user/project-revelation/art/style_anchors/resurrect64.hex") if l.strip()]
assert len(R64) == 64
PAL = {"colors": ["#" + c for c in R64], "name": "Resurrect 64"}
RGB = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in R64]
ANCHOR_CHAR = "/home/user/project-revelation/art/style_anchors/anchor_character_hero_f.png"
ANCHOR_TILES = "/home/user/project-revelation/art/style_anchors/anchor_ground_tiles.png"


def b64(img):
    buf = io.BytesIO(); img.save(buf, "PNG")
    return {"type": "base64", "base64": base64.b64encode(buf.getvalue()).decode(), "format": "png"}


def fetch(url):
    r = urllib.request.Request(url, headers={"User-Agent": "curl/8.5.0"})
    for a in range(5):
        try:
            return Image.open(io.BytesIO(urllib.request.urlopen(r, timeout=120).read())).convert("RGBA")
        except Exception:
            if a == 4: raise
            time.sleep(5)


def dec(o):
    if isinstance(o, dict) and "url" in o and not o.get("base64"): return fetch(o["url"])
    s = o["base64"] if isinstance(o, dict) else o
    return Image.open(io.BytesIO(base64.b64decode(s.split(",")[-1]))).convert("RGBA")


def images_of(j):
    lr = j.get("last_response") or j
    ims = lr.get("images") or ([lr["image"]] if "image" in lr else [])
    return [dec(x) for x in ims]


def style_img(path):
    s = Image.open(path).convert("RGBA")
    return {"style_image": {"image": b64(s), "size": {"width": s.width, "height": s.height}},
            "style_options": {"color_palette": False, "outline": True, "detail": True, "shading": True}}


def gimg(name, desc, w, h, seed=1, style=ANCHOR_CHAR, refs=(), nobg=True):
    body = {"description": desc, "image_size": {"width": w, "height": h}, "no_background": nobg,
            "target_palette": PAL, "style_options": {"color_palette": False}, "seed": seed}
    if style: body.update(style_img(style))
    rr = []
    for p, use in refs:
        r = Image.open(p).convert("RGBA")
        rr.append({"image": b64(r), "size": {"width": r.width, "height": r.height}, "usage_description": use})
    if rr: body["reference_images"] = rr
    est = 10 if max(w, h) <= 170 else 25
    j = guard.paid_post("/generate-image-v2", body, est, name)
    ims = images_of(j)
    for i, im in enumerate(ims): im.save(RAW + f"{name}_{i:02d}.png")
    print(name, j.get("status"), len(ims), "images")
    return ims


def contact(paths, out, scale=3, cols=4, bg=(70, 62, 84, 255)):
    ims = [Image.open(p).convert("RGBA") for p in paths]
    w = max(i.width for i in ims) * scale; h = max(i.height for i in ims) * scale
    rows = (len(ims) + cols - 1) // cols
    o = Image.new("RGBA", (cols * (w + 8), rows * (h + 8)), bg)
    for k, im in enumerate(ims):
        o.alpha_composite(im.resize((im.width * scale, im.height * scale), Image.NEAREST), ((k % cols) * (w + 8), (k // cols) * (h + 8)))
    o.save(out)
