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

# ⚠ Do NOT hardcode an interpreter path. This script broke CI on 2026-09-14 by
#   calling /root/.venvs/revv1/bin/python, which exists on one developer machine
#   and nowhere else. Prefer an explicit override, then the local venv if it is
#   there, then whatever python3 is on PATH.
PY="${REVV1_PY:-}"
if [ -z "$PY" ] && [ -x /root/.venvs/revv1/bin/python ]; then PY=/root/.venvs/revv1/bin/python; fi
if [ -z "$PY" ]; then PY=python3; fi
if ! "$PY" -c "import trimesh" 2>/dev/null; then
  echo "MESH CHECKS UNAVAILABLE: $PY has no trimesh." >&2
  echo "  pip install trimesh manifold3d numpy scipy networkx  (or set REVV1_PY)" >&2
  echo "  Refusing to pass silently — these checks are what catch a hollow part." >&2
  exit 1
fi
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
"$PY" - <<'PYEOF'
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

# ⛔ SAME TRAP, THE PIVOT PUCK (⚠ DM-6 rework, 2026-09-14). New geometry --
# a lead-in frustum + full disc, the same shape family as the historical
# hollow-tooth defect above -- so it gets the same "compare to a hand-formula,
# not just mesh health" treatment before being trusted inside the yoke.
echo "--- pivot puck fill (guards against a hollow disc/frustum)"
openscad -o stl/gen4-pivot-puck-test.stl -D 'part="pivot_puck_test"' "$SRC" >/dev/null 2>&1
python3 tools/check_stl.py stl/gen4-pivot-puck-test.stl
"$PY" - <<'PYEOF'
import trimesh, math, sys
puck = trimesh.load("stl/gen4-pivot-puck-test.stl", process=True).volume
# yoke_pivot_puck()'s own two cylinder() calls, computed independently:
#   frustum(d1=spline_od-2*yoke_ch=38, d2=spline_od=40, h=yoke_ch=1)
#   disc(d=spline_od=40, h=yoke_tip_h-yoke_ch=5)
frustum = (math.pi * 1 / 3) * (19.0**2 + 19.0*20.0 + 20.0**2)
disc = math.pi * 20.0**2 * 5
expect = frustum + disc
ratio = puck / expect
print(f"    puck {puck:8.1f} mm^3 vs expected {expect:8.1f}  ratio {ratio:.3f}")
if not 0.95 <= ratio <= 1.05:
    print("    FAIL: pivot puck fill is wrong — hollow puck, or the geometry changed"); sys.exit(1)
print("    OK")
PYEOF

# ⛔ WHOLE-YOKE SANITY (⚠ DM-6 rework). The puck check above is the tight,
# high-confidence one; this is a looser cross-check that the WHOLE assembled
# yoke -- plate, root, riser, the new Stage B/C transition, the puck, and the
# female spline, minus the M5/boot-slot/pivot-bore cuts -- adds up to
# something in the right ballpark, not just that any one piece in isolation
# is solid. Terms:
#   - plate_root_riserA: the bearing plate + flush root + Stage A riser, all
#     UNCHANGED by this rework. MEASURED by isolating that exact
#     sub-assembly (a temporary part calling chamfer_slab()+yoke_profile()/
#     yoke_band_2d(), the root square(), and Stage A's own hull() -- nothing
#     else -- see the task report for the reproduction), not a formula: this
#     is the same "verify by isolation" method spline-verification.md uses,
#     applied to a different sub-tree.
#   - stageB: a closed-form prism (yoke_arm_w x (yoke_standoff-1) rounded
#     rect, R2 corners, times the riser1-to-approach_y run) -- independent,
#     not measured.
#   - puck: the formula just proven above, reused rather than re-typed.
#   - spline: the female spline's own volume, reloaded from the spline-fill
#     check's own STL (base=3, the same call yoke() makes) -- independent of
#     this script's own yoke export.
#   - cuts: hole_pattern (3x M5 + countersinks) + boot_slot (Ø24 + channel)
#     + the new X-axis pivot bore. Not hand-split further here (the channel's
#     real overlap with the actual Y-truss silhouette is not a clean
#     closed form) -- taken as a single measured allowance instead, from the
#     union-before-cuts vs. the shipped (post-cuts) yoke.
#   The expectation OMITS the Stage-C hull's own transition wedge (rectangle
#   -> full disc) as a separate term -- there is no clean closed form for a
#   convex hull between mismatched cross-sections, so this expectation is a
#   deliberate UNDERESTIMATE by that wedge's real volume, same spirit as the
#   cowl check's own deliberate overestimate elsewhere in this file. A wide,
#   one-sided-by-design tolerance band (0.7-1.3) absorbs that gap without
#   being wide enough to pass a genuinely hollow yoke (order-of-magnitude
#   smaller, same signature as the historical spline-teeth defect).
echo "--- whole-yoke fill sanity (guards against a hollow riser/transition)"
"$PY" - <<'PYEOF'
import trimesh, math, sys
rect_area = 26.0*11.0 - (4-math.pi)*2.0**2      # yoke_arm_w x (yoke_standoff-1), R2 corners
stageB_len = abs(-24.41 - (-47.99))             # yoke_riser_y1 to yoke_approach_y
stageB = rect_area * stageB_len
puck = trimesh.load("stl/gen4-pivot-puck-test.stl", process=True).volume
spline = trimesh.load("stl/gen4-spline-test.stl", process=True).volume
plate_root_riserA = 25826.0   # measured by isolation -- see comment above (re-measured after
                               # yoke_standoff 8->12, ⚠ PIVOT BELOW THE BED fix)
