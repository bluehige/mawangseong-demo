"""Read-only checks for completion art; never changes image pixels."""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--allow-incomplete',action='store_true')
    args=ap.parse_args()
    inventory=json.loads((ROOT/'tools/fixtures/uiux_completion_actor_inventory.json').read_text(encoding='utf-8'))
    catalog=json.loads((ROOT/'data/uiux_actor_art.json').read_text(encoding='utf-8'))
    errors=[];checks=0
    def expect(ok,label):
        nonlocal checks
        checks+=1
        if not ok:errors.append(label)
    required={entry['legacy_path']:id for id,entry in inventory.items()}
    present=[id for id in inventory if id in catalog]
    if not args.allow_incomplete:
        for path,id in required.items():
            expect(any(v['legacy_path']==path and key in catalog for key,v in inventory.items()),id+' art completed')
    for path in sorted((ROOT/'assets/source/imagegen/uiux_completion_20260913').glob('*.png')):
        runtime=ROOT/('assets/sprites/uiux3d' if path.name.endswith('_sheet.png') else 'assets/sprites/portraits/uiux3d')/path.name
        im=Image.open(runtime);a=np.asarray(im)
        expect(im.mode=='RGBA',path.name+' native RGBA')
        if im.mode!='RGBA':continue
        a=a[:,:,3]
        expect(a.max()>=254 and (a==0).mean()>.1,path.name+' foreground and real transparency')
        # Dialogue portraits intentionally crop clothing at the bottom.
        corners=[a[0,0],a[0,-1]] if not path.name.endswith('_sheet.png') else [a[0,0],a[0,-1],a[-1,0],a[-1,-1]]
        expect(max(corners)<=1,path.name+' transparent exterior')
        expect(min(im.size)>=1024,path.name+' source resolution')
        expect(hashlib.sha256(path.read_bytes()).digest()==hashlib.sha256(runtime.read_bytes()).digest(),path.name+' identical source/runtime')
        settings=Path(str(runtime)+'.import')
        expect(settings.exists() and all(x in settings.read_text(encoding='utf-8') for x in ['compress/mode=0','mipmaps/generate=true','process/size_limit=0']),path.name+' lossless mipmaps')
    for id in present:
        info=catalog[id];alpha=np.asarray(Image.open(ROOT/info['path'].removeprefix('res://')))[:,:,3]
        expect(len(info['regions'])==len(info['margins'])==len(info['visible_bounds'])==16,id+' 16 frames')
        for index,(r,m,v) in enumerate(zip(info['regions'],info['margins'],info['visible_bounds'])):
            x,y,w,h=r
            expect(0<=x<x+w<=alpha.shape[1] and 0<=y<y+h<=alpha.shape[0],f'{id}/{index} source bounds')
            expect(w+m[2]==h+m[3]==384,f'{id}/{index} logical frame')
            yy,xx=np.where(alpha[y:y+h,x:x+w]>160)
            expect(len(xx)>1000,f'{id}/{index} character pixels')
            actual=[xx.min()+m[0],yy.min()+m[1],xx.max()-xx.min()+1,yy.max()-yy.min()+1]
            vx,vy,vw,vh=v
            expect(actual[0]>=vx and actual[1]>=vy and actual[0]+actual[2]<=vx+vw and actual[1]+actual[3]<=vy+vh,f'{id}/{index} opaque neighbor outside measured body')
            expect(0<=actual[0]<actual[0]+actual[2]<=384 and 0<=actual[1]<actual[1]+actual[3]<=384,f'{id}/{index} body in frame')
            if index<4:expect(abs(actual[1]+actual[3]-346)<=3,f'{id}/{index} pixel feet')
    print(json.dumps({'assertions':checks,'errors':errors,'present_sheets':present,'incomplete_allowed':args.allow_incomplete},ensure_ascii=False,indent=2))
    print('UIUX_COMPLETION_PIXELS_TEST:', 'FAIL' if errors else 'PASS')
    raise SystemExit(bool(errors))
if __name__=='__main__':main()
