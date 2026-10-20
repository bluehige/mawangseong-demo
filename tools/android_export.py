#!/usr/bin/env python3
"""Export phone-test APK/AAB from an isolated mobile illustration staging copy."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

from mobile_web_export import (
    EXPECTED_IMPORT_COUNT, MOBILE_ILLUSTRATION_SIZE_LIMIT,
    MOBILE_LOSSY_QUALITY, _copy_ignore, _replace_directory,
    _sha256, apply_mobile_import_overrides,
)


def prepare_stage(root: Path, stage: Path) -> int:
    _replace_directory(stage, root / "tmp")
    common_ignore = _copy_ignore(root)
    def ignore(directory: str, names: list[str]) -> set[str]:
        ignored = common_ignore(directory, names)
        if Path(directory) == root:
            ignored.update(set(names) - {"assets", "data", "scenes", "scripts",
                                         "project.godot", "export_presets.cfg"})
        return ignored
    shutil.copytree(root, stage, ignore=ignore)
    count = apply_mobile_import_overrides(stage)
    if count != EXPECTED_IMPORT_COUNT:
        raise ValueError(f"expected {EXPECTED_IMPORT_COUNT} illustrations, got {count}")
    project = stage / "project.godot"
    text = project.read_text(encoding="utf-8")
    text = re.sub(r'\[editor_plugins\]\s+enabled=.*',
                  '[editor_plugins]\n\nenabled=PackedStringArray()', text)
    # Android exporter validates this host-side import flag even for GLES builds.
    text = text.replace("[rendering]", "[rendering]\n\ntextures/vram_compression/import_etc2_astc=true")
    project.write_text(text, encoding="utf-8")
    return count


def run(godot: str, stage: Path, log: Path, *args: str) -> None:
    command = [godot, "--headless", "--path", str(stage), *args]
    print(subprocess.list2cmdline(command), flush=True)
    # Use the GUI executable directly, never a console wrapper spawning a helper.
    def godot_count() -> int:
        listing = subprocess.check_output(["tasklist", "/FO", "CSV", "/NH"],
                                          creationflags=subprocess.CREATE_NO_WINDOW)
        return sum(line.lower().startswith(b'"godot') for line in listing.splitlines())
    if godot_count():
        raise RuntimeError("Godot must be stopped before export")
    import time
    maximum = 1
    with log.open("w", encoding="utf-8") as stream:
        process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 1200
        try:
            while process.poll() is None:
                maximum = max(maximum, godot_count())
                if maximum > 1 or time.monotonic() > deadline:
                    raise RuntimeError("Godot process count or export deadline exceeded")
                time.sleep(0.5)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
    counts_path = log.parent / "build_process_counts.json"
    counts = json.loads(counts_path.read_text()) if counts_path.exists() else []
    after = godot_count()
    counts.append(dict(log=log.name, before=0, maximum=maximum, after=after,
                       exit_code=process.returncode))
    counts_path.write_text(json.dumps(counts, indent=2), encoding="utf-8")
    errors = re.findall(r"^(?:ERROR:|SCRIPT ERROR:).*$", log.read_text(encoding="utf-8", errors="replace"), re.M)
    if process.returncode or after or errors:
        raise RuntimeError(f"Godot failed: {log} (exit {process.returncode}, after {after})")


README = """마왕성 1.3.0 안드로이드 첫 테스트 — 갤럭시 S23

설치할 파일: mawangcastle-1.3.0-test.apk
1. USB 케이블로 폰의 Download 폴더에 복사하거나, 카카오톡/구글 드라이브로
   APK 파일을 본인 폰에 보낸 뒤 내려받으세요.
   약 488MiB라 카카오톡 전송이 막히면 USB 또는 드라이브를 사용하세요.
