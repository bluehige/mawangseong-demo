from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
import numpy as np
from scipy.ndimage import distance_transform_edt

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[3]
BATI = ROOT.parent / 'v1213_bati_cute'
ICONS = [
 ('settings','설정'),('log','로그'),('save','저장'),('load','불러오기'),
 ('encyclopedia','도감'),('speed','배속'),('pause','일시정지'),('play','재생'),
 ('skip','넘기기'),('auto_play','자동재생'),('build','건설'),('garrison','수비대'),
 ('tactics','전술'),('monster','몬스터'),('battle_start','전투시작'),('undo','되돌리기'),
 ('close','닫기'),('info','정보'),('warning','경고'),('lock','잠금'),
 ('check','체크'),('gold','금화'),('mana','마력'),('food','식량'),
 ('infamy','악명'),('throne','왕좌'),('treasury','보물실'),('explorer_enemy','탐험가(적)'),
 ('watch_post_range','감시초소 범위'),('experience','경험치'),('hp','HP'),('language','언어(지구본)')]

def save_new(im, path):
    if path.exists():
        raise FileExistsError(path)
    im.save(path)

def metrics(path):
    im = Image.open(path)
    assert im.mode == 'RGBA', str(path)
    a = np.array(im)[:,:,3]
    assert a.min() == 0 and a.max() >= 240, str(path)
    edge = np.r_[a[0], a[-1], a[:,0], a[:,-1]]
    ys,xs = np.where(a >= 8)
    dist = distance_transform_edt(a < 240)
    return {
        'file':path.relative_to(REPO).as_posix(), 'size':list(im.size), 'mode':im.mode,
        'alpha_min':int(a.min()),'alpha_max':int(a.max()),
        'zero_alpha_pct':round(100*float((a==0).mean()),6),
        'partial_alpha_pct':round(100*float(((a>0)&(a<255)).mean()),6),
        'low_alpha_1_to_7_pct':round(100*float(((a>0)&(a<8)).mean()),6),
        'visible_bbox_alpha_ge8':[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)],
        'edge_nonzero_pixels':int((edge>0).sum()),'edge_alpha_ge8_pixels':int((edge>=8).sum()),
        'max_distance_alpha_ge8_from_core_px':round(float(dist[a>=8].max()),3),
        'alpha_ge32_farther_than_4px_from_core':int(((a>=32)&(a<240)&(dist>4)).sum()),
        'max_edge_alpha':int(edge.max()),
    }

def main():
    cuts=[]
    for n in (1,2):
        im=Image.open(ROOT/'originals'/f'icons_sheet_{n:02}.png').convert('RGBA')
        assert im.size == (1254,1254)
        # Transparent separation gaps inspected against all32 symbol bounds.
        xs=[0,335,627,940,1254] if n==2 else [0,313,627,940,1254]
        ys=[0,327,616,925,1254]
        for j in range(16):
            row,col=divmod(j,4); box=(xs[col],ys[row],xs[col+1],ys[row+1])
            cell=im.crop(box); bounds=cell.getbbox(); assert bounds
            sprite=cell.crop(bounds)
            scale=208/max(sprite.size)
            size=(max(1,round(sprite.width*scale)),max(1,round(sprite.height*scale)))
            sprite=sprite.resize(size,Image.Resampling.LANCZOS)
            canvas=Image.new('RGBA',(256,256),(0,0,0,0))
            # Paste preserves native alpha; no alpha thresholding or background extraction.
            canvas.paste(sprite,((256-size[0])//2,(256-size[1])//2))
            name,label=ICONS[(n-1)*16+j]
            save_new(canvas,ROOT/f'icon_{name}.png')
            m=metrics(ROOT/f'icon_{name}.png')
            assert m['size']==[256,256] and m['edge_nonzero_pixels']==0
            b=canvas.getbbox(); margins=[b[0],b[1],256-b[2],256-b[3]]
            assert min(margins)>=24
            m.update({'label':label,'source_sheet':n,'source_cell':list(box),'native_alpha_bbox_in_cell':list(bounds),'margins_px':margins})
            cuts.append(m)
    font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',19)
    title=ImageFont.truetype('C:/Windows/Fonts/malgunbd.ttf',26)
    preview=Image.new('RGB',(1536,1200),'#171220');d=ImageDraw.Draw(preview)
    d.text((30,20),'스타일 B · 귀여운 다크 판타지 — UI 아이콘 후보 32종',font=title,fill='#f6dfab')
    for i,(name,label) in enumerate(ICONS):
        row,col=divmod(i,8);x=col*192;y=72+row*278
        icon=Image.open(ROOT/f'icon_{name}.png').convert('RGBA').resize((168,168),Image.Resampling.LANCZOS)
        preview.paste(icon,(x+12,y+12),icon)
        d.text((x+96,y+190),label,font=font,fill='#f7edff',anchor='mm')
        d.text((x+96,y+218),name,font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',14),fill='#ae9db9',anchor='mm')
    save_new(preview,ROOT/'icons_preview.png')
    (ROOT/'alpha_checks.json').write_text(json.dumps({'method':'native alpha preserved; crop + isotropic LANCZOS resize + transparent padding only','icons':cuts},ensure_ascii=False,indent=2),encoding='utf-8')
    chars=[metrics(p) for p in sorted(BATI.glob('bati_*.png'))]
    assert len(chars)==8
    for m in chars:
        assert m['size']==([512,512] if 'portrait' in m['file'] else [1024,1536])
        assert m['edge_alpha_ge8_pixels']==0 or 'portrait' in m['file']
    (BATI/'alpha_checks.json').write_text(json.dumps({'threshold_note':'alpha >=8 visible support; alpha >=240 opaque core; alpha1..7 retained and reported, never removed','characters':chars},ensure_ascii=False,indent=2),encoding='utf-8')
    # Review composites only; never used as sprite sources.
    p=Image.new('RGB',(1600,1160),'#231b30');d=ImageDraw.Draw(p)
    for i,mood in enumerate(['dry','dry_happy','stern','tutorial']):
        x=i*400
        stand=Image.open(BATI/f'bati_standing_{mood}.png').resize((360,540),Image.Resampling.LANCZOS)
        p.paste(stand,(x+20,30),stand)
        portrait=Image.open(BATI/f'bati_portrait_{mood}.png').resize((340,340),Image.Resampling.LANCZOS)
        p.paste(portrait,(x+30,660),portrait)
        d.text((x+200,605),mood,font=title,fill='#f6dfab',anchor='mm')
    save_new(p,BATI/'bati_preview.png')
    # Large pale background exposes light-colored fringe around the four full bodies.
    p=Image.new('RGB',(1600,650),'#e6e3ed')
    for i,mood in enumerate(['dry','dry_happy','stern','tutorial']):
        im=Image.open(BATI/f'bati_standing_{mood}.png').resize((400,600),Image.Resampling.LANCZOS)
        p.paste(im,(400*i,0),im)
    save_new(p,BATI/'bati_light_background_check.png')
    print('CHARACTERS',json.dumps(chars,ensure_ascii=False))
    print('ICONS',len(cuts),'transparent_pct_range',min(m['zero_alpha_pct'] for m in cuts),max(m['zero_alpha_pct'] for m in cuts),'edge_nonzero',sum(m['edge_nonzero_pixels'] for m in cuts),'min_margin',min(min(m['margins_px']) for m in cuts))

if __name__=='__main__':main()
