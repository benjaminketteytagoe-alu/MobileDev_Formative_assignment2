#!/usr/bin/env bash
# Starts the local Firebase Storage emulator with storage.rules. Photos are kept
# in .emulator-data between runs. Run from the student_support folder, then in
# another terminal:
#
#   flutter run --dart-define=STORAGE_EMULATOR_HOST=10.0.2.2
set -euo pipefail
cd "$(dirname "$0")/.."

args=(emulators:start --only storage --project studentsupport-88445
      --export-on-exit=.emulator-data)
if [ -f .emulator-data/firebase-export-metadata.json ]; then
  args+=(--import=.emulator-data)
fi
exec firebase "${args[@]}"
