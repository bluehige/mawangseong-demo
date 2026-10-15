"""Offline Windows launcher checks. All setup/generation commands are local stubs."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent
POWERSHELL = shutil.which("powershell.exe")


@unittest.skipUnless(POWERSHELL, "Windows PowerShell is required")
class V130LauncherTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory(prefix="bgm offline ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.tools = self.root / "tools" / "audio"
        self.tools.mkdir(parents=True)
        self.log = self.root / "orchestra logs" / "bgm-1.3.0-run.log"
        for filename in ("start_v130_bgm.ps1", "lyria_v130_manifest.json", "run_lyria.ps1"):
            shutil.copy2(TOOLS / filename, self.tools / filename)
        self.trace = self.root / "trace.txt"

    def run_ps(self, script: str, input_text: str = "", env: dict | None = None) -> subprocess.CompletedProcess:
        return subprocess.run(
            [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script],
            input=input_text, text=True, capture_output=True, timeout=40, env=env,
        )

    def launcher(self, answer: str) -> subprocess.CompletedProcess:
        # Read-Host is replaced only in this test host; no real key or API is used.
        command = (
            f"function Read-Host {{ return '{answer}' }}; "
            f"& '{self.tools / 'start_v130_bgm.ps1'}' -LogPath '{self.log}'"
        )
        return self.run_ps(command)

    def write_stubs(self, setup_exit: int = 0) -> None:
        (self.tools / "setup_lyria.ps1").write_text(
            f"Add-Content -LiteralPath '{self.trace}' -Value 'setup'\n"
            f"Write-Output 'offline setup stub'\nexit {setup_exit}\n", encoding="utf-8",
        )
        (self.tools / "run_lyria.ps1").write_text(
            "param([string]$LogPath, [Parameter(ValueFromRemainingArguments=$true)][string[]]$PipelineArgs)\n"
            f"Add-Content -LiteralPath '{self.trace}' -Value ('generate ' + ($PipelineArgs -join ' '))\n"
            "if ($env:GEMINI_API_KEY) { throw 'inherited key was not cleared' }\n"
            "Add-Content -LiteralPath $LogPath -Value 'offline generation stub'\nexit 0\n", encoding="utf-8",
        )

    def test_non_y_cancels_before_setup_or_generation(self) -> None:
        self.write_stubs()
        result = self.launcher("N")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertIn("15 tracks, 15 requests, estimated USD 1.20", result.stdout)
        self.assertFalse(self.trace.exists())

    def test_y_runs_setup_then_explicit_v130_generation_and_logs_result(self) -> None:
        self.write_stubs()
        result = self.launcher("Y")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        trace = self.trace.read_text(encoding="utf-8-sig").splitlines()
        self.assertEqual("setup", trace[0])
        self.assertIn("--manifest", trace[1])
        self.assertIn("lyria_v130_manifest.json generate --all --takes 1 --run-id v130-", trace[1])
        self.assertTrue(trace[1].endswith("--execute"))
        log = self.log.read_text(encoding="utf-8-sig")
        self.assertIn("estimated_cost_usd=1.20", log)
        self.assertIn("offline setup stub", log)
        self.assertIn("offline generation stub", log)
        self.assertIn("stage=generate exit=0", log)

    def test_setup_failure_prevents_generation(self) -> None:
        self.write_stubs(setup_exit=9)
        result = self.launcher("Y")
        self.assertEqual(1, result.returncode)
        self.assertEqual(["setup"], self.trace.read_text(encoding="utf-8-sig").splitlines())
        self.assertIn("Generation was not started", self.log.read_text(encoding="utf-8-sig"))

    def test_generation_stderr_and_stdout_redact_key_and_keep_exit_code(self) -> None:
        # An offline venv provides the same executable path as production.
        subprocess.run(
            [sys.executable, "-m", "venv", "--without-pip", str(self.root / "tmp/lyria_audio_venv")],
            check=True, capture_output=True, timeout=30,
        )
        fake_key = "offline-test-secret-never-a-real-key"
        (self.tools / "lyria_pipeline.py").write_text(
            "import os,sys\n"
            "print('stdout '+os.environ['GEMINI_API_KEY'], flush=True)\n"
            "print('stderr '+os.environ['GEMINI_API_KEY'], file=sys.stderr, flush=True)\n"
            "raise SystemExit(7)\n", encoding="utf-8",
        )
        env = dict(os.environ, GEMINI_API_KEY=fake_key)
        result = subprocess.run(
            [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
             str(self.tools / "run_lyria.ps1"), "-LogPath", str(self.log), "generate", "--all", "--execute"],
            text=True, capture_output=True, timeout=40, env=env,
        )
        self.assertEqual(7, result.returncode, result.stdout + result.stderr)
        log = self.log.read_text(encoding="utf-8-sig")
        self.assertNotIn(fake_key, log + result.stdout + result.stderr)
        self.assertIn("stdout [REDACTED]", log)
        self.assertIn("stderr [REDACTED]", log)

    def test_run_wrapper_accepts_explicit_v130_manifest_and_stays_dry(self) -> None:
        subprocess.run(
            [sys.executable, "-m", "venv", "--without-pip", str(self.root / "tmp/lyria_audio_venv")],
            check=True, capture_output=True, timeout=30,
        )
        shutil.copy2(TOOLS / "lyria_pipeline.py", self.tools / "lyria_pipeline.py")
        result = subprocess.run(
            [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
             str(self.tools / "run_lyria.ps1"), "-LogPath", str(self.log), "--manifest",
             str(self.tools / "lyria_v130_manifest.json"), "generate", "--all"],
            text=True, capture_output=True, timeout=40,
        )
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        log = self.log.read_text(encoding="utf-8-sig")
        self.assertIn("target_version=v1.3.0 assets=15 takes=1", log)
        self.assertIn("estimated_cost_usd=1.20", log)
        self.assertIn("Dry run complete", log)
        self.assertFalse((self.root / "tmp/lyria_audio_v130").exists())
        # Existing callers pass the command positionally, without a LogPath.
        shutil.copy2(self.tools / "lyria_v130_manifest.json", self.tools / "lyria_v122_manifest.json")
        legacy = subprocess.run(
            [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
             str(self.tools / "run_lyria.ps1"), "generate", "--all"],
            text=True, capture_output=True, timeout=40,
        )
        self.assertEqual(0, legacy.returncode, legacy.stdout + legacy.stderr)
        self.assertIn("Dry run complete", legacy.stdout)


if __name__ == "__main__":
    unittest.main()
