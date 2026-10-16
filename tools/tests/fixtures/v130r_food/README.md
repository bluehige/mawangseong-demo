# 식량 호환성 고정 시험 자료

개인 세이브를 사용하지 않는다. 앞 단계에서 검증한 v5/v6 **시험 복사본**을 고정했다.
플레이어 표시 이름만 재귀적으로 `식량 호환 시험`으로 치환하고 JSON을 압축 직렬화했다.
식량 상태 필드가 없는 기존 구조와 명단을 정상 Continue 경로로 검사한다.
파일에는 제품 SemVer가 없어 실제 개인 1.2.12/1.3.0 세이브의 출처를 증명하지 않는다.
각 버전이 사용하는 v5/v6 저장 구조의 호환 검증이며, 원본 시험 파일은 수정하지 않았다.

- `campaign_save_v5.json`: 기존 시험 산출물 `tmp/v130r_step1/copies/legacy_v5/campaign_save_v5.json`. 원본 SHA256 `d5ff5a680e8f7a2adc85586fc13528d5c9cda23b09c7a28cad83e4577201fc9c`.
- `campaign_save_v6.json`: 기존 시험 산출물 `tmp/v130r_step1/copies/plot_v6/campaign_save_v6.json`. 원본 SHA256 `6a449b06a3cd12d7a150ec62f14fb3d6dd6fd7d663a50b682f9828e90cbbf9ee`.

`V130RStep6FoodTest.gd`는 이 파일을 매번 새로운 `tmp/v130r_step6/copies/run_<pid>_*`에 복사한다.
자동 마이그레이션과 새 저장은 그 사본에만 기록한다.
