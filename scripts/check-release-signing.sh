#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
from pathlib import Path
import re
import sys

path = Path("mobile/android/app/build.gradle.kts")
text = path.read_text()

release_block = re.search(
    r'buildTypes\s*\{.*?release\s*\{(?P<body>.*?)^\s*\}',
    text,
    re.DOTALL | re.MULTILINE,
)

if release_block and re.search(
    r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
    release_block.group("body"),
):
    print(
        "::error file=mobile/android/app/build.gradle.kts::"
        "Release build is configured to use debug signing."
    )
    sys.exit(1)
PY

echo "Release signing guard passed"
