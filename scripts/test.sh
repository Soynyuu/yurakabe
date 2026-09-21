#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
swiftc YurakabeExtension/PlaybackMode.swift YurakabeExtension/PlaybackPolicy.swift Tests/ModeContract.swift -o build/tests/modes
build/tests/modes
swiftc YurakabeExtension/VideoFit.swift Tests/VideoFitContract.swift -o build/tests/fit
build/tests/fit
swiftc YurakabeExtension/LoopPosition.swift Tests/LoopContract.swift -o build/tests/loops
build/tests/loops
swiftc -parse-as-library Yurakabe/LibraryStore.swift Tests/ImportContract.swift -o build/tests/import
build/tests/import
