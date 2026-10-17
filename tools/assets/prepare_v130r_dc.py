"""Import authoritative D/C plans. Only sample/transform generated raster pixels."""
from pathlib import Path
import json
import shutil
import csv
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '_mockup/assets_v8_dc'
DATA = ROOT / 'data/maps/v130r_step10'
ART = ROOT / 'assets/maps/v130r_step10'

def save_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def plans():
    DATA.mkdir(parents=True, exist_ok=True)
    ART.mkdir(parents=True, exist_ok=True)
    kinds = dict(E='entrance', W='watchtower', L='bait_treasure', K='barracks', R='recovery_nest', C='ward_core', T='throne', V='vault')
    for grade, width, height in [('D',40,20),('C',48,22)]:
        text = (ROOT/f'_mockup/plan/plan_{grade}_cells.txt').read_text(encoding='utf-8-sig')
        rows = [s for s in text.splitlines() if s and not s.startswith('#')]
        assert len(rows)==height and all(len(s)==width for s in rows)
        comments = {s[2:].split(':',1)[0]:s.split(':',1)[1] for s in text.splitlines() if s.startswith('# ') and ':' in s}
        buildings = json.loads(comments['buildings'])
        ids = json.loads(comments['building_ids'])
        defenders = json.loads(comments['defender_cells'])
        for b, id in zip(buildings, ids):
            x,y,w,h = b['rect']; side = b['door']
            b.update(id=id, kind=kinds[b['code']], fixed=b['code'] in 'ETV', defense_cells=defenders[id])
            if id=='entrance': front=[[3,8],[3,9]]
            elif id=='ward_core': front=[[18,8],[18,9]]
            elif id=='throne' and grade=='C': front=[[42,2],[42,3]]
            elif side=='S': front=[[x+1,y+h],[x+2,y+h]]
            elif side=='N': front=[[x+1,y-1],[x+2,y-1]]
            else: front=[[x-1,y+1],[x-1,y+2]]
            b['door_outside']=front
            if id=='throne' and grade=='C': b['secondary_doors']=[dict(side='S', front=[[44,5],[45,5]])]
        save_json(DATA/f'layout_{grade.lower()}.json', dict(id=f'approved_v8_{grade}', grade=grade, size=[width,height], rows=rows, buildings=buildings, door_goal_center=True, branch_routes=True,
            route_segments=json.loads(comments['route_segments']),
            traps=[dict(kind='spikes' if i%2==0 else 'sticky', cell=c) for i,c in enumerate([[x,y] for y,row in enumerate(rows) for x,ch in enumerate(row) if ch=='X'])]))
        shutil.copy2(ROOT/f'_mockup/plan/plan_{grade}_cells.txt', DATA/f'plan_{grade}_cells.txt')

