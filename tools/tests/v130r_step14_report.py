"""Audit the requested local startup captures and summarize actual test evidence."""
from pathlib import Path
import json
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "_mockup/game_step14_start"
EXPECTED = ["title", "title_en", "menu", "menu_no_save", "prologue_1", "prologue_last", "name_input"] + [f"day1_guide_{n}" for n in range(1, 5)]
PRODUCT = [
    "data/v130r/start_flow.json", "data/onboarding_flow_dialogue_v0.4.json",
    "data/story/v122_main/day_01.json", "data/localization/story_en.json", "data/localization/story_zh_cn.json",
    "scripts/ui/StartFlow.gd", "scripts/ui/StartFlow.gd.uid", "scripts/ui/TitleWorkspaceUI.gd", "scripts/ui/NameEntryUI.gd",
    "scripts/game/GameRoot.gd", "scripts/game/ApprovedBattleController.gd",
    "scripts/map_builder/ApprovedGradeProgression.gd", "scripts/map_builder/ApprovedPlacementView.gd",
    "scripts/map_builder/ApprovedMonsterPlacementUI.gd",
    "scripts/story/V130RStoryRuntime.gd", "scripts/story/StoryDialoguePresenter.gd",
    "tools/run_v130r_step14.ps1", "tools/tests/V130RStep14StartTest.gd", "tools/tests/V130RStep14StartTest.gd.uid",
    "tools/tests/V130RStep14StartTest.tscn", "tools/tests/v130r_step14_report.py",
    "_mockup/game_step14_start/diagnosis.md", "_mockup/game_step14_start/flow_after.md",
]


def main():
    checks = []

    def check(ok, label):
        checks.append({"ok": bool(ok), "check": label})

    reports = {}
    for mode in ("direct", "capture"):
        reports[mode] = json.loads((OUT / f"{mode}_checks.json").read_text(encoding="utf-8"))
        check(not reports[mode]["failures"], f"{mode}: {reports[mode]['checks']} assertions")
        error_log = ROOT / f"tmp/v130r_step14/{mode}.err.log"
        check(not error_log.read_text(encoding="utf-8").strip(), f"{mode}: empty stderr")
    for name in EXPECTED:
        file = OUT / f"{name}.png"
        check(file.exists(), f"required capture: {name}")
        if file.exists():
            with Image.open(file) as image:
                check(image.size == (1280, 720), f"single reduced 1280x720 image: {name}")
                if name.startswith("prologue_"):
                    check(image.convert("RGB").getpixel((10, 300)) == (0, 0, 0), f"black prologue background: {name}")
    catalog = json.loads((ROOT / "data/v130r/start_flow.json").read_text(encoding="utf-8"))
    for locale in ("ko", "en", "zh_CN"):
        check(set(catalog[locale]) == set(catalog["ko"]), f"complete translation keys: {locale}")
        check(len(catalog[locale]["prologue"]) == 7, f"seven prologue lines: {locale}")
        check("{{player_name}}" not in str(catalog[locale]["prologue"] + catalog[locale]["name_talk"]), f"no name token before input: {locale}")
    trace = json.loads((OUT / "after_trace.json").read_text(encoding="utf-8"))
    main_scenes = [row["story"] for row in trace]
    check("STORY_D01_PRECOMBAT" in main_scenes, "real precombat dialogue observed")
    check(any(row["tag"] == "after_battle" and row["story"] == "STORY_D01_RESULT_WIN" for row in trace), "natural first battle reached victory dialogue")
    check(any(row["line"].get("v130r_scene_id") == "V130R_D01_MANAGEMENT_S1" for row in trace), "owned-speaker overlay fixture observed")
    check(subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip() == "codex/v130r-defense-layout", "requested branch unchanged")
    baseline = json.loads((OUT / "baseline_status.json").read_text(encoding="utf-8"))
    old_paths = {line[3:] for line in baseline if line}
    modified = subprocess.check_output(["git", "-c", "core.safecrlf=false", "diff", "--name-only"], cwd=ROOT, text=True).splitlines()
    unexpected = [name for name in modified if not name.endswith(".import") and name not in PRODUCT and name != "docs/handoff/CURRENT.md" and name not in old_paths]
    check(not unexpected, f"no unexpected tracked source changes: {unexpected}")
    result = {"checks": len(checks), "failures": [row for row in checks if not row["ok"]], "results": checks, "product_paths": PRODUCT, "requested_captures": EXPECTED}
    (OUT / "artifact_checks.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"checks": result["checks"], "failures": result["failures"]}, ensure_ascii=False))
    if result["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
