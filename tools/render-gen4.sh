#!/usr/bin/env bash
# Export every STL and every PNG: the single parts, the print plate, and the
# assembly (iso / side / front).
#
# ⚠ PNG EXPORT EXITS 0 EVEN ON A BAD RENDER. OpenSCAD exits 0 on a failed
#   assert() for PNG export, and ALSO exits 0 when `part` matches no branch
#   in the selector's `if/else` chain (the chain's own `else assert(false,
#   ...)` prints an ERROR line but PNG export still writes -- a blank image,
#   no crash). So this script never trusts openscad's own exit code for a
#   PNG: every PNG call runs through openscad_png() below, which greps the
#   combined stdout+stderr for ERROR and fails the run on a match,
#   regardless of what openscad itself returned. See --selftest-bogus.
#
# ⚠ NEVER PASS --render for a PNG. ~21s vs ~0.3s per call, pixel-identical
#   output, and a failed assert() still prints its ERROR line during
#   CSG-tree evaluation either way (that happens before either backend
#   runs) -- so --render buys nothing here and costs minutes across a batch
#   of renders. STL export is different: it forces the exact boolean result
#   (needed to actually check fill/geometry), so those calls do not pass
#   --render either -- `-o out.stl` already selects the solid backend on
#   its own, no flag needed. --render only matters for tree/preview
#   formats, which this script never asks for.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=src/gen4-display-mount.scad
mkdir -p stl renders

# Every implemented single part -- matches the part="..." selector chain at
# the bottom of the .scad file. Extend this list in lockstep with that
# chain (build.sh's own PARTS list, plus assembly/plate which have no STL
# of their own -- assembly() is stand-ins-and-colour only, not a fabricated
# object, and plate() is exported separately below since it needs its own
# check_stl.py call).
PARTS=(gauge spline_test yoke arm cap cowl brow_test insert_coupon)

FAIL=0

# $1 = output png, $2.. = extra -D args. Always uses --viewall --autocenter
# (never a hand-tuned camera distance -- CLAUDE.md/this repo's own Task 6
# brief: manual framing produced badly cropped images before) and never
# --render (see header). Camera ROTATION (not distance) is the caller's to
# set, via an optional --camera=... passed through in "$@".
openscad_png() {
  local out="$1"; shift
  local log
  log="$(mktemp "${TMPDIR:-/tmp}/render-gen4.XXXXXX.log")"
  set +e
  openscad -o "$out" --viewall --autocenter --imgsize=1600,1200 "$@" "$SRC" \
    > "$log" 2>&1
  local rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    echo "FAIL ($out): openscad exited $rc"; cat "$log"; FAIL=1
  elif grep -qiE 'ERROR' "$log"; then
    echo "FAIL ($out): openscad printed an ERROR -- part typo or a fired"
    echo "  assert(). PNG export exits 0 regardless, so this grep is the"
    echo "  only thing that catches it:"
    cat "$log"
    FAIL=1
  else
    echo "OK   $out"
  fi
  rm -f "$log"
}

echo "=== build.sh: export + verify every single-part STL ==="
./tools/build.sh

echo
echo "=== single-part PNGs (default iso camera) ==="
for part in "${PARTS[@]}"; do
  slug="${part//_/-}"
  openscad_png "renders/gen4-${slug}.png" -D "part=\"$part\""
done

echo
echo "=== plate: STL + PNG ==="
openscad -o stl/gen4-plate.stl -D 'part="plate"' "$SRC"
python3 tools/check_stl.py stl/gen4-plate.stl
# Top-down (looking along the plate's own Z, i.e. down at the bed) reads as
# a print-plate/slicer preview -- the layout the acceptance criteria care
# about -- rather than a foreshortened iso angle.
openscad_png renders/gen4-plate.png -D 'part="plate"' --camera=0,0,0,0,0,0,300

