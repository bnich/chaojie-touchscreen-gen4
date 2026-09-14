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
PARTS=(gauge spline_test yoke arm cap cowl brow_test)   # extend as parts land

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

# ⛔ SAME TRAP, THE COWL'S OWN SHAPE. A thin shell built from several
# unioned pieces (box + riser + cantilever + hook + bosses) can pass
# watertight/0-boundary/0-non-manifold/1-component while still being mostly
# air if a wall silently thinned to nothing somewhere — exactly what
# happened once here: chamfering the box's OPEN front rim eroded the outer
# profile faster than the inner cavity's own erosion, and the wall vanished
# for the first ~0.7mm all the way round (found by slicing the exported
# mesh, not by this check — this check exists so the NEXT such bug doesn't
# need a manual slice to catch).
#   The expectation below is a closed-form per-feature estimate (rounded-
# rect shell formula for the box/riser/cantilever, box/cylinder volumes for
# the hook/bosses) — NOT a re-measurement of this same STL, so it is a
# genuine independent check. It is a deliberate OVERESTIMATE, documented,
# not tuned to match: it does not account for (a) the main box's own cavity
# also trimming the riser/cantilever where their footprints overlap it
# (confirmed by direct construction-stage measurement: box-only shell alone
# is 67071 mm^3, matching this formula's own box term to 0.05%, while the
# riser/cantilever terms alone run high because they don't know about that
# shared trim) or (b) the two M3 clearance holes. Both only ever REMOVE
# material the naive formula still counts, so actual/expected should sit
# below 1.0, comfortably above a real hollow-shell ratio (0.05-0.3, per the
# spline case above) — the tolerance band (0.6-1.0) is wide enough to absorb
# (a)+(b) without being wide enough to pass a genuinely hollow part.
echo "--- cowl fill (guards against a hollow shell)"
/root/.venvs/revv1/bin/python - <<'PYEOF'
import trimesh, math, sys

disp_w, disp_h, disp_corner_r = 159.99, 93.98, 9.0
reveal, cowl_wall = 0.5, 2.4
fillet_out, fillet_vis = 3.0, 2.0
boot_proud = 22.3
cowl_depth = boot_proud + 8
brow, brow_clear, brow_root = 19.0, 3.0, 10.0
riser_y0 = disp_h/2 + reveal - 10
brow_y0 = disp_h/2 + brow_clear
brow_y1 = brow_y0 + brow_root
riser_h = 8.0
cant_lap = 2*cowl_wall
hook_engage, hook_w = 1.5, 40.0
m3_boss_d, m3_boss_len = 8.0, 14.0

def rr_area(w, h, r):
    r = max(r, 0.0)
    return w*h - (4-math.pi)*r*r

def perim(w, h, r):
    r = max(r, 0.0)
    return 2*(w-2*r) + 2*(h-2*r) + 2*math.pi*r

A_o = rr_area(disp_w+2*reveal, disp_h+2*reveal, disp_corner_r)
A_i = rr_area(disp_w+2*reveal-2*cowl_wall, disp_h+2*reveal-2*cowl_wall, disp_corner_r-cowl_wall)
box = A_o*cowl_depth - A_i*(cowl_depth-cowl_wall)
box -= 0.5*fillet_out**2 * perim(disp_w+2*reveal, disp_h+2*reveal, disp_corner_r)

rw, rh = disp_w+2*reveal, brow_y1-riser_y0
Ro, Ri = rr_area(rw, rh, fillet_vis), rr_area(rw-2*cowl_wall, rh-2*cowl_wall, fillet_vis-cowl_wall)
riser = Ro*riser_h - Ri*(riser_h-cowl_wall)

cw, ch_ = disp_w+2*reveal, brow_root
Co, Ci = rr_area(cw, ch_, fillet_vis), rr_area(cw-2*cowl_wall, ch_-2*cowl_wall, fillet_vis-cowl_wall)
cant = Co*(brow+cant_lap) - Ci*(brow-cowl_wall)
cant -= 0.5*fillet_vis**2 * perim(cw, ch_, fillet_vis)

