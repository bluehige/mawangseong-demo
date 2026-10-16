"""Compose GPT artwork only. Masks describe AREA coverage, never painted art.

No game writes, Godot, commits, background removal or synthetic art.
"""
from pathlib import Path
from collections import defaultdict
import json, math, hashlib, shutil, subprocess
import numpy as np
from PIL import Image, ImageOps, ImageDraw

ROOT = Path(__file__).resolve().parent
BASE = ROOT.parent / 'assets_v2'
V3 = ROOT.parent / 'assets_v3'
REPO = Path('C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action')
L = Image.Resampling.LANCZOS
N = Image.Resampling.NEAREST
V4 = ROOT.parent / "assets_v4"
SIZE = (3712, 2432)
W, H = 32, 18
OFF = (2304, 512)
def P(x, y): return round(64*(x+y-W)+OFF[0]), round(32*(y+W-x)+OFF[1])
def cp(x, y): return P(x+.5, y+.5)
def put(canvas, im, anchor, pivot):
    canvas.alpha_composite(im, (round(anchor[0]-pivot[0]), round(anchor[1]-pivot[1])))
def ground(canvas, im, center): put(canvas, im, center, (im.width/2, im.height/2))
def save_json(name, data):
    (ROOT/name).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

plan = (ROOT.parent/'plan/plan_E_cells.txt').read_text(encoding='utf-8-sig')
rows = [s for s in plan.splitlines() if s and not s.startswith('#')]
assert len(rows) == H and all(len(s) == W for s in rows)
buildings = json.loads(next(s.split(':',1)[1] for s in plan.splitlines() if s.startswith('# buildings:')))
def cell(chars, x, y): return 0 <= x < W and 0 <= y < H and rows[y][x] in chars
assets = {str(p.relative_to(BASE).with_suffix('')).replace('\\','/'): Image.open(p).convert('RGBA')
          for cat in ('B_floor','E_bridge','F_building','G_traps','H_edges')
          for p in (BASE/cat).glob('*.png')}
for name in ('spikes','sticky'):
    assets['G_traps/'+name] = Image.open(ROOT/'traps'/(name+'.png')).convert('RGBA')
for folder in ('textures', 'edges/road', 'edges/water', 'edges/cliff', 'layers', 'interiors'):
    (ROOT/folder).mkdir(parents=True, exist_ok=True)

# All visible pixels come from GPT outputs. Native transparency is inspected,
# not inferred from extension or checkerboard appearance.
alpha_records = []
for name in ('road_edges','water_edges','cliff_edges'):
    im = Image.open(ROOT/'source'/(name+'.png'))
    assert im.mode == 'RGBA', name
    a = np.asarray(im.getchannel('A'))
    assert a.min() == 0 and a.max() >= 240 and (a == 0).sum() > a.size*.25, name
    alpha_records.append(dict(id=name,size=list(im.size),mode=im.mode,
                              minimum=int(a.min()),maximum=int(a.max()),
                              zero_alpha_pixels=int((a==0).sum()),native_alpha=True))
save_json('alpha_validation.json', alpha_records)

def crop_native(im):
    box = im.getchannel('A').point(lambda a: 255 if a > 12 else 0).getbbox()
    assert box
    return im.crop(box)

def flatten_rail(im):
    """Geometric assembly transform: unskew a GENERATED rail, preserving alpha.
    This uses the silhouette only to measure orientation, never to key/remove it.
    """
    im = crop_native(im)
    a = np.asarray(im.getchannel('A'))
    xs = np.arange(round(im.width*.08),round(im.width*.92))
    tops = np.array([np.flatnonzero(a[:,x]>100)[0] for x in xs])
    m,b = np.polyfit(xs,tops,1)
    residual = tops - m*xs
    top = float(np.median(residual)) - 4
    heights = [np.flatnonzero(a[:,x]>60)[-1]-m*x-top for x in xs]
    height = math.ceil(max(heights))+5
    out = im.transform((im.width,height),Image.Transform.AFFINE,(1,0,0,m,1,top),Image.Resampling.BICUBIC)
    # Remove terminal faces by a rectangular crop, retaining the native alpha.
    out = out.crop((round(out.width*.10),0,round(out.width*.90),height))
    return crop_native(out),float(m)

