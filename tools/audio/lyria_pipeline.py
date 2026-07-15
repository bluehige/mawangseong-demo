"""Generate, preview, and explicitly promote Lyria 3 game audio assets."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import math
import os
import re
import shutil
import sys
import wave
from array import array
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = Path(__file__).with_name("lyria_v05_manifest.json")
SUPPORTED_MODELS = {"lyria-3-clip-preview", "lyria-3-pro-preview"}
SUPPORTED_KINDS = {"music_loop", "loop_cue", "musical_stinger", "one_shot"}


class PipelineError(RuntimeError):
    """An actionable pipeline validation or execution failure."""


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def load_manifest(path: Path = DEFAULT_MANIFEST) -> dict[str, Any]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PipelineError(f"Cannot read manifest {path}: {error}") from error
    validate_manifest(manifest)
    return manifest


def _repo_path(relative_path: str) -> Path:
    candidate = (ROOT / relative_path).resolve()
    if not candidate.is_relative_to(ROOT):
        raise PipelineError(f"Path escapes repository: {relative_path}")
    return candidate


def validate_manifest(manifest: dict[str, Any]) -> None:
    if manifest.get("schema_version") != 1:
        raise PipelineError("Manifest schema_version must be 1.")
    if not str(manifest.get("target_version", "")).strip():
        raise PipelineError("Manifest target_version is required.")
    defaults = manifest.get("defaults")
    if not isinstance(defaults, dict) or int(defaults.get("takes", 0)) < 1:
        raise PipelineError("Manifest defaults.takes must be a positive integer.")
    models = manifest.get("models")
    if not isinstance(models, dict) or set(models) != SUPPORTED_MODELS:
        raise PipelineError("Manifest models must define both supported Lyria 3 preview IDs.")
    for model_id, model in models.items():
        if float(model.get("usd_per_request", 0.0)) <= 0.0:
            raise PipelineError(f"{model_id} needs a positive usd_per_request.")

    assets = manifest.get("assets")
    if not isinstance(assets, list) or not assets:
        raise PipelineError("Manifest assets must be a non-empty list.")
    seen_ids: set[str] = set()
    seen_paths: set[str] = set()
    for asset in assets:
        asset_id = str(asset.get("id", ""))
        runtime_path = str(asset.get("runtime_path", ""))
        model = str(asset.get("model", ""))
        kind = str(asset.get("kind", ""))
        render = asset.get("render", {})
        if not re.fullmatch(r"[a-z0-9_]+", asset_id):
            raise PipelineError(f"Invalid asset id: {asset_id!r}")
        if asset_id in seen_ids:
            raise PipelineError(f"Duplicate asset id: {asset_id}")
        if runtime_path in seen_paths:
            raise PipelineError(f"Duplicate runtime path: {runtime_path}")
        if model not in SUPPORTED_MODELS:
            raise PipelineError(f"{asset_id}: unsupported model {model}")
        if kind not in SUPPORTED_KINDS:
            raise PipelineError(f"{asset_id}: unsupported kind {kind}")
        if not str(asset.get("brief", "")).strip():
            raise PipelineError(f"{asset_id}: brief is required")
        if not runtime_path.startswith("assets/audio/") or not runtime_path.endswith(".wav"):
            raise PipelineError(f"{asset_id}: runtime_path must be a WAV under assets/audio")
        runtime_file = _repo_path(runtime_path)
        if not runtime_file.is_file():
            raise PipelineError(f"{asset_id}: current runtime file is missing: {runtime_path}")
        if int(render.get("channels", 0)) not in (1, 2):
            raise PipelineError(f"{asset_id}: render.channels must be 1 or 2")
        if int(render.get("sample_rate", 0)) <= 0:
            raise PipelineError(f"{asset_id}: render.sample_rate must be positive")
        if float(render.get("duration_seconds", 0.0)) <= 0.0:
            raise PipelineError(f"{asset_id}: render.duration_seconds must be positive")
        seen_ids.add(asset_id)
        seen_paths.add(runtime_path)

    current_audio = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "assets" / "audio").rglob("*.wav")
    }
    missing = sorted(current_audio - seen_paths)
    stale = sorted(seen_paths - current_audio)
    if missing or stale:
        raise PipelineError(f"Manifest coverage mismatch. missing={missing}, stale={stale}")


def assets_by_id(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {str(asset["id"]): asset for asset in manifest["assets"]}


def select_assets(
    manifest: dict[str, Any], requested: list[str] | None, *, allow_default_all: bool
) -> list[dict[str, Any]]:
    catalog = assets_by_id(manifest)
    if not requested:
        if allow_default_all:
            return list(manifest["assets"])
        raise PipelineError("Select at least one --asset or pass --all.")
    unknown = sorted(set(requested) - set(catalog))
    if unknown:
        raise PipelineError(f"Unknown asset IDs: {', '.join(unknown)}")
    return [catalog[asset_id] for asset_id in requested]


def build_prompt(asset: dict[str, Any]) -> str:
    kind = str(asset["kind"])
    brief = str(asset["brief"]).strip()
    duration = float(asset["render"]["duration_seconds"])
    identity = (
        "This is original audio for a cozy dark-fantasy comedy, 2D quarter-view castle-defense game. "
        "It must be new material, not an imitation of any artist, franchise, existing song, or copyrighted melody."
    )
    if kind == "music_loop":
        return (
            f"{identity}\n\nCompose an instrumental game soundtrack lasting about {duration:.0f} seconds. "
            f"{brief} Keep the arrangement readable under frequent combat sound effects. "
            "No vocals, spoken words, choir syllables, or recognizable samples. Build a coherent arc without a hard ending. "
            "Keep the opening and final two seconds texturally compatible so they can be crossfaded into a seamless loop."
        )

    anchors = "0:02, 0:07, 0:12, 0:17, 0:22, and 0:27"
    if kind == "loop_cue":
        format_direction = (
            f"At each of {anchors}, begin one isolated {duration:.2f}-second seamless loop candidate, "
            "with silence between candidates."
        )
    elif kind == "musical_stinger":
        format_direction = (
            f"At each of {anchors}, begin one isolated musical stinger that fully resolves within {duration:.2f} seconds, "
            "with silence between candidates."
        )
    else:
        format_direction = (
            f"At each of {anchors}, begin one isolated sound-effect variation that fully resolves within {duration:.2f} seconds, "
            "with silence between candidates."
        )
    return (
        f"{identity}\n\nCreate a 30-second game sound-design source reel, not a song. {brief} {format_direction} "
        "Build every variation from three clearly audible layers: a unique physical-material signature, a motion or magical-energy layer, and a short tonal confirmation. "
        "Keep the three layers tightly synchronized and make this identity unmistakably different from a generic hit, slash, fire burst, or UI click. "
        "Use a dry, close, production-ready sound with a clean transient and no clipping. "
        "No background music, beat, continuous ambience, vocals, speech, harsh distress sounds, or long reverb tail."
    )


def estimate_cost(manifest: dict[str, Any], assets: list[dict[str, Any]], takes: int) -> float:
    return sum(float(manifest["models"][asset["model"]]["usd_per_request"]) for asset in assets) * takes


def print_plan(manifest: dict[str, Any], assets: list[dict[str, Any]], takes: int) -> None:
    counts = {model: 0 for model in SUPPORTED_MODELS}
    for asset in assets:
        counts[str(asset["model"])] += takes
    print(f"target_version={manifest['target_version']} assets={len(assets)} takes={takes}")
    for model in sorted(counts):
        print(f"{model}: requests={counts[model]}")
    print(f"estimated_cost_usd={estimate_cost(manifest, assets, takes):.2f}")
    print("Interactions API calls are not made unless generate --execute is present.")


def mime_extension(mime_type: str) -> str:
    normalized = mime_type.lower().split(";", 1)[0].strip()
    if normalized in {"audio/wav", "audio/x-wav", "audio/wave"}:
        return ".wav"
    if normalized in {"audio/mpeg", "audio/mp3"}:
        return ".mp3"
    return ".bin"


def decode_audio(path: Path, channels: int, sample_rate: int) -> array[int]:
    try:
        import miniaudio
    except ImportError as error:
        raise PipelineError("miniaudio is missing. Run tools/audio/setup_lyria.ps1.") from error
    try:
        decoded = miniaudio.decode(
            path.read_bytes(),
            output_format=miniaudio.SampleFormat.SIGNED16,
            nchannels=channels,
            sample_rate=sample_rate,
        )
    except Exception as error:
        raise PipelineError(f"Cannot decode {path}: {error}") from error
    return array("h", decoded.samples)


def _frame_peak(samples: array[int], channels: int, frame: int) -> int:
    start = frame * channels
    return max(abs(int(value)) for value in samples[start : start + channels])


def extract_one_shot(
    samples: array[int], channels: int, sample_rate: int, anchor_seconds: float, duration_seconds: float
) -> array[int]:
    total_frames = len(samples) // channels
    expected = min(total_frames - 1, max(0, int(anchor_seconds * sample_rate)))
    search_start = max(0, expected - int(0.25 * sample_rate))
    search_end = min(total_frames, expected + int(0.60 * sample_rate))
    peak = max((_frame_peak(samples, channels, frame) for frame in range(search_start, search_end)), default=0)
    threshold = max(256, int(peak * 0.08))
    onset = expected
    for frame in range(search_start, search_end):
        if _frame_peak(samples, channels, frame) >= threshold:
            onset = max(0, frame - int(0.004 * sample_rate))
            break
    return slice_frames(samples, channels, onset, int(duration_seconds * sample_rate))


def slice_frames(samples: array[int], channels: int, start_frame: int, frame_count: int) -> array[int]:
    start = max(0, start_frame) * channels
    end = min(len(samples), start + frame_count * channels)
    result = array("h", samples[start:end])
    missing = frame_count * channels - len(result)
    if missing > 0:
        result.extend([0] * missing)
    return result


def loop_crossfade(samples: array[int], channels: int, crossfade_frames: int) -> array[int]:
    frame_count = len(samples) // channels
    if crossfade_frames <= 0:
        return array("h", samples)
    if crossfade_frames * 2 >= frame_count:
        raise PipelineError("Loop crossfade must be shorter than half the rendered cue.")
    mixed = array("h")
    tail_start = (frame_count - crossfade_frames) * channels
    for frame in range(crossfade_frames):
        blend = (frame + 1) / (crossfade_frames + 1)
        for channel in range(channels):
            tail = samples[tail_start + frame * channels + channel]
            head = samples[frame * channels + channel]
            mixed.append(round(tail * (1.0 - blend) + head * blend))
    mixed.extend(samples[crossfade_frames * channels : tail_start])
    return mixed


def apply_fades(samples: array[int], channels: int, fade_in_frames: int, fade_out_frames: int) -> None:
    frame_count = len(samples) // channels
    for frame in range(min(frame_count, fade_in_frames)):
        gain = (frame + 1) / max(1, fade_in_frames)
        for channel in range(channels):
            index = frame * channels + channel
            samples[index] = round(samples[index] * gain)
    for offset in range(min(frame_count, fade_out_frames)):
        gain = (offset + 1) / max(1, fade_out_frames)
        frame = frame_count - 1 - offset
        for channel in range(channels):
            index = frame * channels + channel
            samples[index] = round(samples[index] * gain)


def normalize_peak(samples: array[int], target_dbfs: float) -> None:
    peak = max((abs(int(value)) for value in samples), default=0)
    if peak == 0:
        raise PipelineError("Rendered cue is silent.")
    target = 32767.0 * (10.0 ** (target_dbfs / 20.0))
    gain = min(8.0, target / peak)
    for index, value in enumerate(samples):
        samples[index] = max(-32768, min(32767, round(value * gain)))


def write_wav(path: Path, samples: array[int], channels: int, sample_rate: int) -> None:
    output = array("h", samples)
    if sys.byteorder != "little":
        output.byteswap()
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(output.tobytes())


def find_source_file(take_dir: Path) -> Path:
    sources = sorted(path for path in take_dir.glob("source.*") if path.is_file())
    if len(sources) != 1:
        raise PipelineError(f"Expected one source file in {take_dir}, found {len(sources)}.")
    return sources[0]


def render_take(asset: dict[str, Any], take_dir: Path) -> Path:
    source = find_source_file(take_dir)
    render = asset["render"]
    channels = int(render["channels"])
    sample_rate = int(render["sample_rate"])
    duration = float(render["duration_seconds"])
    samples = decode_audio(source, channels, sample_rate)
    kind = str(asset["kind"])

    if kind == "music_loop":
        requested_frames = int(duration * sample_rate)
        available_frames = len(samples) // channels
        if available_frames < requested_frames * 0.8:
            raise PipelineError(
                f"{asset['id']}: generated track is too short ({available_frames / sample_rate:.2f}s)."
            )
        cue = slice_frames(samples, channels, 0, min(requested_frames, available_frames))
    elif kind in {"one_shot", "musical_stinger"}:
        cue = extract_one_shot(
            samples,
            channels,
            sample_rate,
            float(render.get("anchor_seconds", 2.0)),
            duration,
        )
    else:
        cue = slice_frames(
            samples,
            channels,
            int(float(render.get("anchor_seconds", 2.0)) * sample_rate),
            int(duration * sample_rate),
        )

    crossfade_frames = int(float(render.get("loop_crossfade_seconds", 0.0)) * sample_rate)
    if crossfade_frames:
        cue = loop_crossfade(cue, channels, crossfade_frames)
    apply_fades(
        cue,
        channels,
        int(float(render.get("fade_in_ms", 0.0)) * sample_rate / 1000.0),
        int(float(render.get("fade_out_ms", 0.0)) * sample_rate / 1000.0),
    )
    normalize_peak(cue, float(render.get("peak_dbfs", -1.0)))
    preview = take_dir / "preview.wav"
    write_wav(preview, cue, channels, sample_rate)
    preview_metadata = {
        "asset_id": asset["id"],
        "source_file": source.name,
        "source_sha256": sha256_file(source),
        "preview_file": preview.name,
        "preview_sha256": sha256_file(preview),
        "render": render,
        "rendered_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    write_json(take_dir / "preview.json", preview_metadata)
    return preview


def resolve_run_dir(manifest: dict[str, Any], value: str) -> Path:
    work_root = _repo_path(str(manifest["defaults"]["work_root"])).resolve()
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = ROOT / candidate
    candidate = candidate.resolve()
    if not candidate.is_relative_to(work_root):
        raise PipelineError(f"Run directory must stay under {work_root.relative_to(ROOT)}.")
    return candidate


def generate_assets(
    manifest: dict[str, Any], assets: list[dict[str, Any]], takes: int, run_id: str
) -> Path:
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise PipelineError("GEMINI_API_KEY is not set. Use run_lyria.ps1 for a session-only secure prompt.")
    try:
        from google import genai
    except ImportError as error:
        raise PipelineError("google-genai is missing. Run tools/audio/setup_lyria.ps1.") from error

    if not re.fullmatch(r"[A-Za-z0-9_-]+", run_id):
        raise PipelineError("run_id may contain only letters, numbers, underscores, and hyphens.")
    run_dir = _repo_path(str(manifest["defaults"]["work_root"])) / run_id
    if run_dir.exists():
        raise PipelineError(f"Run directory already exists: {run_dir.relative_to(ROOT)}")
    run_dir.mkdir(parents=True)
    write_json(
        run_dir / "plan.json",
        {
            "target_version": manifest["target_version"],
            "assets": [asset["id"] for asset in assets],
            "takes": takes,
            "estimated_cost_usd": estimate_cost(manifest, assets, takes),
            "store": False,
            "created_at_utc": datetime.now(timezone.utc).isoformat(),
        },
    )

    client = genai.Client(api_key=api_key)
    for asset in assets:
        prompt = build_prompt(asset)
        for take in range(1, takes + 1):
            take_dir = run_dir / str(asset["id"]) / f"take-{take:02d}"
            take_dir.mkdir(parents=True)
            print(f"generating asset={asset['id']} take={take} model={asset['model']}", flush=True)
            interaction = client.interactions.create(
                model=str(asset["model"]),
                input=prompt,
                store=False,
            )
            audio = interaction.output_audio
            if audio is None or not getattr(audio, "data", None):
                raise PipelineError(f"{asset['id']} take {take}: response contains no audio block.")
            encoded = audio.data
            if isinstance(encoded, str):
                encoded = encoded.encode("ascii")
            audio_bytes = base64.b64decode(encoded)
            mime_type = str(getattr(audio, "mime_type", "audio/mpeg") or "audio/mpeg")
            source = take_dir / f"source{mime_extension(mime_type)}"
            source.write_bytes(audio_bytes)
            metadata = {
                "asset_id": asset["id"],
                "target_version": manifest["target_version"],
                "model": asset["model"],
                "interaction_api": "v1beta/interactions",
                "interaction_id": str(getattr(interaction, "id", "")),
                "store": False,
                "prompt": prompt,
                "prompt_sha256": sha256_bytes(prompt.encode("utf-8")),
                "generated_text": str(interaction.output_text or ""),
                "mime_type": mime_type,
                "source_file": source.name,
                "source_sha256": sha256_file(source),
                "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            }
            write_json(take_dir / "generation.json", metadata)
            preview = render_take(asset, take_dir)
            print(f"preview={preview.relative_to(ROOT)}", flush=True)
    return run_dir


def render_existing_run(
    manifest: dict[str, Any], run_dir: Path, assets: list[dict[str, Any]], take: int | None
) -> None:
    for asset in assets:
        asset_dir = run_dir / str(asset["id"])
        take_dirs = [asset_dir / f"take-{take:02d}"] if take else sorted(asset_dir.glob("take-*"))
        if not take_dirs:
            raise PipelineError(f"No takes found for {asset['id']} in {run_dir.relative_to(ROOT)}")
        for take_dir in take_dirs:
            preview = render_take(asset, take_dir)
            print(f"preview={preview.relative_to(ROOT)}")


def source_record(asset: dict[str, Any], generation: dict[str, Any], source_path: str, runtime_path: str) -> str:
    render = asset["render"]
    interaction_id = str(generation.get("interaction_id", "")).strip()
    interaction_reference = interaction_id or "not returned by the Lyria preview response"
    return (
        f"# Lyria 3 source record — {asset['id']}\n\n"
        f"- Generation model: {generation['model']}\n"
        f"- Generated date: {str(generation['generated_at_utc'])[:10]}\n"
        f"- Target version: {generation['target_version']}\n"
        f"- API: Gemini Interactions API (`v1beta/interactions`, `store=false`)\n"
        f"- Interaction ID: `{interaction_reference}`\n"
        f"- Source audio path: `{source_path}`\n"
        f"- Runtime audio path: `{runtime_path}`\n"
        f"- Source SHA-256: `{generation['source_sha256']}`\n"
        f"- Prompt SHA-256: `{generation['prompt_sha256']}`\n"
        f"- Post-processing: decoded to {render['sample_rate']} Hz, {render['channels']} channel(s); "
        f"render contract `{json.dumps(render, ensure_ascii=False, sort_keys=True)}`.\n"
        "- Watermark: Lyria-generated audio contains Google's SynthID audio watermark.\n"
        "- Approval: this file was written only by an explicit `promote --confirm` command.\n"
    )


def promote_asset(
    manifest: dict[str, Any], run_dir: Path, asset: dict[str, Any], take: int, *, confirm: bool, force: bool
) -> None:
    if not confirm:
        raise PipelineError("Promotion overwrites the runtime WAV. Re-run with --confirm after listening.")
    take_dir = run_dir / str(asset["id"]) / f"take-{take:02d}"
    preview = take_dir / "preview.wav"
    generation_file = take_dir / "generation.json"
    if not preview.is_file() or not generation_file.is_file():
        raise PipelineError(f"Missing preview or generation metadata in {take_dir.relative_to(ROOT)}")
    generation = json.loads(generation_file.read_text(encoding="utf-8"))
    source = find_source_file(take_dir)

    source_dir_rel = f"assets/source/audio/lyria/{manifest['target_version']}/{asset['id']}"
    source_dir = _repo_path(source_dir_rel)
    copied_source = source_dir / f"source{source.suffix.lower()}"
    record = source_dir / "SOURCE.md"
    request_record = source_dir / "generation.json"
    if not force and any(path.exists() for path in (copied_source, record, request_record)):
        raise PipelineError(f"Source record already exists for {asset['id']}; use --force to replace it.")

    runtime = _repo_path(str(asset["runtime_path"]))
    source_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, copied_source)
    shutil.copy2(preview, runtime)
    write_json(request_record, generation)
    record.write_text(
        source_record(asset, generation, copied_source.relative_to(ROOT).as_posix(), runtime.relative_to(ROOT).as_posix()),
        encoding="utf-8",
    )
    print(f"promoted={asset['id']} runtime={runtime.relative_to(ROOT)} source={copied_source.relative_to(ROOT)}")


def doctor(manifest: dict[str, Any]) -> int:
    print(f"python={sys.version.split()[0]}")
    for module_name in ("google.genai", "miniaudio"):
        try:
            module = __import__(module_name, fromlist=["*"])
            print(f"{module_name}=OK version={getattr(module, '__version__', 'unknown')}")
        except ImportError:
            print(f"{module_name}=MISSING")
    print(f"manifest=OK assets={len(manifest['assets'])}")
    print(f"GEMINI_API_KEY={'SET' if os.environ.get('GEMINI_API_KEY') else 'NOT_SET'}")
    print("No network request was made.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("validate", help="validate manifest and full current WAV coverage")
    subparsers.add_parser("doctor", help="check local dependencies and key presence without a network call")

    plan_parser = subparsers.add_parser("plan", help="show request counts and estimated cost")
    plan_parser.add_argument("--asset", action="append", dest="assets")
    plan_parser.add_argument("--takes", type=int)

    generate_parser = subparsers.add_parser("generate", help="plan by default; call Interactions only with --execute")
    generate_parser.add_argument("--asset", action="append", dest="assets")
    generate_parser.add_argument("--all", action="store_true")
    generate_parser.add_argument("--takes", type=int)
    generate_parser.add_argument("--run-id", default=None)
    generate_parser.add_argument("--execute", action="store_true")

    render_parser = subparsers.add_parser("render", help="re-render local candidate sources to preview WAV")
    render_parser.add_argument("--run", required=True)
    render_parser.add_argument("--asset", action="append", dest="assets")
    render_parser.add_argument("--take", type=int)

    promote_parser = subparsers.add_parser("promote", help="promote one listened candidate into the game")
    promote_parser.add_argument("--run", required=True)
    promote_parser.add_argument("--asset", required=True)
    promote_parser.add_argument("--take", type=int, required=True)
    promote_parser.add_argument("--confirm", action="store_true")
    promote_parser.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        manifest = load_manifest(args.manifest)
        if args.command == "validate":
            print(f"manifest=OK assets={len(manifest['assets'])} coverage=all-current-wav")
            return 0
        if args.command == "doctor":
            return doctor(manifest)
        if args.command == "plan":
            takes = args.takes or int(manifest["defaults"]["takes"])
            if takes < 1:
                raise PipelineError("--takes must be positive.")
            print_plan(manifest, select_assets(manifest, args.assets, allow_default_all=True), takes)
            return 0
        if args.command == "generate":
            requested = None if args.all else args.assets
            assets = select_assets(manifest, requested, allow_default_all=args.all)
            takes = args.takes or int(manifest["defaults"]["takes"])
            if takes < 1:
                raise PipelineError("--takes must be positive.")
            print_plan(manifest, assets, takes)
            if not args.execute:
                print("Dry run complete. Add --execute to make paid API calls.")
                return 0
            run_id = args.run_id or utc_timestamp()
            run_dir = generate_assets(manifest, assets, takes, run_id)
            print(f"run={run_dir.relative_to(ROOT)}")
            return 0
        if args.command == "render":
            run_dir = resolve_run_dir(manifest, args.run)
            requested = args.assets
            if not requested:
                requested = sorted(path.name for path in run_dir.iterdir() if path.is_dir())
            assets = select_assets(manifest, requested, allow_default_all=False)
            render_existing_run(manifest, run_dir, assets, args.take)
            return 0
        if args.command == "promote":
            run_dir = resolve_run_dir(manifest, args.run)
            asset = select_assets(manifest, [args.asset], allow_default_all=False)[0]
            promote_asset(manifest, run_dir, asset, args.take, confirm=args.confirm, force=args.force)
            return 0
        raise PipelineError(f"Unsupported command: {args.command}")
    except PipelineError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
