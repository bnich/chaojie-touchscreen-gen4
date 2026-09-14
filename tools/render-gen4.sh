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
PARTS=(gauge spline_test yoke arm cap cowl brow_test)

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
# and read off, for each candidate rotation, which rod foreshortens to a
# dot (that is the axis you are looking ALONG) and which two are the
# image's horizontal/vertical (2026-09-14 fix -- see the task report for
# the full derivation and why the PREVIOUS choices here were wrong: they
# were made before arm_seat() itself was corrected, so "looking along Z"
# read as a plausible cowl-face-on shot without anyone noticing Z is ALSO
# the bike's own vertical axis post-fix).
#
# Confirmed axis meanings after arm_seat()'s fix: shared X = the bike's
# lateral axis (the bar's own length, post-fix), shared Y = front-to-back,
# shared Z = the spline's own axis, arm-local Z ("above the bar
# centreline") mapped to shared -Z (marker-rod-verified) -- so shared -Z is
# "real up" and +Z is "real down". A first pass at these three cameras
# used a positive rotx (90/78) for each and got the AXIS right but the
# SIGN backwards: a separate marker test (an asymmetric floor flag at
# z<0 vs a rod at z>0) showed +Z rendering screen-UP at rotx=90/78, which
# means real "up" (shared -Z) was rendering at the BOTTOM of the frame --
# confirmed against the actual assembly render, which showed the
# display+cowl (which sits further along real "up" than the bar) sitting
# BELOW the clamp instead of above it. Negating rotx (90->-90, 78->-78)
# re-tested with the same floor-flag marker and confirmed fixed: real "up"
# now renders at the top, for all three views below.
openscad_png renders/gen4-assembly-iso.png -D 'part="assembly"' \
  --camera=0,0,0,-78,0,25,300
# side: looking along shared X (lateral) with Y (front-to-back) horizontal
# and Z (vertical) vertical in the image -- the bike's profile.
openscad_png renders/gen4-assembly-side.png -D 'part="assembly"' \
  --camera=0,0,0,-90,0,90,300
# front: looking along shared Y (front-to-back) with X (lateral) horizontal
# and Z (vertical) vertical -- as an observer standing in front of the
# parked bike would see it.
openscad_png renders/gen4-assembly-front.png -D 'part="assembly"' \
  --camera=0,0,0,-90,0,0,300

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
VENV=/root/.venvs/revv1/bin/python
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
cat > "$WORKDIR/pos_arm.scad" <<EOF
use <$SRC_ABS>
arm_seat() arm();
EOF
cat > "$WORKDIR/pos_cap.scad" <<EOF
use <$SRC_ABS>
arm_seat() cap();
EOF
cat > "$WORKDIR/display.scad" <<EOF
use <$SRC_ABS>
display_stub();
EOF
openscad -o "$WORKDIR/pos_arm.stl" "$WORKDIR/pos_arm.scad"
openscad -o "$WORKDIR/pos_cap.stl" "$WORKDIR/pos_cap.scad"
openscad -o "$WORKDIR/display.stl" "$WORKDIR/display.scad"

check_clear() {
  local label="$1" a="$2" b="$3"
  if $VENV ../tools/check_fit.py intersect "$a" "$b" > "$WORKDIR/fit.log" 2>&1; then
    echo "OK   $label: CLEAR"
  else
    echo "FAIL $label:"; cat "$WORKDIR/fit.log"; FAIL=1
  fi
}
check_clear "display vs yoke"           "$WORKDIR/display.stl" stl/gen4-yoke.stl
check_clear "display vs positioned arm" "$WORKDIR/display.stl" "$WORKDIR/pos_arm.stl"
check_clear "display vs positioned cap" "$WORKDIR/display.stl" "$WORKDIR/pos_cap.stl"
check_clear "yoke vs positioned cap"    stl/gen4-yoke.stl       "$WORKDIR/pos_cap.stl"
check_clear "cowl vs positioned cap"    stl/gen4-cowl.stl       "$WORKDIR/pos_cap.stl"

echo
if [ "$FAIL" -ne 0 ]; then
  echo "RENDER-GEN4: FAILED -- see FAIL lines above"
  exit 1
fi
echo "RENDER-GEN4: ALL-OK"
