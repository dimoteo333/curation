#!/usr/bin/env bash
set -euo pipefail

if grep -Eq 'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)' mobile/android/app/build.gradle.kts; then
  echo "::error file=mobile/android/app/build.gradle.kts::Release build is configured to use debug signing."
  exit 1
fi

echo "Release signing guard passed"
