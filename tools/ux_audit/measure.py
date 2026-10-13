"""Produce measured report rows and 960px representative JPEGs from real frames.

Control text counts are separate from custom draw text. Clipped scroll entries,
zero visible lines, modal scope, and unknown occlusion are reported explicitly.
"""
import csv
import json
from collections import Counter
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tmp/v1213_uiux_audit"
REPORT = ROOT / "docs/design/v1213_uiux/UX_AUDIT_2026-10-14.md"
JPG = REPORT.parent / "audit"
# id, Korean screen name, player decision, repeated information / visual evidence.
CASES = [
    ("02_update_notice", "첫 실행 업데이트", "확인 후 타이틀로", "첫 진입을 안내창이 점유"),
    ("03_title", "타이틀", "새 게임을 시작할지", "설명 문구 2곳; 동료 카드가 버튼처럼 보임"),
    ("05_settings_display", "설정·화면", "글자·배치·창 모드 선택", "선택값과 우측 현재값 중복"),
    ("06_settings_general", "설정·일반", "언어·튜토리얼 수준 선택", "안내 설명과 미리보기 설명 중복"),
    ("07_settings_audio", "설정·오디오", "음량별 크기 설정", "설정값과 현재값 반복"),
    ("08_settings_combat", "설정·전투 연출", "컷신·효과 정책 선택", "긴 정책 설명; 기본 슬라이더/선택 UI"),
    ("10_name_entry", "이름 입력", "이름 확정", "안내창과 입력 안내 중복"),
    ("11_opening_dialogue", "오프닝 대화", "화자 확인 후 다음", "왼쪽 한 자리만 사용; 1/4 진행 번호"),
    ("13_opening_second_speaker", "오프닝·다음 화자", "화자 교체를 알아볼지", "같은 초상 자리 교체; 대화 참여자 유지 안 됨"),
    ("12_dialogue_backlog", "대화 로그", "지난 대사 읽고 복귀", "날짜·화자·본문 목록; 읽기 전용"),
    ("15_story_dialogue", "관리 진입 스토리", "다음 대사로", "서사와 튜토리얼 대화 진입이 분리됨"),
    ("17_intrusion_brief", "DAY1 침입 정보", "적과 방어선 확인 후 배치", "경로를 긴 방 이름 문장으로 표시"),
    ("18_day1_roster", "DAY1 배치 튜토리얼", "곱의 전열/후열 선택", "지도·카드의 이름/위치 반복; 마스크 테두리"),
    ("20_day1_deploy_choice", "DAY1 배치 후보", "곱 합류 위치 결정", "카드·지도·튜토리얼·하단 안내 중복"),
    ("23_day1_placement_ready", "DAY1 배치 완료", "건설 또는 방어 시작", "수비대 카드와 하단 안내"),
    ("24_day1_build", "건설 탭·팔레트", "시설 종류 선택", "시설 비용·역할의 카드 나열"),
    ("25_build_targets_day1", "건설 위치 강조", "설치할 위치 선택", "지도 건설 문구와 하단 선택 안내"),
    ("26_build_review_day1", "건설 검토 바", "비용·효과 확인 후 확정", "지도 검토 중/하단 검토 중 반복"),
    ("27_build_complete_day1", "건설 완료", "다음 배치/전투로", "수용량 총계가 아닌 시설별 설명"),
    ("30_defense_countdown", "방어 시작 카운트다운", "취소 또는 출진 대기", "배치 고정/변경 잠금 반복"),
    ("31_combat_hud_day1", "DAY1 전투 HUD", "명령·지침·스킬 선택", "지도 이름·선택 정보·지침 위치 반복"),
    ("36_combat_story_overlay", "전투 중 대화", "대사 후 전투 재개", "공통 메뉴와 대화 메뉴 병존"),
    ("37_pause_menu", "일시정지 메뉴", "계속/저장/불러오기 선택", "하네스 저장 미연결 상태; 결함 근거 제외"),
    ("38_save_restriction", "전투 저장 제한", "제한 읽고 계속", "하네스 저장 미연결; 문구 구조만 평가"),
    ("39_confirm_load", "불러오기 확인창", "손실 확인 후 취소/불러오기", "체크포인트·손실 설명을 재표시"),
    ("44_result_initial", "승리 결과·선택 전", "집중성장 한 명 선택", "튜토리얼·성장 확인·다음날 잠금 안내 반복"),
    ("45_result_focus_applied", "승리 결과·집중성장 후", "성장 확인", "EXP·공유/활약·다음 방어 효과 분산"),
    ("46_monster_day1", "승리 결과·확인 완료", "다음 DAY 진행", "성장 확인을 눌러도 결과 화면 유지"),
    ("47_day2_transition", "DAY 전환 대화", "새 날 이야기 읽기", "결과 뒤 다시 8회 대화"),
    ("48_day2_intrusion", "DAY2 침입 정보", "도둑 포함 적 편성 확인", "관리 화면 침입 정보와 별도 페이지"),
    ("49_day2_management_tutorial", "DAY2 관리 튜토리얼", "가시 복도 선택", "어두운 마스크의 가로 테두리 노출"),
    ("51_room_detail_tutorial", "DAY2 방 상세/지침", "함정 유도 지침 선택", "예상 경로·방 설명·튜토리얼 중복"),
    ("56_monster_day2_top", "DAY2 성장 첫 화면", "필수 특화 또는 훈련", "훈련이 필수 특화와 준비 효과 아래로 밀림"),
    ("62_training_scroll", "훈련 영역", "훈련 비용/EXP 확인", "성장 전후 수치는 있으나 경험치바 없음"),
    ("63_training_result", "실제 훈련 후", "다른 동료 선택/추가 훈련", "전후 미리보기가 갱신돼 방금 결과가 약함"),
    ("64_training_visible_click", "오늘 훈련 완료", "다음 동료 선택", "하루 횟수 버튼 문구로 표시"),
    ("143_paid_training_verified", "추가 확인·유료 훈련", "EXP 변경 확인", "실제 금화30 지불·EXP20·당일 훈련1회 확인"),
    ("144_selection_after_training_verified", "추가 확인·훈련 후 선택", "핀으로 선택 전환", "곱 훈련 직후 실제 핀 버튼 선택 가능"),
    ("65_save_success_real", "실제 저장 완료 메뉴", "체크포인트 확인", "저장 완료와 상단 체크포인트 반복"),
    ("66_title_continue", "이어하기 타이틀", "DAY2 이어하기", "저장 DAY·체크포인트·이어하기 문구"),
    ("69_continue_restart", "별도 프로세스 복원", "저장한 성장 화면에서 계속", "합성 저장 실제 직렬화/복원; 날짜 유지"),
    ("70_growth_day12_top", "후기 성장·상단", "훈련·특화·승급 선택", "목록+큰 초상+장문 성장 목록 3열"),
    ("71_growth_promotion", "전직/승급 분기", "두 진화 모습 비교", "효과·비용만 보이고 충족 조건 비교 약함"),
    ("72_growth_skills", "보유 기술·잠금 슬롯", "기술 효과 확인", "174px 카드 3개; 습득 레벨 설명 부족"),
    ("73_memory_empty", "기억·미해금", "해금 방법 파악", "유대/해금 개수와 비어 있는 설명"),
    ("81_memory_unlocked", "기억·해금", "기억을 골라 읽기", "동료 이름·유대·개수는 좌측에서 반복"),
    ("75_duo_links", "합동기 편성", "6개 효과·해금·편성 비교", "동료 성장과 별도 회차 편성 화면"),
    ("76_management_build_day12", "후기 관리·건설", "시설 설치/강화 선택", "운영/전략 바와 DAY 공지 중 작은 글씨"),
    ("77_management_roster_day12", "후기 관리·수비대", "동료 배치 또는 성장", "지도/카드/상단 편성의 동료 정보 반복"),
    ("78_management_tactics_day12", "후기 관리·전술", "전역 지침·예상 경로 선택", "지침·방 지침·경로·특수 전략이 분산"),
    ("79_room_detail_day12", "후기 관리·방 상세", "정원/지침/강화 결정", "경로 설명과 상단 예상 경로 반복"),
    ("80_room_facility_palette", "방 시설 교체", "팔레트에서 새 시설 선택", "교체 진입 후 위치 선택을 다시 요구"),
    ("118_upgrade_insufficient", "강화·재료 부족", "필요 재료 확인", "합성 상태 알림 혼입; 비활성 사유만 평가"),
    ("135_upgrade_eligible", "강화·가능", "강화 효과/비용 확인", "합성 저장 알림 혼입; 효과 전후 표 없음"),
    ("136_upgrade_maximum", "강화·최대", "최대 레벨 사유 확인", "합성 저장 알림 혼입; S1 사유 정상"),
    ("137_upgrade_fixed", "강화·고정 건물", "고정 건물 사유 확인", "합성 저장 알림 혼입; S1 사유 정상"),
    ("95_promotion_applied", "진화 적용 후", "새 역할 확인", "실제 진화/후속 다른 동료 선택 가능"),
    ("96_selection_after_promotion", "진화 후 동료 선택", "다른 동료 육성", "S1 성장 선택 불가 증상 재현 안 됨"),
    ("98_unit_information", "전투·유닛 정보", "스킬 수동 발동", "기본 이름/애칭 혼용; 빈 공간 큰 상세창"),
    ("101_command_targeting", "전투·명령 대상", "강조된 방어 구역 클릭", "명령 선택 안내와 지도 표식 반복"),
    ("100_command_toast", "명령 거절 토스트", "유효 대상 재선택", "생산 토스트에 합성 이벤트 입력"),
    ("99_skill_action", "컷신·지원 알림 겹침", "발동 장면 확인", "지원 알림이 컷신 제목을 덮음; stage 텍스트 4개는 별도 보정"),
    ("141_skill_cutscene", "컷신·정상 대표", "장면 확인 또는 스킵", "평면 단색 무대와 평소 HUD 잔류"),
    ("102_pause_real_checkpoint", "전투 메뉴·체크포인트", "계속 또는 복원", "복원 가능한 실제 감사 저장 표시"),
    ("103_leave_confirmation", "타이틀 이동 확인", "저장/저장 없이/취소", "메뉴의 손실 설명 재표시"),
    ("142_defeat_result", "패배 결과", "배치 수정/동일 배치 재도전", "승리와 같은 큰 기록 프레임; 합성 결산"),
    ("82_campaign_mode_selection", "다음 회차 모드", "전선/의회 선택", "잠금 해금 설명이 텍스트 중심"),
    ("83_front_selection", "전선 선택", "세 전선 효과 비교", "보상·규칙·관계·설명 동시 노출"),
    ("84_heart_selection", "성의 심장 선택", "세 심장 효과 비교", "장문 효과 목록과 준비 선택 단계 추가"),
    ("85_cycle_doctrine", "왕국 교리 대응", "교리 대응 하나 확정", "칙령·인장과 동일 목록/상세 구조"),
    ("86_cycle_decree", "마왕 칙령", "운영 원칙 하나 확정", "교리/지침/전략과 용어 층위 혼동"),
    ("87_challenge_seal", "도전 인장", "도전 하나 선택", "준비 선택 단계를 또 추가"),
    ("88_contract_board", "계약 동료 목록", "계약 동료 비교/영입", "현재 성장과 별도 미래 동료 접근 경로"),
    ("140_companion_collection_clean", "출전·예비 편성", "동료 출전/예비 전환", "성장 목록과 별도 편성 목록"),
    ("89_raid_preview", "첫 원정 예고", "원정 진입", "원정 화면과 별도 예고 화면"),
    ("90_raid", "원정 임무/편성", "임무와 참가자 선택", "동료 이름·역할·보상 목록"),
    ("130_chronicle_front", "연대기·전선/심장", "기록 항목 선택", "다음 회차 설명이 메뉴 안에 숨음"),
    ("131_chronicle_relations", "연대기·라이벌/합동 기억", "기억 기록 확인", "도감/기억/연대기 용어 혼용"),
    ("132_chronicle_run", "연대기·회차/후일담", "지난 회차 기록 확인", "유사 기록 화면이 별도로 존재"),
    ("133_chronicle_accessibility", "연대기·표시/조작 설정", "표시 정책과 층 단축키 선택", "설정과 연대기에 접근성 설정 분산"),
    ("92_upper_floor", "상층 배치·선택", "3가지 배치 비교", "방 그림보다 추상 도식; 장점·주의 문장"),
    ("107_upper_floor_locked", "상층 배치·확정", "고정된 연결 확인", "배치 선택과 실제 2F 화면이 다른 표현"),
    ("108_multifloor_1f", "다층 전투·1F", "층별 상태·명령 확인", "최하단 층 선택이 작은 글씨"),
    ("117_multifloor_valid", "다층 전투·2F", "왕관실/금고와 1F 상황 판단", "2F 도식에 1F 선택 유닛 정보가 남음"),
    ("93_region_selection", "지역 경로 선택", "지역 효과와 적/보상 비교", "규칙·적·보상·인장 조건의 문장 밀도 높음"),
    ("94_outpost_management", "전초기지 관리", "유형/파견/강화 선택", "본성 배치와 별도 출전 관리"),
    ("116_outpost_battle_valid", "전초기지 전투", "깃발과 파견 성과 관찰", "본성 전투와 완전히 다른 도식"),
    ("113_council_vote", "의회 표결", "의제와 찬성/수정/반대 선택", "숫자 예측·설명 다수; 합성 의회 상태"),
    ("114_council_declaration", "의회 최종 선언", "회기 뒤 약속 선택", "4개 긴 문장 버튼"),
    ("115_crown_choices_valid", "왕관·후보 없음", "대체 보상 선택", "왜 후보가 없는지 세부 조건 안 보임"),
    ("139_crown_clean", "왕관·후보 있음", "왕관 진화/대체 보상 선택", "초상·전후 비교 없이 문장 버튼"),
    ("104_ending", "엔딩", "후일담/계승/다음 회차", "긴 계승 설명과 작은 버튼"),
    ("09_ending_archive_locked", "엔딩 도감·미해금", "미해금 엔딩 확인", "목록과 본문; 다음 동료 도감과 다름"),
    ("105_ending_archive", "엔딩 도감·기록", "해금 엔딩 다시 읽기", "계승·기억·후일담 진입점 분산"),
    ("119_tutorial_practice", "튜토리얼 연습", "조작 안내를 따라 연습", "이중 튜토리얼 체계; 실제 진행과 별도"),
    ("120_touch_title", "터치·타이틀", "새 게임 시작", "중앙 메뉴 요구와 불일치"),
    ("121_touch_management", "터치·관리", "큰 카드로 배치/건설", "동료 도크가 탭을 덮음"),
    ("122_touch_room_detail", "터치·방 상세", "방 지침·강화 선택", "큰 상세창과 지도 시야 경쟁"),
    ("123_touch_growth", "터치·성장", "훈련과 동료 선택", "18개 라벨 visible_lines=0; 이름/비용 소실"),
    ("124_touch_dialogue", "터치·대화", "큰 다음 버튼 사용", "합성 영어 대사; 배치만 평가"),
    ("125_touch_combat", "터치·전투", "명령/스킬/배속 탭", "유닛 상세가 배속/명령 일부를 덮음"),
    ("126_touch_skill_cutscene", "터치·컷신", "스킵 또는 관찰", "높은 Canvas의 배속 패널이 컷신 배우를 덮음"),
]

