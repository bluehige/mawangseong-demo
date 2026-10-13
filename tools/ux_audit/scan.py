"""Scan rendered audit captures; preserve raw candidates and explicit exclusions."""
import argparse
import itertools
import json
from pathlib import Path

MODALS = ("PauseMenuOverlay", "CampaignLeaveConfirmation", "DialogueBacklogOverlay", "UpdateNotesOverlay", "Update4CouncilDecisionOverlay")


def intersection(a, b):
    return max(0, min(a[0]+a[2], b[0]+b[2])-max(a[0], b[0])), max(0, min(a[1]+a[3], b[1]+b[3])-max(a[1], b[1]))


def contains(a, b):
    return a[0] <= b[0] and a[1] <= b[1] and a[0]+a[2] >= b[0]+b[2]-1 and a[1]+a[3] >= b[1]+b[3]-1


def scan(data):
    controls = data["controls"]
    for modal in MODALS:
        scope = [c for c in controls if f"/{modal}/" in c["path"] or c["name"] == modal]
        if scope:
            controls = scope
            break
    zeros = [c for c in controls if c["type"] == "Label" and c["text"].strip() and c["visible_lines"] == 0]
    overlaps, excluded = [], []
    # Scan ALL sibling Control pairs. Decorative containment and full-screen
    # backdrop/modal layering are expected; retain them with a reason.
    for a, b in itertools.combinations(controls, 2):
        if a.get("parent") != b.get("parent"):
            continue
        ar = a.get("text_rect", a["visible_rect"])
        br = b.get("text_rect", b["visible_rect"])
        width, height = intersection(ar, br)
        if width <= 1 or height <= 1:
            continue
        pair = {"a": a["path"], "b": b["path"], "texts": [a["text"], b["text"]], "intersection": [width, height]}
        if any(c["type"] in ("Label", "RichTextLabel") and not c["text"].strip() for c in (a, b)):
            pair["reason"] = "empty noninteractive text has no rendered content"
            excluded.append(pair)
            continue
        decorative = ("ColorRect", "TextureRect", "ProgressBar", "HScrollBar", "VScrollBar")
        if a["type"] in decorative or b["type"] in decorative:
            pair["reason"] = "decoration, image background, or scrollbar"
            excluded.append(pair)
            continue
        if any(c["type"] == "Panel" and c.get("mouse_filter") == 2 and c.get("fill_alpha", 1) <= 0.01 for c in (a, b)):
            pair["reason"] = "transparent noninteractive holder"
            excluded.append(pair)
            continue
        if (a["type"] == "Panel" and not a["text"] and contains(a["rect"], b["visible_rect"])) or (b["type"] == "Panel" and not b["text"] and contains(b["rect"], a["visible_rect"])):
            pair["reason"] = "sibling content intentionally inside visual panel bounds"
            excluded.append(pair)
            continue
        if any(c["name"] == "ManagementContextDrawer" for c in (a, b)):
            pair["reason"] = "temporary management detail drawer overlays underlying workspace"
            excluded.append(pair)
            continue
        if any(c["name"] == "TutorialMessageShadow" for c in (a, b)):
            pair["reason"] = "tutorial message drop shadow"
            excluded.append(pair)
            continue
        if {a["name"], b["name"]} == {"DialoguePortraitPanel", "DialogueTextPanel"} and width <= 8:
            pair["reason"] = "joined dialogue frame edges"
            excluded.append(pair)
            continue
        if a["visible_rect"][2:] == [1920, 1080] or b["visible_rect"][2:] == [1920, 1080]:
            pair["reason"] = "full viewport backdrop or modal"
            excluded.append(pair)
            continue
        if any("TutorialFocus" in c["name"] or "TutorialSpotlight" in c["name"] for c in (a, b)):
            pair["reason"] = "tutorial intentional spotlight/ring"
            excluded.append(pair)
            continue
        overlaps.append(pair)
    # Explicit cross-parent contracts are needed where HUD and effect canvases
    # have different ancestors: a sibling-only test cannot detect D05-D07.
    by_name = {c["name"]: c for c in controls}
    for left, right in (("CombatUnitInspector", "CombatSpeedPanel"), ("CombatUnitInspector", "CombatCommandBar"), ("SkillActionInputBlocker", "CombatSpeedPanel"), ("SkillActionInputBlocker", "PromotionSupportNotice")):
        if left in by_name and right in by_name:
            width, height = intersection(by_name[left]["visible_rect"], by_name[right]["visible_rect"])
            if width > 1 and height > 1:
                overlaps.append({"a": by_name[left]["path"], "b": by_name[right]["path"], "intersection": [width, height], "reason": "explicit HUD/inspector/cutscene contract"})
    overflow = [c for c in controls if c["name"].startswith("RegionMastery_") and (c.get("line_count", 0) > c.get("visible_lines", 999) or (c["clipped"] and c["clip_parent"].startswith("RegionCardButton")) or ("parent_rect" in c and c["rect"][1]+c["rect"][3] > c["parent_rect"][1]+c["parent_rect"][3]+1))]
    masks = [c for c in controls if c["name"].startswith("TutorialSpotlightShade") and (c["type"] != "ColorRect" and c.get("border_width", -1) != 0)]
    return {"id": data["id"], "screen": data["screen"], "zero_lines": zeros, "overlaps": overlaps, "intentional_overlaps": excluded, "region_overflow": overflow, "styled_masks": masks}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("directories", type=Path, nargs="+")
    args = parser.parse_args()
    total = 0
    for directory in args.directories:
        captures = json.loads((directory / "captures.json").read_text(encoding="utf-8"))
        fixture = json.loads((directory / "sweep_result.json").read_text(encoding="utf-8"))
        rows = [scan(c) for c in captures]
        summary = {key: sum(len(r[key]) for r in rows) for key in ("zero_lines", "overlaps", "region_overflow", "styled_masks")}
        summary.update(captures=len(rows), screen_count=len({r["screen"] for r in rows}))
        summary["fixture_failures"] = fixture["fixture_failures"]
        if fixture["screen_count"] != 29 or summary["screen_count"] != 29:
            summary["fixture_failures"].append("29-screen coverage required")
        (directory / "scan.json").write_text(json.dumps({"summary": summary, "rows": rows}, ensure_ascii=False, indent=2), encoding="utf-8")
        print(directory, json.dumps(summary))
        total += sum(summary[k] for k in ("zero_lines", "overlaps", "region_overflow", "styled_masks"))
        total += len(summary["fixture_failures"])
    return 1 if total else 0


if __name__ == "__main__":
    raise SystemExit(main())
