#!/bin/bash
# https://stackoverflow.com/questions/3349105/how-can-i-set-the-current-working-directory-to-the-directory-of-the-script-in-ba
cd "$(dirname "$0")"
echo "wokring directory: $PWD"

# build apk
flutter build apk --target-platform android-arm64 --split-per-abi -v

# install apk
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk