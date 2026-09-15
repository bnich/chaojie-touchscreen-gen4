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
# ⚠ Check EVERY dependency the run needs, up front, not just trimesh. rtree
#   backs trimesh's ray engine (tools/check_shade.py); without it the run
#   dies with a ModuleNotFoundError traceback two thirds of the way in,
#   after several minutes of exports.
if ! "$PY" -c "import trimesh, manifold3d, rtree" 2>/dev/null; then
  echo "MESH CHECKS UNAVAILABLE: $PY is missing trimesh, manifold3d or rtree." >&2
  echo "  pip install trimesh manifold3d numpy scipy networkx rtree  (or set REVV1_PY)" >&2
  echo "  Refusing to pass silently — these checks are what catch a hollow part," >&2
  echo "  a knife-edge section, an interference, and a visor that shades nothing." >&2
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

# ⛔ SAME TRAP, ONE WHOLE LEG (⭐ TWO-CLAMP REWORK, 2026-09-15). yoke_leg()
# reuses the already-proven-solid puck (above) and female spline (the
# spline-fill check below reloads spline_test, base=3, the same call
# yoke_leg() makes) but adds NEW material of its own -- the root pad and the
# Stage A/B/C taper_wp()/hull() chain -- so a hollow leg would still slip
# past both of those. No clean closed form for the taper chain (same reason
# the old whole-yoke check never had one either), so this is a LOWER BOUND,
# not a two-sided band: a solid leg's volume must comfortably exceed
# puck+spline alone (it is puck+spline PLUS the root/riser material around
# them); a hollow or disconnected leg would measure close to that floor, the
# same signature as the historical 44mm^3-of-936mm^3 hollow-tooth defect.
echo "--- yoke leg fill (guards against a hollow root/riser)"
openscad -o stl/gen4-yoke-leg-test.stl -D 'part="yoke_leg_test"' "$SRC" >/dev/null 2>&1
python3 tools/check_stl.py stl/gen4-yoke-leg-test.stl
openscad -o stl/gen4-yoke-plate-test.stl -D 'part="yoke_plate_test"' "$SRC" >/dev/null 2>&1
python3 tools/check_stl.py stl/gen4-yoke-plate-test.stl
"$PY" - <<'PYEOF'
import trimesh, sys
puck = trimesh.load("stl/gen4-pivot-puck-test.stl", process=True).volume
spline = trimesh.load("stl/gen4-spline-test.stl", process=True).volume
leg = trimesh.load("stl/gen4-yoke-leg-test.stl", process=True).volume
floor = puck + spline
ratio = leg / floor
print(f"    leg {leg:8.1f} mm^3 vs puck+spline floor {floor:8.1f}  ratio {ratio:.3f}")
if ratio <= 1.05:
    print("    FAIL: leg is barely bigger than its own puck+spline -- the root/riser "
          "material is missing or hollow"); sys.exit(1)
print("    OK")
PYEOF

# ⭐ LOAD-PATH SECTION SCAN, added 2026-09-15 -- the check that should have
# caught the arm's waist before the owner found it by eye: "Ensure that
# there is enough material holding the clamp to the handlebars to the
# toothed piece. It looks very thin." They were right -- arm()'s own
# "vertical riser" (Stage 1 of its rising rib) had collapsed to 4.00 mm^2 at
# its worst station, a hull() between two waypoints at the SAME y collapsing
# to taper_wp()'s own 0.2mm marker thickness for the entire z=19..42 run
# (arm()'s own block comment above Stage 1 has the full story; fixed by
# widening that riser to a real Y-span, clamp_riser_y0..clamp_riser_y1,
# instead of a single Y).
#   EVERY CHECK ABOVE THIS LINE WOULD HAVE STAYED GREEN ON THE BROKEN PART:
# watertight, 0 boundary, 0 non-manifold, 1 component, a plausible total
# volume, clearance clean, a render pixel-normal. None of them measure a
# cross-section -- they watch the outer skin or the total fill, and a 0.2mm
# knife-edge is neither a hole in the skin nor enough missing volume to
# move a whole-part fill ratio. A human's own 5mm-spaced-by-hand table
# caught a mere 78.7 mm^2 at its z=25 station -- the coarse spacing
# partially averaged in the spline puck's own tangent growth and MISSED the
# true, 20x worse minimum one station over. Volume catches a hollow part;
# nothing upstream of this was watching minimum section. This is what does.
#   METHOD: intersect the part with a 1mm-thick slab at each station along
# the load path's own long axis, and divide the slab's volume by 1mm --
# volume/thickness IS the average cross-sectional area over that band, and
# needs no shapely (unlike an exact planar section, which trimesh can only
# turn into a polygon -- and its .area -- via shapely, not installed here):
# a slab is just another solid, and manifold3d (already this file's own
# second-opinion boolean engine -- see check_fit.py) booleans it against the
# part directly, the same primitive the clearance checks below use.
echo "--- load-path section scan (guards against a waist/knife-edge in the load path) ---"
"$PY" - <<'PYEOF'
import trimesh, sys