def mirrored_field(im, size):
    """Assembly of alternating mirrored repeats: opposite repeat edges coincide.
    No crossfade, repainting or seam filter. Independent of plot cell positions.
    """
    out = Image.new(im.mode, size)
    for j,y in enumerate(range(0,size[1],im.height)):
        for i,x in enumerate(range(0,size[0],im.width)):
            tile = ImageOps.mirror(im) if i%2 else im
            if j%2: tile = ImageOps.flip(tile)
            out.paste(tile,(x,y))
    return out

rails = {}; corners = {}; geometry = []
for cat in ('road','water'):
    im = Image.open(ROOT/'source'/(cat+'_edges.png')).convert('RGBA')
    hw,hh = im.width//2,im.height//2
    for i,side in enumerate(('down','up')):
        part=im.crop((i*hw,0,(i+1)*hw,hh))
        flat,slope=flatten_rail(part)
        flat=flat.resize((128,13 if cat=='road' else 8),N if cat=='road' else L)
        flat.save(ROOT/'edges'/cat/('straight_'+side+'_flat.png'))
        rails[cat,side]=flat
        geometry.append(dict(id=cat+'/'+side,source_measured_slope=slope,assembled_slope=.5 if side=='down' else -.5,unit_horizontal_span=128))
    for i,kind in enumerate(('outer','inner')):
        part=crop_native(im.crop((i*hw,hh,(i+1)*hw,im.height)))
        part=part.resize((32,round(part.height*32/part.width)),L)
        corners[cat,kind]=part
        part.save(ROOT/'edges'/cat/(kind+'_corner.png'))
save_json('part_geometry.json',geometry)

cliff=Image.open(ROOT/'source/cliff_edges.png').convert('RGBA')
cliff_rails={}
for side,box in [('down',(0,0,cliff.width,565)),('up',(0,565,cliff.width,cliff.height))]:
    flat,slope=flatten_rail(cliff.crop(box))
    # Continuous load-bearing faces: one generated rail along each front side.
    flat.save(ROOT/'edges/cliff'/('straight_'+side+'_flat.png'))
    cliff_rails[side]=flat

world=Image.new('RGBA',SIZE)
def sloped_strip(flat, width, slope, height=None, repeat=True):
    height=height or flat.height
    unit=flat.resize((flat.width,height),L)
    band=mirrored_field(unit,(width,height)) if repeat else flat.resize((width,height),L)
    rise=round(abs(slope)*width)
    im=band.transform((width,height+rise),Image.Transform.AFFINE,
                      (1,0,0,-slope,1,-rise if slope<0 else 0),Image.Resampling.BICUBIC)
    return im

for cat in ('road','water'):
    for side in ('down','up'):
        sloped_strip(rails[cat,side],128,.5 if side=='down' else -.5).save(ROOT/'edges'/cat/('edge_'+side+'_128.png'))

# Geological front faces BEFORE ground; floor overlaps their upper lips.
for a,b,side in [((0,0),(0,H),'down'),((0,H),(W,H),'up')]:
    pa,pb=P(*a),P(*b);width=pb[0]-pa[0]
    part=sloped_strip(cliff_rails[side],width,.5 if side=='down' else -.5,175,False)
    world.alpha_composite(part,(pa[0],min(pa[1],pb[1])-7))
for x in range(W):
    if not cell('~B',x,0): put(world,assets['H_edges/edge_nw'],P(x,1),(64,196))
for y in range(H):
    if not cell('~B',W-1,y): put(world,assets['H_edges/edge_ne'],P(W-1,y+1),(64,196))
# v4: the old per-cell floor placements are deliberately omitted.

def area_mask(cells):
    mask=Image.new('L',(SIZE[0]*2,SIZE[1]*2))
    d=ImageDraw.Draw(mask)
    for x,y in cells:
        poly=[P(x,y),P(x+1,y),P(x+1,y+1),P(x,y+1)]
        d.polygon([(a*2,b*2) for a,b in poly],fill=255)
    return mask.resize(SIZE,L)

# v4: place a single continuous ground image across the entire plot.
# The only code-created pixels are COVERAGE/OPACITY masks used for assembly.
floor_texture=Image.open(ROOT/'textures/cave_floor_continuous.png').convert('RGB')
floor_mask=area_mask({(x,y) for y in range(H) for x in range(W)})
floor_mask.save(ROOT/'layers/ground_area_mask.png')
plot_box=floor_mask.getbbox()
floor_layer=Image.new('RGBA',SIZE)
floor_layer.paste(floor_texture.resize((plot_box[2]-plot_box[0],plot_box[3]-plot_box[1]),N),plot_box[:2])
floor_layer.putalpha(floor_mask)
floor_layer.save(ROOT/'layers/ground_continuous_fill.png')
world.alpha_composite(floor_layer)

