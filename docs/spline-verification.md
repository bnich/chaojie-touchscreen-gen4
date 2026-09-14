# Face spline mesh verification — bench note

Backs the comments in `gen4-display-mount.scad`'s `face_spline()`. Read this before
touching the tooth geometry or before trusting any `intersection()` result on it —
both the construction and the verification method have a documented failure mode
below, and re-deriving either one from scratch is exactly the expensive mistake
this note exists to prevent. §7 documents a third: the un-fixed construction
exported a non-manifold mesh (0 holes, but edges shared by >2 faces) that made
every part unusable with `tools/check_fit.py`. §8 documents a fourth, found
only after §7 closed: the teeth were watertight and manifold but almost
entirely HOLLOW — a thin shell following the ramp's surface with no material
filling the gap down to the disc. Manifold-ness says nothing about solid fill;
neither defect's checks would have caught the other.

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

⚠️ **This is not a CGAL-specific problem — `tools/check_fit.py intersect`
(manifold3d, a different engine entirely) fails the SAME way on a whole
spline ring**, confirmed 2026-09-14: 42.75mm³ for a correctly-seated pair
and 0.0058mm³ for a deliberately misaligned one — backwards, since a
misaligned (peak-on-peak) pair should report the larger volume by a wide
margin (§5's own numbers put a single point's collision at 1.6mm deep) and
seated should be closest to zero. Same root cause as CGAL's failure above:
both operands are already hundreds of thin, near-touching convex `hull()`
pieces, and that defeats a general-purpose exact boolean regardless of
which library computes it. `check_fit.py` remains the right tool for
whole-part clearance checks (arm vs. yoke, say) — just never `intersect`
on two whole spline rings against each other. The rod probe (§4) is the
only method proven trustworthy on this specific geometry.

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

Read each result's z-range with `tools/check_stl.py` (or, for more than 2
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

Re-measured with the 0.02mm rod against the shipped module, `base=3` both
sides, `r=19.9`, after the §7 trough-pullback fix (numbers below are
POST-fix; §7 explains why the trough (±3.75) and peak (0) columns moved a
little from the pre-fix figures while the quarter points did not):

| θ (deg) | correctly seated — overlap | rotated half a pitch — overlap |
|---|---|---|
| -3.75 (male trough / female peak) | 0.0038 mm (contact) | **-1.5934 mm** (true gap) |
| -1.875 (quarter point) | 0.0258 mm (contact) | 0.0257 mm (touching only) |
| 0 (male peak / female trough) | 0.0034 mm (contact) | **1.6010 mm** (full-depth collision) |
| +1.875 (quarter point) | 0.0258 mm (contact) | 0.0257 mm (touching only) |
| +3.75 (male trough / female peak) | 0.0038 mm (contact) | **-1.5934 mm** (true gap) |

Reading this: correctly seated, the two faces are in real, small
(0.004-0.026mm) contact everywhere sampled around a full pitch — not floating
with a gap, and not colliding hard; the whole ramp is a matched (conjugate)
pair, touching along its full flank rather than only at the peak/trough
extremes. A half-pitch misalignment produces the opposite signature: a full
1.6mm collision exactly where peaks now land on peaks, and a true ~1.6mm gap
exactly where troughs now land on troughs. The two scenes are unambiguously
different, and the "correctly seated" numbers are comfortably below anything
an FDM printer resolves (a 0.4mm nozzle, 0.2mm layers) — a print will fuse
this contact seamlessly rather than leave a visible gap or force the two
faces apart.

## 6. What the shipped yoke actually calls, and what that means for the arm

⚠️ **This section previously verified `base_female=8` ("the real value Task 3's
yoke will use, `yoke_t`") — that never shipped.** The yoke's female half is
`face_spline(male=false, base=3)`, called from a pedestal built up on the
arm's own tip stack (`yoke_tip_h`, `yoke_standoff` — see
`gen4-display-mount.scad`'s own comments), not laid straight onto the 8mm
bearing plate. The spline's base is decoupled from `yoke_t` on purpose: the
plate's own thickness is sized for M5 thread engagement (§ DESIGN — YOKE's
own `yoke_t` comment), the spline pedestal for a compact, printable boss at
the pivot — nothing requires the two to match, and forcing them to would
mean an 8mm-tall boss with no structural reason to be that deep. **`base=3`
is the number to build against, not `yoke_t`.**