echo
echo "=== assembly: iso / side / front (PNG only -- not a fabricated part, no STL) ==="
# Camera rotations below are GROUND-TRUTH derived, not guessed: rendered a
# throwaway scene of three differently-sized marker rods along shared X/Y/Z
# and read off, for each candidate rotation, which rod foreshortens to a dot
# (that is the axis you are looking ALONG) and which two are the image's
# horizontal/vertical.
#
# ⚠ RE-DERIVED 2026-09-14 for the ⚠ DM-6 rework (arm_seat()'s own base
# rotation changed what each shared axis physically means -- see that
# module's own block comment in gen4-display-mount.scad). Confirmed axis
# meanings now: shared X = the bike's lateral axis (the bar's own length,
# unchanged by the rework), shared Y = the display's own vertical (real "up"
# is +Y, since the display's top edge sits at model Y=+disp_h/2 and the
# display is fixed in this frame), shared Z = front-to-back depth. This is
# ALSO, conveniently, OpenSCAD's own default camera convention exactly (no
# rotation needed at all for a Z-depth/Y-up/X-right view) -- confirmed with
# the same marker-rod scene (three different-length rods along X/Y/Z from
# the origin): at rotation (0,0,0) the Z rod foreshortens to a dot and X/Y
# render horizontal/vertical respectively, with no sign flip needed.
openscad_png renders/gen4-assembly-iso.png -D 'part="assembly"' \
  --camera=0,0,0,-25,35,0,300
# side: looking along shared X (lateral) with Z (depth) horizontal and Y
# (vertical) vertical in the image -- the bike's profile. Marker-rod
# confirmed: at ry=90 the X rod foreshortens to a dot, Y renders vertical,
# Z renders horizontal.
openscad_png renders/gen4-assembly-side.png -D 'part="assembly"' \
  --camera=0,0,0,0,90,0,300
# front: looking along shared Z (depth) with X (lateral) horizontal and Y
# (vertical) vertical -- as an observer standing in front of the parked
# bike would see it. No rotation needed (OpenSCAD's own default already
# looks along Z with Y up, X right) -- marker-rod confirmed above.
openscad_png renders/gen4-assembly-front.png -D 'part="assembly"' \
  --camera=0,0,0,0,0,0,300
# rider: looking at the GLASS, from in front of it and a little above --
# the view from the saddle. Same axis along which "front" looks, turned
# through 180 degrees (ry=180) so the camera is on the glass side rather
# than the cowl side, then tilted 20 degrees down. Confirmed by rendering
# it: the screen's own grey face fills the frame, the visor reads across
# the top, and both clamps are visible flanking the centre bracket.
openscad_png renders/gen4-assembly-rider.png -D 'part="assembly"' \
  --camera=0,0,0,20,180,0,300
# three-quarter from the glass side: the one angle that shows the visor's
# own plan curve AND its projection past the glass at the same time.
openscad_png renders/gen4-assembly-threequarter.png -D 'part="assembly"' \
  --camera=0,0,0,-25,145,0,300

echo
echo "=== exploded view ==="
# Side-on enough that the Z explode (display -> yoke -> cowl) reads as
# separation rather than foreshortening, and turned far enough that neither
# clamp hides behind the cowl. Checked by rendering the alternatives, not
# assumed.
openscad_png renders/gen4-exploded.png -D 'part="exploded"' \
  --camera=0,0,0,-25,60,0,300

echo
echo "=== visor: plan + profile (the two views its shape is judged in) ==="
# Plan (looking straight down): the superelliptical leading edge, which is
# the silhouette seen from in front of the bike. Renders the whole cowl,
# not brow_test, so the visor is shown against the box it grows from.
openscad_png renders/gen4-visor-plan.png -D 'part="cowl"' \
  --camera=0,0,0,90,0,0,300
# Profile (looking along the bar): how far it actually reaches past the
# glass, and the flat underside the shading derivation rests on. brow_test
# is the riser+visor strip alone, so nothing else is in the way.
openscad_png renders/gen4-visor-profile.png -D 'part="brow_test"' \
  --camera=0,0,0,0,90,0,200

echo
echo "=== verify: assembly clearance on POSITIONED exports (check_fit.py, a"
echo "    different boolean engine from OpenSCAD/CGAL) ==="
# tools/build.sh already proves cowl vs {yoke, arm(positioned), display}.
# This adds the pairs Task 6's assembly() introduces that build.sh does not
# already cover: the display and the yoke against the POSITIONED arm/cap,
# and the cowl/yoke against the positioned cap. Skips yoke-vs-arm on
# purpose -- their only real contact is the spline teeth, and
# docs/spline-verification.md §3/§5 is explicit that a whole-ring boolean
# on this geometry (CGAL OR manifold3d) is not trustworthy; that mate is
# proven there instead (rod-probe method), not here.
# ⚠ Same two CI hazards build.sh was fixed for on 2026-09-14, which survived
# here until 2026-09-15: a HARDCODED interpreter that exists on exactly one
# developer machine, and a check_fit.py path of `../tools/...` that points
# OUTSIDE the repository -- so a clean public clone could not run this
# script at all. Resolve the interpreter the same way build.sh does, and
# use the VENDORED tools/check_fit.py.
VENV="${REVV1_PY:-}"
if [ -z "$VENV" ] && [ -x /root/.venvs/revv1/bin/python ]; then VENV=/root/.venvs/revv1/bin/python; fi
if [ -z "$VENV" ]; then VENV=python3; fi
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/render-gen4-fit.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