2. 폰의 '내 파일' → '다운로드'에서 APK를 누르세요.
3. 설치가 차단되면 '설정'을 눌러 파일을 여는 앱(내 파일/드라이브 등)의
   '알 수 없는 앱 설치' → '이 출처 허용'을 켠 뒤 돌아와 설치하세요.
   메뉴는 설정 → 보안 및 개인정보 보호 → 기타 보안 설정에도 있습니다.
   삼성 '보안 위험 자동 차단'이 막으면 본인 테스트 APK 설치에 필요한 동안
   해당 설정을 해제한 뒤, 설치 후 다시 켜세요.
4. '설치' → '열기'. 폰을 가로로 사용하세요. 설치 후 출처 허용은 꺼도 됩니다.
5. 타이틀 표시, 터치 입력, 소리, 홈으로 나갔다 복귀, 뒤로가기를 시험하세요.

앱 전환 시 정지하며 안전한 화면에서는 자동 저장합니다. 전투 도중 앱이
강제 종료되면 전투 직전의 마지막 안전저장부터 이어집니다. 복귀 시 메뉴의
계속하기로 재개하세요. 삭제하면 테스트 저장도 삭제되므로 주의하세요.
버튼 크기·핀치·길게 누르기·S23 좌우 여백 보정은 다음 작업입니다.
이번 테스트는 결제/Play 등록 없이 설치합니다. 출시 예정 가격은 5,000원입니다.
AAB는 배포 준비용이며 폰에서 직접 설치하는 파일은 아닙니다.
디버그 키 서명은 정식 출시 서명과 다릅니다. 정식 출시 키는 만들지 않았습니다.
"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--bundle-only", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    work = root / "tmp/android_build"
    work.mkdir(parents=True, exist_ok=True)
    stage = root / "tmp/android_stage"
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    result_path = work / "build_result.json"
    result = json.loads(result_path.read_text()) if args.bundle_only else {}
    if not args.bundle_only:
        result.update(optimized_imports=prepare_stage(root, stage),
                      illustration_size_limit=MOBILE_ILLUSTRATION_SIZE_LIMIT,
                      lossy_quality=MOBILE_LOSSY_QUALITY)
        run(args.godot, stage, work / "import.log", "--editor", "--import")
        apk = output / "mawangcastle-1.3.0-test.apk"
        run(args.godot, stage, work / "apk.log", "--export-debug", "Android", str(apk))
        apk.with_suffix(".apk.idsig").unlink(missing_ok=True)
        result.update(apk_bytes=apk.stat().st_size, apk_sha256=_sha256(apk))
        result_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
        (output / "README_설치방법.txt").write_text(README, encoding="utf-8-sig")
    template = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.6.3.stable/android_source.zip"
    build = stage / "android/build"
    build.parent.mkdir(parents=True, exist_ok=True)
    (build.parent / ".gdignore").touch()
    if not build.exists():
        build.mkdir(parents=True)
        with zipfile.ZipFile(template) as archive:
            archive.extractall(build)
        (stage / "android/.build_version").write_text("4.6.3.stable", encoding="utf-8")
    properties = build / "gradle.properties"
    gradle_text = properties.read_text(encoding="utf-8")
    gradle_text = re.sub(r"org.gradle.jvmargs=.*", "org.gradle.jvmargs=-Xmx1536m", gradle_text)
    gradle_text += "\norg.gradle.workers.max=2\norg.gradle.daemon=false\n"
    properties.write_text(gradle_text, encoding="utf-8")
    presets = stage / "export_presets.cfg"
    text = presets.read_text(encoding="utf-8")
    start = text.index("[preset.5.options]")
    end = text.find("\n[preset.", start + 1)
    if end < 0: end = len(text)
    options = text[start:end].replace("gradle_build/use_gradle_build=false", "gradle_build/use_gradle_build=true")
    options = options.replace("gradle_build/export_format=0", "gradle_build/export_format=1")
    options = options.replace("package/signed=true", "package/signed=false")
    presets.write_text(text[:start] + options + text[end:], encoding="utf-8")
    aab = output / "mawangcastle-1.3.0-test.aab"
    run(args.godot, stage, work / "aab.log", "--export-release", "Android", str(aab))
    result.update(aab_bytes=aab.stat().st_size, aab_sha256=_sha256(aab), aab_signed=False)
    result_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
