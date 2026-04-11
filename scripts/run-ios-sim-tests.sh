#!/usr/bin/env bash
set -euo pipefail

cd mobile
flutter test integration_test
# 상황에 따라 아래로 대체 가능
# flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart