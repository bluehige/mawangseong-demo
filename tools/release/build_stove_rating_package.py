#!/usr/bin/env python3
"""Build the local STOVE self-rating submission material package."""

from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path
from typing import Any, Iterable

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[2]
VERSION = "v2.0.1"
GENERATED_DATE = "2026-07-15"
FONT_PATH = ROOT / "assets/fonts/NotoSansCJKkr-Regular.otf"
PDF_FONT_PATH = Path("C:/Windows/Fonts/malgun.ttf")
PDF_OUTPUT = ROOT / "output/pdf"
DEFAULT_OUTPUT = Path.home() / "Desktop/STOVE_UPLOAD/STOVE_SUBMISSION_v2.0.1/02_RATING_MATERIALS"
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}

CATALOG_SPECS = [
    ("characters", "기본 캐릭터", ROOT / "data/characters.json"),
    ("characters", "UPDATE 4 캐릭터", ROOT / "data/regular_version/update4/characters.json"),
    ("monsters", "기본 몬스터", ROOT / "data/monsters.json"),
    ("monsters", "UPDATE 3 몬스터", ROOT / "data/regular_version/update3/monsters.json"),
    ("monsters", "UPDATE 4 몬스터", ROOT / "data/regular_version/update4/monsters.json"),
    ("enemies", "기본 적", ROOT / "data/enemies.json"),
    ("enemies", "UPDATE 3 적", ROOT / "data/regular_version/update3/enemies.json"),
    ("enemies", "UPDATE 4 적", ROOT / "data/regular_version/update4/enemies.json"),
    ("enemies", "UPDATE 4 라이벌 보스", ROOT / "data/regular_version/update4/rival_bosses.json"),
]

