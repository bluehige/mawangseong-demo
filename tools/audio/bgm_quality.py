"""Measure and optionally match rendered BGM to the existing scene loudness.

Install requirements-bgm-quality.txt. Run AFTER lyria_pipeline render and BEFORE
promote. No network calls. Normalization changes preview.wav and its hash only;
generated source audio is preserved. The report is evidence, not a listening test.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import wave
import soundfile as sf
from pathlib import Path

import numpy as np
import pyloudnorm as pyln
from scipy.signal import resample_poly

ROOT = Path(__file__).resolve().parents[2]
SCENE_REFERENCES = {
    "title": ["title_demon_castle_overture", "management_castle_bustle"],
    "management": ["management_castle_bustle", "title_demon_castle_overture"],
    "result": ["management_castle_bustle", "title_demon_castle_overture"],
    "combat": ["combat_dungeon_pressure", "combat_late_siege_pressure", "combat_boss_council"],
    "final_ending": ["final_ending_crown_of_ashes"],
}


def load(path: Path) -> np.ndarray:
    samples, rate = sf.read(path, dtype="float64", always_2d=True)
    if rate != 44100 or samples.shape[1] != 2:
        raise ValueError(f"Expected stereo/44100: {path}")
    return samples


def measure(samples: np.ndarray) -> dict:
    peak = float(np.max(np.abs(samples)))
    # Four-times polyphase oversampling estimates inter-sample peaks.
    true_peak = float(np.max(np.abs(resample_poly(samples, 4, 1, axis=0))))
    window = 2205  # 50 ms RMS windows, silence below -60 dBFS.
    blocks = samples[:len(samples) // window * window].reshape(-1, window, 2)
    rms = np.sqrt(np.mean(blocks * blocks, axis=(1, 2)))
    longest = run = 0
    for silent in rms < 0.001:
        run = run + 1 if silent else 0
        longest = max(longest, run)
    return {
        "duration_seconds": len(samples) / 44100,
        "lufs": float(pyln.Meter(44100).integrated_loudness(samples)),
        "peak_dbfs": 20 * math.log10(max(peak, 1e-12)),
        "true_peak_dbtp": 20 * math.log10(max(true_peak, 1e-12)),
        "longest_silence_seconds": longest * 0.05,
        "seam_delta": float(np.max(np.abs(samples[0] - samples[-1]))),
        "adjacent_delta_p999": float(np.quantile(np.max(np.abs(np.diff(samples, axis=0)), axis=1), 0.999)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT / "tools/audio/lyria_v130_manifest.json")
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--normalize", action="store_true")
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    references = {path.stem: measure(load(path)) for path in (ROOT / "assets/audio/bgm").glob("*.ogg")}
    reports = []
    for asset in manifest["assets"]:
        take = args.run / asset["id"] / "take-01"
        preview = take / "preview.wav"
        samples = load(preview)
        before = measure(samples)
        target = float(np.median([references[name]["lufs"] for name in SCENE_REFERENCES[asset["scene"]]]))
        gain_db = 0.0
        if args.normalize:
            # Constant gain preserves dynamics and the existing two-second loop.
            gain_db = min(target - before["lufs"], -3.1 - before["true_peak_dbtp"])
            pcm = np.rint(samples * 10 ** (gain_db / 20) * 32768).clip(-32768, 32767).astype("<i2")
            with wave.open(str(preview), "wb") as wav:
                wav.setparams((2, 2, 44100, 0, "NONE", "not compressed"))
                wav.writeframes(pcm.tobytes())
        after = measure(load(preview))
        checks = {
            "duration_90_to_150": 90 <= after["duration_seconds"] <= 150,
            "sample_peak_at_most_minus3": after["peak_dbfs"] <= -3,
            "estimated_true_peak_at_most_minus3": after["true_peak_dbtp"] <= -3,
            "no_silence_at_least_one_second": after["longest_silence_seconds"] < 1,
            "reference_loudness_within_one_lu": abs(after["lufs"] - target) <= 1.0,
            "seam_within_ordinary_transients": after["seam_delta"] <= max(after["adjacent_delta_p999"], 0.01),
            "two_second_loop_render": asset["render"]["loop_crossfade_seconds"] == 2,
        }
        report = dict(asset_id=asset["id"], scene=asset["scene"], reference_lufs=target,
                      gain_db=gain_db, before=before, after=after, checks=checks, passed=all(checks.values()))
        reports.append(report)
        if args.normalize:
            metadata = json.loads((take / "preview.json").read_text(encoding="utf-8"))
            metadata["preview_sha256"] = hashlib.sha256(preview.read_bytes()).hexdigest()
            metadata["loudness_postprocessing"] = report
            (take / "preview.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{asset['id']} duration={after['duration_seconds']:.3f} LUFS={after['lufs']:.2f} "
              f"peak={after['peak_dbfs']:.2f} PASS={report['passed']}", flush=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(dict(references=references, tracks=reports), indent=2) + "\n", encoding="utf-8")
    return 0 if all(report["passed"] for report in reports) else 1


if __name__ == "__main__":
    raise SystemExit(main())