def slab_area(mesh, axis, s0, s1, pad=300.0):
    lo, hi = mesh.bounds
    center = [(lo[i] + hi[i]) / 2 for i in range(3)]
    extents = [pad, pad, pad]
    extents[axis] = s1 - s0
    box = trimesh.creation.box(extents=extents)
    t = list(center); t[axis] = (s0 + s1) / 2
    box.apply_translation(t)
    hit = trimesh.boolean.intersection([mesh, box], engine="manifold")
    if hit is None or len(hit.faces) == 0:
        return 0.0
    return float(hit.volume) / (s1 - s0)

def scan(label, path, axis, s_lo, s_hi, min_mm2, step=1.0):
    mesh = trimesh.load(path, process=True)
    worst_area, worst_s = None, None
    s = s_lo
    while s < s_hi:
        a = slab_area(mesh, axis, s, s + step)
        if worst_area is None or a < worst_area:
            worst_area, worst_s = a, s
        s += step
    print(f"    {label}")
    print(f"      minimum {worst_area:8.2f} mm^2 at station {worst_s:.1f}  "
          f"(floor {min_mm2} mm^2)")
    if worst_area < min_mm2:
        print(f"      FAIL: narrows to {worst_area:.2f} mm^2 -- below the {min_mm2} "
              f"mm^2 floor. Every mesh/volume check above can stay green while this "
              f"fails; that is the point of this check.")
        return False
    return True

ok = True

# Clamp -> spline path: arm()'s own rising rib, tip puck and male spline.
# Z=0 (the clamp half's own split face) .. 45 (arm_len, the spline's own
# CENTRE) -- stopping at the centre, not the part's full Z=65 bbox top,
# because past it the section naturally tapers toward the disc's outer rim
# (every tooth engages at once -- docs/design-notes.md's own "why a toothed
# face spline" section), which is not a structural weak point and would
# otherwise read as a false failure the same way the fillet-vis corner taper
# would elsewhere in this file. 200 mm^2: the task's own floor, "comparable
# to its neighbours" (250-500 mm^2 through the rest of this same part).
ok &= scan("clamp->spline path (arm.stl, Z 0..45)",
           "stl/gen4-arm.stl", 2, 0.0, 45.0, 200.0)

