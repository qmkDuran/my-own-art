# Credits

## Scripture
Scripture quotations taken from The Holy Bible, New International Version® NIV® Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.™ Used by permission. All rights reserved worldwide.

The game quotes 59 distinct verses (well under Biblica's 500-verse limit, and far from a complete book or 25% of the work).
All verse text lives in `game/data/verses.json`; every fragment is checked word for word against the NIV text
(fetched from biblegateway.com by `tools/fetch_niv.py`) by `tools/check_verses.py`.

## Font
monogram by datagoblin, CC0 (https://datagoblin.itch.io/monogram). `game/fonts/monogram_ext.ttf` adds hand-drawn glyphs
for ‘ ’ “ ” – — … ® ™ é (`tools/extend_font.py`), same CC0 terms. See `game/fonts/LICENSE-monogram.txt`.

## Audio
All sound is original procedural audio (CC0). See `game/audio/CREDITS.md`. The worship hymn arranges NICAEA (J. B. Dykes, 1861, public domain).

## Art
Pixel art generated with PixelLab and finished by hand (scripts in `art/`), Resurrect 64 palette.
