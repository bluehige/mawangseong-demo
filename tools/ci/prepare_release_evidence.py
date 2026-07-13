#!/usr/bin/env python3
import argparse
import shutil
import sys
from pathlib import Path

from core_verification_evidence import EvidenceError, validate_runner_report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-report", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--expected-commit", required=True)
    args = parser.parse_args()

    try:
        _, full_ids = validate_runner_report(
            args.raw_report,
            args.catalog,
            args.expected_commit,
        )
    except EvidenceError as error:
        print(f"RELEASE_EVIDENCE: FAIL - {error}", file=sys.stderr)
        raise SystemExit(1)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    report_target = args.output_dir / "verification-report.json"
    catalog_target = args.output_dir / "verification-catalog.json"
    shutil.copyfile(args.raw_report, report_target)
    shutil.copyfile(args.catalog, catalog_target)
    print(
        "RELEASE_EVIDENCE: PASS "
        f"({len(full_ids)} Full checks, {args.expected_commit})"
    )


if __name__ == "__main__":
    main()
