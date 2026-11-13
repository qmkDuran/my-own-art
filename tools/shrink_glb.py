"""Shrinks the textures embedded in a Meshy GLB so the repo stays small: every image is resized to at most
MAX_SIDE pixels and stored as JPEG. Before resizing, each texture's colours are padded outward from its UV islands
into the empty gutters (the islands are rasterised from the mesh's own UVs), so mipmaps and JPEG never blend a dark
gutter into an island edge: that was the seam line down the middle of the characters. Geometry, skins and
animations are copied untouched.
Run: python3 -I tools/shrink_glb.py IN.glb OUT.glb [MAX_SIDE]"""
from __future__ import annotations

import io
import json
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw

JPEG_QUALITY = 88
PAD_ROUNDS = 48
COMPONENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
FORMATS = {5126: "<f", 5125: "<I", 5123: "<H", 5121: "<B"}
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


def accessor(doc: dict, blob: bytes, index: int) -> list:
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    width = COMPONENTS[acc["type"]]
    fmt = FORMATS[acc["componentType"]]
    size = struct.calcsize(fmt)
    stride = view.get("byteStride", size * width)
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    out = []
    for item in range(acc["count"]):
        base = start + item * stride
        out.append([struct.unpack_from(fmt, blob, base + c * size)[0] for c in range(width)])
    return out


def uv_mask(doc: dict, blob: bytes, image_index: int, size: tuple) -> np.ndarray:
    """Where the UV islands of every primitive textured by this image lie (True inside an island)."""
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    for mesh in doc.get("meshes", []):
        for prim in mesh["primitives"]:
            if "TEXCOORD_0" not in prim["attributes"] or not _uses_image(doc, prim, image_index):
                continue
            uvs = accessor(doc, blob, prim["attributes"]["TEXCOORD_0"])
            order = [i[0] for i in accessor(doc, blob, prim["indices"])] if "indices" in prim else range(len(uvs))
            order = list(order)
            for tri in range(0, len(order) - 2, 3):
                draw.polygon([(uvs[order[tri + k]][0] * size[0], uvs[order[tri + k]][1] * size[1]) for k in range(3)],
                             fill=255, outline=255)
    return np.array(mask) > 0


def _uses_image(doc: dict, prim: dict, image_index: int) -> bool:
    material = doc.get("materials", [{}])[prim.get("material", 0)]
    texture = material.get("pbrMetallicRoughness", {}).get("baseColorTexture")
    return texture is not None and doc["textures"][texture["index"]]["source"] == image_index


def pad(image: Image.Image, mask: np.ndarray) -> Image.Image:
    """Grows the island colours outward into the gutters, one pixel ring per round."""
    colour = np.array(image).astype(np.float32)
    filled = mask.copy()
    for _ in range(PAD_ROUNDS):
        total = np.zeros_like(colour)
        count = np.zeros(filled.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            shifted = np.roll(filled, (dy, dx), (0, 1))
            total += np.roll(colour, (dy, dx), (0, 1)) * shifted[..., None]
            count += shifted
        grow = (~filled) & (count > 0)
        colour[grow] = total[grow] / count[grow][..., None]
        filled |= grow
    return Image.fromarray(colour.clip(0, 255).astype(np.uint8))


def shrink_image(raw: bytes, max_side: int, mask: np.ndarray | None = None) -> bytes:
    image = Image.open(io.BytesIO(raw)).convert("RGB")
    if mask is not None and mask.any():
        image = pad(image, mask)
    image.thumbnail((max_side, max_side), Image.LANCZOS)
    out = io.BytesIO()
    image.save(out, "JPEG", quality=JPEG_QUALITY)
    return out.getvalue()


def rebuild(doc: dict, blob: bytes, max_side: int) -> bytes:
    image_views = {img["bufferView"]: img for img in doc.get("images", []) if "bufferView" in img}
    image_index = {img["bufferView"]: i for i, img in enumerate(doc.get("images", [])) if "bufferView" in img}
    out = bytearray()
    for index, view in enumerate(doc["bufferViews"]):
        chunk = blob[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
        if index in image_views:
            size = Image.open(io.BytesIO(chunk)).size
            chunk = shrink_image(chunk, max_side, uv_mask(doc, blob, image_index[index], size))
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
