"""Encode local preview WAVs to the runtime Vorbis format (no network calls)."""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import wave
from pathlib import Path


def encode(source: Path, destination: Path, *, quality: int, channels: int) -> None:
    ffmpeg = os.environ.get("FFMPEG") or shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg/libvorbis is required. Install ffmpeg or set FFMPEG to its executable.")
    result = subprocess.run(
        [ffmpeg, "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-threads", "1",
         "-i", str(source), "-map_metadata", "-1", "-vn", "-ar", "44100", "-ac", str(channels),
         "-c:a", "libvorbis", "-q:a", str(quality), str(destination)],
        capture_output=True, text=True,
    )
    if result.returncode:
        raise RuntimeError(f"Vorbis encoding failed: {result.stderr}")


def write_pcm16(destination: Path, samples: bytes, *, sample_rate: int, channels: int = 1) -> None:
    """Keep deterministic cue synthesizers from reintroducing runtime WAVs."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="mawang-ogg-") as directory:
        preview = Path(directory) / "preview.wav"
        with wave.open(str(preview), "wb") as wav:
            wav.setparams((channels, 2, sample_rate, 0, "NONE", "not compressed"))
            wav.writeframes(samples)
        encode(preview, destination, quality=5, channels=channels)