ENDING_CATALOGS = [
    ROOT / "data/ending_rules.json",
    ROOT / "data/regular_version/update3/endings.json",
    ROOT / "data/regular_version/update4/council_endings.json",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def res_path(value: str) -> Path | None:
    if not value.startswith("res://"):
        return None
    path = ROOT / value.removeprefix("res://")
    return path if path.is_file() else None


def nested_resource_paths(value: Any) -> list[Path]:
    paths: list[Path] = []
    if isinstance(value, str):
        path = res_path(value)
        if path is not None and path.suffix.lower() in IMAGE_SUFFIXES:
            paths.append(path)
    elif isinstance(value, dict):
        for child in value.values():
            paths.extend(nested_resource_paths(child))
    elif isinstance(value, list):
        for child in value:
            paths.extend(nested_resource_paths(child))
    return paths


def first_art_path(entry: dict[str, Any]) -> Path | None:
    for key in ("portrait", "portraits", "sprite", "sprite_sheet", "placeholder_art"):
        candidates = nested_resource_paths(entry.get(key))
        if candidates:
            return candidates[0]
    return None


def collect_character_art() -> dict[str, list[dict[str, str]]]:
    groups: dict[str, list[dict[str, str]]] = {"characters": [], "monsters": [], "enemies": []}
    for group, catalog_label, path in CATALOG_SPECS:
        data = load_json(path)
        for entry_id, raw_entry in data.items():
            entry = raw_entry if isinstance(raw_entry, dict) else {}
            art_path = first_art_path(entry)
            groups[group].append(
                {
                    "id": str(entry_id),
                    "name": str(entry.get("display_name", entry_id)),
                    "catalog": catalog_label,
                    "path": str(art_path) if art_path is not None else "",
                }
            )
    return groups


def collect_endings() -> list[dict[str, str]]:
    endings: list[dict[str, str]] = []
    for catalog in ENDING_CATALOGS:
        for ending_id, raw_entry in load_json(catalog).items():
            entry = raw_entry if isinstance(raw_entry, dict) else {}
            art = res_path(str(entry.get("illustration", "")))
            endings.append(
                {
                    "id": str(ending_id),
                    "code": str(entry.get("catalog_code", "")),
                    "name": str(entry.get("display_name", ending_id)),
                    "path": str(art) if art is not None else "",
                }
            )
    return sorted(endings, key=lambda item: (item["code"], item["id"]))


def chroma_cleanup(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = np.array(rgba)
    red = pixels[:, :, 0].astype(np.int16)
    green = pixels[:, :, 1].astype(np.int16)
    blue = pixels[:, :, 2].astype(np.int16)
    mask = (red >= 210) & (blue >= 210) & (green <= 80) & (np.abs(red - blue) <= 70)
    pixels[mask, 3] = 0
    return Image.fromarray(pixels, "RGBA")


def fit_art(path: Path, size: tuple[int, int]) -> Image.Image:
    with Image.open(path) as opened:
        image = chroma_cleanup(opened)
    return ImageOps.contain(image, size, Image.Resampling.LANCZOS)


def safe_name(text: str) -> str:
    safe = "".join(character if character.isalnum() or character in "-_" else "_" for character in text)
    return safe.strip("_") or "item"


def wrap_pillow_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, max_width: int, max_lines: int = 2) -> list[str]:
    lines: list[str] = []
    current = ""
    for character in text:
        candidate = current + character
        box = draw.textbbox((0, 0), candidate, font=font)
        if current and box[2] - box[0] > max_width:
            lines.append(current)
            current = character
            if len(lines) == max_lines - 1:
                break
        else:
            current = candidate
    if current and len(lines) < max_lines:
        remaining_start = sum(len(line) for line in lines)
        remaining = text[remaining_start:]
        current = remaining
        while current and draw.textbbox((0, 0), current + "…", font=font)[2] > max_width:
            current = current[:-1]
        if remaining != current:
            current = current.rstrip() + "…"
        lines.append(current)
    return lines


def create_contact_sheets(
    items: list[dict[str, str]],
    output_dir: Path,
    prefix: str,
    title: str,
    columns: int = 4,
    rows: int = 3,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    title_font = ImageFont.truetype(str(FONT_PATH), 34)
    label_font = ImageFont.truetype(str(FONT_PATH), 19)
    small_font = ImageFont.truetype(str(FONT_PATH), 14)
    sheet_size = (1600, 1200)
    margin_x = 32
    header_h = 80
    tile_w = (sheet_size[0] - margin_x * 2) // columns
    tile_h = (sheet_size[1] - header_h - 28) // rows
    per_sheet = columns * rows
    paths: list[Path] = []

    for sheet_index in range(0, len(items), per_sheet):
        chunk = items[sheet_index : sheet_index + per_sheet]
        sheet = Image.new("RGB", sheet_size, "#100b18")
        draw = ImageDraw.Draw(sheet)
        page = sheet_index // per_sheet + 1
        page_count = (len(items) + per_sheet - 1) // per_sheet
        draw.text((32, 20), f"{title} ({page}/{page_count})", font=title_font, fill="#ffe9ad")
        for item_index, item in enumerate(chunk):
            column = item_index % columns
            row = item_index // columns
            x0 = margin_x + column * tile_w
            y0 = header_h + row * tile_h
            draw.rounded_rectangle(
                (x0 + 8, y0 + 8, x0 + tile_w - 8, y0 + tile_h - 8),
                radius=18,
                fill="#211631",
                outline="#7a5a9f",
                width=2,
            )
            image_path = Path(item["path"]) if item.get("path") else None
            if image_path is not None and image_path.is_file():
                art = fit_art(image_path, (tile_w - 44, tile_h - 105))
                art_x = x0 + (tile_w - art.width) // 2
                art_y = y0 + 22 + (tile_h - 105 - art.height) // 2
                sheet.paste(art, (art_x, art_y), art if art.mode == "RGBA" else None)
            else:
                draw.rectangle((x0 + 70, y0 + 70, x0 + tile_w - 70, y0 + tile_h - 125), fill="#39284a")
                draw.text((x0 + 94, y0 + 145), "런타임 도형/공용 자산", font=small_font, fill="#d4c1e8")
            label = f"{item.get('name', '')} [{item.get('id', '')}]"
            label_lines = wrap_pillow_text(draw, label, label_font, tile_w - 36, max_lines=2)
            label_y = y0 + tile_h - 88
            for label_line in label_lines:
                label_box = draw.textbbox((0, 0), label_line, font=label_font)
                label_x = x0 + max(16, (tile_w - (label_box[2] - label_box[0])) // 2)
                draw.text((label_x, label_y), label_line, font=label_font, fill="#fff4cf")
                label_y += 23
            draw.text((x0 + 18, y0 + tile_h - 30), item.get("catalog", ""), font=small_font, fill="#b9a5cf")
        path = output_dir / f"{prefix}_{page:02d}.png"
        sheet.save(path, "PNG", optimize=True)
        paths.append(path)
    return paths


def copy_ending_images(endings: list[dict[str, str]], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, ending in enumerate(endings, start=1):
        source = Path(ending["path"]) if ending.get("path") else None
        if source is None or not source.is_file():
            continue
        suffix = source.suffix.lower()
        destination = output_dir / f"{index:02d}_{safe_name(ending['code'])}_{safe_name(ending['id'])}{suffix}"
        shutil.copy2(source, destination)


def wrap_by_width(text: str, font_name: str, font_size: float, width: float) -> list[str]:
    if not text:
        return [""]
    lines: list[str] = []
    current = ""
    for character in text:
        candidate = current + character
        if current and pdfmetrics.stringWidth(candidate, font_name, font_size) > width:
            lines.append(current)
            current = character
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def register_pdf_font() -> str:
    font_name = "NotoSansCJKkr"
    if font_name not in pdfmetrics.getRegisteredFontNames():
        font_path = PDF_FONT_PATH if PDF_FONT_PATH.is_file() else FONT_PATH
        pdfmetrics.registerFont(TTFont(font_name, str(font_path)))
    return font_name


def draw_pdf_header(pdf: canvas.Canvas, font_name: str, title: str, page_number: int) -> float:
    page_w, page_h = A4
    pdf.setFillColorRGB(0.11, 0.07, 0.16)
    pdf.rect(0, page_h - 40, page_w, 40, fill=1, stroke=0)
    pdf.setFillColorRGB(1.0, 0.92, 0.69)
    pdf.setFont(font_name, 10)
    pdf.drawString(32, page_h - 26, title)
    pdf.drawRightString(page_w - 32, page_h - 26, f"{VERSION} | {page_number}")
    pdf.setFillColorRGB(0.25, 0.25, 0.25)
    pdf.setFont(font_name, 7)
    pdf.drawString(32, 20, f"STOVE 자체등급 심의자료 | 생성일 {GENERATED_DATE}")
    return page_h - 54


def write_language_pdf(tsv_path: Path, target: Path) -> tuple[int, int]:
    with tsv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    font_name = register_pdf_font()
    pdf = canvas.Canvas(str(target), pagesize=A4, pageCompression=1)
    page_w, _ = A4
    page_number = 1
    y = draw_pdf_header(pdf, font_name, "게임 전체 언어 텍스트", page_number)
    pdf.setFillColorRGB(0.08, 0.08, 0.08)
    pdf.setFont(font_name, 17)
    pdf.drawString(32, y - 24, "마왕님, 마왕성은 누가 지켜요?")
    pdf.setFont(font_name, 9)
    y -= 50
    summary = [
        f"심의 빌드: {VERSION}",
        f"수록 문자열: {len(rows):,}건",
        "범위: data/*.json, scripts/*.gd, scenes/*.gd, project.godot에서 추출한 한국어 및 문장형 영문",
        "내용: 캐릭터 대사, 나레이션, UI, 아이템·스킬·이벤트·엔딩 텍스트의 소스 위치와 원문",
    ]
    for line in summary:
        pdf.drawString(38, y, line)
        y -= 20
    y -= 24

    for index, row in enumerate(rows, start=1):
        source_line = f"[{index:05d}] {row['source']} | {row['locator']}"
        text_lines = wrap_by_width(row["text"], font_name, 7.4, page_w - 76)
        needed = 12 + len(text_lines) * 10 + 6
        if y - needed < 38:
            pdf.showPage()
            page_number += 1
            y = draw_pdf_header(pdf, font_name, "게임 전체 언어 텍스트", page_number)
        pdf.setFillColorRGB(0.31, 0.20, 0.43)
        pdf.setFont(font_name, 6.7)
        pdf.drawString(34, y, source_line[:180])
        y -= 11
        pdf.setFillColorRGB(0.08, 0.08, 0.08)
        pdf.setFont(font_name, 7.4)
        for line in text_lines:
            pdf.drawString(42, y, line)
            y -= 10
        pdf.setStrokeColorRGB(0.88, 0.84, 0.91)
        pdf.line(34, y + 3, page_w - 34, y + 3)
        y -= 6
    pdf.save()
    return len(rows), page_number


def strip_markdown(line: str) -> str:
    cleaned = line.replace("**", "").replace("`", "")
    if cleaned.startswith("#"):
        cleaned = cleaned.lstrip("#").strip()
    if cleaned.startswith("|"):
        cleaned = " / ".join(part.strip() for part in cleaned.strip("|").split("|"))
    return html.unescape(cleaned)


def write_manual_pdf(markdown_path: Path, target: Path) -> int:
    font_name = register_pdf_font()
    pdf = canvas.Canvas(str(target), pagesize=A4, pageCompression=1)
    page_w, _ = A4
    page_number = 1
    y = draw_pdf_header(pdf, font_name, "게임 설명서", page_number)
    for raw_line in markdown_path.read_text(encoding="utf-8").splitlines():
        if raw_line.startswith("|---"):
            continue
        is_heading = raw_line.startswith("#")
        line = strip_markdown(raw_line)
        font_size = 14 if is_heading else 9
        leading = 19 if is_heading else 13
        if not line:
            y -= 9
            continue
        wrapped = wrap_by_width(line, font_name, font_size, page_w - 76)
        needed = max(leading, len(wrapped) * leading)
        if y - needed < 38:
            pdf.showPage()
            page_number += 1
            y = draw_pdf_header(pdf, font_name, "게임 설명서", page_number)
        pdf.setFillColorRGB(0.22, 0.12, 0.31) if is_heading else pdf.setFillColorRGB(0.08, 0.08, 0.08)
        pdf.setFont(font_name, font_size)
        for wrapped_line in wrapped:
            pdf.drawString(36 if is_heading else 42, y, wrapped_line)
            y -= leading
        if is_heading:
            y -= 4
    pdf.save()
    return page_number


def write_manifest(root: Path) -> None:
    rows: list[tuple[str, int, str]] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.name == "FILE_MANIFEST.tsv":
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        rows.append((path.relative_to(root).as_posix(), path.stat().st_size, digest))
    with (root / "FILE_MANIFEST.tsv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("path", "bytes", "sha256"))
        writer.writerows(rows)


def write_readme(output: Path, string_count: int, ending_count: int, art_counts: dict[str, int]) -> None:
    text = f"""STOVE 자체등급 심의자료 - 마왕님, 마왕성은 누가 지켜요?
버전: {VERSION}
생성일: {GENERATED_DATE}

1. VIDEOS
- 01_early_game_v2.0.1.mp4: 초반부 6분 이상
- 02_mid_game_v2.0.1.mp4: 중반부 6분 이상
- 03_late_game_v2.0.1.mp4: 후반부 6분 이상
- 04_all_endings_v2.0.1.mp4: 등록 엔딩 {ending_count}개 전체

2. CG_IMAGES
- CHARACTER_SHEETS: 캐릭터 {art_counts['characters']}종
- MONSTER_SHEETS: 몬스터 {art_counts['monsters']}종
- ENEMY_SHEETS: 적/보스 {art_counts['enemies']}종
- ENDINGS_INDIVIDUAL: 엔딩 CG {ending_count}장
- ENDING_SHEETS: 엔딩 CG 접촉표
- 별도 원화가 없는 런타임 도형/공용 자산 유닛은 이름 카드로 표시

3. DOCUMENTS
- GAME_MANUAL_v2.0.1.pdf: 게임 설명·조작·등급 관련 표현
- GAME_TEXT_ALL_v2.0.1.pdf: 전체 텍스트 {string_count}건
- language_text_v2.0.1.tsv: 동일 텍스트의 검색·대조용 원본
- RATING_ELEMENTS_TIMECODES.txt: 폭력·공포 표현 확인 위치

STOVE 페이지 요구사항에 따라 초·중·후반 영상은 각각 6분 이상이며, 모든 엔딩과
모든 캐릭터 CG, 대사·나레이션·UI 텍스트를 함께 제출한다. 심사요청 버튼을 누르기
전에는 반드시 업로드한 빌드가 v2.0.1인지 다시 확인한다.
"""
    (output / "README_FIRST.txt").write_text(text, encoding="utf-8-sig")


def write_timecodes(output: Path) -> None:
    text = """STOVE 심의 등급요소 확인표 (v2.0.1)

01_early_game_v2.0.1.mp4
- 02:34 이후: DAY 1 방어전, 무기·마법·함정, 타격 이펙트, 체력 감소

02_mid_game_v2.0.1.mp4
- 02:19 이후: 성장 몬스터의 무기·마법·함정 전투와 직접 지휘 기술

03_late_game_v2.0.1.mp4
- 01:50 이후: 용사·성기사·조사관이 포함된 보스급 전투
- 05:50 전후: 엔딩 진입 예시

04_all_endings_v2.0.1.mp4
- 화면 좌상단에 엔딩 순번, 카탈로그 코드, 엔딩 ID, 제목 표시

표현 수준 메모
- 판타지 캐릭터의 만화적 전투와 단순 이펙트
- 사실적 선혈, 절단, 장기 노출 없음
- 악마·유령·해골·던전 소재의 경미한 공포 분위기
"""
    (output / "RATING_ELEMENTS_TIMECODES.txt").write_text(text, encoding="utf-8-sig")


def main() -> int:
    args = parse_args()
    output = args.output.resolve()
    cg_dir = output / "CG_IMAGES"
    documents_dir = output / "DOCUMENTS"
    video_dir = output / "VIDEOS"
    for directory in (output, cg_dir, documents_dir, video_dir, PDF_OUTPUT):
        directory.mkdir(parents=True, exist_ok=True)

    subprocess.run([sys.executable, str(ROOT / "tools/release/export_stove_rating_materials.py")], check=True)
    language_tsv = ROOT / "stove/ratings/language_text.tsv"
    character_groups = collect_character_art()
    endings = collect_endings()

    for group, items in character_groups.items():
        label = {"characters": "전체 캐릭터 CG", "monsters": "전체 몬스터 대표 이미지", "enemies": "전체 적·보스 대표 이미지"}[group]
        create_contact_sheets(items, cg_dir / f"{group.upper()}_SHEETS", f"{group}_sheet", label)
    ending_items = [
        {"id": item["id"], "name": f"{item['code']} {item['name']}", "catalog": "엔딩 CG", "path": item["path"]}
        for item in endings
    ]
    create_contact_sheets(ending_items, cg_dir / "ENDING_SHEETS", "ending_sheet", "전체 엔딩 CG", columns=2, rows=2)
    copy_ending_images(endings, cg_dir / "ENDINGS_INDIVIDUAL")

    language_pdf = PDF_OUTPUT / "GAME_TEXT_ALL_v2.0.1.pdf"
    manual_pdf = PDF_OUTPUT / "GAME_MANUAL_v2.0.1.pdf"
    string_count, _ = write_language_pdf(language_tsv, language_pdf)
    write_manual_pdf(ROOT / "stove/ratings/GAME_MANUAL.md", manual_pdf)
    shutil.copy2(language_pdf, documents_dir / language_pdf.name)
    shutil.copy2(manual_pdf, documents_dir / manual_pdf.name)
    shutil.copy2(language_tsv, documents_dir / "language_text_v2.0.1.tsv")
    shutil.copy2(ROOT / "stove/ratings/illustration_manifest.tsv", documents_dir / "illustration_manifest_v2.0.1.tsv")

    art_counts = {key: len(value) for key, value in character_groups.items()}
    write_readme(output, string_count, len(endings), art_counts)
    write_timecodes(output)
    video_marker = video_dir / "VIDEO_FILES_ARE_GENERATED_BY_RatingVideoCapture.txt"
    if list(video_dir.glob("*.mp4")):
        video_marker.unlink(missing_ok=True)
    else:
        video_marker.write_text(
            "초반·중반·후반 각 6분 이상과 전체 엔딩 영상을 이 폴더에 생성합니다.\n",
            encoding="utf-8-sig",
        )
    write_manifest(output)
    print(
        "STOVE_RATING_PACKAGE: PASS "
        f"({string_count} strings, {sum(art_counts.values())} character/unit rows, {len(endings)} endings -> {output})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
