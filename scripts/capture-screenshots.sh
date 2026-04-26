#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/mobile"
CAPTURE_ROOT="$ROOT_DIR/captures/store"
SUPPORT_DIR="$CAPTURE_ROOT/support"
SAMPLE_IMPORT_FILE="$SUPPORT_DIR/sample-record.txt"
APP_BUNDLE_ID="com.curator.curatormobile"

TARGET="${1:-appstore67}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/capture-screenshots.sh appstore67
  ./scripts/capture-screenshots.sh appstore47
  ./scripts/capture-screenshots.sh play

Profiles:
  appstore67  Boot iPhone 15 Pro Max and capture the App Store 6.7" set
  appstore47  Boot iPhone 8 and capture the App Store 4.7" set
  play        Boot iPhone 15 Pro Max and capture the Play Store raw set
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

ensure_sample_file() {
  mkdir -p "$SUPPORT_DIR"
  cat >"$SAMPLE_IMPORT_FILE" <<'EOF'
2026-04-26

오늘은 퇴근 뒤에 산책을 하니 머리가 조금 맑아졌다.
아침에는 피곤했지만, 오후에 짧게 메모를 정리하니 해야 할 일이 덜 무겁게 느껴졌다.
이번 주에는 무리해서 많이 하기보다, 작게 끝낸 일을 기록하는 편이 더 도움이 된다.
EOF
}

latest_ios_runtime() {
  xcrun simctl list runtimes available -j | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
best = None
best_key = None
for runtime in data.get("runtimes", []):
    identifier = runtime.get("identifier", "")
    if "iOS" not in identifier or not runtime.get("isAvailable", False):
        continue
    version = runtime.get("version", "")
    parts = tuple(int(p) for p in re.findall(r"\d+", version))
    if best is None or parts > best_key:
        best = identifier
        best_key = parts
if not best:
    raise SystemExit("No available iOS simulator runtime found.")
print(best)
'
}

find_device_udid() {
  local device_name="$1"
  xcrun simctl list devices available -j | python3 -c '
import json, sys
target = sys.argv[1]
data = json.load(sys.stdin)
matches = []
for _, devices in data.get("devices", {}).items():
    for device in devices:
        if device.get("isAvailable") and device.get("name") == target:
            matches.append(device.get("udid"))
if matches:
    print(matches[0])
' "$device_name"
}

ensure_device() {
  local device_name="$1"
  local device_type_id="$2"
  local udid

  udid="$(find_device_udid "$device_name")"
  if [[ -n "$udid" ]]; then
    echo "$udid"
    return
  fi

  local runtime_id
  runtime_id="$(latest_ios_runtime)"
  xcrun simctl create "$device_name" "$device_type_id" "$runtime_id"
}

boot_device() {
  local udid="$1"
  open -a Simulator --args -CurrentDeviceUDID "$udid" >/dev/null 2>&1 || true
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl ui "$udid" appearance light >/dev/null 2>&1 || true
}

build_and_launch_app() {
  pushd "$MOBILE_DIR" >/dev/null
  flutter pub get
  flutter build ios --simulator --debug --no-codesign
  popd >/dev/null

  local app_bundle="$MOBILE_DIR/build/ios/iphonesimulator/Runner.app"
  if [[ ! -d "$app_bundle" ]]; then
    echo "Built app bundle not found at $app_bundle" >&2
    exit 1
  fi

  xcrun simctl uninstall "$UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$UDID" "$app_bundle"
  xcrun simctl launch "$UDID" "$APP_BUNDLE_ID" >/dev/null
}

print_common_setup() {
  cat <<EOF

Common setup before capturing:
  1. Use Korean locale: Settings > General > Language & Region > 한국어 / 대한민국
  2. Keep the simulator in Light mode
  3. Dismiss system alerts and notification banners
  4. Use the sample import file when needed:
     $SAMPLE_IMPORT_FILE

When a step is ready:
  - Press Enter to save the current simulator screen to the target path
  - Type s to skip a file
  - Type q to quit
EOF
}