# Yoke leg path: yoke_leg()'s own root pad, riser and pivot puck/female
# spline. Y runs from just inside the root (near the bearing plate) out to
# the pivot's own centre -- restated here rather than read back from the
# .scad file, same risk already flagged wherever else this script restates a
# literal (the cowl-clearance block below): if these drift from
# gen4-display-mount.scad this check silently stops meaning anything.
#   ROOT_NEAR_Y = p(hole_lone)[1] = disp_h/2 - hole_lone[1] = 93.98/2-63.28
#   PIVOT_Y = pivot_y
# Stopping at the pivot's own centre, not the puck's outer rim (pivot_y -
# spline_od/2), for the identical reason the arm scan above stops at its
# own spline centre rather than its part's full bbox.
#   ⚠ THE NEAR BOUND IS INSET fillet_vis (2mm) FROM ROOT_NEAR_Y, NOT AT IT --
# a real, confirmed effect, not guesswork: yoke_leg_test() renders yoke_leg()
# ALONE, without yoke_profile()'s own widened hull, so its root pad has a
# genuine free edge exactly at ROOT_NEAR_Y that does NOT exist in the
# assembled yoke() (there the plate's own hull anchor continues the material
# past it -- see yoke_profile()'s own comment). That free edge is rounded by
# the SAME fillet_vis corner radius as every other silhouette in this file,
# and the last ~2mm before it reads as low as 76.55 mm^2 in isolation purely
# from that corner rounding, confirmed by first running this scan against
# the unmodified part: it failed at station -17.0 with exactly that number,
# a false positive from testing a sub-assembly's own cut edge, not a
# structural defect. Inset by fillet_vis so the scan covers the leg's own
# real load-bearing material without grading it on an edge only the isolated
# test part has.
#   ⚠ THIS FLOOR IS LOWER THAN THE ARM'S, DELIBERATELY -- NOT A DOUBLE
# STANDARD, A DIFFERENT, ALREADY-REASONED DESIGN. This scan's own fine pass
# found the yoke leg's true minimum at ~119 mm^2 (not the ~144 mm^2
# docs/design-notes.md quoted before this task, a 5mm-by-hand estimate that
# missed the same kind of dip the arm's own coarse table did, just a much
# smaller one) -- narrowed on purpose, for clearance from the lone M5's own
# socket sweep (see leg_w's own comment), and shared by TWO legs in
# parallel, not carried by one the way the arm's rib is. 100 mm^2 leaves
# real margin under the measured ~119 mm^2 floor while still catching any
# FURTHER, unintended thinning -- proven to fire on a real thinning this
# task tried (leg_w=6, which clears every existing assertion -- the fillet
# guard only requires leg_w > 2*fillet_vis+1 = 5 -- yet measures ~46-65 mm^2
# here, invisible to anything upstream of this check).
ok &= scan("yoke leg path (yoke-leg-test.stl, Y -70..-18.29)",
           "stl/gen4-yoke-leg-test.stl", 1, -70.0, -18.29, 100.0)

if not ok:
    sys.exit(1)
print("    OK")
PYEOF

# ⛔ WHOLE-YOKE SANITY, ⭐ REBUILT FOR THE TWO-CLAMP REWORK (2026-09-15). The
# leg check above is the tight, high-confidence one for ONE leg; this is a
# looser cross-check that the WHOLE assembled yoke -- the (now wider) plate
# plus BOTH legs, minus the M5/boot-slot/pivot-bore cuts (now 2x, one per
# leg) -- adds up to something in the right ballpark. Both terms below are
# MEASURED BY ISOLATION (yoke_plate_test, yoke_leg_test -- see their own
# block comments in gen4-display-mount.scad), not hand-derived formulas, the
# same "verify by isolation" method spline-verification.md uses: this
# geometry (a widened hull, a mirrored leg) has no clean closed form the way
# the old single-arm design's rectangular Stage B prism did.
#   expect = plate + 2*leg is a DELIBERATE OVERESTIMATE (same one-sided-band
# spirit as the cowl check below): union() only counts the small overlap
# between each leg's root pad and the plate ONCE, so the real solid is
# slightly less than plate+2*leg even before the M5/boot/bore cuts remove
# more on top of that -- actual/expected should sit somewhat under 1.0, not
# at it. A wide, one-sided tolerance band (0.6-1.05) absorbs both effects
# without being wide enough to pass a genuinely hollow yoke (order-of-
# magnitude smaller, same signature as the historical spline-teeth defect).
echo "--- whole-yoke fill sanity (guards against a hollow riser/transition)"
"$PY" - <<'PYEOF'
import trimesh, sys
plate = trimesh.load("stl/gen4-yoke-plate-test.stl", process=True).volume
leg = trimesh.load("stl/gen4-yoke-leg-test.stl", process=True).volume
expect = plate + 2*leg
actual = trimesh.load("stl/gen4-yoke.stl", process=True).volume
ratio = actual / expect
print(f"    yoke {actual:8.1f} mm^3 vs expected(overestimate) {expect:8.1f}  ratio {ratio:.3f}")
if not 0.6 <= ratio <= 1.05:
    print("    FAIL: yoke total fill is wrong — hollow riser/transition, disconnected leg, "
          "or geometry changed enough to need a new expectation"); sys.exit(1)
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
# shared trim), (b) the two M3 clearance holes, or (c) the visor's own
# sections being lenses inside the bounding rectangles this bounds them by
# (worth roughly 1.4x on the lofted run). All three only ever REMOVE
# material the naive formula still counts, so actual/expected should sit
# below 1.0, comfortably above a real hollow-shell ratio (0.05-0.3, per the
# spline case above).
#   THE BAND IS 0.66-1.0, and the floor is not arbitrary. The shipped part
# measures 0.733. Deleting the visor outright takes it to ~0.51 and losing
# half of it to ~0.62 — both fail. The old 0.6 floor passed the half-lost
# case, which is exactly the class of defect this file keeps being bitten
# by. This geometry carries no tolerance (it is a deterministic export), so
# 11% of headroom is enough; if a $fn change ever moves it, re-derive the
# floor from the new measured ratio rather than widening the band.
echo "--- cowl fill (guards against a hollow shell)"
"$PY" - <<'PYEOF'
import trimesh, math, sys

