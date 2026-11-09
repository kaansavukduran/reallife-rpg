#!/bin/sh
# Run the real storage/UI roundtrip instead of relying on screen coordinates.
set -eu
flutter test integration_test/file_roundtrip_test.dart -d linux