capture_prompt() {
  local output_path="$1"
  mkdir -p "$(dirname "$output_path")"

  while true; do
    printf "\nCapture to %s ? [Enter=save, s=skip, q=quit] " "$output_path"
    read -r answer
    case "$answer" in
      "")
        xcrun simctl io "$UDID" screenshot "$output_path" >/dev/null
        echo "Saved: $output_path"
        return
        ;;
      s|S|skip|SKIP)
        echo "Skipped: $output_path"
        return
        ;;
      q|Q|quit|QUIT)
        echo "Stopping capture run."
        exit 0
        ;;
      *)
        echo "Enter=save, s=skip, q=quit"
        ;;
    esac
  done
}

show_step() {
  local title="$1"
  local instructions="$2"
  local output_path="$3"

  echo
  echo "================================================================"
  echo "$title"
  echo "----------------------------------------------------------------"
  printf "%s\n" "$instructions"
  echo "Expected file:"
  echo "  $output_path"
  capture_prompt "$output_path"
}

show_play_export_summary() {
  cat <<EOF

Play Store post-processing:
  - Raw captures were saved under:
    $PLAY_RAW_DIR
  - Export final uploads to:
    $PLAY_FINAL_DIR
  - Final size per screenshot: 1080 x 1920
  - Crop the iPhone 15 Pro Max raw portrait vertically before export.

Expected final files:
  $PLAY_FINAL_DIR/01-onboarding-1080x1920.png
  $PLAY_FINAL_DIR/02-home-first-entry-1080x1920.png
  $PLAY_FINAL_DIR/03-question-input-1080x1920.png
  $PLAY_FINAL_DIR/04-curation-result-1080x1920.png
  $PLAY_FINAL_DIR/05-settings-runtime-badge-1080x1920.png
  $PLAY_FINAL_DIR/06-file-import-state-1080x1920.png
  $PLAY_FINAL_DIR/07-calendar-sync-state-1080x1920.png
  $PLAY_FINAL_DIR/08-delete-confirmation-1080x1920.png
EOF
}

run_app_store_sequence() {
  local output_dir="$1"

  show_step \
    "1. Onboarding" \
    $'Fresh install state.\nWait for the first onboarding page with `큐레이터 시작하기` and the large `큐\\n레이터` hero copy.' \
    "$output_dir/01-onboarding.png"

  show_step \
    "2. Home Dashboard" \
    $'Move to the last onboarding page.\nEnable `데모 데이터 함께 시작하기`, tap `시작하기`, and wait for the populated home screen.\nCapture the home screen with `오늘의 질문` visible.' \
    "$output_dir/02-home-dashboard.png"

  show_step \
    "3. Question Input" \
    $'Open the ask flow from `오늘의 질문`.\nEnter `나 요즘 왜 이렇게 무기력하지?` and capture before submitting.' \
    "$output_dir/03-question-input.png"

  show_step \
    "4. Curation Result" \
    $'Submit the question and wait for the answer stream to finish.\nCapture the answer body with `참고한 기록` and at least one supporting record card visible.' \
    "$output_dir/04-curation-result.png"

  show_step \
    "5. Settings Runtime / Privacy" \
    $'Open Settings.\nStay near the top so the runtime summary, `사용 방식`, `온디바이스 우선`, and `현재 모드` are visible in one frame.' \
    "$output_dir/05-settings-runtime-privacy.png"

  show_step \
    "6. File Import" \
    $'Use `파일 가져오기` and import the sample file:\n'"$SAMPLE_IMPORT_FILE"$'\nAfter import, capture the settings area showing file import state or import history.' \
    "$output_dir/06-file-import.png"

  show_step \
    "7. Calendar Sync" \
    $'Create a recent test event in the iOS Calendar app if possible, then return to Curator.\nEnable `캘린더 동기화`, grant permission, run `지금 동기화`, and capture the status rows.' \
    "$output_dir/07-calendar-sync.png"
}