disp_w, disp_h, disp_corner_r = 159.99, 93.98, 9.0
reveal, cowl_wall = 0.5, 2.4
fillet_out, fillet_vis = 3.0, 2.0
boot_proud = 22.3
cowl_depth = boot_proud + 8
disp_d = 26.0
brow, brow_clear, brow_root = 33.0, 3.0, 10.0
brow_plan_n, brow_stations = 3.0, 14
brow_d_c, brow_d_s = 7.0, 3.0
brow_edge_x = disp_w/2 + reveal - brow_d_s/2
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

# ⭐ THE VISOR IS SOLID AND SUPERELLIPTICAL IN PLAN (2026-09-15), not the
# hollow full-width prism this term used to model. Bound it the only way
# that is provably an OVER-estimate without re-deriving the model: every
# cross-section of a hull() between two convex sections lies inside the
# linear interpolation of their BOUNDING RECTANGLES, so integrating that
# product along the run can only run high. The real sections are lenses
# (thick on the centreline, thin at the edges), so this bound runs high by
# roughly 1.4x on the lofted part -- see the band note below.
def brow_p(i):     return brow * math.sin(math.radians(90.0*i/brow_stations))
def brow_halfw(p): return brow_edge_x * max(0.0, 1 - (p/brow)**brow_plan_n)**(1/brow_plan_n)
def brow_rect(p):
    w = brow_halfw(p)
    return (brow_d_s, brow_d_c) if w < brow_d_s/2 else (2*w + brow_d_s, brow_d_c)

def ruled(rect0, rect1, length):
    """Volume of the bounding-rectangle interpolation between two sections."""
    (W0, H0), (W1, H1) = rect0, rect1
    dW, dH = W1 - W0, H1 - H0
    return length * (W0*H0 + (W0*dH + H0*dW)/2 + dW*dH/3)

cw = disp_w + 2*reveal
root_rect = (cw, brow_root)
# Root slab -> the station at the glass plane. This stretch is over the
# display's own box; it wraps into the cowl's corner and shades nothing.
cant = ruled(root_rect, brow_rect(0.0), cant_lap + disp_d)
# Everything past the glass plane: station to station, the part that shades.
for i in range(brow_stations):
    p0, p1 = brow_p(i), brow_p(i+1)
    cant += ruled(brow_rect(p0), brow_rect(p1), p1 - p0)

hook = hook_w * (hook_engage+reveal) * cowl_wall
bosses = 2 * math.pi*(m3_boss_d/2)**2 * m3_boss_len

expect = box + riser + cant + hook + bosses
actual = trimesh.load("stl/gen4-cowl.stl", process=True).volume
ratio = actual/expect
print(f"    actual {actual:8.1f} mm^3 vs expected(overestimate) {expect:8.1f}  ratio {ratio:.3f}")
if not 0.66 <= ratio <= 1.0:
    print("    FAIL: cowl fill is wrong — hollow shell, or the geometry changed enough to need a new expectation"); sys.exit(1)
print("    OK")
PYEOF