cuts = 4778.0                 # measured (union-before-cuts minus shipped yoke) -- see comment
                               # above (unaffected by the yoke_standoff change: none of
                               # hole_pattern/boot_slot/the pivot bore depend on it)
expect = plate_root_riserA + stageB + puck + spline - cuts
actual = trimesh.load("stl/gen4-yoke.stl", process=True).volume
ratio = actual / expect
print(f"    yoke {actual:8.1f} mm^3 vs expected(underestimate) {expect:8.1f}  ratio {ratio:.3f}")
if not 0.7 <= ratio <= 1.3:
    print("    FAIL: yoke total fill is wrong — hollow riser/transition, or geometry changed"); sys.exit(1)
print("    OK")
PYEOF

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
"$PY" - <<'PYEOF'
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
"$PY" - <<'PYEOF'
import math, os, sys, trimesh
import numpy as np

# cowl and yoke are both built directly in the shared display-rear-face
# frame (both go through the file's own p() convention) -- no transform.
# The arm needs arm_seat()'s own seating transform -- ⚠ DM-6 REWORK
# (2026-09-14): the spline axis is now X (parallel to the bar), not Z, so
# this is REBUILT from the current gen4-display-mount.scad, not the old
# rotate([180,0,0])+Rz(theta) formula (see arm_seat()'s own block comment
# for the full derivation). Re-state every literal it depends on here, the
# same way this block always has -- if these drift from the .scad file this
# check silently stops meaning anything, same risk as before.
disp_w, disp_h = 159.99, 93.98
hole_lone = (80.00, 63.28)
pivot_x = hole_lone[0] - disp_w/2         # == p(hole_lone)[0]
yoke_t, yoke_standoff = 8.0, 12.0          # yoke_standoff raised 8->12: see
                                            # the ⚠ PIVOT BELOW THE BED guard
                                            # in gen4-display-mount.scad
pivot_y = -70.0
pivot_z = yoke_t + yoke_standoff
yoke_tip_h = 6.0
base_female, base_male, spline_h = 3.0, 3.0, 1.6
clamp_x0, clamp_w, arm_crank, arm_len = 1.0, 18.0, 32.5, 45.0
arm_pivot_y = clamp_x0 + clamp_w/2 - arm_crank
seat = base_male + base_female + spline_h
theta = 0.0   # the reference pose every check/render in this file uses

# R0 = rotate([0,-90,-90]) -- local (x,y,z) -> shared (y,z,x). Matches
# arm_seat()'s own (corrected 2026-09-14) rotate() calls exactly -- this IS
# that matrix, not a re-derivation, and the translate below is its own
# matching (also corrected, twice: the Y/Z sign AND the +yoke_tip_h the male
# target needs -- the female's own flat back sits at pivot_x+yoke_tip_h, not
# pivot_x -- see arm_seat()'s own block comment) formula.
R0 = np.array([[0, 1, 0], [0, 0, 1], [1, 0, 0]], dtype=float)
Rx = trimesh.transformations.rotation_matrix(math.radians(theta), [1, 0, 0])[:3, :3]
Rtot = Rx @ R0
T = np.array([
    pivot_x + yoke_tip_h + seat - arm_pivot_y,
    pivot_y - arm_len * math.cos(math.radians(theta)),
    pivot_z - arm_len * math.sin(math.radians(theta)),
])

M = np.eye(4)
M[:3, :3] = Rtot
M[:3, 3] = T
arm = trimesh.load("stl/gen4-arm.stl")
arm_t = arm.copy(); arm_t.apply_transform(M)
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
    rc = os.system(f"{sys.executable} tools/check_fit.py intersect "
                    f"stl/gen4-cowl.stl {path}")
    status = "CLEAR" if rc == 0 else "FAILED"
    print(f"    cowl vs {label}: {status}")
    if rc != 0:
        ok = False
if not ok:
    sys.exit(1)
PYEOF
rm -f stl/_check_arm_positioned.stl stl/_check_display_stub.stl /tmp/_display_stub.scad