def boundary(cells):
    # Each shared edge is deliberately excluded; all turns are area turns.
    edge_set=[];group=defaultdict(list)
    for x,y in sorted(cells):
        for neighbor,a,b,axis,fixed,start in [
            ((x,y-1),(x,y),(x+1,y),'x',y,x),
            ((x,y+1),(x,y+1),(x+1,y+1),'x',y+1,x),
            ((x-1,y),(x,y),(x,y+1),'y',x,y),
            ((x+1,y),(x+1,y),(x+1,y+1),'y',x+1,y)]:
            if neighbor not in cells:
                group[axis,fixed].append(start)
                edge_set.append((a,b))
    runs=[]
    for (axis,fixed),values in sorted(group.items()):
        values=sorted(set(values));start=previous=values[0]
        for value in values[1:]+[10**6]:
            if value != previous+1:
                a=(start,fixed) if axis=='x' else (fixed,start)
                b=(previous+1,fixed) if axis=='x' else (fixed,previous+1)
                runs.append((a,b));start=value
            previous=value
    return edge_set,runs

reports=[];all_placements=[]
for cat,chars in [('water','~B'),('road','=Xm')]:
    cells={(x,y) for y in range(H) for x in range(W) if cell(chars,x,y)}
    mask=area_mask(cells);mask.save(ROOT/'layers'/(cat+'_area_mask.png'))
    # ImageDraw only touches COVERAGE masks. ALL material pixels are GPT art.
    source=Image.open(ROOT/'source'/(cat+'_texture.png')).convert('RGB')
    assert source.width>=1024 and source.height>=512
    tile=source.resize((768,512),N if cat=='road' else L)
    # Four rectangular placements form an exactly periodic assembled texture.
    # Raw GPT originals are preserved, including their unaltered edge pixels.
    periodic=mirrored_field(tile,(tile.width*2,tile.height*2))
    periodic.save(ROOT/'textures'/(cat+'_texture.png'))
    pixels=np.asarray(periodic,dtype=np.int16)
    seam_lr=int(np.abs(pixels[:,0]-pixels[:,-1]).max())
    seam_tb=int(np.abs(pixels[0]-pixels[-1]).max())
    assert seam_lr==0 and seam_tb==0
    field=mirrored_field(tile,SIZE).convert('RGBA')
    field.putalpha(mask)
    field.save(ROOT/'layers'/(cat+'_continuous_fill.png'))
    world.alpha_composite(field)
    edges,runs=boundary(cells)
    boundary_layer=Image.new('RGBA',SIZE)
    for a,b in runs:
        pa,pb=P(*a),P(*b);width=pb[0]-pa[0]
        side='down' if pb[1]>pa[1] else 'up'
        art=sloped_strip(rails[cat,side],width,.5 if side=='down' else -.5)
        boundary_layer.alpha_composite(art,(pa[0],min(pa[1],pb[1])-3))
        all_placements.append(dict(category=cat,kind='outer_boundary_run',start=a,end=b))
    turn_count=0
    for vy in range(H+1):
        for vx in range(W+1):
            adjacent=[(vx-1,vy-1),(vx,vy-1),(vx,vy),(vx-1,vy)]
            q=[xy in cells for xy in adjacent]
            if sum(q) not in (1,3): continue
            kind='outer' if sum(q)==1 else 'inner'
            index=q.index(True) if kind=='outer' else q.index(False)
            part=corners[cat,kind]
            pivot=(part.width/2,part.height-3)
            if index==3:
                pivot=(pivot[0],part.height-1-pivot[1]);part=ImageOps.flip(part)
            elif index==0:
                # Rotate in GROUND space: screen x scales by 2, y by 1/2.
                pivot=(2*pivot[1],(part.width-1-pivot[0])/2)
                part=part.transpose(Image.Transpose.ROTATE_90)
                part=part.resize((part.width*2,round(part.height/2)),L)
            elif index==2:
                pivot=(2*(part.height-1-pivot[1]),pivot[0]/2)
                part=part.transpose(Image.Transpose.ROTATE_270)
                part=part.resize((part.width*2,round(part.height/2)),L)
            # The generated elbow overlaps just 1/4-cell of the two rails.
            p=P(vx,vy)
            put(boundary_layer,part,p,pivot);turn_count+=1
            all_placements.append(dict(category=cat,kind=kind+'_corner',vertex=[vx,vy]))
    boundary_layer.save(ROOT/'layers'/(cat+'_boundary_only.png'))
    world.alpha_composite(boundary_layer)
    internal=[]
    for x,y in cells:
        for dx,dy in [(1,0),(0,1)]:
            if (x+dx,y+dy) in cells:
                internal.append(((x+1,y),(x+1,y+1)) if dx else ((x,y+1),(x+1,y+1)))
    edgekeys={tuple(sorted(e)) for e in edges}
    internal_hits=sum(tuple(sorted(e)) in edgekeys for e in internal)
    coverage=np.asarray(mask)
    # Test the middle of each shared edge: no mask seam, and no curb there.
    alphas=[];border_hits=0
    ba=np.asarray(boundary_layer.getchannel('A'))
    for a,b in internal:
        pa,pb=P(*a),P(*b);px,py=round((pa[0]+pb[0])/2),round((pa[1]+pb[1])/2)
        alphas.append(int(coverage[py,px]));border_hits+=int(ba[py,px]>20)
    assert internal_hits==0 and min(alphas)==255 and border_hits==0,(cat,internal_hits,border_hits)
    reports.append(dict(category=cat,cells=len(cells),boundary_unit_edges=len(edges),merged_boundary_runs=len(runs),corners=turn_count,
                        shared_internal_edges=len(internal),internal_boundary_segments=internal_hits,
                        shared_edge_mask_minimum=min(alphas),shared_edge_curb_pixels=border_hits,
                        fill_operations=1,texture_mapping='single global screen-space mirrored repeat; no cell-local UV resets',
                        native_texture_size=list(source.size),assembled_texture_size=list(periodic.size),
                        periodic_opposite_edge_delta_left_right=seam_lr,periodic_opposite_edge_delta_top_bottom=seam_tb))