# ⚠ ABSOLUTE path, deliberately. These wrapper files live in $WORKDIR, not
# next to $SRC -- OpenSCAD resolves `use <...>` relative to the FILE
# containing it (and does not fall back to the invoking cwd for a path that
# isn't found there), so the plain relative $SRC that works everywhere else
# in this script silently fails here ("Can't open library", `use` treated
# as a no-op, `arm_seat`/`display_stub` come back "unknown module", and the
# .stl exports empty -- confirmed the hard way, once).
SRC_ABS="$(pwd)/$SRC"
# ⭐ TWO-CLAMP REWORK (2026-09-15): arm_seat() is now clamp_seat(side) --
# side=1 right, side=-1 left, mirror([1,0,0]) of the same right-side seating
# (see clamp_seat()'s own block comment in gen4-display-mount.scad for why
# that mirror needs no separate re-derivation). Both sides positioned here,
# not just the right, so this script's own clearance sweep covers the same
# ground tools/build.sh's does.
cat > "$WORKDIR/pos_arm_r.scad" <<EOF
use <$SRC_ABS>
clamp_seat(1) arm();
EOF
cat > "$WORKDIR/pos_cap_r.scad" <<EOF
use <$SRC_ABS>
clamp_seat(1) cap();
EOF
cat > "$WORKDIR/pos_arm_l.scad" <<EOF
use <$SRC_ABS>
clamp_seat(-1) arm();
EOF
cat > "$WORKDIR/pos_cap_l.scad" <<EOF
use <$SRC_ABS>
clamp_seat(-1) cap();
EOF
cat > "$WORKDIR/display.scad" <<EOF
use <$SRC_ABS>
display_stub();
EOF
openscad -o "$WORKDIR/pos_arm_r.stl" "$WORKDIR/pos_arm_r.scad"
openscad -o "$WORKDIR/pos_cap_r.stl" "$WORKDIR/pos_cap_r.scad"
openscad -o "$WORKDIR/pos_arm_l.stl" "$WORKDIR/pos_arm_l.scad"
openscad -o "$WORKDIR/pos_cap_l.stl" "$WORKDIR/pos_cap_l.scad"
openscad -o "$WORKDIR/display.stl" "$WORKDIR/display.scad"

check_clear() {
  local label="$1" a="$2" b="$3"
  if $VENV tools/check_fit.py intersect "$a" "$b" > "$WORKDIR/fit.log" 2>&1; then
    echo "OK   $label: CLEAR"
  else
    echo "FAIL $label:"; cat "$WORKDIR/fit.log"; FAIL=1
  fi
}
check_clear "display vs yoke"               "$WORKDIR/display.stl" stl/gen4-yoke.stl
check_clear "display vs positioned arm (r)" "$WORKDIR/display.stl" "$WORKDIR/pos_arm_r.stl"
check_clear "display vs positioned cap (r)" "$WORKDIR/display.stl" "$WORKDIR/pos_cap_r.stl"
check_clear "display vs positioned arm (l)" "$WORKDIR/display.stl" "$WORKDIR/pos_arm_l.stl"
check_clear "display vs positioned cap (l)" "$WORKDIR/display.stl" "$WORKDIR/pos_cap_l.stl"
check_clear "yoke vs positioned cap (r)"    stl/gen4-yoke.stl       "$WORKDIR/pos_cap_r.stl"
check_clear "yoke vs positioned cap (l)"    stl/gen4-yoke.stl       "$WORKDIR/pos_cap_l.stl"
check_clear "cowl vs positioned cap (r)"    stl/gen4-cowl.stl       "$WORKDIR/pos_cap_r.stl"
check_clear "cowl vs positioned cap (l)"    stl/gen4-cowl.stl       "$WORKDIR/pos_cap_l.stl"
check_clear "positioned cap (r) vs (l)"     "$WORKDIR/pos_cap_r.stl" "$WORKDIR/pos_cap_l.stl"

echo
if [ "$FAIL" -ne 0 ]; then
  echo "RENDER-GEN4: FAILED -- see FAIL lines above"
  exit 1
fi
echo "RENDER-GEN4: ALL-OK"
