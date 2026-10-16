"""Import Claude's F cell plan and assemble cliff strips from approved GPT pixels."""
from pathlib import Path
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MOCK = Path('C:/Users/blueh/Desktop') / ''.join(map(chr, [51652,54665,51473,51064,54532,47196,51229,53944])) / '_mockup'


def main():
    target = ROOT / 'data/maps/v130r_step5'
    target.mkdir(parents=True, exist_ok=True)
    raw = (MOCK/'plan/plan_F_cells.txt').read_text(encoding='utf-8-sig')
    rows = [s for s in raw.splitlines() if s and not s.startswith('#')]
    assert len(rows) == 16 and all(len(s) == 22 for s in rows)
    buildings = json.loads(next(s.split(':', 1)[1] for s in raw.splitlines() if s.startswith('# buildings:')))
    ids = dict(E='entrance', K='barracks', W='watchtower', L='bait_treasure', T='throne', V='vault')
    for b in buildings:
        b.update(id=ids[b['code']], fixed=b['code'] in 'ETV')
        x,y,w,h = b['rect']
        front = dict(N=(x,y-2,w,2), S=(x,y+h,w,2), E=(x+w,y,2,h), W=(x-2,y,2,h))[b['door']]
        fx,fy,fw,fh = front
        b['defense_cells'] = [[cx,cy] for cy,row in enumerate(rows) for cx,ch in enumerate(row)
                              if ch == 'm' and fx <= cx < fx+fw and fy <= cy < fy+fh] if b['code'] != 'E' else []
        if b['code'] == 'E': b['door_outside'] = [[3,8],[3,9]]
        if b['code'] == 'T': b['door_outside'] = [[18,5],[19,5]]
        if b['code'] == 'V': b['door_outside'] = [[17,12],[17,13]]
    data = dict(id='approved_v7d_F', grade='F', size=[22,16], rows=rows, buildings=buildings,
                traps=[dict(kind='spikes', cell=[x,y]) for y,row in enumerate(rows) for x,ch in enumerate(row) if ch == 'X'])
    (target/'layout_f.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    shutil.copy2(MOCK/'plan/plan_F_cells.txt', target/'plan_F_cells.txt')
    art = ROOT/'assets/maps/v130r_step5'
    art.mkdir(parents=True, exist_ok=True)
    # Resize the whole band to the F boundary length, exactly as the E reference,
    # then split it into unique per-cell affine pieces for runtime assembly.
    for side in ['down','up']:
        src = ROOT/f'assets/maps/v130r_step1/cliff/straight_{side}_flat.png'
        count = 16 if side == 'down' else 22
        band = Image.open(src).convert('RGBA').resize((64*count,175), Image.Resampling.LANCZOS)
        slope = .5 if side == 'down' else -.5
        atlas = Image.new('RGBA', (64*count,207))
        for i in range(count):
            strip = band.crop((i*64,0,(i+1)*64,175)).transform((64,207), Image.Transform.AFFINE,
                                  (1,0,0,-slope,1,-32 if slope < 0 else 0), Image.Resampling.BICUBIC)
            atlas.paste(strip,(i*64,0))
        atlas.save(art/f'cliff_{side}_cell.png', optimize=True)
    provenance = ROOT/'assets/source/imagegen/v130r_step5'
    provenance.mkdir(parents=True, exist_ok=True)
    lines = ['# F boundary assembly from approved GPT artwork', '',
             '- Generation model: GPT internal image generation', '- Generated date: 2026-10-16',
             '- Target version: 1.3.0', '',
             'No generation call. Reuse of assets_v7d GPT pixels already imported in v130r_step1.',
             'Source ownership and original prompts: ../v130r_step1/SOURCE.md.',
             'Postprocessing: resize whole GPT bands to F boundary lengths 1024/1408x175, split into unique 64x175 cell strips, reference slope ±0.5 affine assembly; native alpha retained.', '']
    for side in ['down','up']:
        original = ROOT/f'assets/maps/v130r_step1/cliff/straight_{side}_flat.png'
        shutil.copy2(original, provenance/f'approved_cliff_{side}_flat.png')
        lines.append(f'- Source image path: assets/source/imagegen/v130r_step5/approved_cliff_{side}_flat.png')
        lines.append(f'- Runtime image path: assets/maps/v130r_step5/cliff_{side}_cell.png')
    (provenance/'SOURCE.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print('F 22x16 plan imported, 6 buildings, 4 traps, 2 GPT cliff assembly strips')


if __name__ == '__main__': main()
