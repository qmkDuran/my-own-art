from PIL import Image, ImageChops
A='game/art/'
bg=Image.open(A+'bg.png').convert('RGBA')
wa=Image.open(A+'water_a.png'); wb=Image.open(A+'water_b.png')
for x in range(0,960,240): bg.alpha_composite(wa,(x,272)); bg.alpha_composite(wb,(x+60,272))
bg.alpha_composite(Image.open(A+'bridge.png'),(424,268))
hero=Image.open(A+'hero.png').crop((0,0,64,64))
trees=[('tree1',90,262),('tree2',290,262),('tree1',670,262),('tree2',870,262),('tree2',140,406),('tree1',330,406),('tree2',630,406),('tree1',830,406)]
objs=[(y,'t',n,x) for n,x,y in trees]+[(470,'h',None,480)]
for y,k,n,x in sorted(objs):
    if k=='t':
        im=Image.open(A+n+'.png'); bg.alpha_composite(im,(x-62,y-118))
    else: bg.alpha_composite(hero,(x-32,y-61))
def add(img,ov,pos):
    layer=Image.new('RGBA',img.size); layer.alpha_composite(ov,pos)
    a=layer.split()[3].point(lambda v:v/255)
    rgb=Image.composite(layer,Image.new('RGBA',img.size),layer)
    import numpy as np
    I=np.array(img).astype(float); L=np.array(layer).astype(float)
    I[...,:3]=np.minimum(255,I[...,:3]+L[...,:3]*L[...,3:4]/255); return Image.fromarray(I.astype('uint8'))
bg=add(bg,Image.open(A+'glow_throne.png'),(-180,140))
bg=add(bg,Image.open(A+'glow_gate.png'),(380,0))
bg.save('art/work/mock.png'); bg.resize((1920,1080),0).save('art/work/mock2x.png')
