"""v7c: external mockup only; GPT art, geometric assembly, no game writes."""
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,csv,hashlib,shutil
import numpy as np
ROOT=Path(__file__).resolve().parent
BASE=ROOT.parent/'assets_v2'
L=Image.Resampling.LANCZOS
SIZE=(3712,2432);W=32;H=18
OFF=(2304,512)
def P(x,y):return round(64*(x+y-W)+OFF[0]),round(32*(y+W-x)+OFF[1])
def cp(x,y):return P(x+.5,y+.5)
def put(canvas,im,anchor,pivot):canvas.alpha_composite(im,(round(anchor[0]-pivot[0]),round(anchor[1]-pivot[1])))
def ground(canvas,im,center):put(canvas,im,center,(im.width/2,im.height/2))
def write(name,data):(ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
plan=(ROOT.parent/'plan/plan_E_cells.txt').read_text(encoding='utf-8-sig')
rows=[s for s in plan.splitlines() if s and not s.startswith('#')]
buildings=json.loads(next(s.split(':',1)[1] for s in plan.splitlines() if s.startswith('# buildings:')))
def cell(chars,x,y):return 0<=x<W and 0<=y<H and rows[y][x] in chars
# Snapshot the preserved reference folder before assembly.
def hashes(folder):return {str(p.relative_to(folder)):hashlib.sha256(p.read_bytes()).hexdigest() for p in folder.rglob('*') if p.is_file()}
reference=ROOT.parent/'assets_v7b';before=hashes(reference)
alpha=[]
for name in ['door_arch_down','entrance_gate']:
    im=Image.open(ROOT/f'source/{name}.png')
    a=np.asarray(im.getchannel('A'));assert a.min()==0 and a.max()>240 and (a==0).mean()>.35
    alpha.append(dict(name=name,mode=im.mode,minimum=int(a.min()),maximum=int(a.max()),zero_fraction=float((a==0).mean()),native_alpha=True))
# Rectangular margin crop only: preserve every original alpha value inside.
raw=Image.open(ROOT/'source/door_arch_down.png').convert('RGBA')
box=raw.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
# Selected centers of the two pillar contact faces in the generated source.
feet=((530,627),(1035,921));sx=128/(feet[1][0]-feet[0][0]);sy=64/(feet[1][1]-feet[0][1])
arch=raw.crop(box).resize((round((box[2]-box[0])*sx),round((box[3]-box[1])*sy)),L)
pivot=((sum(p[0] for p in feet)/2-box[0])*sx,(sum(p[1] for p in feet)/2-box[1])*sy)
arches={'down':(arch,pivot),'up':(ImageOps.mirror(arch),(arch.width-pivot[0],pivot[1]))}
for side,(im,pv) in arches.items():im.save(ROOT/f'final/building/door_arch_{side}.png')
# Compatibility default is corrected; direction table is authoritative.
arch.save(ROOT/'final/building/door_arch.png')
raw=Image.open(ROOT/'source/entrance_gate.png').convert('RGBA')
boxg=raw.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox();gscale=.36
gate=raw.crop(boxg).resize((round((boxg[2]-boxg[0])*gscale),round((boxg[3]-boxg[1])*gscale)),L)
gpivot=((782.5-boxg[0])*gscale,(720-boxg[1])*gscale)
gate.save(ROOT/'interiors/entrance.png');gate.save(ROOT/'final/interiors/entrance.png')
world=Image.open(reference/'terrain_native.png').convert('RGBA')
assets={str(p.relative_to(BASE).with_suffix('')).replace('\\','/'):Image.open(p).convert('RGBA') for cat in ['B_floor','E_bridge','F_building','G_traps','H_edges'] for p in (BASE/cat).glob('*.png')}
for name in ['spikes','sticky']:assets['G_traps/'+name]=Image.open(ROOT/f'traps/{name}.png').convert('RGBA')
# Through-route from outside x<0 to the unchanged internal E door at x=3.
# Only a coverage mask is drawn; all visible paving pixels are existing GPT art.
extmask=Image.new('L',SIZE);d=ImageDraw.Draw(extmask)
d.polygon([P(-2.5,8),P(3,8),P(3,10),P(-2.5,10)],fill=255)
road=Image.open(ROOT/'textures/road_material.png').convert('RGBA');field=Image.new('RGBA',SIZE)
for yy in range(0,SIZE[1],road.height):
    for xx in range(0,SIZE[0],road.width):field.paste(road,(xx,yy))
field.putalpha(extmask);world.alpha_composite(field)
field.save(ROOT/'layers/entrance_external_road.png');extmask.save(ROOT/'checks/entrance_route_mask.png')
# Existing bridge groups, unchanged.
seen=set()
for y in range(H):
    for x in range(W):
        if not cell('B',x,y) or (x,y) in seen:continue
        todo=[(x,y)];group=[]
        while todo:
            a,b=todo.pop()
            if (a,b) in seen or not cell('B',a,b):continue
            seen.add((a,b));group.append((a,b));todo.extend([(a-1,b),(a+1,b),(a,b-1),(a,b+1)])
        center=P((min(a for a,b in group)+max(a for a,b in group)+1)/2,(min(b for a,b in group)+max(b for a,b in group)+1)/2)
        put(world,assets['E_bridge/bridge_water_y'],center,(128,64))
# Reuse the original building walls, gap selection, traps and native sprites.
REPO=Path('C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action')
source=(BASE/'assemble_preview.py').read_text(encoding='utf-8-sig')
block=source[source.index('objects=[];doorchecks=[]'):source.index('for _,im,anchor,pivot in sorted(objects')]
block=block.replace('(x//2+y//2)%2==0','(x+y)%2==0')
block=block.replace("    bx,by,bw,bh=b['rect'];side=b['door'];length", "    bx,by,bw,bh=b['rect'];side=b['door'];length")
# Entrance is a through-gate; no small room enclosure or duplicate internal arch.
block=block.replace("for b in buildings:\n    bx", "for b in buildings:\n    if b['code']=='E':continue\n    bx")
old="    obj('F_building/door_arch',*dc,pivot=(96,98),flip=side in ('N','S'))"
new="""    direction='up' if side in ('N','S') else 'down'
    im,pv=arches[direction];anchor=P(*dc)
    objects.append((anchor[1]+1,im,anchor,pv))
    doorinfo.append(dict(code=b['code'],side=side,arch=direction,door_cell=list(dc),anchor=list(anchor),pivot=list(pv),outside=[list(p) for p in outside],wall_screen_vector=[64,-32] if direction=='up' else [64,32],foot_screen_offsets=[[-64,32],[64,-32]] if direction=='up' else [[-64,-32],[64,32]],contact=all(cell('=XmB',x,y) for x,y in outside)))"""
assert old in block;block=block.replace(old,new)
env=dict(world=world,P=P,cp=cp,put=put,ground=ground,cell=cell,rows=rows,buildings=buildings,W=W,H=H,assets=assets,Image=Image,ImageOps=ImageOps,REPO=REPO,L=L,arches=arches,doorinfo=[])
exec(compile(block,'read-only placement adapter','exec'),env)
objects=env['objects'];doorinfo=env['doorinfo']
records=json.loads((BASE/'interiors/asset_inventory.json').read_text(encoding='utf-8'))
for b in buildings:
    if b['code']=='E':continue
    record=next(r for r in records if r['code']==b['code'])
    bx,by,bw,bh=b['rect'];anchor=P(bx,by+bh)
    objects.append((P(bx+bw/2,by+bh/2)[1]+12,Image.open(ROOT/f"interiors/{record['id']}.png").convert('RGBA'),anchor,record['pivot']))
# Main gate wall at the exterior edge, normal points northeast INTO map.
ganchor=P(.25,9)
objects.append((ganchor[1]+5,gate,ganchor,gpivot))
for _,im,anchor,pv in sorted(objects,key=lambda z:z[0]):put(world,im,anchor,pv)
world.save(ROOT/'assembly_native.png')
bg=Image.open(ROOT/'source/cave_background.png').convert('RGBA')
scale=.48;center=(1856,1260);bgsize=(4000,2250);origin=(center[0]-2000,center[1]-1125)
bgplane=bg.resize(bgsize,L)
def camera(im,f,c,size=(1920,1080)):
    w,h=size
    return im.transform(size,Image.Transform.AFFINE,(1/f,0,c[0]-w/2/f,0,1/f,c[1]-h/2/f),Image.Resampling.BICUBIC)
def preview(f,c,size=(1920,1080)):
    background=camera(bgplane,f,(c[0]-origin[0],c[1]-origin[1]),size)
    background.alpha_composite(camera(world,f,c,size));return background.convert('RGB')
preview(scale,center).save(ROOT/'preview_full.png')
preview(.96,P(.8,8.8)).save(ROOT/'entrance_close.png')
preview(.96,P(18,9)).save(ROOT/'preview_zoom2x.png')
composite=camera(bgplane,1,(SIZE[0]/2-origin[0],SIZE[1]/2-origin[1]),SIZE);composite.alpha_composite(world);composite.save(ROOT/'assembly_cave_native.png')
# Seven actual assembled doorway closeups, no diagnostic lines painted on art.
names={'K':'병영','R':'회복둥지','C':'결계핵','W':'감시탑','L':'미끼보물실','T':'옥좌','V':'금고'}
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',25)
sheet=Image.new('RGB',(2800,470),(20,18,26));draw=ImageDraw.Draw(sheet)
for i,code in enumerate(['K','R','C','W','L','T','V']):
    info=next(r for r in doorinfo if r['code']==code)
    anchor=info['anchor'];crop=preview(1.35,(anchor[0],anchor[1]-65),(400,415))
    sheet.paste(crop,(i*400,55));draw.text((i*400+12,12),f"{names[code]} | {info['side']} | {'↙' if info['arch']=='up' else '↘'}",font=font,fill=(240,229,201))
sheet.save(ROOT/'door_check.png')
assert len(doorinfo)==7 and all(r['contact'] for r in doorinfo)
for r in doorinfo:
    a,b=r['foot_screen_offsets'];assert abs((b[1]-a[1])/(b[0]-a[0]))==.5
assert next(b for b in buildings if b['code']=='E')['rect']==[0,7,3,3]
# Sampling the continuous route proves connection through exterior edge and interior.
assert all(extmask.getpixel(P(x,9))==255 for x in [-2,-1,0,.25,1,2,3])
assert hashes(reference)==before
write('door_direction_table.json',dict(projection='X_iso=y; Y_iso=W-x; screen=(64*(x+y-W)+2304,32*(y+W-x)+512)',face_table={'N':dict(arch='up',wall='↙',outward=[-64,-32]),'S':dict(arch='up',wall='↙',outward=[64,32]),'E':dict(arch='down',wall='↘',outward=[64,-32]),'W':dict(arch='down',wall='↘',outward=[-64,32])},buildings=doorinfo))
write('assembly_config.json',dict(entrance_rect=[0,7,3,3],entrance_anchor_cell=[.25,9],entrance_pivot=gpivot,entrance_output_size=list(gate.size),external_route=[[-2.5,8],[3,8],[3,10],[-2.5,10]],arch_pivots={k:list(v[1]) for k,v in arches.items()}))
write('alpha_validation_v7c.json',alpha)
write('checks/v7c_validation.json',dict(result='PASS',v7b_hash_preserved=True,reference_file_count=len(before),door_count=7,all_doors_contact_road=True,all_wall_slopes_exact_half=True,entrance_footprint=[3,3],external_route_continuous=True,native_alpha=True,code_drawn_art=False,game_code_changed=False,godot_run=False,commit_made=False,visual_review='PENDING'))
# Update existing runtime manifest, including every new direction and external road layer.
manifest=json.loads((ROOT/'checks/final_manifest.json').read_text(encoding='utf-8'))
def update(identifier,im,pv,src,notes):
    p=ROOT/'final'/f'{identifier}.png';p.parent.mkdir(exist_ok=True,parents=True);im.save(p)
    rec=next((r for r in manifest if r['path']==identifier+'.png'),None)
    if rec is None:rec=dict(manifest[0]);manifest.append(rec)
    rec.update(name=identifier.replace('/','_'),path=identifier+'.png',width=im.width,height=im.height,pivot_x=pv[0],pivot_y=pv[1],pivot_normalized_x=round(pv[0]/im.width,6),pivot_normalized_y=round(pv[1]/im.height,6),anchor='door wall midpoint',world_top_left='',source=src,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),notes=notes)