Re-verified with the pair that actually exists in this codebase today —
`base_male=3` (`spline_test`'s own demo instance, the only male call in the
file so far) and `base_female=3` (the yoke's real value) — using §4's method
against the shipped module, not transcribed from §5:

```
seat = base_male + base_female + spline_h = 3 + 3 + 1.6 = 7.6
male_top(θ=0)     [z-range 0.0 .. 4.6005]     = 4.6005
female_bottom(θ=0) [z-range 4.59710 .. 7.6]   = 4.59710
overlap = 4.6005 - 4.59710 = 0.0034 mm
```

Small, real, correctly-signed contact — consistent with (and, since this is
literally the `base=3/base=3` case, numerically matching) §5's own θ=0 row
(0.0034mm). `male_top` is bit-for-bit the same value as before §7's fix
(θ=0 is the centre of a tooth's peak, an interior sample the fix never
touches); `female_bottom` moved from 4.58722 to 4.59710 because, at this
θ, the female half is at ITS OWN trough (its phase is half a pitch from the
male's), which is exactly the vertex §7's fix pulls back — still a small,
real, positive-contact number, just not bit-identical to the pre-fix one.

**What Task 4's arm therefore needs:** its own male base is a free choice —
the formula holds for any `base_male`, proven independently in the original
version of this section with `base_male=3, base_female=8` — but whatever
value the arm picks, it must compute `seat` against the female's REAL base
(**3**, read from `gen4-display-mount.scad`'s `yoke()`, not assumed to be
`yoke_t`), and should re-run this section's method against both shipped
modules once the arm exists, the same way this update did.

## 7. The non-manifold defect, and the trough-pullback fix

Found after Task 2 closed, by a checker that didn't exist then
(`tools/check_fit.py`, which refuses to answer on a non-watertight mesh —
see its own header for why). Measured with trimesh (`mesh.is_watertight`
and an edge-face-count pass: an edge shared by more than 2 faces is
non-manifold):

| part | faces | boundary edges (1 face) | non-manifold edges (>2 faces) | watertight |
|---|---|---|---|---|
| `spline_test`, `teeth=false` | 768 | 0 | 0 | **True** |
| `spline_test`, `spline_n=12` | 5864 | 0 | 11 | False |
| `spline_test`, `spline_n=48` | 16560 | 0 | 80 | False |
| `yoke` | 21578 | 0 | 54 | False |

Zero boundary edges rules out a hole (`fill_holes()` found nothing to fill);
the count scaling with tooth count, and `teeth=false` alone being clean,
both point at the teeth specifically, not the disc or the bore.

### Isolating the junction, not guessing it

`tooth()` builds each flank as a chain of `nseg=8` short `hull()`s (16 per
tooth). There are two candidate junctions: adjacent segments *within* one
tooth's own chain, and adjacent *teeth* meeting at the shared trough. Built
each in isolation (no cylinder, no bore, just the raw union) and measured:

| construction | faces | watertight | non-manifold edges |
|---|---|---|---|
| 2 adjacent segments, one flank | 56 | True | 0 |
| 1 whole tooth (all 16 segments) | 280 | True | 0 |
| 1 tooth + the base disc | 692 | True | 0 |
| 2 adjacent teeth, no disc | 590 | **False** | **1** |
| full ring (48 teeth), no disc | 14896 | **False** | **82** |

The intra-tooth chain is clean at every step (proven twice: 2 segments
alone, and the whole 16-segment tooth), and a tooth resting on the disc is
clean too. Only two *separate* `tooth()` instances meeting each other
reproduce the defect — 1 non-manifold edge per adjacent pair, ~82 for a
48-tooth ring, matching the shipped part's 80 (the small gap between 82 and
80 is the disc changing the local mesh slightly; it doesn't change which
junction is at fault). Inspecting the actual non-manifold edge in the
2-tooth case placed it exactly at the trough vertex (r=spline_od/2, the
outer radius, at the shared boundary angle) where 4 faces meet instead of 2.

**Root cause:** every tooth is the same `tooth()` reached through a
different `rotate([0,0,i*step+phase])`. Tooth *i*'s own last sample and
tooth *i+1*'s own first sample are meant to be the identical point
(`i*step+phase+half` on one side equals `(i+1)*step+phase-half` on the
other, algebraically) — but each is reached via a *different* `rotate()`
call, hence a different floating-point path to "the same" angle. CGAL's
exact arithmetic sees two near- but not bit-identical faces meeting exactly
face-to-face and leaves a degenerate seam instead of merging them, exactly
the "adjacent solids meeting exactly face-to-face" signature this file's
own CLAUDE.md-equivalent warning describes for CGAL booleans elsewhere.

### Two fixes tried and rejected

- **Extend each tooth past ±half to overlap the neighbour's first chord**,
  using the wrapped triangular-wave formula so the extension's height
  matches the neighbour's real geometry exactly (a deliberate duplicate).
  Made it WORSE: 4 non-manifold edges on the 2-tooth isolation, up from 1.
  Two independently-rotated, near-duplicate surfaces crossing each other
  throughout a whole overlap band gives CGAL more disagreement to resolve,
  not less.
- **Enlarge the shared boundary vertex into a small cube** (a marker big
  enough to swamp the floating-point gap between the two rotate() paths).
  Same failure, same reason: still two independently-rotated near-duplicate
  solids, just bigger ones, at spline_n=48 giving 81 non-manifold edges —
  no better than the original 80.

### The fix that works: pull the trough vertex back, don't extend it

Rather than making the two teeth's boundary geometry cross or duplicate,
stop each tooth a small angle short of the shared boundary so the two
neighbours never place a vertex at the same spot at all. Only the `k =
±nseg` sample (the trough end of each flank) moves; its *height* stays
exactly 0, so the tooth still touches the disc (still one connected body —
checked by counting connected components, not just `is_watertight`: an
early version of this fix changed the trough's height too and silently
detached every tooth from the disc into its own floating island, 13
separate bodies at spline_n=12). The small gap this opens between
neighbouring teeth is covered by the disc's own flat top, already at height
0 there, so nothing is left open.

`trough_pullback = (half/nseg) * 0.05` — 5% of the finest existing chord,
so it scales with both `nseg` and `spline_n` automatically. Swept
0.001-0.08 (as a fraction of one chord) at `spline_n` = 4, 6, 8, 12, 24, 36,
48, 72, 96, 180: still non-manifold at 0.001 (barely pulled back — within
CGAL's own numerical noise), clean from 0.005 up at every `n` tried. 0.05
keeps a 10x margin over that measured threshold while moving the trough
vertex by well under 0.02mm at `spline_od/2` — an order of magnitude below
the 0.004-0.026mm contact spread §5 already treats as FDM-invisible.

Only the two boundary samples move; every interior sample (everything §5
and §6 probe: the quarter points, the peak) is untouched, so the tooth
PROFILE away from the exact trough point is bit-for-bit what it was.
Re-measuring §5 and §6 after the fix (numbers now current in both
sections) shows exactly that: the quarter-point row is unchanged to 4
decimal places (0.0258mm both before and after), while the trough and peak
rows — which sample at or adjacent to the pulled-back vertex — shifted by a
few thousandths of a millimetre, still small, still real, still
correctly-signed contact.

### Verification after the fix

```
$ openscad -o stl/gen4-spline-test.stl -D 'part="spline_test"' src/gen4-display-mount.scad
$ python3 tools/check_fit.py report stl/gen4-spline-test.stl
    watertight True
$ openscad -o stl/gen4-yoke.stl -D 'part="yoke"' src/gen4-display-mount.scad
$ python3 tools/check_fit.py report stl/gen4-yoke.stl
    watertight True
```

Both parts: 0 boundary edges, 0 non-manifold edges, 1 connected component,
watertight True. `spline_test` bbox unchanged at 40 × 40 × 4.6mm, `yoke`
unchanged at 103 × 90.1 × 20.5mm, `gauge` unchanged at 101 × 48.6 × 8mm —
the fix is confined to the trough vertex and changes no part's outer
envelope.

## 8. The hollow-tooth defect, and the base-sample fix

Found after §7 closed — a real, separate defect in the SAME `tooth()`, in
the geometry the trough-pullback fix never touched. §7's four checks
(watertight, 0 boundary edges, 0 non-manifold edges, 1 connected component)
all test whether a mesh's SURFACE is a closed, consistent skin. None of
them test whether the solid it encloses is actually filled — a hollow shell
passes all four the same as a solid part would.

**The defect:** each of `tooth()`'s segments is `hull()` of exactly 4
points — 2 radii × 2 thetas, both AT the profile height (`base+height`,
never at `base` itself). A convex hull's z-extent is bounded by its own
vertices, so a segment built only from its two profile-height corners never
reaches any lower than `min(height_k, height_k+1)`. Only the one segment
immediately adjacent to each trough (whose low end is height 0, i.e.
z=base) ever actually touched the disc; every other segment floated a thin
shell above it, following the ramp's top surface with nothing filling the
gap underneath — a ribbon, not the solid ridge the whole meshing argument
(§0's block comment in `gen4-display-mount.scad`, "every tooth is a single
straight ridge") and the tilt-moment claim both assume.

Measured three independent ways on the bare (pre-fix) `face_spline()`:

- **Volume.** `spline_test` totalled 3472.3mm³ against a 3428.2mm³
  disc-minus-bore (measured directly with `teeth=false`, not a hand
  formula) — the teeth were contributing only **~44mm³** of a solid ridge
  set that should run close to 900mm³.
- **Thin-rod probe (0.02mm, the §4 method) at the quarter point
  (θ=1.875°, r=19.9).** Solid material found only in a narrow band right
  under the profile surface, with the disc-to-surface span below it empty
  — the reviewer's independent sweep (17 points across one flank at
  r=6.5/13/19.9) found the same disc-gap-thin-roof signature everywhere
  except the exact trough.
- **Peak (θ=0°).** Same signature: a thin roof at the profile height, air
  below it down toward the disc.

**The fix:** hull() 8 points per segment, not 4 — the same 2 radii × 2
thetas as before, but at BOTH `z=base` and `z=base+height` at each. This
does not move the top surface at all: a convex hull's upper envelope is
set by its highest points, and adding points strictly below cannot pull it
down — the same 4 profile points are still in the vertex set, so the
mating flank §1-§6 already proved is untouched. What it adds is a proper
bottom face at z=base and sloped side walls down to it, so every segment is
a solid prism reaching the disc across its own full angular span, not only
at the two ends of the chain.

### Verification after the fix

```
$ openscad -o stl/gen4-spline-test.stl -D 'part="spline_test"' src/gen4-display-mount.scad
$ python3 tools/check_fit.py report stl/gen4-spline-test.stl
    volume 4364.414 mm^3
    watertight True
```

- **Volume:** 4364.4mm³ total, 3428.2mm³ disc, so the teeth now contribute
  **~936mm³** — in line with the ~900-930mm³ a solid Hirth ridge set should
  weigh in at, up from ~44mm³.
- **Rod probe, corrected method.** The reviewer's first attempt used a
  0.3mm-diameter rod at a fixed radius, which is wider than the ~0.1mm of
  radial slop between the probe and the tooth's own outer edge (od/2=20,
  probing at r=19.9) — the same smearing trap §4 already warns about, here
  in the radial direction instead of angular, and it produces a false
  partial "gap" at the very edge that is a probe-sizing artifact, not a
  hollow tooth. Repeated with the established 0.02mm rod, spanning exactly
  `z=[base, base+expected_height]` at the probed θ (no overshoot past the
  real profile top): at the peak (θ=0°) and the quarter point (θ=1.875°),
  `intersection(face_spline(), rod)` is ONE connected, watertight solid
  spanning the FULL expected range (peak: z=3.0..4.6; quarter: z=3.0..3.8)
  — not a thin roof over air. `difference(rod, face_spline())` at the same
  two points leaves only a sub-micron³ sliver right at the very tip (within
  0.01mm of the profile height, an expected apex-rounding artifact, not an
  internal void).
- **Mesh health**, `spline_test` / `yoke` / `arm` (all three call
  `face_spline()`; `arm` didn't exist when §7 was written):

  | part | faces | watertight | boundary edges | non-manifold edges | components | volume |
  |---|---|---|---|---|---|---|
  | `spline_test` | 12288 | True | 0 | 0 | 1 | 4364.4mm³ |
  | `yoke` | 17414 | True | 0 | 0 | 1 | 35410.4mm³ |
  | `arm` | 17996 | True | 0 | 0 | 1 | 25962.8mm³ |

  `yoke`'s volume rose from 34518.3mm³ to 35410.4mm³ (+892mm³, matching the
  female spline filling in) with its bbox unchanged at 103 × 90.1 × 20.5mm.

- **Seating figures (§5/§6): unchanged from their post-§7 values.** Every
  number in both sections comes from `male_top`/`female_bottom` — the
  MATING SURFACE, the same 4 profile points this fix never moves — so
  re-running §4's exact method against the current file reproduces §5's
  table and §6's `4.6005`/`4.59710`/`0.0034` to the same decimal places.
  This isn't assumed: re-measured directly against the post-fix module
  rather than left on the strength of the "top surface unchanged" argument
  alone.
- **Assertions:** all fire as before (engagement, pivot height, socket
  clearance, standoff, pivot bore, chamfer depth, arm width, unknown part,
  and `face_spline()`'s own `male`/`base`-required pair) — none of this
  fix's changes touch assertion-guarded values.

### Why §7's checks didn't catch it

Watertight / 0 boundary / 0 non-manifold / 1 component are all properties
of the mesh's SURFACE topology — they ask "is this skin closed and
consistent," never "is there material inside it." A perfectly sealed
hollow shell satisfies all four exactly as well as a solid part does; only
a volume check or a probe that samples the interior (not just the
boundary) can tell them apart. Worth carrying forward to any future
`hull()`-chain construction in this file: manifold-ness and solid fill are
independent properties, and both need their own check.
