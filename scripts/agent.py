#!/usr/bin/env python3
"""Compatibility wrapper for the MoonBit-first AutoAgent shell runtime."""

import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    shell = root / "scripts" / "autoagent.sh"
    command = [str(shell), *sys.argv[1:]]
    return subprocess.call(command, cwd=root, env=os.environ.copy())


if __name__ == "__main__":
    raise SystemExit(main())