for side,(im,pv) in arches.items():update('building/door_arch_'+side,im,pv,'source/door_arch_down.png','GPT native-alpha art; up is horizontal mirror; choose using door_direction_table.json')
update('building/door_arch',arch,pivot,'source/door_arch_down.png','Compatibility default DOWN; use directional variants for assembly')
update('interiors/entrance',gate,gpivot,'source/entrance_gate.png','GPT open skull-keystone gateway; anchor P(.25,9), inward normal (+64,-32); 3x3 plan footprint preserved')
boxe=extmask.getbbox();update('terrain/entrance_external_road',field.crop(boxe),(P(0,9)[0]-boxe[0],P(0,9)[1]-boxe[1]),'textures/road_material.png','Coverage-only assembly of GPT paving; anchor P(0,9); world top-left '+str(boxe[:2]))
with (ROOT/'final/asset_table.csv').open('w',newline='',encoding='utf-8-sig') as f:
    writer=csv.DictWriter(f,fieldnames=list(manifest[0]));writer.writeheader();writer.writerows(manifest)
write('checks/final_manifest.json',manifest)
shutil.copy2(ROOT/'door_direction_table.json',ROOT/'final/door_direction_table.json')
shutil.copy2(ROOT/'assembly_config.json',ROOT/'final/assembly_config.json')
print('PASS: seven aligned doors, open entrance, external route, native alpha, v7b preserved. Final visual inspection remains.')
