"""Prepare per-cell texture pieces from approved GPT artwork, never a map image.

Coverage masks and affine transforms only assemble the supplied raster pieces.
The coordinate hash fixes each floor variant and global material phase forever.
"""
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[2]
MOCK = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup')
ART = ROOT/'assets/maps/v130r_step2'
SOURCE = ROOT/'assets/source/imagegen/v130r_step2'


def main():
    ART.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    layout = json.loads((ROOT/'data/maps/v130r_step1/layout.json').read_text())
    floor = Image.open(ROOT/'assets/maps/v130r_step1/terrain/ground_unique_field.png').convert('RGBA')
    mask = Image.new('L', (130*4, 66*4))
    ImageDraw.Draw(mask).polygon([(4,132),(260,4),(516,132),(260,260)], fill=255)
    mask = mask.resize((130,66), Image.Resampling.LANCZOS)
    coords = [(x,y) for y in range(18) for x in range(32)]
    coords.sort(key=lambda c: ((c[0]*73856093) ^ (c[1]*19349663), c))
    mapping = {}
    for kind in ('floor','road','water'):
        atlas = Image.new('RGBA',(16*130,36*66))
        material = None if kind=='floor' else Image.open(ROOT/f'assets/maps/v130r_step1/terrain/{kind}_material.png').convert('RGBA')
        for index,(x,y) in enumerate(coords):
            # P(x+.5,y+.5), top-left of its diamond, one sampling gutter.
            left,top = 64*(x+y-32)+2304-1, 32*(y+32-x)+512-33
            if kind=='floor':
                tile = floor.crop((left-254,top-510,left-254+130,top-510+66))
            else:
                tile = Image.new('RGBA',(130,66))
                px = tile.load()
                for yy in range(66):
                    for xx in range(130): px[xx,yy] = material.getpixel(((left+xx)%material.width,(top+yy)%material.height))
            tile.putalpha(mask)
            atlas.paste(tile,((index%16)*130,(index//16)*66))
            mapping[f'{x},{y}'] = index
        atlas.save(ART/f'{kind}_cells.png', optimize=True)
    # Half-cell rails with four fixed material phases; corners are selected by
    # the four terrain occupancies around each dual-grid vertex at runtime.
    for kind in ('road','water'):
        for side in ('down','up'):
            src = ROOT/f'assets/source/imagegen/v130r_step1/assembly_rails/{kind}/straight_{side}_flat.png'
            flat = Image.open(src).convert('RGBA')
            band = Image.new('RGBA',(256,flat.height))
            band.paste(flat,(0,0)); band.paste(ImageOps.mirror(flat),(128,0))
            for phase in range(4):
                part = band.crop((phase*64,0,phase*64+64,flat.height))
                slope = .5 if side=='down' else -.5
                piece = part.transform((64,flat.height+32),Image.Transform.AFFINE,
                    (1,0,0,-slope,1,-32 if slope<0 else 0),Image.Resampling.BICUBIC)
                piece.save(ART/f'{kind}_{side}_{phase}.png', optimize=True)
    ids = ['build_barracks','build_recovery_nest','build_ward_core','build_watchtower','build_decoy_treasure','build_spike_trap','build_sticky_trap','menu_info','menu_upgrade','menu_move','menu_dismantle_refund','menu_assign_defenders','frame_normal','frame_selected','frame_disabled','place_auto','place_clear_all']
    for id in ids:
        for dest in (ART/'ui'/f'{id}.png',SOURCE/'approved_ui'/f'{id}.png'):
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(MOCK/'ui_icons_v1/icons_128'/f'{id}.png',dest)
        prompt = MOCK/'ui_icons_v1/prompts'/f'{id}.json'
        if prompt.exists():
            (SOURCE/'prompts').mkdir(exist_ok=True)
            shutil.copy2(prompt,SOURCE/'prompts'/prompt.name)
    shutil.copy2(MOCK/'ui_icons_v1/icon_catalog.json',SOURCE/'icon_catalog.json')
    shutil.copy2(MOCK/'ui_icons_v1/SOURCE.md',SOURCE/'reference_ui_SOURCE.md')
    # The new cell highlight was generated natively transparent, no keying.
    generated = Path('C:/Users/blueh/.codex/generated_images/01a142fe-7690-7490-a8f9-d07780ff7bc7/exec-6f2783e2-2027-49f2-94b6-8c8d664fbb28.png')
    v2 = MOCK/'ui_icons_v2'
    v2.mkdir(exist_ok=True)
    for dest in (v2/'cell_highlight_source.png',SOURCE/'cell_highlight_source.png'):
        shutil.copy2(generated,dest)
    highlight = Image.open(generated).convert('RGBA')
    assert highlight.getchannel('A').getextrema()==(0,255), 'Native alpha required'
    highlight.resize((160,80),Image.Resampling.LANCZOS).save(ART/'ui/cell_highlight.png',optimize=True)
    manifest = {'atlas_size':[2080,2376],'cell_region':[130,66],'columns':16,'cell_index':mapping,
        'floor_hash':'(x*73856093) ^ (y*19349663); sorted once; no frame random',
        'fixed_grade':'E','source':'approved v7d pieces, not the composite preview'}
    data = ROOT/'data/maps/v130r_step2'
    data.mkdir(parents=True,exist_ok=True)
    (data/'terrain.json').write_text(json.dumps(manifest,indent=2)+'\n')
    shutil.copy2(MOCK/'assets_v7d/final/door_direction_table.json',data/'door_directions.json')
    lines = ['# Step 2 assembly assets','', '- Generation model: GPT internal image generation',
        '- Generated date: 2026-10-16','- Target version: v1.3.0','',
        'Approved UI icons copied unchanged from external ui_icons_v1. See reference_ui_SOURCE.md.',
        'Cell highlight: one native-transparent built-in imagegen call; resize only, alpha preserved.',
        'Terrain atlases: geometric diamond coverage of approved source pixels, coordinate hash indexing.',
        'No runtime combined floor/road/water map image; no background removal or synthetic decoration.',
        'Terrain original source mappings belong to v130r_step1/SOURCE.md; not duplicated here.','']
    for path in sorted(SOURCE.rglob('*.png')): lines.append('- Source image path: '+path.relative_to(ROOT).as_posix())
    for path in sorted(ART.rglob('*.png')): lines.append('- Runtime image path: '+path.relative_to(ROOT).as_posix())
    (SOURCE/'SOURCE.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('Prepared cell atlases, 16 dual-grid rail pieces, 17 UI icons and native-alpha highlight')


if __name__=='__main__': main()
