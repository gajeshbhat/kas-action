#!/usr/bin/env bash
set -euo pipefail

if [[ -d build/tmp/deploy/images ]]; then
  echo "Unexpected images directory found at build/tmp/deploy/images"
  exit 1
fi

if [[ -d build ]]; then
  echo "Unexpected build directory found at ./build"
  exit 1
fi

echo "No build artifacts found. OK."