hook = hook_w * (hook_engage+reveal) * cowl_wall
bosses = 2 * math.pi*(m3_boss_d/2)**2 * m3_boss_len

expect = box + riser + cant + hook + bosses
actual = trimesh.load("stl/gen4-cowl.stl", process=True).volume
ratio = actual/expect
print(f"    actual {actual:8.1f} mm^3 vs expected(overestimate) {expect:8.1f}  ratio {ratio:.3f}")
if not 0.6 <= ratio <= 1.0:
    print("    FAIL: cowl fill is wrong — hollow shell, or the geometry changed enough to need a new expectation"); sys.exit(1)
print("    OK")
PYEOF

# ⛔ A RENDER CANNOT SHOW INTERFERENCE. Prove the cowl clears the yoke, the
# arm, and the display itself with a different boolean engine (manifold3d,
# not CGAL) on the actual exported meshes, positioned into one shared frame.
echo "--- cowl clearance vs yoke / arm / display"
/root/.venvs/revv1/bin/python - <<'PYEOF'
import math, os, sys, trimesh

# cowl and yoke are both built directly in the shared display-rear-face
# frame (both go through the file's own p() convention) -- no transform.
# The arm needs the seating transform derived from face_spline()'s own
# ORIENTATION contract (docs/spline-verification.md): mirror it in Z and
# translate so the two flat backs land base_female+base_male+spline_h apart,
# with the male spline's XY centred on the female's (p(pivot_c)).
disp_w, disp_h = 159.99, 93.98
pivot_c = (80, 100)
p_pivot = (pivot_c[0]-disp_w/2, disp_h/2-pivot_c[1])
yoke_t, yoke_standoff = 8.0, 8.0
base_female, base_male, spline_h = 3.0, 3.0, 1.6
clamp_x0, clamp_w, arm_crank, arm_len = 1.0, 18.0, 32.5, 45.0
arm_pivot_y = clamp_x0 + clamp_w/2 - arm_crank

F = yoke_t + yoke_standoff
target_male_back_z = F + base_female + base_male + spline_h
Tx = p_pivot[0]
Ty = p_pivot[1] + arm_pivot_y
Tz = target_male_back_z + arm_len

R = trimesh.transformations.rotation_matrix(math.radians(180), [1, 0, 0])
T = trimesh.transformations.translation_matrix([Tx, Ty, Tz])
arm = trimesh.load("stl/gen4-arm.stl")
arm_t = arm.copy(); arm_t.apply_transform(T @ R)
arm_t.export("stl/_check_arm_positioned.stl")

disp_d, disp_corner_r = 26.0, 9.0
disp_scad = f"""
disp_w={disp_w}; disp_h={disp_h}; disp_d={disp_d}; disp_corner_r={disp_corner_r};
$fn = 64;
translate([0,0,-disp_d])
  linear_extrude(disp_d)
    offset(r = disp_corner_r) offset(delta = -disp_corner_r)
      square([disp_w, disp_h], center = true);
"""
with open("/tmp/_display_stub.scad", "w") as f:
    f.write(disp_scad)
os.system("openscad -o stl/_check_display_stub.stl /tmp/_display_stub.scad >/dev/null 2>&1")

ok = True
for label, path in [("yoke", "stl/gen4-yoke.stl"),
                     ("arm (positioned)", "stl/_check_arm_positioned.stl"),
                     ("display stand-in", "stl/_check_display_stub.stl")]:
    rc = os.system(f"/root/.venvs/revv1/bin/python ../tools/check_fit.py intersect "
                    f"stl/gen4-cowl.stl {path}")
    status = "CLEAR" if rc == 0 else "FAILED"
    print(f"    cowl vs {label}: {status}")
    if rc != 0:
        ok = False
if not ok:
    sys.exit(1)
PYEOF
rm -f stl/_check_arm_positioned.stl stl/_check_display_stub.stl /tmp/_display_stub.scad

echo "ALL-OK"