def terrain():
    # Unique coordinate samples: each expanded cell uses its own generated patch.
    # Reuse the approved native diamond alpha, never draw replacement artwork.
    mask = Image.open(ROOT/'assets/maps/v130r_step2/floor_cells.png').crop((0,0,130,66)).getchannel('A')
    for grade,width,height in [('d',40,20),('c',48,22)]:
        src = Image.open(SOURCE/f'floor_{grade}_source.png').convert('RGBA')
        atlas=Image.new('RGBA',(16*130,((width*height+15)//16)*66))
        mapping={}
        for y in range(height):
            for x in range(width):
                i=y*width+x
                # Rectangular source is a unique top-down material field. Affine
                # maps one non-repeated cell patch to the same 2:1 floor diamond.
                sx=src.width/width; sy=src.height/height
                tile=src.transform((130,66),Image.Transform.AFFINE,
                    (sx/128,sx/64,x*sx-sx/2, -sy/128,sy/64,y*sy+sy/2),Image.Resampling.BICUBIC)
                tile.putalpha(mask); atlas.paste(tile,((i%16)*130,(i//16)*66))
                mapping[f'{x},{y}']=i
        atlas.save(ART/f'floor_{grade}_cells.png',optimize=True)
        save_json(DATA/f'terrain_{grade}.json',dict(cell_index=mapping,columns=16,cell_region=[130,66]))
    # Boundary bands are still approved v7d pixels, assembled per-cell.
    for side,count in [('down',22),('up',48)]:
        src=Image.open(ROOT/f'assets/maps/v130r_step1/cliff/straight_{side}_flat.png').convert('RGBA')
        band=src.resize((64*count,175),Image.Resampling.LANCZOS)
        atlas=Image.new('RGBA',(64*count,207)); slope=.5 if side=='down' else -.5
        for i in range(count):
            tile=band.crop((64*i,0,64*(i+1),175)).transform((64,207),Image.Transform.AFFINE,(1,0,0,-slope,1,-32 if slope<0 else 0),Image.Resampling.BICUBIC)
            atlas.paste(tile,(64*i,0))
        atlas.save(ART/f'cliff_{side}_cell.png',optimize=True)

def sprites():
    manifest={}
    def export(name, im, size, pivot=None):
        assert im.getchannel('A').getextrema()==(0,255), f'native alpha required: {name}'
        im=im.crop(im.getchannel('A').getbbox()).resize(size,Image.Resampling.LANCZOS)
        im.save(ART/f'{name}.png',optimize=True)
        manifest[f'dc/{name}.png']=dict(size=list(size),pivot=pivot or [size[0]/2,size[1]/2])
    export('stone_deck',Image.open(SOURCE/'stone_deck_source.png').convert('RGBA'),(256,128))
    # A two-cell diagonal cross section spans 128px horizontally and 64px vertically.
    export('gate_frame',Image.open(SOURCE/'gate_frame_source.png').convert('RGBA'),(152,152),[76,120])
    sheet=Image.open(SOURCE/'masonry_source.png').convert('RGBA'); w,h=sheet.size
    for name,box,size,pivot in [
        ('rail_back',(0,0,w//2,h//2),(140,80),[70,60]),
        ('rail_front',(w//2,0,w,h//2),(140,80),[70,60]),
        ('abutment',(0,h//2,w//2,h),(144,80),[72,40]),
        ('throne_arch',(w//2,h//2,w,h),(160,180),[80,150])]:
        im=sheet.crop(box)
        if name.startswith('rail_') or name=='throne_arch': im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        export(name,im,size,pivot)
    save_json(DATA/'art.json',manifest)
    with (SOURCE/'asset_table.csv').open('w',encoding='utf-8',newline='') as file:
        writer=csv.writer(file)
        writer.writerow(['asset','width','height','pivot_x','pivot_y','logical_footprint','axes'])
        for key,entry in manifest.items():
            writer.writerow([key,*entry['size'],*entry['pivot'],'2x2' if 'deck' in key else 'separate trim','x; y by horizontal assembly reflection'])
    provenance=ROOT/'assets/source/imagegen/v130r_step10'
    provenance.mkdir(parents=True,exist_ok=True)
    lines=['# D/C generated assembly pieces','', '- Generation model: GPT internal image generation',
           '- Generated date: 2026-10-17','- Target version: v1.3.0','',
           'Five built-in image_gen calls. Native alpha checked before trim/resize.',
           'Originals and exact prompts in _mockup/assets_v8_dc/. No background removal.',
           'Postprocessing: native-alpha bounds crop, resize, rail and south throne-frame mirrors, unique floor affine sampling with the existing approved cell alpha.',
           'Cliffs reuse approved v7d straight bands, per-cell affine assembly; original provenance is ../v130r_step1/SOURCE.md.', '']
    for p in sorted(SOURCE.glob('*_source.png')):
        shutil.copy2(p,provenance/p.name)
        lines.append('- Source image path: '+p.relative_to(ROOT).as_posix())
        lines.append('- Source image path: '+(provenance/p.name).relative_to(ROOT).as_posix())
    for p in sorted(ART.glob('*.png')): lines.append('- Runtime image path: '+p.relative_to(ROOT).as_posix())
    (provenance/'SOURCE.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    save_json(SOURCE/'alpha_checks.json',{p.name:dict(size=Image.open(p).size,alpha=Image.open(p).convert('RGBA').getchannel('A').getextrema()) for p in SOURCE.glob('*_source.png')})

if __name__=='__main__':
    plans()
    if (SOURCE/'floor_c_source.png').exists():
        terrain(); sprites()
    print('D/C plans imported')