# ⛔ A RENDER CANNOT SHOW INTERFERENCE. Prove the cowl clears the yoke, BOTH
# seated clamps, and the display itself with a different boolean engine
# (manifold3d, not CGAL) on the actual exported meshes, positioned into one
# shared frame. ⭐ TWO-CLAMP REWORK (2026-09-15): TWO positioned arms now,
# right and left, each with its OWN transform stated explicitly below --
# ⚠ A CLEARANCE CHECK CANNOT CATCH A BAD TRANSFORM, IT USES THE SAME ONE, so
# each positioned arm's bbox is ALSO checked against an INDEPENDENTLY
# hand-derived expectation per axis (simple axis-permutation arithmetic on
# arm.stl's own known local bbox, not a re-run of the transform below) --
# see the BBOX CHECK block.
echo "--- cowl clearance vs yoke / both clamps / display"
"$PY" - <<'PYEOF'
import math, os, sys, trimesh
import numpy as np

# cowl and yoke are both built directly in the shared display-rear-face
# frame (both go through the file's own p() convention) -- no transform.
# The two clamps need clamp_seat()'s own seating transform. Re-state every
# literal it depends on here, the same way this block always has -- if these
# drift from the .scad file this check silently stops meaning anything, same
# risk as before.
bracket_w, bracket_half = 45.0, 22.5
yoke_t, yoke_standoff = 8.0, 12.0          # yoke_standoff raised 8->12: see
                                            # the ⚠ PIVOT BELOW THE BED guard
                                            # in gen4-display-mount.scad
pivot_y = -70.0
pivot_z = yoke_t + yoke_standoff
yoke_tip_h = 6.0
base_female, base_male, spline_h = 3.0, 3.0, 1.6
clamp_x0, clamp_w, arm_len = 0.0, 18.0, 45.0
arm_pivot_y = clamp_x0 + clamp_w/2         # ⭐ NO CRANK any more
seat = base_male + base_female + spline_h
theta = 0.0   # the reference pose every check/render in this file uses

# pivot_x_r: DERIVED, same closed form as gen4-display-mount.scad's own
# pivot_x_r (near arm_pivot_y) -- "what X puts the seated clamp's inboard
# face exactly on the real bracket's own face (bracket_half)".
pivot_x_r = bracket_half - yoke_tip_h - seat + arm_pivot_y

# R0 = rotate([0,-90,-90]) -- local (x,y,z) -> shared (y,z,x). Matches
# clamp_seat()'s own (corrected 2026-09-14, unchanged by the two-clamp
# rework) rotate() calls exactly -- this IS that matrix, not a
# re-derivation, and the translate below is its own matching formula.
R0 = np.array([[0, 1, 0], [0, 0, 1], [1, 0, 0]], dtype=float)
Rx = trimesh.transformations.rotation_matrix(math.radians(theta), [1, 0, 0])[:3, :3]
Rtot = Rx @ R0

def right_transform():
    T = np.array([
        pivot_x_r + yoke_tip_h + seat - arm_pivot_y,
        pivot_y - arm_len * math.cos(math.radians(theta)),
        pivot_z - arm_len * math.sin(math.radians(theta)),
    ])
    M = np.eye(4)
    M[:3, :3] = Rtot
    M[:3, 3] = T
    return M

MIRROR = np.diag([-1.0, 1.0, 1.0, 1.0])   # mirror([1,0,0]) -- left = mirror(right),
                                           # see clamp_seat()'s own commutation
                                           # argument for why this needs no
                                           # separate theta sign flip.
M_right = right_transform()
M_left = MIRROR @ M_right

arm = trimesh.load("stl/gen4-arm.stl")
arm_r = arm.copy(); arm_r.apply_transform(M_right)
arm_r.export("stl/_check_arm_r_positioned.stl")
arm_l = arm.copy(); arm_l.apply_transform(M_left)
arm_l.export("stl/_check_arm_l_positioned.stl")

# ⛔ BBOX CHECK -- independent of the transform above by construction: this
# reasons from arm.stl's own KNOWN local bbox (min/max, from
# tools/check_stl.py, re-measured 2026-09-15) through the SAME axis
# permutation (local x,y,z -> shared y,z,x, theta=0 so Rx=identity) worked
# out by hand, not by re-running M_right/M_left. A wrong M_right/M_left could
# still pass check_fit's intersect test (both meshes just floating in the
# wrong place, still not overlapping anything) -- this catches that class of
# error, which a clearance check alone cannot.
arm_local_lo = np.array([-35.00, -0.10,  0.00])
arm_local_hi = np.array([ 35.00, 18.10, 65.00])
# shared_X = local_y + Tx ; shared_Y = local_z + Ty ; shared_Z = local_x + Tz
Tx = pivot_x_r + yoke_tip_h + seat - arm_pivot_y
Ty = pivot_y - arm_len
Tz = pivot_z
expect_r_lo = np.array([arm_local_lo[1] + Tx, arm_local_lo[2] + Ty, arm_local_lo[0] + Tz])
expect_r_hi = np.array([arm_local_hi[1] + Tx, arm_local_hi[2] + Ty, arm_local_hi[0] + Tz])

