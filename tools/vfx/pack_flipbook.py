"""Packs rendered flipbook frames (NAME_01.png ...) into one square sheet, row by row, for Godot's particle
animation (h_frames x v_frames). Run: python3 -I tools/vfx/pack_flipbook.py FRAMES_DIR NAME OUT.png [COLUMNS]"""
import math
import sys
from pathlib import Path

from PIL import Image


def main() -> None:
    folder, name, out = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
    frames = sorted(folder.glob(f"{name}_*.png"))
    columns = int(sys.argv[4]) if len(sys.argv) > 4 else math.ceil(math.sqrt(len(frames)))
    tile = Image.open(frames[0]).size
    rows = math.ceil(len(frames) / columns)
    sheet = Image.new("RGBA", (tile[0] * columns, tile[1] * rows), (0, 0, 0, 0))
    for index, path in enumerate(frames):
        sheet.paste(Image.open(path).convert("RGBA"), ((index % columns) * tile[0], (index // columns) * tile[1]))
    sheet.save(out, optimize=True)
    print(f"{out}: {len(frames)} frames, {columns}x{rows}, {sheet.size[0]}x{sheet.size[1]} px")


if __name__ == "__main__":
    main()
