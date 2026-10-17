"""0103: crop, uniformly scale, align and assemble native generated pixels only."""
from pathlib import Path
import importlib.util, json, hashlib, sys, statistics
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[4]
RUNTIME=ROOT/'assets/sprites/v130r/quarter_final/crumpled_map'
DOC=ROOT/'assets/source/imagegen/v130r_quarter_final/crumpled_map/retry'
BOARDS=OUT.parents[1]
BASE=ROOT/'assets/sprites/v130r/quarter_final/river_frog/assemble_0101a.py'
spec=importlib.util.spec_from_file_location('base0101a',BASE)
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
L=Image.Resampling.LANCZOS
EDGES=[0,313,627,940,1254]
def dump(p,v):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def width(im):
    a=np.array(im);y,x=np.where((a[:,:,3]>=96)&(a[:,:,:3].max(axis=2)>=52))
    return int(x.max()-x.min()+1)
def selected():
    sw=base.extract(OUT/'generated_attempt_2.png',4)
    ne=base.extract(OUT/'generated_attempt_3.png',4)
    patch=base.audit_cells(base.extract_seams(OUT/'generated_attempt_4.png',2,2),OUT/'generated_attempt_4.png')
    # One uniform size conversion per source sheet, using typical unchanged footprint widths.
    keys=[(0,0),(0,1)]+[(1,i) for i in range(4)]
    target=statistics.median(width(sw[k]['image']) for k in keys)
    norms={2:1.0,3:target/statistics.median(width(ne[k]['image']) for k in keys),4:target/statistics.median(width(v['image']) for v in patch.values())}
    cells={('sw',r,c):v for (r,c),v in sw.items()}
    cells.update({('ne',r,c):v for (r,c),v in ne.items()})
    replacement=[(('sw',3,2),(0,0)),(('ne',3,0),(0,1)),(('ne',4,0),(1,0)),(('ne',4,1),(1,1))]
    for key,pk in replacement:cells[key]=patch[pk]
    for v in cells.values():
        n=int(Path(v['source_path']).stem.rsplit('_',1)[1]);v['attempt']=n;v['source_normalization']=norms[n]
    return cells,norms
def assemble():
    cells,norms=selected()
    for v in cells.values():
        assert not any(v[k] for k in ['slice_edge_alpha192','own_body_cropped_alpha96','foreign_body_pixels']),v
    scale=min(250/max(v['image'].width*v['source_normalization'] for v in cells.values()),250/max(v['image'].height*v['source_normalization'] for v in cells.values()))
    for v in cells.values():
        n=v['source_normalization'];cx,cy=base.contact(v['image'])
        scale=min(scale,139/max(1,cx*n),139/max(1,(v['image'].width-cx)*n),270/max(1,cy*n),15/max(1,(v['image'].height-cy)*n))
    meta={'species_id':'crumpled_map','status':'ACCEPTED_OFFLINE_NOT_INTEGRATED','workstream':'0103','sheet_size':[1254,1254],'grid':[4,4],'cell_edges':EDGES,'logical_frame_size':[384,384],'logical_anchor':[192,345],'atlas_anchor':[156.5,289],'animations':base.ANIMS,'uniform_scale':scale,'source_uniform_normalizations':norms,'directions':{},'camera_reference':'0098 C + adopted 0101a frog/snail; elevated camera evaluated visually','measurement_note':'Contact is alpha>=192 bottom8px weighted center, not anatomical foot tracking. One uniform size conversion per source sheet. Original RGBA retained; no drawing, warping, masking, background removal or mirroring.'}
    RUNTIME.mkdir(parents=True,exist_ok=True)
    for direction in ['sw','ne']:
        for hurt in [False,True]:
            atlas=Image.new('RGBA',(1254,313 if hurt else 1254));records=[]
            for index in range(4 if hurt else 16):
                row,col=(4,index) if hurt else divmod(index,4);src=cells[direction,row,col]
                n=scale*src['source_normalization'];im=src['image'].resize((max(1,round(src['image'].width*n)),max(1,round(src['image'].height*n))),L)
                cx,cy=base.contact(im);top=0 if hurt else EDGES[row]
                x=round(EDGES[col]+156.5-cx);y=top+289-cy
                assert x>=EDGES[col]+5 and x+im.width<EDGES[col+1]-5
                assert y>=top+5 and y+im.height<(313 if hurt else EDGES[row+1])-5
                atlas.alpha_composite(im,(x,y))
                rec={k:v for k,v in src.items() if k!='image'}
                rec.update({'index':index,'rect':[x,y,*im.size],'cell':[EDGES[col],top,EDGES[col+1]-EDGES[col],313 if hurt else EDGES[row+1]-top],'contact_x':x-EDGES[col]+cx,'support_y':289})
                records.append(rec)
            name='crumpled_map_hurt_'+direction+'.png' if hurt else 'crumpled_map_sheet'+('_ne' if direction=='ne' else '')+'.png'
            path=RUNTIME/name;atlas.save(path,optimize=True)
            meta['directions'].setdefault(direction,{})['hurt' if hurt else 'combat']={'path':str(path),'frames':records,'sha256':sha(path)}
    dump(RUNTIME/'art_review.json',meta)
    dump(OUT/'selection.json',{'accepted':True,'selected_attempts':[2,3,4],'rejected_attempts':[1],'combat_and_hurt':meta['directions'],'source_uniform_normalizations':norms})
    print('Assembled SW16 + NE16 + hurt4/4; source norms',norms)