run_play_sequence() {
  show_step \
    "1. Onboarding" \
    $'Fresh install state.\nWait for the first onboarding page with `큐레이터 시작하기`.' \
    "$PLAY_RAW_DIR/01-onboarding.png"

  show_step \
    "2. Home First Entry" \
    $'Move to the last onboarding page.\nEnable `데모 데이터 함께 시작하기`, tap `시작하기`, and wait for the first populated home screen.' \
    "$PLAY_RAW_DIR/02-home-first-entry.png"

  show_step \
    "3. Question Input" \
    $'Open the ask flow and enter `나 요즘 왜 이렇게 무기력하지?`.\nCapture before submission.' \
    "$PLAY_RAW_DIR/03-question-input.png"

  show_step \
    "4. Curation Result" \
    $'Submit the question, wait until the answer finishes rendering, and capture the answer card / supporting record composition.' \
    "$PLAY_RAW_DIR/04-curation-result.png"

  show_step \
    "5. Settings Runtime Badge" \
    $'Open Settings.\nCapture the top area with the runtime summary and the `온디바이스 우선` state.' \
    "$PLAY_RAW_DIR/05-settings-runtime-badge.png"

  show_step \
    "6. File Import State" \
    $'Import the sample file:\n'"$SAMPLE_IMPORT_FILE"$'\nCapture the `파일 가져오기` area after the import completes.' \
    "$PLAY_RAW_DIR/06-file-import-state.png"

  show_step \
    "7. Calendar Sync State" \
    $'Create a recent test event in Calendar if possible.\nEnable calendar sync, allow permission, run `지금 동기화`, and capture the permission/status/imported-count area.' \
    "$PLAY_RAW_DIR/07-calendar-sync-state.png"

  show_step \
    "8. Delete Confirmation" \
    $'In Settings, tap `모든 데이터 삭제`.\nWhen the confirmation dialog appears, capture it and then tap `취소` unless you intentionally want to reset the simulator state.' \
    "$PLAY_RAW_DIR/08-delete-confirmation.png"

  show_play_export_summary
}

require_cmd xcrun
require_cmd python3
require_cmd flutter
require_cmd open

case "$TARGET" in
  appstore67)
    DEVICE_NAME="iPhone 15 Pro Max"
    DEVICE_TYPE_ID="com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max"
    OUTPUT_DIR="$CAPTURE_ROOT/app-store/ko-KR/iphone-15-pro-max"
    ;;
  appstore47)
    DEVICE_NAME="iPhone 8"
    DEVICE_TYPE_ID="com.apple.CoreSimulator.SimDeviceType.iPhone-8"
    OUTPUT_DIR="$CAPTURE_ROOT/app-store/ko-KR/iphone-8"
    ;;
  play)
    DEVICE_NAME="iPhone 15 Pro Max"
    DEVICE_TYPE_ID="com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max"
    PLAY_RAW_DIR="$CAPTURE_ROOT/play-store/ko-KR/raw-iphone-15-pro-max"
    PLAY_FINAL_DIR="$CAPTURE_ROOT/play-store/ko-KR/final"
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

ensure_sample_file

echo "Preparing simulator device: $DEVICE_NAME"
UDID="$(ensure_device "$DEVICE_NAME" "$DEVICE_TYPE_ID")"
echo "Using UDID: $UDID"

boot_device "$UDID"
build_and_launch_app
print_common_setup

echo
echo "Expected output root: $CAPTURE_ROOT"

case "$TARGET" in
  appstore67|appstore47)
    run_app_store_sequence "$OUTPUT_DIR"
    ;;
  play)
    run_play_sequence
    ;;
esac

echo
echo "Capture guide complete."