world.save(ROOT/'terrain_native.png')
# Existing bridge artwork is placed over the continuous water, once per group.
seen=set()
for y in range(H):
    for x in range(W):
        if not cell('B',x,y) or (x,y) in seen: continue
        todo=[(x,y)];group=[]
        while todo:
            a,b=todo.pop()
            if (a,b) in seen or not cell('B',a,b): continue
            seen.add((a,b));group.append((a,b));todo.extend([(a-1,b),(a+1,b),(a,b-1),(a,b+1)])
        center=P((min(a for a,b in group)+max(a for a,b in group)+1)/2,(min(b for a,b in group)+max(b for a,b in group)+1)/2)
        put(world,assets['E_bridge/bridge_water_y'],center,(128,64))

# Reuse ONLY the v2 object-placement block; do not execute v2 asset generation,
# road masks, perimeter assembly, output writes or any interiors generator.
source=(BASE/'assemble_preview.py').read_text(encoding='utf-8-sig')
block=source[source.index('objects=[];doorchecks=[]'):source.index('for _,im,anchor,pivot in sorted(objects')]
env=dict(world=world,P=P,cp=cp,put=put,ground=ground,cell=cell,rows=rows,buildings=buildings,W=W,H=H,
         assets=assets,Image=Image,ImageOps=ImageOps,REPO=REPO,L=L)
block=block.replace('(x//2+y//2)%2==0','(x+y)%2==0')
# Clear only the exterior rear lip of the entrance so the through-passage is visible.
block=block.replace("if not(side=='W' and (bx,y) in gap):obj('F_building/front_sw',bx,y+1,(64,80))","if not((side=='W' and (bx,y) in gap) or (b['code']=='E' and y in (by+1,by+2))):obj('F_building/front_sw',bx,y+1,(64,80))")
exec(compile(block,'v2 read-only object placement','exec'),env)
records=json.loads((BASE/'interiors/asset_inventory.json').read_text(encoding='utf-8'))
specs=json.loads((BASE/'interiors/specs.json').read_text(encoding='utf-8'))
bycode={s['code']:s for s in specs};interior_copies=[]
for b in buildings:
    s=bycode[b['code']];record=next(r for r in records if r['id']==s['id'])
    src=BASE/'interiors'/(s['id']+'.png');dst=ROOT/'interiors'/src.name
    if s['id']!='entrance':
        shutil.copy2(src,dst)
        assert hashlib.sha256(src.read_bytes()).digest()==hashlib.sha256(dst.read_bytes()).digest()
    bx,by,bw,bh=b['rect'];anchor=P(bx,by+bh);depth=P(bx+bw/2,by+bh/2)[1]+12
    if s['id']=='entrance':
        # Locate the generated mouth's ground lip at the unchanged EAST door.
        config=json.loads((ROOT/'assembly_config.json').read_text(encoding='utf-8'))
        anchor=P(*config['entrance_anchor_cell'])
        pivot=config['entrance_pivot']
    else: pivot=record['pivot']
    env['objects'].append((depth,Image.open(dst).convert('RGBA'),anchor,pivot))
    interior_copies.append(dict(id=s['id'],source=str(src),copy=str(dst.relative_to(ROOT)),sha256=hashlib.sha256(dst.read_bytes()).hexdigest()))
