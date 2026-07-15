# STOVE upload asset workspace

STOVE Studio에 바로 올릴 최종 규격 파일만 둔다. 현재 자산은 승인된 게임 내
일러스트와 Steam용 실제 플레이 캡처를 결정론적으로 크롭·리사이즈한 것이다.

| 경로 | 규격 | 용도 |
|---|---:|---|
| `store/title_square_500.png` | 500×500 | 정사각 타이틀 이미지 |
| `store/title_landscape_757x426.png` | 757×426 | 16:9 타이틀 이미지 |
| `store/pc_thumbnail_500.png` | 500×500 | PC 썸네일 |
| `icons/windows_desktop.ico` | 256×256 포함 ICO | Windows 바탕화면 아이콘 |
| `screenshots/*.png` | 860×483 | 실제 플레이 스크린샷 6장 |

재생성:

```powershell
python tools/release/generate_stove_graphics.py
```

스크린샷은 합성 홍보물이 아니라 실제 게임 화면이어야 한다. 최종 빌드에서 UI와
콘텐츠가 바뀌면 원본 캡처를 갱신한 뒤 다시 생성한다.
