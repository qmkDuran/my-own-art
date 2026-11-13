"""Copies the animation clips of Meshy animation GLBs into the rigged character GLB, so each character is one
file holding its mesh, skin and every clip. Nodes are matched by name; clips are renamed.
Run: python3 -I tools/merge_clips.py RIGGED.glb OUT.glb CLIP_NAME=ANIM.glb[#INDEX] ..."""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shrink_glb import read_glb, write_glb  # noqa: E402


def append_accessor(doc: dict, blob: bytearray, src_doc: dict, src_blob: bytes, index: int) -> int:
    accessor = dict(src_doc["accessors"][index])
    view = src_doc["bufferViews"][accessor["bufferView"]]
    start = view.get("byteOffset", 0)
    chunk = src_blob[start:start + view["byteLength"]]
    while len(blob) % 4:
        blob.append(0)
    doc["bufferViews"].append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(chunk)})
    blob += chunk
    accessor["bufferView"] = len(doc["bufferViews"]) - 1
    doc["accessors"].append(accessor)
    return len(doc["accessors"]) - 1


def copy_clip(doc: dict, blob: bytearray, name: str, src_path: str, clip_index: int) -> None:
    src_doc, src_blob = read_glb(src_path)
    node_by_name = {n.get("name"): i for i, n in enumerate(doc["nodes"])}
    source = src_doc["animations"][clip_index]
    samplers = []
    for sampler in source["samplers"]:
        samplers.append({"input": append_accessor(doc, blob, src_doc, src_blob, sampler["input"]),
                         "output": append_accessor(doc, blob, src_doc, src_blob, sampler["output"]),
                         "interpolation": sampler.get("interpolation", "LINEAR")})
    channels = []
    for channel in source["channels"]:
        node_name = src_doc["nodes"][channel["target"]["node"]].get("name")
        if node_name in node_by_name:
            channels.append({"sampler": channel["sampler"],
                             "target": {"node": node_by_name[node_name], "path": channel["target"]["path"]}})
    doc["animations"].append({"name": name, "samplers": samplers, "channels": channels})


def main() -> None:
    doc, base_blob = read_glb(sys.argv[1])
    blob = bytearray(base_blob)
    doc["animations"] = []
    for spec in sys.argv[3:]:
        name, source = spec.split("=", 1)
        path, _, index = source.partition("#")
        copy_clip(doc, blob, name, path, int(index or 0))
    while len(blob) % 4:
        blob.append(0)
    doc["buffers"] = [{"byteLength": len(blob)}]
    write_glb(sys.argv[2], doc, bytes(blob))


if __name__ == "__main__":
    main()
