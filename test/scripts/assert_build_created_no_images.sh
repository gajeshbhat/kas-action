#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d build ]]; then
  echo "Expected build directory at ./build but none found"
  exit 1
fi

if [[ -d build/tmp/deploy/images ]]; then
  echo "Unexpected images directory found at build/tmp/deploy/images (should not exist for -n/noexec)"
  exit 1
fi

echo "Build directory exists and no images were produced. OK."

