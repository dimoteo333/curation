#!/usr/bin/env bash
set -euo pipefail

strict=0
if [[ "${1:-}" == "--strict" ]]; then
  strict=1
fi

issues=0

while IFS= read -r line; do
  if [[ "$line" =~ latest\.release|[\"\']\+[\"\']|SNAPSHOT ]]; then
    echo "::warning file=mobile/android/app/build.gradle.kts::Dynamic Android dependency detected: $line"
    issues=1
  fi
done < <(grep -n 'implementation(' mobile/android/app/build.gradle.kts || true)

while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*pod[[:space:]]\'[^\']+\'[[:space:]]*$ ]]; then
    echo "::warning file=mobile/ios/Podfile::Unpinned iOS pod detected: $line"
    issues=1
  fi
done < mobile/ios/Podfile

if [[ "$issues" -eq 1 && "$strict" -eq 1 ]]; then
  echo "Native dependency pin check failed"
  exit 1
fi

if [[ "$issues" -eq 1 ]]; then
  echo "Native dependency pin check reported warnings"
else
  echo "Native dependency pin check passed"
fi
