"""Offline WAV -> Vorbis migration, with decoded quality and loop evidence.

Requires ffmpeg (libvorbis), numpy, scipy, soundfile and Pillow. Originals are
backed up under the ignored output directory; removal is a separate review step.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import re
import shutil
import subprocess
from pathlib import Path

import numpy as np
import soundfile as sf
from PIL import Image, ImageDraw, ImageFont
from scipy.signal import spectrogram

ROOT = Path(__file__).resolve().parents[2]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command: list[str]) -> str:
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode:
        raise RuntimeError(f"Command failed: {command}\n{result.stderr[-4000:]}")
    return result.stderr


def encode(ffmpeg: str, source: Path, dest: Path, quality: int, channels: int, gain_db: float = 0, ceiling: float | None = None) -> None:
    command = [ffmpeg, "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-threads", "1",
               "-i", str(source), "-map_metadata", "-1", "-vn", "-ar", "44100", "-ac", str(channels)]
    filters = [f"volume={gain_db:.6f}dB"] if gain_db else []
    if ceiling is not None:
        filters += [f"alimiter=limit={ceiling}:level=false:attack=0.1:release=1:latency=true"]
    if filters:
        command += ["-filter_threads", "1", "-af", ",".join(filters)]
    run(command + ["-c:a", "libvorbis", "-q:a", str(quality), str(dest)])


def loudness(ffmpeg: str, path: Path, duration: float, log: Path) -> dict:
    # EBU R128 needs a 400 ms integration block. For shorter cues only, append
    # silence to 1 s to BOTH versions; never call an undefined -70 LUFS a pass.
    pad = "apad=whole_dur=1," if duration < 0.4 else ""
    output = run([ffmpeg, "-nostdin", "-hide_banner", "-nostats", "-threads", "1", "-i", str(path),
                  "-filter_threads", "1", "-af", pad + "ebur128=peak=sample+true:framelog=verbose",
                  "-f", "null", "-"])
    log.write_text(output, encoding="utf-8")
    summary = output.rsplit("Summary:", 1)[-1]
    integrated = float(re.search(r"I:\s+([-\d.]+) LUFS", summary)[1])
    true_peak = float(re.search(r"True peak:\s+Peak:\s+([-\d.]+) dBFS", summary)[1])
    if integrated <= -70:
        raise ValueError(f"Undefined loudness: {path}")
    return {"lufs": integrated, "true_peak_dbtp": true_peak, "short_cue_padded": duration < 0.4}


def signal_stats(samples: np.ndarray, rate: int) -> dict:
    peak = float(np.max(np.abs(samples)))
    steps = np.max(np.abs(np.diff(samples, axis=0)), axis=1)
    return {"duration_seconds": len(samples) / rate, "sample_rate": rate, "channels": samples.shape[1],
            "peak_dbfs": 20 * math.log10(max(peak, 1e-12)),
            "clipped_samples": int(np.count_nonzero(np.abs(samples) >= 1)),
            "seam_delta": float(np.max(np.abs(samples[0] - samples[-1]))),
            "adjacent_delta_p999": float(np.quantile(steps, 0.999))}


def write_import(original: dict, dest: Path) -> dict:
    text = original["import_text"]
    mode = int(re.search(r"edit/loop_mode=(\d+)", text)[1])
    begin = int(re.search(r"edit/loop_begin=(-?\d+)", text)[1])
    end = int(re.search(r"edit/loop_end=(-?\d+)", text)[1])
    # Inventory has no WAV smpl chunks; detect-from-WAV therefore means no loop.
    if mode not in (0, 1, 2) or begin < 0 or end not in (-1, original["frames"]):
        raise ValueError(f"Unsupported non-forward or bounded loop: {original['path']}")
    for option in ("edit/trim", "edit/normalize", "force/mono", "force/8_bit", "force/max_rate"):
        if re.search(re.escape(option) + r"=true", text):
            raise ValueError(f"Non-default WAV processing needs explicit migration: {option}")
    uid = re.search(r'uid="([^"]+)"', text)[1]
    resource = "res://" + dest.relative_to(ROOT).as_posix()
    imported = "res://.godot/imported/" + dest.name + "-" + hashlib.md5(resource.encode()).hexdigest() + ".oggvorbisstr"
    loop = mode == 2
    offset = begin / original["rate"]
    content = (f'[remap]\n\nimporter="oggvorbisstr"\ntype="AudioStreamOggVorbis"\nuid="{uid}"\n'
               f'path="{imported}"\n\n[deps]\n\nsource_file="{resource}"\n'
               f'dest_files=["{imported}"]\n\n[params]\n\nloop={str(loop).lower()}\n'
               f'loop_offset={offset}\nbpm=0.0\nbeat_count=0\nbar_beats=4\n')
    Path(str(dest) + ".import").write_text(content, encoding="utf-8")
    return {"wav_import_mode": mode, "wav_loop_begin": begin, "wav_loop_end": end,
            "loop": loop, "loop_offset": offset, "uid": uid}


def comparison_png(source: Path, dest: Path, output: Path) -> None:
    canvas = Image.new("RGB", (1400, 820), "#111820")
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 20)
    small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
    colors = np.array([[8, 9, 28], [50, 18, 89], [132, 40, 129], [215, 76, 85], [250, 158, 59], [252, 253, 191]])
    for index, path in enumerate((source, dest)):
        samples, rate = sf.read(path, always_2d=True)
        # Same FFT, time/frequency axes and absolute dB scale in both panels.
        freq, times, power = spectrogram(samples.mean(axis=1), rate, nperseg=2048, noverlap=1024, scaling="spectrum")
        db = 10 * np.log10(np.maximum(power, 1e-12))
        wanted_freq = np.geomspace(30, 22050, 280)[::-1]
        selected = np.linspace(0, len(times) - 1, 1240).astype(int)
        data = np.stack([np.interp(wanted_freq, freq, db[:, t]) for t in selected], axis=1)
        intensity = np.clip((data + 100) / 100, 0, 1) * (len(colors) - 1)
        pixels = np.stack([np.interp(intensity, np.arange(len(colors)), colors[:, c]) for c in range(3)], axis=2).astype("uint8")
        y = 80 + index * 350
        canvas.paste(Image.fromarray(pixels), (100, y))
        draw.text((100, y - 30), ("WAV original" if index == 0 else "OGG Vorbis decoded") + " | " + dest.stem, font=font, fill="white")
        for hz in (30, 100, 1000, 10000, 22050):
            fy = y + (1 - math.log(hz / 30) / math.log(22050 / 30)) * 279
            draw.text((8, fy - 8), f"{hz} Hz", font=small, fill="#c0cad6")
        for frac in (0, .25, .5, .75, 1):
            draw.text((100 + int(frac * 1190), y + 286), f"{frac * len(samples) / rate:.1f}s", font=small, fill="#c0cad6")
    draw.text((100, 780), "Identical scale: -100 to 0 dBFS | FFT 2048, hop 1024 | log frequency 30-22050 Hz | seed 64", font=small, fill="white")
    canvas.save(output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=ROOT / "tmp/ogg_check")
    args = parser.parse_args()
    baseline = json.loads(args.baseline.read_text(encoding="utf-8"))
    ffmpeg = baseline["ffmpeg"]
    manifest = json.loads((ROOT / "tools/audio/lyria_v130_runtime_manifest.json").read_text(encoding="utf-8"))
    assets = {asset["id"]: asset for asset in manifest["assets"]}
    by_path = {asset["runtime_path"].replace(".ogg", ".wav"): asset for asset in assets.values()}
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    report_file = output / "quality.json"
    reports = json.loads(report_file.read_text(encoding="utf-8")) if report_file.exists() else []
    finished = {r["source_path"] for r in reports if r["passed"] and (ROOT / r["runtime_path"]).exists()
                and digest(ROOT / r["runtime_path"]) == r["runtime_sha256"]}
    for original in baseline["audio"]:
        path = original["path"]
        if path in finished:
            continue
        asset = by_path[path]
        source = ROOT / path
        backup = output / "wav" / path.removeprefix("assets/audio/")
        backup.parent.mkdir(parents=True, exist_ok=True)
        if source.exists():
            assert digest(source) == original["sha256"], f"Source changed: {source}"
            shutil.copy2(source, backup)
        assert digest(backup) == original["sha256"]
        dest = source.with_suffix(".ogg")
        music = asset["kind"] in ("music_loop", "ambience_loop")
        quality, channels = (7, 2) if music else (5, original["channels"])
        encode(ffmpeg, backup, dest, quality, channels)
        before_samples, rate = sf.read(backup, dtype="float32", always_2d=True)
        after_samples, out_rate = sf.read(dest, dtype="float32", always_2d=True)
        before, after = signal_stats(before_samples, rate), signal_stats(after_samples, out_rate)
        gain_db, ceiling = 0.0, None
        log_dir = output / "logs"
        log_dir.mkdir(exist_ok=True)
        before.update(loudness(ffmpeg, backup, before["duration_seconds"], log_dir / (asset["id"] + "_wav.log")))
        after.update(loudness(ffmpeg, dest, after["duration_seconds"], log_dir / (asset["id"] + "_ogg.log")))
        # A few original effects already exceed -1 dBFS. A very short
        # peak limiter protects transients without lowering the
        # whole cue beyond the +/-0.5 LU tolerance. Every retry is remeasured.
        # The owner's ceiling is sample dBFS; inter-sample dBTP is separately
        # reported, rather than silently treating it as the same measurement.
        for attempt in range(12):
            peak_ok = after["peak_dbfs"] <= -1
            lufs_delta = after["lufs"] - before["lufs"]
            if peak_ok and abs(lufs_delta) <= .5:
                break
            if not peak_ok:
                ceiling = .82 if ceiling is None else ceiling * .9
            if abs(lufs_delta) > .45:
                gain_db -= lufs_delta
            encode(ffmpeg, backup, dest, quality, channels, gain_db, ceiling)
            after_samples, out_rate = sf.read(dest, dtype="float32", always_2d=True)
            after = signal_stats(after_samples, out_rate)
            after.update(loudness(ffmpeg, dest, after["duration_seconds"], log_dir / (asset["id"] + "_ogg.log")))
        loop = write_import(original, dest)
        duration_delta = after["duration_seconds"] - before["duration_seconds"]
        lufs_delta = after["lufs"] - before["lufs"]
        checks = {"duration_within_0_05s": abs(duration_delta) <= .05,
                  "peak_at_most_minus1": after["peak_dbfs"] <= -1,
                  "no_clipped_samples": after["clipped_samples"] == 0,
                  "lufs_within_0_5": abs(lufs_delta) <= .5,
                  "format": out_rate == 44100 and after["channels"] == channels}
        if music and asset["render"].get("loop_crossfade_seconds") == 2:
            seam_error = float(np.max(np.abs((after_samples[0] - after_samples[-1]) - (before_samples[0] - before_samples[-1]))))
            checks["seam_within_original_local_transients"] = after["seam_delta"] <= max(before["adjacent_delta_p999"] * 1.1, before["seam_delta"] * 1.1, .001)
            checks["seam_encoding_error_below_minus40"] = seam_error < .01
        else:
            seam_error = None
        runtime_path = dest.relative_to(ROOT).as_posix()
        report = {"id": asset["id"], "kind": asset["kind"], "source_path": path, "runtime_path": runtime_path,
                  "source_sha256": original["sha256"], "runtime_sha256": digest(dest),
                  "source_bytes": original["bytes"], "runtime_bytes": dest.stat().st_size,
                  "quality": quality, "gain_db": gain_db, "limiter_ceiling_linear": ceiling, "before": before, "after": after,
                  "duration_delta_seconds": duration_delta, "lufs_delta": lufs_delta,
                  "bitrate_kbps": dest.stat().st_size * 8 / after["duration_seconds"] / 1000,
                  "loop_import": loop, "loop_crossfade_seconds": asset["render"].get("loop_crossfade_seconds", 0),
                  "seam_encoding_error": seam_error, "checks": checks, "passed": all(checks.values())}
        reports = [r for r in reports if r["source_path"] != path] + [report]
        report_file.write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
        print(f"{len(reports)}/131 {asset['id']} q{quality} delta={lufs_delta:+.1f}LU peak={after['peak_dbfs']:.2f} PASS={report['passed']}", flush=True)
        if not report["passed"]:
            print(json.dumps(report, indent=2), flush=True)
            return 1
    music_reports = [r for r in reports if r["kind"] == "music_loop"]
    selected = random.Random(64).sample(sorted(music_reports, key=lambda r: r["id"]), 5)
    for report in selected:
        comparison_png(output / "wav" / report["source_path"].removeprefix("assets/audio/"),
                       ROOT / report["runtime_path"], output / (report["id"] + "_spectrogram.png"))
    (output / "spectrograms.json").write_text(json.dumps([r["id"] for r in selected], indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
