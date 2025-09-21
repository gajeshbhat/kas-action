#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d build/tmp/deploy/images ]]; then
  echo "Images directory not found at build/tmp/deploy/images"
  exit 1
fi

shopt -s nullglob
mapfile -t files < <(compgen -G "build/tmp/deploy/images/*/core-image-minimal*")

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No core-image-minimal artifacts found under build/tmp/deploy/images/*"
  exit 1
fi

echo "Found core-image-minimal artifacts:"
printf ' - %s\n' "${files[@]}"