REPRESENTATIVES = ["03_title", "11_opening_dialogue", "17_intrusion_brief", "18_day1_roster", "26_build_review_day1", "78_management_tactics_day12", "70_growth_day12_top", "46_monster_day1", "99_skill_action", "117_multifloor_valid", "123_touch_growth", "104_ending"]
MODALS = ["CampaignLeaveConfirmation", "DialogueBacklogOverlay", "UpdateNotesOverlay", "PauseMenuOverlay", "Update4CouncilDecisionOverlay"]


def scope(controls):
    for modal in MODALS:
        selected = [c for c in controls if f"/{modal}/" in c["path"] or c["name"] == modal]
        if selected:
            return selected, modal
    return controls, "screen"


def metrics(case):
    identity, name, decision, note = case
    data = json.loads((OUT / f"{identity}.json").read_text(encoding="utf-8"))
    controls, modal = scope(data["controls"])
    text = [c for c in controls if c["text"]]
    visible = [c for c in text if c.get("visible_lines", 1) > 0]
    buttons = [c for c in controls if c["button"]]
    sizes = Counter(c["font_px"] for c in visible)
    modes = sorted(n for n, count in sizes.items() if count == max(sizes.values())) if sizes else []
    zeros = [c for c in text if c.get("visible_lines", 1) == 0]
    candidates = list({c["path"]: c for c in text + buttons}.values())
    scroll = [c for c in candidates if c["clipped"] and c["clip_parent"] and "Scroll" in c["clip_parent"]]
    bounds = [c for c in candidates if c["clipped"] and not c["clip_parent"]]
    suspicious = [c for c in visible if c.get("line_count", 0) > c.get("visible_lines", 999) and not c["clipped"]]
    world = data.get("world_text", []) if modal == "screen" else []
    row = dict(id=identity, screen=name, engine_screen=data["screen"], decision=decision,
               scope=modal, rendered_blocks=len(visible), configured_blocks=len(text),
               font_min=min(sizes) if sizes else None, font_modes=modes,
               buttons=len(buttons), tooltip_empty=sum(not c["tooltip"].strip() for c in buttons),
               zero_lines=len(zeros), scroll_clipped=len(scroll), viewport_clipped=len(bounds),
               multiline_cut_candidates=len(suspicious), duplicate_note=note, world_badges=len(world),
               raw_sha_note="Product SHA 45eb925; UI-only runtime fixtures",
               zero_line_paths=[c["path"] for c in zeros])
    if identity == "99_skill_action":
        # Old capture preceded effect-root collection. Actual stage has 3 Labels
        # (36,24,24) and one Button (20); verified in later capture 141.
        row["rendered_blocks"] += 4
        row["configured_blocks"] += 4
        row["buttons"] += 1
        row["tooltip_empty"] += 1
        row["effect_stage_correction"] = True
    return row