# ⭐ THE ACCEPTANCE TEST — the one nobody ran before this rework, and the
# reason the defect survived every other check (mesh health, clearance, and
# the spline's own meshing proof all say nothing about which AXIS the joint
# turns on). Rotate the spline joint a few steps and PROVE the display's own
# elevation changes while its roll about the hinge does not — on real
# exported geometry (pitch_probe_fixed/pitch_probe_arm, gen4-display-
# mount.scad), not algebra. See those two parts' own block comment for what
# each of their two marker rods is and why.
#
# Method, entirely self-contained (no re-typed model literals to drift):
# each export is TWO rods of different diameter; split them apart
# (trimesh .split()), get each rod's direction from ALL its vertices (a
# PCA/eigenvector axis — far more robust than picking any single mesh
# vertex, which sits on the rod's own surface, not its centreline), and
# fix the sign using the OTHER rod in the same export as a reference (both
# rods emanate from a small, shared gap near one local origin, so a rod's
# own centroid is displaced from its companion's centroid mostly along its
# OWN axis — verified against a known-good hand transform before trusting
# it, task report has the numbers).
echo "--- PITCH ACCEPTANCE TEST: does the joint actually pitch the display? ---"
openscad -o stl/_pitch_fixed.stl -D 'part="pitch_probe_fixed"' "$SRC" >/dev/null 2>&1
THETAS=(0 7.5 15 22.5)
for th in "${THETAS[@]}"; do
  openscad -o "stl/_pitch_arm_${th}.stl" -D 'part="pitch_probe_arm"' -D "arm_seat_theta=${th}" "$SRC" >/dev/null 2>&1
done
"$PY" - <<PYEOF
import trimesh, numpy as np, sys

def split_by_radius(path):
    m = trimesh.load(path, process=True)
    parts = m.split(only_watertight=False)
    if len(parts) != 2:
        print(f"    FAIL: {path} split into {len(parts)} pieces, expected 2 "
              "(the two marker rods) — did rod_gap collapse, or did a rod "
              "vanish?")
        sys.exit(1)
    return sorted(parts, key=lambda p: -p.volume)  # [thick (Ø4), thin (Ø2)]

def pca_axis(mesh):
    v = mesh.vertices
    c = v.mean(axis=0)
    vc = v - c
    _, vecs = np.linalg.eigh(vc.T @ vc)
    return c, vecs[:, -1]

def rod_direction(mesh_a, mesh_b):
    ca, da = pca_axis(mesh_a)
    cb, _ = pca_axis(mesh_b)
    if np.dot(da, ca - cb) < 0:
        da = -da
    return da

fixed_thick, fixed_thin = split_by_radius("stl/_pitch_fixed.stl")
normal_dir = rod_direction(fixed_thick, fixed_thin)   # display's own face normal
up_dir     = rod_direction(fixed_thin, fixed_thick)   # display's own "up"

thetas = [${THETAS[@]/%/,}]
elevations, axis_dirs = [], []
for th in thetas:
    thick, thin = split_by_radius(f"stl/_pitch_arm_{th}.stl")
    reach_dir = rod_direction(thick, thin)   # arm-local Z ("up off the bore")
    axis_dir  = rod_direction(thin, thick)   # arm-local Y (bar/hinge axis)
    elev = np.degrees(np.arccos(np.clip(np.dot(reach_dir, normal_dir), -1, 1)))
    elevations.append(elev)
    axis_dirs.append(axis_dir)

print(f"    {'theta':>6} | {'elevation':>10} {'d(elev)':>9} | {'roll=axis.up':>13} {'axis drift(deg)':>16}")
ok = True
for i, th in enumerate(thetas):
    d_elev = "" if i == 0 else f"{elevations[i]-elevations[i-1]:+.3f}"
    roll = float(np.dot(axis_dirs[i], up_dir))
    drift = float(np.degrees(np.arccos(np.clip(np.dot(axis_dirs[i], axis_dirs[0]), -1, 1))))
    print(f"    {th:6.1f} | {elevations[i]:10.4f} {d_elev:>9} | {roll:13.7f} {drift:16.6f}")
    if i > 0:
        step = thetas[i] - thetas[i-1]
        # sign is a modelling convention (which way "theta" turns the joint),
        # not a claim this file makes elsewhere -- only the MAGNITUDE is the
        # contract with docs/bike-fitment.md's own "7.5 deg per click".
        if abs(abs(elevations[i]-elevations[i-1]) - step) > 0.05:
            print(f"    FAIL: step {thetas[i-1]}->{th} moved elevation by "
                  f"{elevations[i]-elevations[i-1]:+.3f} deg, expected +-{step} deg")
            ok = False
    if roll > 1e-6:
        print(f"    FAIL: roll (axis.up) at theta={th} is {roll} -- expected ~0 (no roll)")
        ok = False
    if drift > 1e-3:
        print(f"    FAIL: hinge axis drifted {drift} deg from its theta=0 direction "
              f"at theta={th} -- the pivot line itself is moving, not just rotating "
              "about it")
        ok = False

total_step = elevations[-1] - elevations[0]
print(f"    total pitch over {thetas[-1]-thetas[0]} deg of clicks: {total_step:+.3f} deg "
      f"(expected +-{thetas[-1]-thetas[0]} deg)")
if not ok:
    sys.exit(1)
print("    OK — elevation tracks theta 1:1, roll and the hinge axis itself stay fixed.")
PYEOF
rm -f stl/_pitch_fixed.stl stl/_pitch_arm_*.stl

echo "ALL-OK"
