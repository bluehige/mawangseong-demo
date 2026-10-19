"""Resize CU evidence before any model viewing; OCR only the <=960px copy."""
import json
from pathlib import Path
import subprocess
from PIL import Image

root=Path(__file__).resolve().parent
state=json.loads((root/'capture_pending.json').read_text(encoding='utf-8'))
source=root/'captures/raw_capture.png'
image=Image.open(source)
raw_size=image.size
image.thumbnail((960,960),Image.Resampling.LANCZOS)
dest=root/'captures'/(state['tag']+'.png')
image.save(dest)
state.update(path=str(dest),raw_size=raw_size,size=image.size,xscale=state.get('api_width',raw_size[0])/image.width,yscale=state.get('api_height',raw_size[1])/image.height)
history=json.loads((root/'cu_capture_index.json').read_text(encoding='utf-8')) if (root/'cu_capture_index.json').exists() else []
history.append(state)
(root/'cu_capture_index.json').write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf-8')
(root/'capture_latest.json').write_text(json.dumps(state,ensure_ascii=False,indent=2),encoding='utf-8')
p=subprocess.run(['powershell','-NoProfile','-File',str(root/'ocr_capture.ps1'),'-CapturePath',str(dest)],capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW)
try:
    lines=json.loads(p.stdout.decode('utf-8-sig'))
except (UnicodeDecodeError,json.JSONDecodeError):
    lines=p.stdout.decode('utf-8',errors='replace')
(root/'captures'/(state['tag']+'_ocr.json')).write_text(json.dumps(lines,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(dict(tag=state['tag'],size=image.size,xscale=state['xscale'],yscale=state['yscale'],lines=lines),ensure_ascii=False))
