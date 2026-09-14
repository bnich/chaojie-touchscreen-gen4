#!/usr/bin/env bash
# Export every part and verify each bounding box.
#
# NOTE: exports a SOLID format deliberately. OpenSCAD exits 0 on a failed
# assert() for tree formats (echo/csg/ast/term) and for PNG, and only returns
# non-zero for stl/off/3mf/amf. Checking assertions any other way silently
# reports success.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=src/gen4-display-mount.scad
mkdir -p stl renders

# parts implemented so far; extend as they land
PARTS=(gauge spline_test yoke)   # extend as parts land

for part in "${PARTS[@]}"; do
  out="stl/gen4-${part//_/-}.stl"
  echo "--- $part"
  openscad -o "$out" -D "part=\"$part\"" "$SRC"
  python3 tools/check_stl.py "$out"
done

echo "ALL-OK"