def main():
    JPG.mkdir(parents=True, exist_ok=True)
    assert len(REPRESENTATIVES) <= 12
    for identity in REPRESENTATIVES:
        with Image.open(OUT / f"{identity}.png") as source:
            assert source.size == (1920, 1080), identity
            source.convert("RGB").resize((960, 540), Image.Resampling.LANCZOS).save(JPG / f"{identity}.jpg", quality=86, optimize=True)
    rows = [metrics(case) for case in CASES]
    OUT.joinpath("measurements.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    with OUT.joinpath("measurements.csv").open("w", encoding="utf-8-sig", newline="") as f:
        fields = [k for k in rows[0] if k != "zero_line_paths"]
        writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    table = ["| 캡처 / 화면 | 텍스트 실제/설정 | 글자 최소/최빈 px | 버튼 / 빈 툴팁 | 잘림 L/S/V | 플레이어의 결정 | 중복·표시 관찰 |", "|---|---:|---:|---:|---:|---|---|"]
    for r in rows:
        size = f"{r['font_min']}/{'·'.join(map(str,r['font_modes']))}"
        table.append(f"| [{r['id']}](../../../tmp/v1213_uiux_audit/{r['id']}.png) · {r['screen']} | {r['rendered_blocks']}/{r['configured_blocks']} | {size} | {r['buttons']} / {r['tooltip_empty']} | {r['zero_lines']}/{r['scroll_clipped']}/{r['viewport_clipped']} | {r['decision']} | {r['duplicate_note']} |")
    content = REPORT.read_text(encoding="utf-8")
    before, tail = content.split("<!-- MEASURED_TABLE_START -->", 1)
    _, after = tail.split("<!-- MEASURED_TABLE_END -->", 1)
    REPORT.write_text(before + "<!-- MEASURED_TABLE_START -->\n\n" + "\n".join(table) + "\n\n<!-- MEASURED_TABLE_END -->" + after, encoding="utf-8")
    print(f"MEASUREMENTS: {len(rows)} cases; JPEG: {len(REPRESENTATIVES)} x 960x540")


if __name__ == "__main__":
    main()