occlusion=Image.new('L',SIZE)
for _,im,anchor,pivot in sorted(env['objects'],key=lambda z:z[0]):
    put(world,im,anchor,pivot)
    alpha=im.getchannel('A')
    where=(round(anchor[0]-pivot[0]),round(anchor[1]-pivot[1]))
    layer=Image.new('L',SIZE);layer.paste(alpha,where)
    occlusion=Image.fromarray(np.maximum(np.asarray(occlusion),np.asarray(layer)))
occlusion.save(ROOT/'layers/object_occlusion_mask.png')
world.save(ROOT/'assembly_native.png')

# Painted cave background; absolutely no code-drawn gradient or vignette.
bg=Image.open(ROOT/'source/cave_background.png').convert('RGBA')
scale=.48;center=(1856,1260)
bg_size=(round(1920/scale),round(1080/scale))
bg_origin=(center[0]-bg_size[0]/2,center[1]-bg_size[1]/2)
bgplane=bg.resize(bg_size,L)
bgworld=bgplane.transform(SIZE,Image.Transform.AFFINE,(1,0,-bg_origin[0],0,1,-bg_origin[1]),Image.Resampling.BICUBIC)
composite=bgworld.copy();composite.alpha_composite(world);composite.save(ROOT/'assembly_cave_native.png')
def camera(im,factor,c,size=(1920,1080)):
    w,h=size
    return im.transform(size,Image.Transform.AFFINE,(1/factor,0,c[0]-w/2/factor,0,1/factor,c[1]-h/2/factor),Image.Resampling.BICUBIC)
def preview(factor,c):
    # Background covers the complete view even outside the native world canvas.
    background=camera(bgplane,factor,(c[0]-bg_origin[0],c[1]-bg_origin[1]))
    view=camera(world,factor,c)
    background.alpha_composite(view)
    return background.convert('RGB')
preview(scale,center).save(ROOT/'preview_full.png')
preview(scale*2,P(18,9)).save(ROOT/'preview_zoom2x.png')
oldview=Image.open(V4/'preview_full.png').convert('RGB')
compare=Image.new('RGB',(3840,1080));compare.paste(oldview,(0,0));compare.paste(Image.open(ROOT/'preview_full.png'),(1920,0));compare.save(ROOT/'compare_v4_v5.png')
preview(1.6,P(3,8.5)).save(ROOT/'entrance_close.png')
preview(.96,P(6.5,9)).save(ROOT/'checks/entrance_traps_zoom2x.png')
preview(.96,P(13,3)).save(ROOT/'checks/ground_left_zoom2x.png')
preview(.96,P(25,15)).save(ROOT/'checks/ground_right_zoom2x.png')
# Direct evidence crops of uninterrupted road junctions and canal junction.
review=Image.new('RGB',(1920,1080))
for i,xy in enumerate([(17,9),(24,9),(9,9),(17,12)]):
    im=camera(composite,1.65,P(*xy),(960,540)).convert('RGB');review.paste(im,((i%2)*960,(i//2)*540))
review.save(ROOT/'boundary_review.png')
save_json('placements.json',all_placements)

# Additional requested grayscale preview and camera-space masks for verification.
ImageOps.grayscale(Image.open(ROOT/'preview_full.png')).save(ROOT/'grayscale_check.png')
for name in ('road_area_mask','ground_area_mask','water_area_mask','object_occlusion_mask'):
    mask=Image.open(ROOT/'layers'/(name+'.png')).convert('RGBA')
    camera(mask,scale,center).getchannel('R').save(ROOT/'checks'/('preview_'+name+'.png'))
save_json('assembly_report.json',dict(areas=reports,interiors=interior_copies,ground_field_placements=1,ground_tiled=False,ground_mirrored=False,entrance_regenerations=1,artwork_drawn_by_code=False,background_removed=False,game_code_changed=False,godot_run=False,commit_made=False))
print('v5 assembled. Direct visual review and verify.py remain.')
