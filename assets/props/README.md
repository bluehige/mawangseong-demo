이 파일이 왜 필요한지: 왕좌, 보물더미, 병영 장식 같은 오브젝트를 바닥 타일과 분리하기 위한 위치를 정한다.

# Quarter-View Prop Assets

소품은 방 배경에 굽지 않고 Blueprint의 `object_slots`로 배치한다.

- `throne`: 왕좌 back/front 분리 이미지.
- `treasure`: 보물더미, 상자, 금화.
- `barracks`: 무기대, 훈련 더미, 침상.
- `recovery`: 회복 둥지, 회복 풀, 포션 선반.
- `traps`: 가시, 마법진, 독안개 등 함정 프레임.

큰 소품은 `asset_manifest.json`에 footprint와 block_cells를 함께 기록한다.
