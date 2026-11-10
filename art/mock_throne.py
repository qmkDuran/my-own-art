import json
import numpy as np
from PIL import Image
D='game/art/throne/'
L=json.load(open(D+'layout.json'))
bg=Image.open(D+'tbg.png').convert('RGBA')
def add(img,ov,pos):
    layer=Image.new('RGBA',img.size); layer.alpha_composite(ov,pos)
    I=np.array(img).astype(float); Lr=np.array(layer).astype(float)
    I[...,:3]=np.minimum(255,I[...,:3]+Lr[...,:3]*Lr[...,3:4]/255); return Image.fromarray(I.astype('uint8'))
ang=Image.open(D+'angels.png'); n=ang.width//32
k=0
for row,(y,step,off) in enumerate([(30,26,0),(52,28,13),(78,30,6)]):
    for x in range(off,960,step):
        if abs(x+16-480)<150: continue
        a=ang.crop(((k%n)*32,0,(k%n)*32+32,32)); k+=7
        bg.alpha_composite(a,(x,y-30))
bg=add(bg,Image.open(D+'throne_glow.png'),(160,-46))
bg.alpha_composite(Image.open(D+'throne_core.png'),(480-40,154-124))
bg=add(bg,Image.open(D+'rays.png'),(160,-46))
fl=Image.open(D+'flame.png').crop((0,0,7,9))
for lx,ly in L['lamps']: bg.alpha_composite(fl,(lx-3,ly-26-9))
objs=[]
for c,x,y in L['creatures']:
    im=Image.open(D+'creature_%s.png'%c); b=im.getbbox(); objs.append((y,im,(x-56,y-b[3])))
lamb=Image.open(D+'lamb.png'); objs.append((L['lamb'][1],lamb,(L['lamb'][0]-24,L['lamb'][1]-41)))
for e in L['elders']:
    im=Image.open(D+'elder%d.png'%e['variant']).crop((0,0,64,64))
    if e['face']<0: im=im.transpose(Image.FLIP_LEFT_RIGHT)
    objs.append((e['y'],im,(e['x']-32,e['y']-62)))
    bw=Image.open(D+'bowl.png'); objs.append((e['y']+6,bw,(e['x']+e['face']*24-5,e['y']+1)))
hero=Image.open('game/art/hero.png').crop((0,64,64,128)); objs.append((470,hero,(480-32,470-61)))
for y,im,p in sorted(objs,key=lambda o:o[0]): bg.alpha_composite(im,p)
bg.save('art/work/tmock.png')
