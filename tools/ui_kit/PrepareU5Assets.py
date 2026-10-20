"""Optimize approved U5 art without replacing originals or changing alpha."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def save(source, target, size=None):
    image = Image.open(ROOT / source)
    if size:
        image.thumbnail(size, Image.Resampling.LANCZOS)
    destination = ROOT / target
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, optimize=True)
    return {"source": source, "runtime": target, "size": image.size,
            "mode": image.mode, "alpha_extrema": image.getchannel("A").getextrema() if image.mode == "RGBA" else None,
            "bytes": destination.stat().st_size}


def main():
    records = []
    source_dir = "assets/source/imagegen/v1213_bati_cute"
    runtime_dir = "assets/sprites/portraits/v1213_bati_cute"
    for expression in ("dry", "dry_happy", "stern", "tutorial"):
        for kind, suffix, limit in (("standing", "_fullheight", (1080, 1080)), ("portrait", "", (512, 512))):
            source = f"{source_dir}/bati_{kind}_{expression}{suffix}.png"
            target = f"{runtime_dir}/bati_{kind}_{expression}.png"
            records.append(save(source, target, limit))
    path = ROOT / source_dir / "SOURCE.md"
    text = path.read_text(encoding="utf-8")
    for expression in ("dry", "dry_happy", "stern", "tutorial"):
        text = text.replace(f"assets/sprites/portraits/uiux3d/bati_{expression}.png (planned; not yet wired)",
                            f"{runtime_dir}/bati_standing_{expression}.png")
        text = text.replace(f"assets/sprites/portraits/onboarding/CHR_BATI_portrait_{expression}.png (planned; not yet wired)",
                            f"{runtime_dir}/bati_portrait_{expression}.png")
    text = text.replace("- Runtime image path: assets/sprites/portraits/onboarding/portrait_bati.png (planned reuse of dry portrait; not yet wired)\n", "")
    path.write_text(text, encoding="utf-8")
    records.append(save("docs/design/v1213_screens/dialogue_bg_throne_report.png",
                        "assets/ui/v1213/dialogue_throne.png", (1920, 1080)))
    for language, directory in (("ko", ""), ("en", "english/"), ("zh_CN", "schinese/")):
        source = f"marketing/steam/{directory}library/logo.png"
        image = Image.open(ROOT / source)
        # Tight alpha bounds only; existing transparent wordmark is reused.
        image = image.crop(image.getchannel("A").getbbox())
        target = ROOT / f"assets/ui/v1213/logo_{language}.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, optimize=True)
        records.append({"source": source, "runtime": target.relative_to(ROOT).as_posix(), "size": image.size,
                        "mode": image.mode, "alpha_extrema": image.getchannel("A").getextrema(), "bytes": target.stat().st_size})
    report = ROOT / "tmp/v1213_u5a/asset_checks.json"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(records, ensure_ascii=False))


if __name__ == "__main__":
    main()
