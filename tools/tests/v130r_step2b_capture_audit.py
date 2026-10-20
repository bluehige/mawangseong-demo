"""Audit genuine captures; QA overlays/comparison never replace game output."""
from pathlib import Path
import csv
import hashlib
import json
import shutil
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
MOCK = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup')
OUT = MOCK/'game_step2b'
LOCAL = ROOT/'tmp/v130r_step2b'
SIZES = {'start_1920':(1920,1080), 'start_1280':(1280,720),
         'start_2560':(2560,1440), 'start_16x10':(1920,1200),
         **dict.fromkeys(['info_upgrade','info_dismantle','radial_edge',
                          'build_bar_cost','minimap_click'],(1920,1080))}
DIFFERENCES = [
    ['시작 카메라','임의 도형 맵 구도','옥좌·입구 문 알파 외곽과 실제 UI 사각형으로 최대 배율 계산','다리와 다른 건물 일부 잘림은 사용자 허용'],
    ['건설 바','왼쪽 세로형','하단 가로형·모든 비용 한 줄 자원 그림+숫자','사용자 지시의 가로형 유지'],
    ['정보창','목업의 보라 사각 프레임·임의 가격','GPT 흑요석 패널·실제 배치 모델의 정원/강화/환불','프레임·가격·효과 문구가 목업과 다름'],
    ['단계 탭','보라 도형 탭·문자','GPT 흑요석 판·GPT 건설/몬스터/전투 그림','건설 강조·나머지 비활성, 단계 연결 없음'],
    ['원형 메뉴','건물 중심 고정 5개','벽·문·건물·UI를 피해 각도/거리 개별 조정','혼잡하면 완전한 원이 아닌 벌어진 배치'],
    ['미니맵','고정 도형 축소 그림·흰 사각형','현재 실제 조립 맵의 별도 뷰포트·GPT 금빛 화면 테두리','장식과 가시성은 사용자 확인 대기'],
    ['자원 HUD','문자 한 줄·악명·옥좌/금고/명령','GPT 금/마나/식량 아이콘+현재 시험 자원','이번 범위의 자원 3종만 표시'],
    ['영향 효과','목업의 예시 전투 수치','정원·반경 및 기존 시설 역할을 게임 용어로 요약','시각 반경은 2단계 값, 전투 적용은 다음 단계'],
]


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    checks = []
    def check(ok,label): checks.append({'ok':bool(ok),'label':label})
    for name,size in SIZES.items():
        check(Image.open(OUT/(name+'.png')).size==size,'actual game dimensions '+name)
    metrics = json.loads((LOCAL/'camera_metrics.json').read_text(encoding='utf-8'))
    (OUT/'camera_metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2),encoding='utf-8')
    with (OUT/'camera_values.csv').open('w',encoding='utf-8-sig',newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['resolution','zoom','maximum_before_inset','center_x','center_y'])
        for resolution,data in metrics.items():
            writer.writerow([resolution,data['zoom'],data['maximum'],*data['center']])
            width,height = map(int,resolution.split('x'))
            for target in data['targets']:
                x,y,w,h = target
                check(x>=0 and y>=0 and x+w<=width and y+h<=height,'target inside '+resolution)
                for key,panel in data['ui'].items():
                    a,b,c,d = panel
                    check(x+w<=a or a+c<=x or y+h<=b or b+d<=y,'independent no overlap '+resolution+' '+key)
    # QA-only rectangles on an exact copy of the pure start screenshot.
    overlay = Image.open(OUT/'start_1920.png').convert('RGB')
    draw = ImageDraw.Draw(overlay)
    font = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',22)
    def box(rect,color,label):
        x,y,w,h = rect
        draw.rectangle((round(x),round(y),round(x+w),round(y+h)),outline=color,width=3)
        draw.text((x+5,y+5),label,font=font,fill=color,stroke_width=2,stroke_fill='black')
    for name,r in zip(['옥좌 전체','입구 문 전체'],metrics['1920x1080']['targets']):
        box(r,'#7cffa8',name)
    for name,r in metrics['1920x1080']['ui'].items(): box(r,'#ffd66e','UI: '+name)
    overlay.save(OUT/'start_check.png')
    compare = Image.new('RGB',(3840,1080))
    compare.paste(Image.open(MOCK/'ui_icons_v1/ui_preview_build.png').convert('RGB'),(0,0))
    compare.paste(Image.open(OUT/'info_upgrade.png').convert('RGB'),(1920,0))
    compare.save(OUT/'compare_ui_vs_mockup.png')
    check(compare.size==(3840,1080),'comparison dimensions')
    with (OUT/'differences.csv').open('w',encoding='utf-8-sig',newline='') as file:
        writer = csv.writer(file); writer.writerow(['항목','목업','실제 게임','남은 차이/판정']); writer.writerows(DIFFERENCES)
    # Keep inspection bounded: exactly one <=1000px preview is opened at a time.
    thumb = OUT/'previews'; thumb.mkdir(exist_ok=True)
    for name in [*SIZES,'start_check','compare_ui_vs_mockup']:
        image = Image.open(OUT/(name+'.png')); image.thumbnail((1000,650)); image.save(thumb/(name+'.png'))
    original = json.loads((LOCAL/'existing_files.json').read_text(encoding='utf-8'))
    changed = [name for name,digest in original.items()
               if not (ROOT/name).is_file() or hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest]
    check(not changed,'existing mixed changes preserved')
    preservation = {'existing_file_count':len(original),'changed':changed}
    (OUT/'preservation_audit.json').write_text(json.dumps(preservation,ensure_ascii=False,indent=2),encoding='utf-8')
    for mode in ['direct','capture']:
        result = json.loads((LOCAL/(mode+'_result.json')).read_text(encoding='utf-8'))
        check(result['result']=='TARGETED_PASS' and not result['failures'],mode+' checks pass')
        err = (LOCAL/(mode+'.err.log')).read_text(encoding='utf-8')
        check(not err.strip(),mode+' stderr empty')
        for suffix in ['.log','.err.log','_result.json']:
            shutil.copy2(LOCAL/(mode+suffix),OUT/(mode+suffix))
    report = {'checks':len(checks),'failures':[c for c in checks if not c['ok']],
              'result':'TARGETED_PASS' if all(c['ok'] for c in checks) else 'FAIL','details':checks}
    (OUT/'capture_audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='details'},ensure_ascii=False))
    if report['failures']: raise SystemExit(1)


if __name__=='__main__': main()
