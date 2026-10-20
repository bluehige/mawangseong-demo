"""External mockup only. Composite GPT artwork; never draw/recolor materials."""
from pathlib import Path
import json, shutil
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent
V6=ROOT.parent/'assets_v6'
SIZE=(3712,2432)

def write(name,data):
    (ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

# Four unique source images, each used ONCE at native 1:1. No reflections.
patches=[
    ('cave_floor.png',(254,1024)),
    ('cave_floor_b.png',(1050,510)),
    ('cave_floor_c.png',None),
    ('cave_floor_d.png',None),
]
ims=[Image.open(ROOT/'source'/n).convert('RGB') for n,_ in patches]
patches[2]=(patches[2][0],(3459-ims[2].width,510))
patches[3]=(patches[3][0],(1150,2115-ims[3].height))
coverage=np.zeros((SIZE[1],SIZE[0]),dtype=np.float32)
# Opaque center, 64px overlap feather: only an assembly opacity mask.
accum=np.zeros((SIZE[1],SIZE[0],3),dtype=np.float32)
records=[]
for (name,(x,y)),im in zip(patches,ims):
    h,w=im.height,im.width
    yy,xx=np.mgrid[0:h,0:w]
    edge=np.minimum.reduce([xx+1,w-xx,yy+1,h-yy])
    weight=np.minimum(edge/64,1).astype(np.float32)
    # Prioritize later patches, keeping transitions narrow and detailed.
    old=coverage[y:y+h,x:x+w]
    alpha=weight
    accum[y:y+h,x:x+w]*=(1-alpha[...,None])
    accum[y:y+h,x:x+w]+=np.asarray(im,dtype=np.float32)*alpha[...,None]
    coverage[y:y+h,x:x+w]=old*(1-alpha)+alpha
    records.append(dict(source='source/'+name,world_xy=[x,y],size=[w,h],scale=1,flipped=False,placements=1,feather_pixels=64))
mask=np.asarray(Image.open(V6/'layers/ground_area_mask.png'))
assert coverage[mask>0].min()>0, float(coverage[mask>0].min())
# Normalization affects opacity only, not palette or per-source lighting.
arr=np.divide(accum,coverage[...,None],out=np.zeros_like(accum),where=coverage[...,None]>0)
field=Image.fromarray(np.clip(np.rint(arr),0,255).astype('uint8'))
box=Image.open(V6/'layers/ground_area_mask.png').getbbox()
field.crop(box).save(ROOT/'textures/cave_floor_continuous.png')
write('checks/floor_assembly.json',dict(patches=records,source_count=4,new_source_count=3,flip_count=0,repeat_count=0,field_bbox=list(box),native_scale=1,uncovered_pixels=int((coverage[mask>0]<=0).sum()),processing='Only native 1:1 placement and overlap alpha compositing, no material drawing, recolor, filtering or synthetic texture.'))

text=(ROOT/'assemble.py').read_text(encoding='utf-8')
def replace(old,new):
    global text
    assert text.count(old)==1,(text.count(old),old[:120])
    text=text.replace(old,new)
replace('N = Image.Resampling.NEAREST','N = Image.Resampling.LANCZOS')
replace("tile=source.resize((768,512),N if cat=='road' else L)",
        "tile=source.resize((512,round(source.height*512/source.width)),L) if cat=='road' else source.resize((768,round(source.height*768/source.width)),L)")
# Floor field is already assembled from unique once-only patches.
replace("floor_layer.paste(floor_texture.resize((plot_box[2]-plot_box[0],plot_box[3]-plot_box[1]),N),plot_box[:2])",
        "assert floor_texture.size==(plot_box[2]-plot_box[0],plot_box[3]-plot_box[1]); floor_layer.paste(floor_texture,plot_box[:2])")
# Only road fill gets unreflected repeats; curbs/water retain exact v6 assembly.
replace("periodic=mirrored_field(tile,(tile.width*2,tile.height*2))",
        "periodic=plain_field(tile,(tile.width*2,tile.height*2)) if cat=='road' else mirrored_field(tile,(tile.width*2,tile.height*2))")
replace("assert seam_lr==0 and seam_tb==0","assert cat=='road' or (seam_lr==0 and seam_tb==0)")
replace("field=mirrored_field(tile,SIZE).convert('RGBA')",
        "field=(plain_field(tile,SIZE) if cat=='road' else mirrored_field(tile,SIZE)).convert('RGBA')")
replace("oldview=Image.open(V4/'preview_full.png').convert('RGB')",
        "oldview=Image.open((ROOT.parent/'assets_v6')/'preview_full.png').convert('RGB')")
replace("compare.save(ROOT/'compare_v4_v5.png')","compare.save(ROOT/'compare_v6_v7.png')")
replace("preview(1.6,P(3,8.5)).save(ROOT/'entrance_close.png')",
        "preview(.96,P(3,8.5)).save(ROOT/'entrance_close.png')")
replace("im=camera(composite,1.65,P(*xy),(960,540)).convert('RGB')",
        "im=camera(composite,.96,P(*xy),(960,540)).convert('RGB')")
replace("ground_tiled=False,ground_mirrored=False,entrance_regenerations=1",
        "ground_tiled=False,ground_mirrored=False,entrance_regenerations=0")
replace("print('v5 assembled. Direct visual review and verify.py remain.')",
        "print('v7 assembled; placements, interiors and entrance unchanged from v6.')")

def plain_field(im,size):
    out=Image.new(im.mode,size)
    for y in range(0,size[1],im.height):
        for x in range(0,size[0],im.width):out.paste(im,(x,y))
    return out

namespace={'__file__':str(ROOT/'assemble.py'),'__name__':'__main__','plain_field':plain_field}
exec(compile(text,'v7 material-only adapter of unchanged assembler','exec'),namespace)
preview=namespace['preview'];P=namespace['P']
close=Image.new('RGB',(1920,1080))
for i,xy in enumerate([(15.5,9),(22.5,9),(17,13.5),(25,5)]):
    im=namespace['camera'](namespace['composite'],.96,P(*xy),(960,540)).convert('RGB')
    close.paste(im,((i%2)*960,(i//2)*540))
close.save(ROOT/'road_close.png')
# Native scale source road, ready for global screen-space texture sampling.
Image.open(ROOT/'source/road_texture.png').resize((512,256),Image.Resampling.LANCZOS).save(ROOT/'textures/road_material.png')
# Collect only runtime artwork and record pivots in a separate packing step.
print('Once-only 4-patch floor, no enlargement; road material 512x256.')
