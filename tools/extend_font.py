"""Adds the punctuation the NIV text needs (curly quotes, dashes, ellipsis, (R), TM, e-acute) to the CC0 monogram font
as hand-drawn pixel glyphs on its own grid (64 units = 1 px, 5x7 cell, baseline at row 0).
Usage: python3 -I tools/extend_font.py  -> game/fonts/monogram_ext.ttf"""
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

SRC, DST = 'game/fonts/monogram.ttf', 'game/fonts/monogram_ext.ttf'
PX = 64
# rows listed top to bottom; `top` is the row index (from baseline) of the first listed row
GLYPHS = {
    0x2018: (6, ["..#", ".#.", ".#."], 6),                     # ‘
    0x2019: (6, ["..#", "..#", ".#."], 6),                     # ’
    0x201C: (6, ["..#.#", ".#.#.", ".#.#."], 6),               # “
    0x201D: (6, [".#.#.", ".#.#.", "#.#.."], 6),               # ”
    0x2013: (3, ["#####"], 6),                                 # –
    0x2014: (3, ["#######"], 8),                               # —
    0x2026: (0, ["#.#.#"], 6),                                 # …
    0x00AE: (6, [".#####.", "#.....#", "#.##..#", "#.#.#.#", "#.##..#", "#.#.#.#", ".#####."], 8),   # ®
    0x2122: (6, ["###.#...#", ".#..##.##", ".#..#.#.#"], 10),  # ™
    0x00E9: (7, ["..#", ".#.", ".###.", "#...#", "#####", "#....", ".####"], 6),                    # é
}


def glyph(top, rows):
    pen = TTGlyphPen(None)
    for r, line in enumerate(rows):
        y = (top - r) * PX
        for c, ch in enumerate(line):
            if ch == '#':
                x = c * PX
                pen.moveTo((x, y)); pen.lineTo((x, y + PX)); pen.lineTo((x + PX, y + PX)); pen.lineTo((x + PX, y)); pen.closePath()
    return pen.glyph()


def main():
    f = TTFont(SRC)
    order = f.getGlyphOrder()
    for cp, (top, rows, adv) in GLYPHS.items():
        name = 'uni%04X' % cp
        if name not in order:
            order.append(name)
        f['glyf'][name] = glyph(top, rows)
        f['hmtx'][name] = (adv * PX, 0)
        for t in f['cmap'].tables:
            if t.isUnicode():
                t.cmap[cp] = name
    f.setGlyphOrder(order)
    f.save(DST)
    cm = TTFont(DST).getBestCmap()
    print('added', [chr(c) for c in GLYPHS if c in cm])


if __name__ == '__main__':
    main()