# expect_r_lo < expect_r_hi component-wise already (arm_local_lo < arm_local_hi
# on every axis, and the permutation above only reorders which local axis
# feeds which shared one -- it never reverses a sign), so the right side
# needs no reordering. Mirroring for the left side negates X only, which
# DOES swap lo/hi on that one axis (lo := -hi, hi := -lo); Y and Z are
# untouched by a mirror about the X=0 plane.
expect_l_lo = np.array([-expect_r_hi[0], expect_r_lo[1], expect_r_lo[2]])
expect_l_hi = np.array([-expect_r_lo[0], expect_r_hi[1], expect_r_hi[2]])

ok = True
for label, mesh, exp_lo, exp_hi in [
        ("right", arm_r, expect_r_lo, expect_r_hi),
        ("left",  arm_l, expect_l_lo, expect_l_hi)]:
    lo, hi = mesh.bounds
    diff_lo = np.abs(lo - exp_lo)
    diff_hi = np.abs(hi - exp_hi)
    print(f"    {label} arm bbox   actual lo={lo.round(2)} hi={hi.round(2)}")
    print(f"    {label} arm bbox expected lo={exp_lo.round(2)} hi={exp_hi.round(2)}")
    # 0.5mm tolerance: the ear boss/chamfer detail this plain-permutation
    # arithmetic doesn't model, same ~0.1-0.2mm gap the original single-arm
    # design's own equivalent check always carried.
    if np.any(diff_lo > 0.5) or np.any(diff_hi > 0.5):
        print(f"    FAIL: {label} arm positioned bbox does not match the hand-derived "
              f"expectation (diff lo={diff_lo.round(3)} hi={diff_hi.round(3)})")
        ok = False

disp_w, disp_h = 159.99, 93.98
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

for label, path in [("yoke", "stl/gen4-yoke.stl"),
                     ("right clamp (positioned)", "stl/_check_arm_r_positioned.stl"),
                     ("left clamp (positioned)", "stl/_check_arm_l_positioned.stl"),
                     ("display stand-in", "stl/_check_display_stub.stl")]:
    rc = os.system(f"{sys.executable} tools/check_fit.py intersect "
                    f"stl/gen4-cowl.stl {path}")
    status = "CLEAR" if rc == 0 else "FAILED"
    print(f"    cowl vs {label}: {status}")
    if rc != 0:
        ok = False

# Also the two clamps against each other -- opposite sides of a 45mm
# bracket, so trivially far apart, but stated and checked rather than
# assumed.
rc = os.system(f"{sys.executable} tools/check_fit.py intersect "
                f"stl/_check_arm_r_positioned.stl stl/_check_arm_l_positioned.stl")
status = "CLEAR" if rc == 0 else "FAILED"
print(f"    right clamp vs left clamp: {status}")
if rc != 0:
    ok = False

if not ok:
    sys.exit(1)
PYEOF
rm -f stl/_check_arm_r_positioned.stl stl/_check_arm_l_positioned.stl stl/_check_display_stub.stl /tmp/_display_stub.scad

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

# ⭐ Does the visor actually shade the screen? See tools/check_shade.py for
# why this exists: "projects 19 mm" passed while the brow projected -7 mm.
# The floor is 20%, set just under the 24.8% the shipped superelliptical
# visor measures — tight enough that flattening the plan curve back toward
# a straight taper trips it (that shape scores 14.8%), and the old brow
# that prompted all this scores 0.0% and fails by 20 points.
echo "--- SUN VISOR SHADE TEST: does the brow actually block anything? ---"
"$PY" tools/check_shade.py stl/gen4-cowl.stl --min-45 20 || exit 1

echo "ALL-OK"
