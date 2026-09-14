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
PARTS=(gauge spline_test yoke arm cap)   # extend as parts land

for part in "${PARTS[@]}"; do
  out="stl/gen4-${part//_/-}.stl"
  echo "--- $part"
  openscad -o "$out" -D "part=\"$part\"" "$SRC"
  python3 tools/check_stl.py "$out"
done

# ⛔ VOLUME IS THE ONLY CHECK THAT CATCHES A HOLLOW PART.
# Watertight, zero boundary edges, zero non-manifold edges and one connected
# component ALL PASS on a shell that is mostly air. The spline teeth shipped
# for two rounds at 44 mm^3 against the ~915 mm^3 a solid ridge set needs, and
# every one of those four checks was green. Compare volume to a hand-computed
# expectation, or you are not testing fill at all.
echo "--- spline fill (guards against a hollow tooth set)"
openscad -o /tmp/_disc_only.stl -D 'part="spline_test"' -D 'teeth=false' "$SRC" >/dev/null 2>&1
/root/.venvs/revv1/bin/python - <<'PYEOF'
import trimesh, math, sys
disc = trimesh.load("/tmp/_disc_only.stl", process=True).volume
full = trimesh.load("stl/gen4-spline-test.stl", process=True).volume
teeth = full - disc
expect = math.pi*(20.0**2 - 6.0**2) * (1.6/2)   # annulus x mean height of a triangular wave
ratio = teeth/expect
print(f"    teeth {teeth:8.1f} mm^3 vs expected {expect:8.1f}  ratio {ratio:.2f}")
if not 0.9 <= ratio <= 1.15:
    print("    FAIL: tooth fill is wrong — hollow teeth, or the profile changed"); sys.exit(1)
print("    OK")
PYEOF
rm -f /tmp/_disc_only.stl

echo "ALL-OK"
