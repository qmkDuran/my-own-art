"""out/reference_sheet.png: the approved look at true relative scale on one sheet - Michael (idle, walk, slash), every
enemy, a praying person, key world pieces (houses, store, car, fence, lamp, tree, crate, waystone), the palette
swatches and the type sizes. Run from heaven/arpg/:  python3 art/reference_sheet.py"""
import sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, 'art')
import style   # noqa: E402

BG = (24, 22, 32)
INK = (240, 230, 200)


def frame(path, col=0, row=0, size=64):
    return Image.open(path).convert('RGBA').crop((col * size, row * size, col * size + size, row * size + size))


def main():
    f = ImageFont.truetype('game/fonts/PixelifySans.ttf', 20)
    fs = ImageFont.truetype('game/fonts/Silkscreen.ttf', 8)
    o = Image.new('RGBA', (1500, 980), BG); d = ImageDraw.Draw(o)
    d.fontmode = '1'
    d.text((12, 8), 'The Great Prince - approved reference (all at 1x game scale; see STYLE.md)', font=f, fill=INK)

    def row(y, label, items):
        d.text((12, y - 22), label, font=f, fill=INK)
        x = 12
        for name, im in items:
            o.alpha_composite(im, (x, y + 150 - im.height))
            d.text((x, y + 154), name, font=fs, fill=(200, 200, 210))
            x += im.width + 14
    mi = 'game/art/michael/'
    row(50, 'Michael', [('idle', frame(mi + 'idle.png')), ('walk', frame(mi + 'walk.png', 2)), ('side', frame(mi + 'walk.png', 2, 2)),
                        ('back', frame(mi + 'idle.png', 0, 1)), ('slash', frame(mi + 'slash.png', 4)), ('slash side', frame(mi + 'slash.png', 5, 2))])
    demons = ['swarmer', 'cinder', 'brute', 'ravager', 'mauler', 'caster', 'caller', 'stalker', 'locust', 'frog', 'firehorse']
    names = {'swarmer': 'imp', 'caster': 'shade'}
    row(250, 'Enemies (Mauler and Fire Horse are drawn 1.5x in game)', [(names.get(n, n), frame(f'game/art/demons/{n}.png')) for n in demons] +
        [('praying', frame('game/art/people/pray_a.png'))])
    z = 'game/art/zone/'
    pieces = ['house_c', 'store', 'car_wreck', 'van', 'fence_picket_broken', 'fence_chainlink', 'streetlight', 'tree_dead',
              'crate', 'lockbox', 'waystone_lit', 'trash_can', 'mailbox']
    items = [(n, Image.open(z + n + '.png').convert('RGBA')) for n in pieces]
    y = 470
    d.text((12, y - 22), 'World pieces (true scale next to Michael)', font=f, fill=INK)
    x = 12
    o.alpha_composite(frame(mi + 'idle.png'), (x, y + 300 - 64)); x += 70
    for n, im in items:
        if x + im.width > 1490: break
        o.alpha_composite(im, (x, y + 300 - im.height))
        d.text((x, y + 304), n, font=fs, fill=(200, 200, 210))
        x += max(im.width, 70) + 10
    d.text((12, 820), 'World palette (Michael\'s 20 colours + grass, embers, night blue, light)', font=f, fill=INK)
    for i, c in enumerate(style.WORLD):
        d.rectangle((12 + i * 46, 850, 12 + i * 46 + 40, 890), fill=style.H(c), outline=style.H(style.OUTLINE))
        d.text((12 + i * 46, 894), c, font=fs, fill=(200, 200, 210))
    d.text((12, 920), 'Type: Pixelify Sans 20 titles / 10 body, Silkscreen 8 labels and numbers', font=f, fill=INK)
    o.save('out/reference_sheet.png')
    print('reference sheet ok', o.size)


if __name__ == '__main__':
    main()
