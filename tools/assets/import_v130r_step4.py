"""Preserve GPT sources; crop/resize native alpha and import approved icons."""
from pathlib import Path
from PIL import Image
import json,shutil

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/source/imagegen/v130r_step4'
RUNTIME=ROOT/'assets/maps/v130r_step4'
MOCKUP=Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/ui_icons_v1')
PROMPT='Generate a single production game UI icon named skill_direct_control_v2. Transparent background native alpha. One circular antique gold and dark obsidian medallion with a clearly recognizable pale silver armored gauntlet holding two small marionette control strings over a tiny purple demon pawn: meaning direct player control. Warm hand painted fantasy RPG, polished bevel, blue violet shadows and gold rim, legible at 64 pixels. Only one centered icon, full icon inside canvas, ample transparent margin. No words, no letters, no numbers, no background, no checkerboard, no label or extra panels. Square image.'

def main():
    import argparse
    parser=argparse.ArgumentParser(); parser.add_argument('--generated',type=Path,required=True); args=parser.parse_args()
    SOURCE.mkdir(parents=True,exist_ok=True); RUNTIME.mkdir(parents=True,exist_ok=True)
    source=SOURCE/'skill_direct_control_v2_source.png'; shutil.copy2(args.generated,source)
    im=Image.open(source).convert('RGBA'); extrema=im.getchannel('A').getextrema(); assert extrema==(0,255),extrema
    im=im.crop(im.getbbox()); im.thumbnail((128,128),Image.Resampling.LANCZOS); im.save(RUNTIME/'skill_direct_control_v2.png',optimize=True)
    names=['tactic_'+s for s in ['rally','focus_attack','emergency_retreat','hold_ground','lure_retreat']]+['speed_'+s for s in ['pause','1','2','3']]+['skill_block','skill_counter']
    records=[]
    for name in names:
        original=MOCKUP/'icons_128'/f'{name}.png'
        assert original.is_file(),original
        saved=SOURCE/f'{name}_source.png'; shutil.copy2(original,saved)
        image=Image.open(original).convert('RGBA'); assert image.getchannel('A').getextrema()[0]==0,name
        image.save(RUNTIME/f'{name}.png',optimize=True)
        records.append((saved,RUNTIME/f'{name}.png'))
    records.append((source,RUNTIME/'skill_direct_control_v2.png'))
    lines=['# V130R Step4 battle artwork','', '- Generation model: GPT internal image generation','- Generated date: 2026-10-16','- Target version: 1.3.0','']
    for source,runtime in records:
        lines+=['- Source image path: '+source.relative_to(ROOT).as_posix(),'- Runtime image path: '+runtime.relative_to(ROOT).as_posix()]
    lines+=['','Direct-control v2: one native transparent image_gen call; source alpha 0..255. Only transparent-margin crop and Lanczos downscale to 128px. No background removal or code painting.',
            'Other icons: unchanged approved GPT ui_icons_v1/icons_128 raster sources, original provenance in external ui_icons_v1/SOURCE.md (also preserved as APPROVED_SOURCE.md). No new generation for these.',
            'Map, traps, actors, skill icons, panels and cell highlights reuse existing attributed GPT assets. All controls are texture composition/tint/alpha. NEXON_Maplestory Bold/Light text.']
    (SOURCE/'SOURCE.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    shutil.copy2(MOCKUP/'SOURCE.md',SOURCE/'APPROVED_SOURCE.md')
    (SOURCE/'PROMPT.txt').write_text(PROMPT+'\n',encoding='utf-8')
    print(json.dumps({'native_alpha':extrema,'runtime_icons':len(records)}))

if __name__=='__main__': main()
