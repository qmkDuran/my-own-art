"""Quick PIL composite of the new-earth layout (no Godot) for layout review."""
import json
from PIL import Image
D = 'game/art/earth/'
L = json.load(open(D + 'layout.json'))
bg = Image.open(D + 'ebg.png').convert('RGBA')
objs = []
for n, x, y in L['houses']:
    im = Image.open(D + n + '.png'); objs.append((y, im, (x - im.width // 2, y - im.height)))
v = Image.open(D + 'vines.png')
for x0, y in L['vine_rows']:
    for k in range(L['vine_segments']): objs.append((y, v, (x0 + k * (v.width - 2), y - v.height)))
hay = Image.open(D + 'hay.png'); hx, hy = L['hay']; objs.append((hy, hay, (hx - hay.width // 2, hy - hay.height)))
for n, x, y in L['animals']:
    s = Image.open(D + 'an_' + n + '.png'); w = s.width // 2; im = s.crop((0, 0, w, s.height)); objs.append((y, im, (x - w // 2, y - im.height)))
for n, x, y in L['trees']:
    s = Image.open(D + n + '.png'); im = s.crop((0, 0, 128, 128)); objs.append((y, im, (x - 64, y - 112)))
hero = Image.open('game/art/hero.png').crop((0, 0, 64, 64)); objs.append((660, hero, (630 - 32, 660 - 61)))
for y, im, p in sorted(objs, key=lambda o: o[0]): bg.alpha_composite(im, p)
bg.save('art/work/emock.png')