def stamp(board,im,x,y,w,h):
    b=im.getchannel('A').point(lambda a:255 if a>=8 else 0).getbbox();im=im.crop(b);im.thumbnail((w,h),L)
    board.alpha_composite(im,(x+(w-im.width)//2,y+h-im.height))
def frame(meta,d,i,hurt=False):
    rec=meta['directions'][d]['hurt' if hurt else 'combat'];f=rec['frames'][i];x,y,w,h=f['rect']
    return Image.open(rec['path']).convert('RGBA').crop((x,y,x+w,y+h))
def text(board,xy,s,size=22,color='#f2eadb'):
    ImageDraw.Draw(board).text(xy,s,font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',size),fill=color)
def boards():
    old=json.loads((OUT.parent/'rejected_sheets/art_review.json').read_text(encoding='utf-8'))
    new=json.loads((RUNTIME/'art_review.json').read_text(encoding='utf-8'))
    board=Image.new('RGBA',(1600,1520),'#353442')
    text(board,(35,15),'0103 '+ '\uaf2c\uae43' +' / crumpled_map',32)
    text(board,(35,63),'T top >= front / F foreshortening / H downward face / E contact ellipse / S southwest',22)
    text(board,(35,105),'0101a REJECTED / T X  F O  H ?  E O  S X',25,'#ffae9e')
    text(board,(820,105),'0103 ADOPTED / T O  F O  H O  E O  S O',25,'#91e4be')
    rows=[('SW idle', 'sw',0,False),('SW move','sw',4,False),('SW attack','sw',10,False),('SW skill (repair)','sw',14,False),('NE idle / true rear','ne',0,False),('NE hurt (repair)','ne',0,True)]
    for row,(label,d,index,hurt) in enumerate(rows):
        top=160+row*210
        text(board,(35,top),label,23)
        stamp(board,frame(old,d,index,hurt),220,top,470,180)
        stamp(board,frame(new,d,index,hurt),1000,top,470,180)
    text(board,(35,1450),'4 calls total; attempt2 SW + attempt3 NE + attempt4 four replacements. Offline candidate; Godot not run.',22)
    path=BOARDS/'review_0103.png';board.convert('RGB').save(path)
    thumb=board.copy();thumb.thumbnail((1050,1000),L);thumb.convert('RGB').save(BOARDS/'review_0103_review.png')
    # One reduced board for all final frames, inspected as a single image.
    contact=Image.new('RGBA',(1200,850),'#353442')
    for direction,offset in [('sw',0),('ne',4)]:
        for row in range(5):
            for col in range(4):
                im=frame(new,direction,col if row==4 else row*4+col,row==4)
                stamp(contact,im,(offset+col)*150,row*170,145,145)
    contact.convert('RGB').save(OUT/'final_40_review.png')
    print('Created previous-rejected | new-adopted review and one reduced final40 board')
def provenance():
    DOC.mkdir(parents=True,exist_ok=True)
    decisions=[{'attempt':1,'status':'REJECTED','selected_frames':0,'T':False,'F':True,'H':False,'E':True,'S':False,'reason':'Half-unrolled lower base exists, but upright front/near-frontal face remains too dominant.'},
    {'attempt':2,'status':'PARTIAL_ADOPTED','selected_frames':19,'T':True,'F':True,'H':True,'E':True,'S':True,'excluded':'SW skill14 face too frontal; replaced by4.'},
    {'attempt':3,'status':'PARTIAL_ADOPTED','selected_frames':17,'T':True,'F':True,'H':'rear face hidden','E':True,'S':'NE rear check','excluded':'NE skill12/hurt0/hurt1 ambiguous direction; replaced by4.'},
    {'attempt':4,'status':'ADOPTED','selected_frames':4,'T':True,'F':True,'H':True,'E':True,'S':True,'reason':'SW skill14 and NE skill12/hurt0/hurt1 direction replacements.'}]
    dump(OUT/'attempt_decisions.json',decisions)
    visual={'accepted':True,'criteria':{'T':'Broad floor-level map top dominates the small raised face/back panel.','F':'Low deep half-unrolled body and short corner feet.','H':'Small face below broad upper fold, looking down-left; NE face fully occluded.','E':'Small generated horizontal contact shadow, visually elliptical.','S':'SW map base extends down-left from raised upper-right fold; asymmetric downward face. NE is rotated rear: raised back near lower-left, base recedes upper-right.'},'limitations':['Visual judgement, not recovered3D camera or exact projected area measurement.','Generated partly occluded contact shadow, not measured perfect2:1 ellipse.','Exactly3 throne doodles retained on SW; NE can occlude original front markings. Tiny routes/crease/doodle placement varies.','Engine playback not tested; offline assets only.']}
    dump(OUT/'visual_decisions.json',visual)
    prompts=['# crumpled_map retry / 0103','','Generation model: GPT internal image generation','Generated date: 2026-10-17','Target version: 1.3.0','','Native image_gen only; transparent_background=true. Maximum4 calls reached.','Input roles: reference.png identity+real-map; approved_C_camera.png0098 C; approved_0101a_camera.png adopted frog/snail camera.','Calls1-2 use all three camera/identity images; call2 also rejected1 for identity only.','Call3 uses all three plus SW2 design. Call4 uses identity+0098 C+SW2+NE3.','']
    for n in range(1,5):
        prompts += [f'## Attempt{n}','', '```text',(OUT/f'prompt_attempt_{n}.txt').read_text(encoding='utf-8').rstrip(),'```','']
    prompts+=['## Selection','',json.dumps(decisions,ensure_ascii=False,indent=2)]
    (OUT/'prompts.md').write_text('\n'.join(prompts)+'\n',encoding='utf-8')
    pngs=sorted(OUT.glob('*.png'))+[BOARDS/'review_0103.png',BOARDS/'review_0103_review.png']
    lines=['# crumpled_map retry / 0103','','Generation model: GPT internal image generation','Generated date: 2026-10-17','Target version: 1.3.0','Status: ACCEPTED_OFFLINE_NOT_INTEGRATED','']
    for p in pngs:lines += ['Source image path: '+p.relative_to(ROOT).as_posix(),'Source SHA-256: '+sha(p)]
    for p in sorted(RUNTIME.glob('*.png')):lines += ['Runtime image path: '+p.relative_to(ROOT).as_posix(),'Runtime SHA-256: '+sha(p)]
    lines += ['', 'Original generator locations/alpha/hashes: `_mockup/monsters_v130r/quarter_final/crumpled_map/retry/generation_attempt_*.json`.','Exact prompts and reference roles: `_mockup/monsters_v130r/quarter_final/crumpled_map/retry/prompts.md`.','4 calls total. First rejected. Selected SW attempt2(19), NE attempt3(17), repair4(4).','References copied/assembled from approved original pixels only. Raw4 PNGs kept unchanged in requested retry directory.','Postprocessing: rectangular source crop; uniform scale per source sheet normalized by median unchanged floor footprint width; translation and direct alpha compositing. No pixel painting, background removal, alpha cleanup, warping, mirroring or fabricated animation. Source rectangles and sizes fully recorded in runtime art_review.json.','Contract: combat1254x1254,4x4 edges[0,313,627,940,1254]; hurt1254x313 each4frames; logical384x384 anchor192,345; atlas support156.5,289.','Native alpha verified numerically. Very faint detached residue outside significant-component rectangles may be omitted by rectangular cropping only.','Visual T/F/H/E/S pass; camera angle/top-area and partially occluded2:1 shadow are visual judgements, not a3D reconstruction. Three red throne doodles on SW; some hidden on NE; tiny folds/marks vary.','Godot not launched. No gameplay integration. Historical0101a rejections remain archived.','0102 integrated board still needs crumpled_map replacement.']
    (DOC/'SOURCE.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('Recorded4 native calls, exact prompts, source mapping and decisions')
def validate():
    m=json.loads((RUNTIME/'art_review.json').read_text(encoding='utf-8'))
    report={'status':'TARGETED_PASS','frames':0,'unique_frames':0,'border_alpha_pixels':0,'source_edge_alpha192':0,'own_body_cropped_alpha96':0,'foreign_body_pixels':0,'cropped_residue_alpha8':0,'max_contact_x_error':0,'support_y_error':0,'native_originals':0,'pixel_reproduction':True,'changed_existing':[]}
    hashes=set()
    for direction in m['directions'].values():
        for kind,rec in direction.items():
            im=Image.open(rec['path']);assert im.mode=='RGBA' and im.size==(1254,313 if kind=='hurt' else 1254);assert sha(Path(rec['path']))==rec['sha256']
            for f in rec['frames']:
                x,y,w,h=f['cell'];q=im.crop((x,y,x+w,y+h));a=np.array(q.getchannel('A'));border=a.copy();border[5:-5,5:-5]=0
                report['border_alpha_pixels']+=int((border>0).sum());report['frames']+=1
                for key,field in [('source_edge_alpha192','slice_edge_alpha192'),('own_body_cropped_alpha96','own_body_cropped_alpha96'),('foreign_body_pixels','foreign_body_pixels'),('cropped_residue_alpha8','cropped_residue_alpha8')]:report[key]+=f[field]
                report['max_contact_x_error']=max(report['max_contact_x_error'],abs(f['contact_x']-156.5));report['support_y_error']=max(report['support_y_error'],abs(f['support_y']-289))
                hashes.add(hashlib.sha256(q.tobytes()).hexdigest())
                src=Image.open(f['source_path']).convert('RGBA').crop(f['source_slice']).crop(f['source_bbox']);rx,ry,rw,rh=f['rect'];src=src.resize((rw,rh),L)
                blank=Image.new('RGBA',(rw,rh));blank.alpha_composite(src)
                assert np.array_equal(np.array(blank),np.array(im.crop((rx,ry,rx+rw,ry+rh)))),('pixel mismatch',f)
    report['unique_frames']=len(hashes)
    for n in range(1,5):
        im=Image.open(OUT/f'generated_attempt_{n}.png');a=np.array(im.getchannel('A'));g=json.loads((OUT/f'generation_attempt_{n}.json').read_text(encoding='utf-8'))
        assert im.mode=='RGBA' and a.min()==0 and g['sha256']==sha(OUT/f'generated_attempt_{n}.png');report['native_originals']+=1
    protected=json.loads((OUT/'protected_hashes.json').read_text(encoding='utf-8'))
    report['changed_existing']=[p for p,h in protected.items() if not (ROOT/p).exists() or sha(ROOT/p)!=h]
    allowed=['assets/sprites/v130r/quarter_final/crumpled_map/REJECTED.md','docs/handoff/CURRENT.md']
    assert set(report['changed_existing'])<=set(allowed),report['changed_existing']
    source_docs=list((ROOT/'assets/source/imagegen').rglob('SOURCE.md'))
    for p in list(RUNTIME.glob('*.png'))+list(OUT.glob('*.png'))+[BOARDS/'review_0103.png',BOARDS/'review_0103_review.png']:
        rel=p.relative_to(ROOT).as_posix()
        matches=sum(t.read_text(encoding='utf-8').count('image path: '+rel+'\n') for t in source_docs)
        assert matches==1,('source mapping',rel,matches)
    assert report['frames']==report['unique_frames']==40
    assert report['max_contact_x_error']<=.51 and report['support_y_error']==0
    assert all(report[k]==0 for k in ['border_alpha_pixels','source_edge_alpha192','own_body_cropped_alpha96','foreign_body_pixels'])
    dump(OUT/'validation_0103.json',report);print(json.dumps(report,indent=2))
if __name__=='__main__':
    {'assemble':assemble,'boards':boards,'provenance':provenance,'validate':validate}[sys.argv[1]]()
