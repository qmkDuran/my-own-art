"""Shrinks the textures embedded in a Meshy GLB so the repo stays small: every image is resized to at most
MAX_SIDE pixels and stored as JPEG. Geometry, skins and animations are copied untouched.
Run: python3 -I tools/shrink_glb.py IN.glb OUT.glb [MAX_SIDE]"""
from __future__ import annotations

import io
import json
import struct
import sys

from PIL import Image

JPEG_QUALITY = 88
DEFAULT_MAX_SIDE = 1024
GLB_HEADER = 12
CHUNK_HEADER = 8
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


def read_glb(path: str) -> tuple[dict, bytes]:
    data = open(path, "rb").read()
    json_len = struct.unpack_from("<I", data, GLB_HEADER)[0]
    start = GLB_HEADER + CHUNK_HEADER
    doc = json.loads(data[start:start + json_len])
    bin_start = start + json_len + CHUNK_HEADER
    bin_len = struct.unpack_from("<I", data, start + json_len)[0]
    return doc, data[bin_start:bin_start + bin_len]


def shrink_image(raw: bytes, max_side: int) -> bytes:
    image = Image.open(io.BytesIO(raw)).convert("RGB")
    image.thumbnail((max_side, max_side), Image.LANCZOS)
    out = io.BytesIO()
    image.save(out, "JPEG", quality=JPEG_QUALITY)
    return out.getvalue()


def rebuild(doc: dict, blob: bytes, max_side: int) -> bytes:
    image_views = {img["bufferView"]: img for img in doc.get("images", []) if "bufferView" in img}
    out = bytearray()
    for index, view in enumerate(doc["bufferViews"]):
        chunk = blob[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
        if index in image_views:
            chunk = shrink_image(chunk, max_side)
            image_views[index]["mimeType"] = "image/jpeg"
        while len(out) % 4:
            out.append(0)
        view["byteOffset"] = len(out)
        view["byteLength"] = len(chunk)
        out += chunk
    while len(out) % 4:
        out.append(0)
    doc["buffers"] = [{"byteLength": len(out)}]
    return bytes(out)


def write_glb(path: str, doc: dict, blob: bytes) -> None:
    text = json.dumps(doc, separators=(",", ":")).encode()
    text += b" " * ((4 - len(text) % 4) % 4)
    total = GLB_HEADER + CHUNK_HEADER * 2 + len(text) + len(blob)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<II", len(text), JSON_CHUNK) + text)
        f.write(struct.pack("<II", len(blob), BIN_CHUNK) + blob)


def main() -> None:
    max_side = int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_MAX_SIDE
    doc, blob = read_glb(sys.argv[1])
    write_glb(sys.argv[2], doc, rebuild(doc, blob, max_side))


if __name__ == "__main__":
    main()
