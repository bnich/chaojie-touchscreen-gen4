# Face spline mesh verification — bench note

Backs the comments in `gen4-display-mount.scad`'s `face_spline()`. Read this before
touching the tooth geometry or before trusting any `intersection()` result on it —
both the construction and the verification method have a documented failure mode
below, and re-deriving either one from scratch is exactly the expensive mistake
this note exists to prevent.

All numbers below are from the shipped module (`spline_od=40, spline_id=12,
spline_n=48, spline_h=1.6`), re-measured against the current file, not transcribed
from an earlier draft.

## 1. The single-hull tooth doesn't mesh — measured, not assumed

The first construction built one flank as `hull()` of 6 points: the two trough
corners (at `spline_id/2` and `spline_od/2`, at the tooth's angular edge) and the
peak point (at both radii, at the tooth's centre angle). This looks right in a
render — even, radial, meeting at the bore — but a render only shows the
silhouette, not whether the height at a given angle is independent of radius,
which is what two mating faces actually need.

Probing the solid with a thin (0.02mm) vertical rod at several radii and the same
angular fraction across one flank showed the height BOWS with radius:

| angular fraction (0=peak, 1=trough) | r=6.5 | r=13.0 | r=19.9 | ideal (linear) |
|---|---|---|---|---|
| 0.25 | 1.34 | 1.35 | 1.21 | 1.20 |
| 0.50 | 0.91 | 1.09 | 0.82 | 0.80 |
| 0.75 | 0.47 | 0.83 | 0.42 | 0.40 |

Worst deviation from "height independent of radius": **0.43mm at r=13
(mid-radius), fraction 0.75**. Cause: `hull()` joins the trough point at
`spline_id/2` to the trough point at `spline_od/2` with a straight CARTESIAN
edge, not a constant-radius arc — that chord dips inboard of the true circle
between its ends, and the resulting flank is a warped (non-planar) ruled surface,
not the flat "height = f(theta) only" ramp the meshing argument needs. Mated
against a correctly-phased partner this bow showed up as ~330mm³ of real
interference at the design distance (measured on the pre-fix construction) — not
the near-zero a provably-meshing joint needs.

(An even earlier idea, `linear_extrude(scale=...)` of one radial cross-section,
was rejected without needing measurement: `scale` shrinks both plan axes toward
the centroid as it extrudes, so a ridge meant to span the full
`spline_id/2..spline_od/2` radius collapses toward a point at full height —
a starburst of spikes meeting near the bore, not radial ridges reaching the tip.)

## 2. The fix: chain short hulls instead of one long one

Each flank is now walked in `nseg=8` steps from trough to peak (16 short hulls
per tooth, 768 for the whole ring). Every sample's height comes from the exact
triangular-wave formula, not from interpolating the previous hull, and each pair
of adjacent samples becomes its own short `hull()` of 4 points (2 radii x 2
angles). Shrinking the angle per chord shrinks its inboard dip much faster than
linearly, so a modest `nseg` gets the bow down to a fraction of a millimetre
(numbers in §4). Raise `nseg` if a future `spline_n`/`spline_od` combination (a
longer chord per segment) reopens a measurable gap.

## 3. The whole-ring `intersection()` is not a trustworthy mesh test

The obvious verification — `intersection(){ male_face; female_face; }` on the
full 48-tooth rings — gives answers that contradict direct measurement at the
same relative pose. Reproduced against the shipped module:

```
male   = face_spline(male=true,  base=3)
female = translate([0,0,seat]) mirror([0,0,1]) face_spline(male=false, base=3)
   where seat = base + base + spline_h = 7.6
```

| scene | `intersection()` volume | CGAL `Volumes:` | rod probe at θ=0 (0.02mm rod, r=19.9) |
|---|---|---|---|
| correctly seated | 44.38 mm³ | 2 | 0.013 mm (real, small contact) |
| rotated a half tooth pitch (deliberately misaligned, peak-on-peak) | **0.0058 mm³** | **193** (≈192 disjoint fragments + 1 exterior) | **1.601 mm** (full-depth collision) |

The misaligned row is the damning one: a single point on the ring already
measures 1.601mm of unambiguous, full-depth collision (male's peak driven
1.601mm into female's peak — nowhere near touching, let alone meshing), yet the
whole-ring boolean reports 0.0058mm³ total across all 48 teeth. That is at least
three orders of magnitude too small to be consistent with even ONE tooth
colliding this hard, and the `Volumes: 193` fingerprint (versus the expected
single connected interference region, or 48 separated ones) shows CGAL's Nef
polyhedron boolean shattering the result into ~192 near-degenerate fragments
instead of computing it — it has lost its footing, not found a small answer.
This is CGAL/OpenSCAD running out of numerical robustness on two operands that
are each already hundreds of thin, near-touching convex pieces (every `hull()`
segment from §2, on both sides at once), not a defect in the modelled solid.

The "correctly seated" row's 44.38mm³ happens to be the right order of magnitude
(a ~0.01-0.03mm contact spread over the ~1144mm² teeth annulus is ballpark
10-35mm³) but should NOT be read as a precise figure either, for the same
reason — a whole-ring boolean on this geometry is not a instrument to trust,
even when its answer looks plausible.

**Conclusion: verify this geometry by intersecting each face separately against
a small probe (a thin rod, or a small region), then compare the two resulting
z-ranges arithmetically — never by booleaning the two complex faces directly
against each other.** Every rod-probe number in this note was cross-checked
this way across dozens of points during development and never once disagreed
with hand-derived geometry; the whole-face boolean disagreed with it twice
(the case above, and a smaller-scale version restricted to 5 teeth instead of
48, ruling out "just needs simpler geometry" as the fix).

## 4. The rod-probe method, in enough detail to re-run

⚠️ **The redeclaration line below is load-bearing — do not delete it as boilerplate.**
`use <>` imports **modules and functions only, never top-level variables.** They are *not* inherited
from the file above. Drop that line and `spline_h` becomes `undef`, so `seat` becomes `undef`, and
`translate([0, 0, undef])` **silently coerces to `translate([0, 0, 0])`** — OpenSCAD emits a
`WARNING`, not an error, and every z-value below comes out wrong while the script appears to run.
A reviewer reproducing this method hit exactly that and got a plausible-looking wrong answer.

(The reverse is also true and worth knowing: these redeclarations cannot *override* the constants
`face_spline()` itself uses — it reads its own file's values. They exist only so this wrapper can
compute `seat`.)

```openscad
use <gen4-display-mount.scad>
// ⚠ Required. See the note above — `use` does not import variables.
spline_od = 40; spline_id = 12; spline_n = 48; spline_h = 1.6; teeth = true; eps = 0.1;

base = 3;                              // or whatever the caller under test uses
seat = base + base + spline_h;         // general: base_male + base_female + spline_h

module male() { face_spline(male = true, base = base); }
module female_mated(extra_rot = 0, dz = 0) {
  translate([0, 0, seat + dz])
    mirror([0, 0, 1])
    rotate([0, 0, extra_rot])
    face_spline(male = false, base = base);
}
// thin probe — 0.02mm dia. A fatter rod (0.3mm was tried) smears across enough
// angle near a peak/trough to inflate the reading by an order of magnitude —
// confirmed by re-measuring the same points with both diameters; this is why
// the diameter is called out explicitly rather than left to "whatever's handy".
module rod(r, theta_deg) {
  translate([r*cos(theta_deg), r*sin(theta_deg), -5])
    cylinder(d = 0.02, h = 20, $fn = 6);
}

// Probe each side SEPARATELY against the rod (two simple, reliable 2-way
// booleans), not against each other:
intersection() { male();              rod(19.9, THETA); }   // -> male_top
intersection() { female_mated(0, 0);  rod(19.9, THETA); }   // -> female_bottom
```

Read each result's z-range with `mounts/check_stl.py` (or, for more than 2
decimal places, `check_stl.read_stl()` directly — the printed 2-decimal figures
round differently enough at this scale to matter). Overlap at that θ =
`male_top - female_bottom`; positive means contact/interference, and OpenSCAD
refusing to write an STL at all (empty top-level object) means a true physical
gap there.

⚠️ **Probe by calling the module directly — never by `import()`ing an already-
exported STL.** Re-importing `gen4-yoke.stl` (or any part's own export) and
intersecting it against a probe gives a FALSE EMPTY (verified,
2026-09-13): OpenSCAD prints `ERROR: The given mesh is not closed! Unable
to convert to CGAL_Nef_Polyhedron.` to stderr, then reports the top-level
object empty and exits non-zero — the error line IS there to `grep`, but
it is easy to miss if the check is written the way every other probe in
this file is (`grep -iE "empty|error"` then treat "no STL written" as the
proof passing): that pattern reads this failure as a clean, genuine
clearance result, not a boolean CGAL refused to even attempt. The part's
own `.stl` export is watertight by every check this file uses
(`check_stl.py`'s bbox, `Volumes:`, and the union-find connected-component
check); it is specifically the round-trip through `import()` that produces
a mesh CGAL won't boolean against. Every proof in Tasks 3+ intersects the
live module (`yoke()`, `arm()`, …) called
straight out of `gen4-display-mount.scad`, never a re-imported mesh — keep
doing that for Tasks 4–6's own probes too.

## 5. Corrected seated / misaligned table

Supersedes the Task 2 report's original figures (0.19 / 0.38mm), which used a
0.3mm probe rod and were inflated by exactly the smearing effect described in
§4 — re-measured here with the 0.02mm rod against the shipped module, `base=3`
both sides, `r=19.9`:

| θ (deg) | correctly seated — overlap | rotated half a pitch — overlap |
|---|---|---|
| -3.75 (male trough / female peak) | 0.0136 mm (contact) | **empty** (true gap) |
| -1.875 (quarter point) | 0.0258 mm (contact) | 0.0000 mm (touching only) |
| 0 (male peak / female trough) | 0.0132 mm (contact) | **1.6010 mm** (full-depth collision) |
| +1.875 (quarter point) | 0.0258 mm (contact) | 0.0000 mm (touching only) |
| +3.75 (male trough / female peak) | 0.0136 mm (contact) | **empty** (true gap) |

Reading this: correctly seated, the two faces are in real, small (0.013-0.026mm)
contact everywhere sampled around a full pitch — not floating with a gap, and
not colliding hard; the whole ramp is a matched (conjugate) pair, touching along
its full flank rather than only at the peak/trough extremes. A half-pitch
misalignment produces the opposite signature: a full 1.6mm collision exactly
where peaks now land on peaks, and a true, empty gap exactly where troughs now
land on troughs. The two scenes are unambiguously different, and the "correctly
seated" numbers are comfortably below anything an FDM printer resolves (a
0.4mm nozzle, 0.2mm layers) — a print will fuse this contact seamlessly rather
than leave a visible gap or force the two faces apart.

## 6. Seating formula, verified with two DIFFERENT `base` values

`face_spline()`'s doc comment gives the general seating offset as
`base_male + base_female + spline_h`, explicitly not assuming the two sides
share a `base`. Verified directly rather than only algebraically: `base_male=3`,
`base_female=8` (the real value Task 3's yoke will use, `yoke_t`), so
`seat = 3 + 8 + 1.6 = 12.6`:

```
male_top(θ=0)    = 4.6005   (unaffected by the other side's base, as expected)
female_bottom(θ=0, base=8, seat=12.6) = 4.5872
overlap = 0.0133 mm
```

Same small, real, correctly-signed contact as the `base=3/base=3` case (§5's
θ=0 row, 0.0132mm) — the formula holds when the two sides differ, which is the
case Tasks 3 and 4 will actually build.
