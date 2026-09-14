// ============================================================
//  Chaojie Gen 4 5" display (CJ-V5-04) — BAR MOUNT + REAR COWL
//
//  Design notes: docs/design-notes.md
//  Display geometry: docs/display-geometry.md
//    — taken off the factory manual's §III installation drawing, rendered at
//      600 dpi and calibrated on its own printed dimensions (0.26% agreement).
//      Thread, depth and orientation confirmed on the unit 2026-09-13.
//
//  ⚠ THE TWO TRAPS. Both are forced by the display, not chosen. The assertions
//     below exist so that "simplifying" either one fails the render, loudly,
//     instead of failing on the bike.
//       1. The boot slot opens UPWARD. A downward slot cuts off the lone M5.
//       2. The pivot sits BELOW the housing. Any higher and the toothed face
//          covers the lone M5's head and the bolt can never be fitted.
//
//  ⚠ THE M5 THREADS ARE 5 mm DEEP — ONE BOLT DIAMETER. M5 x 12, no washer,
//     never longer. A bolt that bottoms feels tight and holds nothing.
//
//  PARTS:  gauge | yoke | arm | cap | cowl | brow_test | plate | spline_test
//  Export: openscad -o out.stl -D 'part="gauge"' gen4-display-mount.scad
//  ⚠ Only "gauge" and "spline_test" are implemented so far (below). The rest
//     land in later tasks, each wired into the `part = "..."` selector at
//     the same spot. spline_test is a throwaway proof piece for the toothed
//     tilt joint (face_spline(), shared geometry) — it is not one of the
//     assembled parts above; yoke and arm (Tasks 3-4) call face_spline()
//     directly and never appear as "spline_test" themselves.
//  ⭐ PNG RENDERS DON'T NEED `--render`. Timed on spline_test: ~21s with
//     `--render 1` (forces the exact CGAL backend) vs ~0.3s with plain PNG
//     export (OpenCSG preview) — ~70x, visually identical for every part in
//     this file so far. A failed assert() still prints its ERROR line during
//     CSG-tree evaluation either way (that happens before either backend
//     runs), so the fast path keeps the loud-failure safety net. Use
//     `--render` only when you need the exact boolean result itself (e.g.
//     the mesh-proof STLs in spline-verification.md) — not for a batch of
//     inspection PNGs (Task 6).
// ============================================================

/* [DISPLAY — canonical, do not edit without changing docs/display-geometry.md too] */

/* [DISPLAY — OVERALL] the shell itself; the cowl is sized to match this */
disp_w        = 159.99;   // overall width
disp_h        =  93.98;   // overall height
disp_d        =  26;      // rear face -> glass. EXCLUDES the cable boot.
disp_corner_r =   9;      // the cowl reuses this so the two read as one object

/* [DISPLAY — HOLE PATTERN] the three M5s that carry the whole assembly.
   In doc coords: X from the left edge, Y DOWN from the top (docs/display-geometry.md). */
holes     = [ [ 39.50, 40.9 ], [ 120.50, 40.9 ], [ 80.00, 63.28 ] ];
hole_lone = holes[2];      // the unpaired M5, below the pair (confirmed on the
                           // unit 2026-09-13). Named so it is never re-derived
                           // by index elsewhere — if `holes` is ever reordered,
                           // only this line needs to change.
m5_depth  = 5;             // ⚠ usable thread. ONE bolt diameter. See assertions.
m5_head_d = 8.5;           // socket cap head
m5_len    = 12;            // ⚠ M5 x 12. Set by what the owner stocks (8/12/16/20
                           // — there is no M5 x 10 in the drawer, 2026-09-13) and
                           // by the 3-4 mm engagement window the 5 mm thread
                           // allows: bolt length minus part thickness must land
                           // in [3,4]. M5x12 pairs with 8 mm parts; M5x8 would
                           // have meant 5 mm parts. The assertions below are the
                           // real guard — change this and they will tell you what
                           // thickness it now demands.

/* [DISPLAY — CABLE BOOT] the whole loom leaves the device through this */
boot_c        = [ 80.0, 40.9 ];
boot_d        = 13.0;
boot_collar_d = 21.7;     // size the clearance on THIS, not on boot_d
boot_proud    = 22.3;     // how far it stands off the rear face
boot_clear_d  = 24;       // Ø24 relief, sized on the Ø21.7 collar, not the
                          // Ø13 boot (docs/display-geometry.md: "opening of at least Ø24 ...
                          // Design the plate with a Ø24 relief either way —
                          // it costs nothing"). Shared by every part that
                          // has to let the boot through (gauge below, the
                          // yoke's bearing face later) — defined here, with
                          // its own source, rather than buried in whichever
                          // part module uses it first.

/* [DISPLAY — FLAT BAND] the only part of the back that is flat enough to
   bear on. Outside this band the shell chamfers away and a bracket would
   rock on two lines.

   ⭐ MEASURED ON HARDWARE 2026-09-13, and it corrects the drawing.
   The printed fit gauge spanned the drawing-derived 20.0..74.6 and overhung
   by ~3 mm at each end, hanging over the chamfer rather than touching. So
   the flat area is ~6 mm narrower than the side view suggested.

   Why the drawing misled: the side view shows where the surface BEGINS to
   chamfer, which is a soft transition — the genuinely flat bearing area
   stops about 3 mm inboard of that line. A figure read off an elevation
   will always be the optimistic one. This is the number to trust; the
   gauge sat flat on it with all three M5s pulled up. */
band_y0 = 23.0;   // was 20.0 from the drawing
band_y1 = 71.6;   // was 74.6 from the drawing
// ⬜ Both are an eyeball ~3 mm off the printed gauge's edges, not a caliper
//    reading. Good to ~±1 mm. Refine if a part ever needs the last millimetre
//    of bearing area — nothing does today.

/* [DESIGN — YOKE] the handlebar-side part: clamps the bar, carries the
   pivot and spline that the cowl's arm indexes against */
yoke_t     = 8;                 // bearing-face thickness. Paired with m5_len: 12
                                // - 8 = 4 mm engaged, the most a 5 mm thread
                                // safely gives. 8 mm of ASA is also ~4x stiffer
                                // in bending than 5 mm (stiffness goes as t^3),
                                // which is worth having under a 5" screen on a
                                // hub-motor moped.
pivot_c    = [ 80, 100 ];       // ⚠ DM-6. Below the housing. See assertion.
pivot_bolt_clear_d = 6.4;       // M6 clearance through both spline halves —
                                // named here (not just typed inline at the
                                // yoke's own bore) so Task 4's arm drills the
                                // identical bore, not a separately-guessed one.
spline_od  = 40;
spline_id  = 12;                // M6 clearance + boss
spline_n   = 48;                // 48 teeth = 7.5 deg steps
spline_h   = 1.6;               // tooth height
teeth      = true;              // false -> solid fixed-angle joint, same file

/* [DESIGN — COWL] the rear shroud that covers the display's edges, boot and
   fasteners, and carries the brow over the glass */
cowl_wall  = 2.4;               // 6 perimeters at 0.4
brow       = 19;                // ⬜ UNPROVEN. 18-20 mm; confirm with the
                                //   throwaway brow-test piece before committing.
reveal     = 0.5;               // ⚠ DELIBERATE even shadow gap, cowl to display.
                                //   Not an attempt at zero. A consistent reveal
                                //   reads as designed; a wandering one reads as
                                //   a bad fit. This is the single detail that
                                //   most separates "professional" from "printed".
fillet_out = 3;                 // cowl outer perimeter
fillet_vis = 2;                 // every other visible edge
fillet_in  = 1;                 // internal wall-to-rib junctions (anti-crack)

/* [⬜ GATING MEASUREMENT — the build is not blocked, the gauge does not need it] */
bar_d = 22.2;   // ⬜ MEASURE AT THREE CLOCK ANGLES. A used bar goes oval where
                //    clamps have sat, and a round bore on an oval bar touches
                //    in only two places. 22.2 is a PLACEHOLDER, not a reading.

$fn = 96;

/* ===================== ASSERTIONS =========================
   These encode the spec's constraints. If you change a number above and one
   of these fires, the number was wrong — not the assertion. */

assert(m5_len - yoke_t <= m5_depth - 1,
  "BOLT BOTTOMS OUT: m5_len - yoke_t must leave >=1mm of air in a 5mm thread.");
assert(m5_len - yoke_t >= 3,
  "TOO LITTLE ENGAGEMENT: need >=3mm of thread engaged.");

assert(pivot_c[1] - spline_od/2 >= hole_lone[1] + m5_head_d/2 + 2,
  "PIVOT TOO HIGH: the toothed face covers the lone M5's head. See DM-6.");

assert(hole_lone[1] > boot_c[1],
  "ORIENTATION FLIPPED: the lone hole is BELOW the pair on this display.");

for (h = holes)
  assert(h[1] >= band_y0 + 3 && h[1] <= band_y1 - 3,
    str("BOLT PAD (", h[0], ",", h[1], ") FALLS OUTSIDE THE FLAT BAND (Y ",
        band_y0, "..", band_y1, ")."));

assert(boot_c[1] + boot_collar_d/2 + 1 < hole_lone[1] - m5_head_d/2,
  "BOOT CLEARANCE OVERLAPS THE LONE M5 PAD.");

// band_y0 is the smaller doc-Y value, i.e. the edge nearer the display's TOP
// (docs/display-geometry.md's Y runs down the page) — so this is the constraint that the boot's
// clearance actually reaches that top edge. If it fired, the slot geometry
// in boot_slot() would be cutting a pocket, not an opening — and the whole
// loom has to leave through it.
assert(band_y0 < boot_c[1] - boot_clear_d/2,
  "SLOT NOT OPEN: the boot clearance does not reach the top edge of the band.");

echo(str("gen4 mount OK — engagement ", m5_len - yoke_t,
         "mm, spline step ", 360/spline_n, " deg"));

// p(xy) — the ONE mapping from doc coords to model space. Every part goes
// through this for every hole, the boot centre and the pivot; do not
// reimplement it locally, or a later part risks a wrong sign or a half-width
// offset that only shows up once parts are assembled together.
//   IN:  doc coords from docs/display-geometry.md —
//        X measured from the display's LEFT edge, Y measured DOWN from its
//        TOP edge, both in mm (the factory drawing's own convention).
//   OUT: model-space [x, y], origin at the CENTRE of the display's REAR
//        FACE. X keeps the same sense (still increasing to the right). Y is
//        INVERTED, not merely re-zeroed or rescaled — the sign flips, so
//        that "down the doc page" becomes "down in Z-up model space" instead
//        of "up". Forgetting the sign flip (using a pure offset instead)
//        mirrors every feature top-to-bottom while looking correct in
//        isolation.
//   OUT OF SCOPE: Z / depth. docs/display-geometry.md's drawing is a single face-on 2D view, so
//        p() only ever returns an [x, y] pair. Each part places its own
//        geometry along Z using whichever depth number applies to it
//        (disp_d, m5_len, boot_proud, ...) — p() has no opinion on depth.
function p(xy) = [ xy[0] - disp_w/2, disp_h/2 - xy[1] ];

// ============================================================
// PART MODULES — one module per part, landing here in PARTS order (header)
// as each is built, and wired into the `part = "..."` selector below.
// ============================================================

/* ---- shared geometry ---------------------------------------
   hole_pattern() and boot_slot() are not part of any one part's section:
   the gauge uses both here, and the yoke's bearing face (Task 3) reuses
   both again, so they live between the parts rather than inside the first
   one that happened to need them.
   Both assume the caller's solid spans Z ∈ [0, t] — every cut below runs
   from -eps to t+eps, not centred on some other Z origin. A caller whose
   relevant face isn't at z=0 gets the wrong Z-range cut, silently: put the
   caller's own geometry at z=0..t and translate the RESULT afterwards,
   rather than changing the padding in here to compensate. */
eps = 0.1;   // boolean-safety overshoot on every cut below: two faces left
             // exactly coincident is a degenerate, orientation-dependent
             // case for a CGAL boolean, so every through-cut overshoots
             // both faces of whatever it's subtracted from by this much.
             // Same idea as fardriver-underseat-mount.scad's `eps`, sized up
             // for this file's coarser (mm, not sub-mm) tolerances.

// Ø5.5 clearance at each bolt, plus a 0.5x45 lead-in chamfer so elephant-foot
// on the first layer cannot foul the fit.
module hole_pattern(t) {
  for (h = holes) {
    translate([p(h)[0], p(h)[1], -eps])
      cylinder(d = 5.5, h = t + 2*eps);
    // Own translate at the TRUE z=0 face — NOT the through-cut's -eps
    // overshoot above. Sharing that overshoot used to put this chamfer at
    // z=[-eps, 0.5-eps], i.e. 6.3->5.5 over 0.4mm at the real face instead
    // of the 6.5->5.5 over 0.5mm the comment claims: immaterial at FDM
    // tolerances, but the code should do what it says.
    translate([p(h)[0], p(h)[1], 0])
      cylinder(d1 = 6.5, d2 = 5.5, h = 0.5);
  }
}

// ⚠ OPENS UPWARD (+Y). Sized on the Ø21.7 collar, not the Ø13 boot.
// Closed end is the semicircle BELOW the boot; the slot runs from there for
// `up`, and MUST clear `top_y` — the CALLER's own top edge, in model space
// — or the cut stops short of open air and becomes a closed pocket that
// still renders clean and trips no other assertion. That is exactly what a
// plausible-looking default for `up` (60, as it briefly was) hides: it was
// only ever correct for gauge()'s own ~54.6mm-tall shape, and nothing
// stopped a differently-shaped second caller (Task 3's yoke) inheriting it
// and silently sealing off the loom's only exit. So there is no default —
// every caller states its own `up` and its own `top_y`, and gets checked.
//
// ⚠ WHAT `top_y` MUST BE, because the assertion trusts you completely.
// `top_y` is the caller's real solid boundary **measured along the boot's own
// X-band** (the 24mm-wide column the slot cuts through), in model space.
// It is NOT the tallest point anywhere on your shape, and it is NOT a value
// borrowed from another part. Hand it a plausible wrong number — gauge_top_y
// reused by a taller part, say — and the assertion passes happily while the
// cut lands mid-plate as a closed pocket (verified, 2026-09-13). The check
// catches a wrong `up` given a correct `top_y`; it cannot prove the result is
// open, because OpenSCAD gives no way to interrogate an arbitrary CSG tree's
// true boundary along a column. If your part's top edge is not flat across
// that band, use the LOWEST point of it.
module boot_slot(t, up, top_y) {
  assert(p(boot_c)[1] + up > top_y,
    str("SLOT TOO SHORT: up=", up, " does not reach this caller's top edge (",
        top_y, ") — the boot clearance would be a closed pocket, not a slot."));
  translate([0, 0, -eps]) {
    translate(p(boot_c)) cylinder(d = boot_clear_d, h = t + 2*eps);
    translate([p(boot_c)[0] - boot_clear_d/2, p(boot_c)[1], 0])
      cube([boot_clear_d, up, t + 2*eps]);
  }
}

// A ready-made, provably-safe value to pass as `up`: every part built on
// this display's own footprint has every feature's model-space Y within
// disp_h/2 of the origin (p() maps the full doc-Y range 0..disp_h
// symmetrically about 0 — see p()'s block comment), so starting behind the
// boot's own centre and running for a full disp_h clears any such part's
// top edge with room to spare. NOT a proof for a caller that reaches beyond
// the display's own envelope in +Y — that caller passes its own `up`, and
// the assertion above still catches a short one either way.
slot_reach = disp_h;

// Bevels the top AND bottom edge of a linear_extrude(h) of the 2D child
// profile by `ch`, at 45 deg, via a 3-slice hull() instead of minkowski() —
// this file's own geometry does not get to trust a CGAL boolean OR a CGAL
// minkowski() (spline-verification.md §3), so the edge break is built the
// same robust way the spline teeth are: short hull()s of simple pieces, not
// one complex operator. Two thin (0.01mm) slices of the profile inset by
// `ch`, hulled through a full-size middle slice, taper linearly between
// them — the same "grow, then shrink back" idea as the offset(r)/
// offset(delta=-r) silhouette fillet above, just carried into Z. Requires
// the child profile to be CONVEX (a hull() across all three slices otherwise
// bridges over any concave notch and silently fills it in) — every caller in
// this file passes a hull()-of-circles-derived profile, which is convex by
// construction.
module chamfer_slab(h, ch) {
  assert(2 * ch < h,
    str("CHAMFER TOO DEEP: 2*ch (", 2 * ch, ") must be < h (", h,
        ") or the top and bottom bevels invert into each other."));
  hull() {
    linear_extrude(0.01) offset(delta = -ch) children(0);
    translate([0, 0, ch]) linear_extrude(h - 2 * ch) children(0);
    translate([0, 0, h - 0.01]) linear_extrude(0.01) offset(delta = -ch) children(0);
  }
}

// A thin (2*eps in Y) slice of a `w`-wide rectangular footprint centred at
// x_c, at a given y, spanning z0..z1 — a hull() waypoint.
//
// WHY THIS EXISTS, not just how to call it: a single hull() from a flush,
// flat-footed root straight to a distant, taller tip does not taper
// cleanly between the two. A convex hull is bounded only by the z-RANGE of
// its inputs, not by either input's own per-point height, so a supporting
// plane tangent to a high point on the tip and a different point on the
// root can sit ABOVE the root's own flat top, directly over the root's own
// footprint — or, in the other direction, sit BELOW where the root should
// already have risen, for a long stretch of y beyond it. Both leaks are
// measured, not theoretical, on this file's own yoke (see yoke_root_y0's
// and yoke_riser_y0/y1's block comments for the actual numbers). The fix
// in both directions is the same: never hull() the root or tip directly:
// hull() them each against a thin, PINNED waypoint like this one instead.
// A convex hull can never exceed the y-range of ITS OWN inputs, so
// whichever tilt the taller/farther partner would otherwise leak backward
// or forward is confined to y <= (or >=) this waypoint's own y — never
// back into a caller's flat, unaffected territory. Get the waypoint's own
// y wrong (place it past the boundary it's meant to hold) and the
// confinement argument stops applying; it is the PINNING, not the shape,
// that does the work. Any single-hull() taper between a flush, flat-footed
// root and a distant, taller tip needs this same treatment — Task 4's arm
// included.
//
// Its own corners still round with fillet_vis, the same as every other
// silhouette in this file: a sharp-cornered box hulled against a smooth
// (fillet_vis-rounded, or round) neighbour leaves the box's own corners as
// visible ridges running the length of the taper, since hull() only
// smooths where BOTH sides are already smooth. Built by rotating a normal
// linear_extrude() 90 deg — that plane is the (w x z-height) cross-section
// this waypoint actually presents to its neighbours, not the XY plane
// chamfer_slab() extrudes from.
//
// Generic (x_c, w — not tied to hole_lone or yoke_arm_w) so Task 4's arm
// can reuse this directly for its own taper instead of re-deriving the
// same rotate-and-offset recipe.
//
// ⚠ SELF-GUARDED, deliberately, the same way chamfer_slab() checks its own
// `2*ch < h` rather than trusting every caller to remember: this module's
// own offset(r=fillet_vis) offset(delta=-fillet_vis) hits the identical
// empty-for-H<=2*fillet_vis collapse as yoke_root_len's and yoke_arm_w's
// own guards, on EITHER of ITS OWN two dimensions (`w` or `z1-z0`) — and a
// caller can reach it through values that look unrelated. Confirmed
// reachable: `m5_len=8` (a length the owner stocks) with `yoke_t=4.0`
// satisfies the M5 engagement window ([3,4]mm) with no other assert
// noticing, yet feeds `taper_wp(..., z0=0, z1=yoke_t)` a height of exactly
// 4.0 — inside the empty zone — for a silent `Volumes: 3` split, three
// sections and two call sites away from here. Guarding every CALL SITE
// individually is what has already failed three times in this part's own
// history (root length, root width, and now this); guarding the shared
// primitive once closes it for every current and future caller instead.
module taper_wp(x_c, w, y, z0, z1) {
  assert(w > 2 * fillet_vis + 1,
    str("TAPER WAYPOINT TOO NARROW FOR ITS OWN FILLET: w (", w,
        ") leaves < 1mm clearance over 2*fillet_vis (", 2 * fillet_vis,
        ") — the offset() round-trip returns EMPTY there, not a smaller ",
        "radius, and this waypoint silently vanishes."));
  assert(z1 - z0 > 2 * fillet_vis + 1,
    str("TAPER WAYPOINT TOO THIN FOR ITS OWN FILLET: z1-z0 (", z1 - z0,
        ") leaves < 1mm clearance over 2*fillet_vis (", 2 * fillet_vis,
        ") — same offset() trap, on this waypoint's height instead of its ",
        "width, and it silently vanishes just the same."));
  translate([x_c - w/2, y + eps, z0])
    rotate([90, 0, 0])
      linear_extrude(2 * eps)
        offset(r = fillet_vis) offset(delta = -fillet_vis)
          square([w, z1 - z0]);
}

/* ---- shared geometry: face_spline ------------------------------
   The toothed tilt joint between the yoke (screen side, Task 3) and the arm
   (handlebar side, Task 4). Both call this directly — it never appears as
   its own assembled `part`; "spline_test" below exists only so the joint
   can be printed and inspected on its own before it is buried inside
   either part, where a bad tooth is far more expensive to notice.

   WHY A FACE SPLINE AND NOT FRICTION: a face spline engages every tooth at
   once, so the load on any one tooth is tiny and FDM's weak axis — strength
   ACROSS layer lines — never governs. That is also what lets the yoke print
   with its bearing face flat on the bed, instead of needing to stand the
   part on edge to put layer lines the "right" way for a friction pivot.
   And because the teeth carry the tilt moment geometrically instead of
   relying on clamp friction, an angle set today is still set in a year — a
   friction pivot on a hub-motor moped vibrates loose and needs periodic
   re-nipping. The spline trades that maintenance item for a print detail.

   GEOMETRY: this is a Hirth-style coupling, not a gear — every tooth is a
   single straight ridge running radially from spline_id/2 to spline_od/2,
   full height (spline_h) at its own centre angle and tapering LINEARLY down
   to zero at the midpoint to each neighbouring tooth. The whole ring is one
   continuous triangular wave in theta (n peaks, n troughs, nothing else)
   rather than n separate points sitting on a plain disc. Two such rings
   mesh when one is turned by exactly half a tooth pitch relative to the
   other and then turned to FACE the first (`male` only ever selects one of
   those two phases) — every peak of one then falls exactly in a trough of
   the other, at all n indexed angles at once, not just a favoured one. This
   only works because the wave is symmetric: shifting it by half a period is
   the same as inverting it (peak <-> trough), so hm(theta) + hf(theta) ==
   spline_h identically, at every angle (hf is hm's own formula evaluated a
   half-period away) — see `mounts/spline-verification.md` for the mesh test
   this claim rests on.

   HOW THE RAMP IS BUILT, AND WHY IT ISN'T ONE hull(). The obvious way to
   build one flank is hull() of two points (trough, at ±half from the
   tooth's centre) and one point (the peak), at both radii — 6 points, one
   hull(). That construction was tried and MEASURED WRONG: hull() joins the
   trough point at radius r_i to the trough point at radius r_o with a
   straight CARTESIAN edge, not a constant-radius arc, and that chord dips
   inboard of the true circle between its ends. The resulting flank BOWS
   away from "height independent of radius" by up to 0.43 mm at mid-radius
   on this part's own numbers (spline_od 40, spline_n 48) — sampled with a
   probe rod through the solid, not eyeballed. Mated against a correctly
   phased partner this bow shows up as real, non-negligible interference
   (tens of mm³ over the full ring), not the near-zero a "provably meshing"
   joint needs. (`linear_extrude(scale=...)` of one radial cross-section was
   tried before that and rejected outright: `scale` shrinks BOTH plan axes
   toward the centroid as it extrudes, so a ridge meant to run the full
   spline_id/2..spline_od/2 span collapses toward a single point at full
   height instead — a starburst of spikes meeting near the bore, not radial
   ridges reaching the tip.)
     The fix is to chain many short hull()s instead of one long one: each
   flank is walked in `nseg` steps from trough to peak, and each step is its
   own hull() of 4 points (2 radii x 2 adjacent theta samples), with the
   height at every sample taken from the exact triangular-wave formula, not
   interpolated from the previous hull. Shrinking the angle per chord
   shrinks the chord's inboard dip much faster than linearly, so a modest
   nseg (8, i.e. 16 short hulls per tooth) brings two mated faces down to a
   fraction of a millimetre of interference at their design distance —
   confirmed the same way, by sampling, not by re-trusting the construction
   because it "should" work this time too (numbers: spline-verification.md).
   Every hull point is dropped in as
   a zero-size marker (`cube(0.001, center=true)`) rather than typed out as
   a hand-wound `polyhedron()`: each short segment is convex by the same
   argument as the single wedge was, so hull() gets every face right
   without anyone hand-winding a face list.

   VERIFYING TWO FACES ACTUALLY MESH IS NOT A ONE-LINE intersection(). A
   whole-ring `intersection(){ male_face; female_face; }` (48 teeth against
   48 teeth, hundreds of small hull() pieces on each side) was tried as the
   mesh proof and gave answers that CONTRADICTED direct measurement at the
   same relative pose — including reporting near-zero interference for a
   deliberately-misaligned (peak-on-peak) pair that a probe at that exact
   angle shows colliding a full spline_h deep. That is CGAL/OpenSCAD Nef
   polyhedron booleans losing their footing on two operands that are each
   already hundreds of thin, near-touching convex pieces — not a defect in
   the modelled solid, confirmed by re-running the identical pair restricted
   to a small probe volume first (via `intersection()` with a thin rod),
   which reproduces the hand-derived answer exactly every time. So: trust a
   restricted (rod- or small-region-limited) `intersection()` for this
   geometry's mesh proof, not the unrestricted whole-ring one — full numbers,
   the `Volumes:` fingerprint that flags the failure, and the rod-probe
   method in enough detail to re-run it: `mounts/spline-verification.md`.

   ORIENTATION (every caller relies on this): the flat, toothless face sits
   at z=0 — that is this instance's own mating/bonding face, whatever the
   caller bolts, glues, or grows it directly out of. Teeth occupy
   z ∈ [base, base+spline_h], trough to peak. To seat a male instance
   against a female one (own base = base_f), mirror the female in Z and
   translate it by `base + base_f + spline_h` — NOT `2*base+spline_h` unless
   the two share a base — so that the two flat backs end up that far apart
   and the root planes come into contact with the teeth fully interleaved
   (derivation, a worked check with two DIFFERENT base values, and the
   corrected seated/misaligned numbers: `mounts/spline-verification.md`).

   ⚠ NO DEFAULTS ON `male` OR `base`, DELIBERATELY — same reasoning as
   `boot_slot`'s missing default for `up` above. `male` selects which of two
   phases a given face is cut at, and phase correctness is a RELATIONSHIP
   BETWEEN TWO INSTANCES, not a property either instance can check alone —
   a caller that gets the female's `male=` wrong (e.g. relying on a
   `male=true` default for what should be the other half) produces a
   peak-on-peak collision that is INDISTINGUISHABLE FROM A CORRECTLY MESHED
   JOINT IN ANY RENDER, including a direct side-on orthographic one —
   confirmed by building that exact mistake and looking at it. OpenSCAD's
   preview draws interpenetrating triangles without resolving the boolean,
   so there is nothing to see wrong. The ONLY way to catch it is the
   restricted-intersection method in `mounts/spline-verification.md` — not
   a render, however careful. Making both arguments required at least turns
   a silently-wrong call into a loud one. */
function spline_pt(r, a, z) = [ r*cos(a), r*sin(a), z ];

// Seating: mirror the partner in Z, translate by base + partner's base +
// spline_h — see ORIENTATION above for the derivation.
module face_spline(male, base) {
  assert(male == true || male == false,
    "face_spline(): `male` must be given explicitly (true or false) — no default. See the ⚠ NO DEFAULTS note above.");
  assert(is_num(base),
    "face_spline(): `base` must be given explicitly — no default. See the ⚠ NO DEFAULTS note above.");

  step  = 360 / spline_n;     // 7.5 deg at the default 48 teeth
  half  = step / 2;
  phase = male ? 0 : half;    // the ONLY difference between the two calls —
                              // see the block comment above for why a
                              // half-step shift is what makes two copies of
                              // the same wave nest instead of collide.

  // Segments per flank (trough->peak); see the block comment above for why
  // this exists at all. 8 (16 short hulls per tooth, 768 total for the
  // whole ring) was the smallest value that got two mated faces' measured
  // interference at their design distance down to a fraction of a
  // millimetre everywhere sampled — comfortably inside FDM's own slop.
  // Raise it if a future spline_n/spline_od combination (a longer chord per
  // segment) reopens a measurable gap; re-run the mesh test either way.
  nseg = 8;

  // One tooth, drawn in its own LOCAL frame (peak at theta=0, base flush
  // with the disc top at z=base); rotate() below places n copies at
  // i*step + phase. `thetas`/`heights` sample the exact triangular wave at
  // 2*nseg+1 points from -half to +half; each adjacent PAIR of samples (at
  // both radii) becomes its own short hull(), chained by the for loop
  // rather than hulled all at once — see the block comment for why.
  module tooth() {
    thetas  = [ for (k = [-nseg : nseg]) k * half / nseg ];
    heights = [ for (t = thetas) spline_h * (1 - abs(t) / half) ];
    for (k = [0 : len(thetas) - 2])
      hull()
        for (r = [spline_id/2, spline_od/2], j = [k, k + 1])
          translate(spline_pt(r, thetas[j], base + heights[j]))
            cube(0.001, center = true);
  }

  difference() {
    union() {
      cylinder(d = spline_od, h = base);
      if (teeth)
        for (i = [0 : spline_n - 1])
          rotate([0, 0, i * step + phase]) tooth();
    }
    // Through the full base-plus-tooth height, eps overshoot both faces —
    // same convention as hole_pattern()/boot_slot() above — rather than
    // just `base`, so a future change that adds material above the disc at
    // small radius doesn't quietly leave the bore blind on one side.
    translate([0, 0, -eps])
      cylinder(d = spline_id, h = base + spline_h + 2 * eps);
  }
}

/* ---- PART: spline_test ------------------------------------------
   Throwaway print of one face alone — proves the tooth geometry (even,
   radial, meshing, bore clear through) before it is buried inside the yoke
   or arm, where a bad tooth costs a lot more print time to notice. */
// base=3 is arbitrary — this part exists only to prove the tooth geometry
// (even, radial, meshing, bore clear through), not to stand in for the
// yoke's or arm's real pedestal thickness, so it's picked for print speed
// (thin) rather than tied to yoke_t the way gauge_t is tied to it below.
module spline_test() { face_spline(male = true, base = 3); }

/* ---- PART: gauge ---------------------------------------------
   Bearing footprint only: a rounded rectangle spanning the bolt pads,
   trimmed to the flat band so it also proves the band assumption. Nothing
   shaped — no pivot, no spline, no cowl — because the point of printing
   this first is to find a wrong hole or a closed slot on a flat plate,
   not after hours of print time on a shaped part. */
gauge_t = yoke_t;   // ⚠ DERIVED, deliberately — do not replace with a literal.
               // Proving the bolt length is one of this gauge's jobs, and it can
               // only do that at the thickness the real joint uses: a 3 mm gauge
               // tested against an 8 mm yoke would prove an engagement nobody
               // ever assembles. Tying it to yoke_t also means the engagement
               // assertions above cover the gauge too, and the two can never
               // drift apart. Costs print time; buys a gauge that tests the
               // actual joint rather than a proxy for it.
gauge_margin = 10;   // room beyond the outer (paired) bolt centres for the
                     // bolt-head land — same on both sides since the pair
                     // is symmetric about the centreline (docs/display-geometry.md).
gauge_top_y = p([0, band_y0])[1];   // this gauge's own top edge, model
                                     // space — fed to boot_slot() below so
                                     // it can check its own reach against it.
module gauge() {
  // Rectangle spans the two outer bolt centres +/- gauge_margin in X, and
  // the flat band's own extent (band_y0..band_y1) in Y — so moving a bolt
  // pad or resizing the band shows up here directly, without tracing back
  // through p().
  difference() {
    linear_extrude(gauge_t)
      offset(r = 6) offset(delta = -6) polygon([
        [p(holes[0])[0] - gauge_margin, p([0, band_y0])[1]],
        [p(holes[1])[0] + gauge_margin, p([0, band_y0])[1]],
        [p(holes[1])[0] + gauge_margin, p([0, band_y1])[1]],
        [p(holes[0])[0] - gauge_margin, p([0, band_y1])[1]] ]);
    hole_pattern(gauge_t);
    boot_slot(gauge_t, slot_reach, gauge_top_y);
  }
}

/* ---- PART: yoke ------------------------------------------------
   The only part that touches the display: bears on the flat band through
   the three bolt pads, stands the lower arm off the chamfer beyond the band,
   and carries the female half of the tilt spline at the pivot. */

yoke_arm_w    = 26;   // width of the arm's root at hole_lone — a bit over the
                       // Ø24 pad it grows out of, because that pad's own
                       // chord is narrower than 26 by the time it reaches
                       // yoke_root_len below its centre (a circle, not a
                       // rectangle) — the wider root flares the transition
                       // into the taper instead of starting from that chord.
                       // ⚠ MUST ALSO clear 2*fillet_vis (asserted below,
                       // mirroring yoke_root_len's own guard just below): the
                       // root is `square([yoke_arm_w, yoke_root_len])`, a
                       // rectangle has TWO dimensions, and the offset(r)/
                       // offset(delta=-r) collapse hits whichever one is
                       // smaller — `square([4,6])` and `square([6,4])` both
                       // come back empty. Fixing this for yoke_root_len alone
                       // left yoke_arm_w with the identical failure, unguarded
                       // (confirmed: yoke_arm_w=4 renders clean, exit 0, no
                       // warning, `Volumes: 3`, bbox still a plausible
                       // 103x90.1x20.5 — check_stl.py would not have caught
                       // it either). 26 has huge margin today; the guard is
                       // for whoever narrows this for weight or print time
                       // later and has no reason to suspect an offset() trap.
yoke_root_len =  6;    // how far (+Y, toward the plate) the arm's flush root
                       // reaches from hole_lone's own pad — must stay inside
                       // the flat band (asserted below) so this reinforcement
                       // still bears, unlike the taper beyond it. ⚠ MUST clear
                       // 2*fillet_vis (asserted below) — not a single unsafe
                       // point but a whole ZONE: swept H = 3.5, 3.9, 3.99, 4.0,
                       // 4.01, 4.1, 5, 6 through `offset(r=fillet_vis)
                       // offset(delta=-fillet_vis) square([26, H])` and every
                       // H <= 2*fillet_vis (4mm) came back EMPTY — not a
                       // smaller fillet, no warning, nothing — while 4.01
                       // already renders normally. The grow-then-shrink round
                       // trip closes the last straight sliver to zero width
                       // everywhere at or under that tangency, not just at
                       // it. That silently dropped the entire arm root, which
                       // is how this part first exported as two disjoint
                       // bodies (CGAL `Volumes: 3`) even though every
                       // face-overlap in the rest of the arm looked fine.
                       // ⚠ THE GUARDS BELOW ARE LAYERED, NOT INDEPENDENT.
                       // Nudging yoke_root_len UP trips SOCKET REACHES THE
                       // TILTED ZONE before RISER TOO SHORT; nudging it DOWN
                       // trips SOCKET REACHES before this fillet guard —
                       // because all three read yoke_root_y0, and that
                       // assert appears earliest in the file. Consistent with
                       // the design (each is still a real, independently
                       // derivable constraint — see each one's own comment),
                       // but a reader chasing one of these by adjusting
                       // yoke_root_len should expect to land on whichever
                       // fires first, not necessarily the one they were
                       // aiming at.
yoke_standoff =  8;    // how far the arm's pivot end lifts clear (+Z, away
                       // from the display) of the chamfer beyond the flat
                       // band. Outside band_y0/band_y1 the shell is no
                       // longer flat (see the FLAT BAND header comment); a
                       // rib still sitting at yoke_t there risks bearing on
                       // that chamfer instead of standing off it. ⚠ MUST
                       // clear yoke_t — asserted below, on yoke_tip_z0 (the
                       // tip's own lowest point, yoke_t+yoke_standoff-
                       // yoke_tip_h). Criterion 1 needs THAT point, not just
                       // the tip's top, at or above yoke_t, or the tip
                       // itself sits back down in the danger zone regardless
                       // of how the taper between root and tip is built.
                       // ⚠ THIS GUARD WAS MISSING FOR A WHILE — a version of
                       // this comment claimed it existed under a name
                       // (`yoke_riser_z1`) that was never actually written
                       // anywhere in the file. Swept yoke_standoff = 1, 3, 5
                       // against that unguarded state: all three rendered
                       // clean (exit 0, no assertion) and produced CGAL
                       // `Volumes: 3` — the exact two-body split this whole
                       // waypoint construction exists to prevent, passing
                       // silently. 6 and 7 already gave `Volumes: 2`, so the
                       // real threshold for THIS assert is yoke_standoff >=
                       // 6; the assert below is the guard that comment
                       // always should have had.
                       // ⚠ 6 clears this assert but now fails a DIFFERENT,
                       // independent one: taper_wp()'s own fillet-margin
                       // guard, on the second riser waypoint's height
                       // (yoke_standoff-1). At standoff=6 that height is
                       // exactly 5, inside the same 1mm safety margin
                       // yoke_root_len's own comment explains (empty only
                       // for H<=4, but a bare 4.01 is already "a different,
                       // thinner-than-intended fillet" — this file asks for
                       // real clearance everywhere, not just clearing the
                       // exact math boundary). So the PRACTICAL minimum,
                       // once both guards are satisfied together, is
                       // yoke_standoff >= 7, not 6 — 8 was already chosen
                       // with margin over either number.
yoke_ch       =  1;    // 45 deg edge-break on every slab-like face this part
                       // adds (the plate, the arm's root) — same purpose as
                       // hole_pattern()'s own countersink, carried to this
                       // part's outer edges so nothing here is a bare 90 deg
                       // print edge. A chamfer, not a round radius, and built
                       // with chamfer_slab()'s hull()-of-slices — deliberately
                       // not minkowski(), which is a CGAL operation and this
                       // file's geometry doesn't get to trust those
                       // (spline-verification.md §3).
yoke_pad_d    = 22;    // bolt-pad land around each of the PAIRED holes
                       // (holes[0]/[1]) in yoke_profile()'s hull(). Named so
                       // yoke_top_y (below) can derive its own "+radius" from
                       // this instead of restating 22/2=11 as a bare literal
                       // — two numbers stating the same fact is exactly the
                       // trap boot_slot()'s own top_y warning exists to
                       // prevent, reintroduced here by two literals instead
                       // of one bad argument. hole_lone's own pad stays a
                       // literal (Ø24, used once, nothing else derives from
                       // it) rather than being named for symmetry alone.

// Southern (more negative model-Y) edge of the arm's flush root — the one
// value that pins where the flat, unaffected-by-the-tip territory ends.
//
// ⚠ A SINGLE hull() FROM THE ROOT ALL THE WAY TO THE TIP LEAKS HEIGHT
// BACKWARD INTO THE ROOT'S OWN FOOTPRINT. The root's own top face is flat
// at yoke_t everywhere on its own — but hull()ing it directly against the
// tip (which reaches z = yoke_t+yoke_standoff+6, taller, and centred far to
// the south) does not just taper cleanly between the two: a convex hull is
// bounded only by the z-RANGE of its inputs, not by either input's own
// per-point height, so a supporting plane tangent to a HIGH point on the
// tip and a DIFFERENT point on the root can sit above the root's own flat
// top even directly above the root's own footprint. Measured, not just
// argued, with a 0.02mm rod (spline-verification.md §4's method) through a
// reconstruction of this exact rejected single-hull() arm, at the current
// yoke_standoff=8: 0mm excess on the bolt's own axis (the hull isn't
// pulled up AT the centre), 1.9mm at the Ø9.5 socket's own sweep boundary
// (hole_lone y - m5_socket_d/2) — the point the socket-clearance criterion
// actually cares about — and 2.5mm at the root's own southern edge
// (yoke_root_y0), the worst point sampled. This is the failure DM-6
// already warns about (the pivot's own height covering the lone M5),
// recurring one level down in the arm's own construction instead of the
// spline's.
//
// Fix: hull() the tip against a thin SLICE of the root's own cross-section
// (below), not the root solid itself, pinned at this one y value. A convex
// hull can never exceed the y-range of its inputs, so whatever tilt hulling
// with the taller tip introduces is confined to y <= yoke_root_y0 + eps —
// south of the root's own territory, checked below against the socket.
yoke_root_y0 = p(hole_lone)[1] - yoke_root_len;

// The lone M5's own socket (criterion: "a socket or key must get to it")
// sweeps a Ø9.5 circle centred on the hole, so it reaches m5_socket_d/2
// south of the hole into the root's own territory. That reach must stay
// NORTH of (numerically greater than) yoke_root_y0 + eps, or the confined
// tilt above would land inside the socket's own sweep instead of outside
// it — the exact failure this whole construction exists to avoid.
//
// ⚠ WHAT THIS PROVES, AND WHAT IT DOESN'T. This (and the matching
// yoke_ev_socket-style probe in the part's own report) only proves
// STRAIGHT-DOWN insertion clearance: nothing sits directly above the head
// along the bolt's own axis. It does NOT prove a ratchet can turn the
// bolt — checked separately (a 6x12mm handle swept from the head): south,
// toward the arm root, it collides within about 6mm of travel (the root's
// own southern edge is only yoke_root_len away); north, away from the arm,
// it is clear for the full length tried. So the honest claim is "the
// socket seats with nothing above it", not "any tool can turn this bolt" —
// the ratchet has to swing away from the arm, not toward it. Worth a line
// in the work order / assembly notes, not just here.
m5_socket_d = 9.5;   // generic 3/8" hex socket, the tool that turns the bolt
assert(p(hole_lone)[1] - m5_socket_d/2 > yoke_root_y0 + eps,
  str("SOCKET REACHES THE TILTED ZONE: the Ø", m5_socket_d,
      " socket's own sweep reaches y=", p(hole_lone)[1] - m5_socket_d/2,
      ", not clear of the confined-tilt boundary at yoke_root_y0+eps=",
      yoke_root_y0 + eps, "."));

// The arm-tip stack's own local height (frustum lead-in + disc, see the
// union below) and, from that, the z its LOWEST point sits at — the value
// yoke_standoff's own header comment promises is guarded. Named so that
// promise is checkable instead of a dangling forward-reference.
//
// Why 6, not 4 or 8: it needs to clear yoke_ch (1) by enough that the
// frustum lead-in reads as a small chamfer on the puck, not a taper that
// IS the puck — at 6 the lead-in is 1/6 (~17%) of the total, in the same
// ballpark as hole_pattern()'s own countersink-to-hole-depth proportion.
// It also needs to stay small enough that this puck doesn't itself need
// the yoke_riser_y0/y1 treatment: hulling its own top (the flat disc the
// spline boss lands on) against its own bottom (the frustum) spans only
// yoke_tip_h itself, not the tens-of-mm y-run that caused the leaks above,
// so a plain two-point stack (no waypoint confinement) is still safe here.
// The real design cost of raising it is direct, not free: yoke_tip_z0's
// own formula below means yoke_standoff must be >= yoke_tip_h (asserted),
// so a taller puck only ever demands a taller standoff for no shape
// benefit — 6 is the smallest value that still satisfies the proportion
// argument above.
yoke_tip_h  = 6;
yoke_tip_z0 = yoke_t + yoke_standoff - yoke_tip_h;

// yoke_standoff's own guard: the tip's lowest point must sit AT OR ABOVE
// yoke_t, or the tip itself — not merely the taper reaching it — sits back
// down in the danger zone. This is the assert a stale comment once claimed
// existed under the name `yoke_riser_z1` (it did not; grep found only the
// comment). Swept, not just derived: yoke_standoff = 1, 3, 5 all rendered
// clean with NO assertion and produced CGAL `Volumes: 3` (a real two-body
// split) before this existed; 6 and 7 already gave `Volumes: 2`, matching
// the >= yoke_t threshold below exactly.
assert(yoke_tip_z0 >= yoke_t,
  str("TIP TOO LOW: yoke_tip_z0 (", yoke_tip_z0, ") sits below yoke_t (",
      yoke_t, ") — the tip end of the arm is back in the danger zone no ",
      "matter how the taper leading to it is built. Needs yoke_standoff >= ",
      yoke_tip_h, " (currently ", yoke_standoff, ")."));

// ⚠ A SECOND, INDEPENDENT convex-hull leak, in the OTHER direction. The
// root-to-tip taper also needs criterion 1 (never bears on the chamfer
// beyond the band): every point south of the band edge must sit at
// z >= yoke_t. Hulling the root (z as low as 0) STRAIGHT to the tip does
// the opposite of the socket leak above — instead of pulling z UP where it
// should stay at yoke_t, a straight line from the root's own z=0 to the
// tip's z (however high) passes through LOW z values for a good stretch of
// y beyond the root, because the hull must contain every point on that
// line, root to tip, and only reaches the tip's height AT the tip.
// Measured (a probe box over the whole danger zone against a
// reconstruction of this exact rejected single-hull() arm, at the current
// yoke_standoff=8): material was found continuously from y=-46.99 (the
// display's own bottom edge) up through y=-24.61 (the band edge, i.e. the
// WHOLE danger zone), with a minimum z of 0.65 — well under yoke_t, sitting
// almost flush against the display's own back-face plane exactly where the
// FLAT BAND comment says the shell chamfers away underneath it.
//
// Fix: two more waypoint slices, exactly as thin (2*eps) and exactly as
// confined (by the same y-bounding argument) as yoke_root_y0's own fix
// above, so that no single hull() spans BOTH a z=0 point and a distant,
// taller one:
//   yoke_riser_y0 (= yoke_root_y0, the root's own edge) at z=[0,yoke_t] —
//     hulled to —
//   yoke_riser_y1 (just north of the band edge) at z=[yoke_t+1, yoke_t+
//     yoke_standoff] — ALREADY at the full standoff height, confined to
//     y >= band edge (never reaches the danger zone) — hulled to —
//   the tip, whose OWN lowest point is now >= yoke_t (yoke_standoff's own
//     guard above) — so this last hull is a convex combination of two
//     inputs that are BOTH already at z >= yoke_t, which by itself
//     guarantees every point of the result is too, everywhere from the
//     band edge to the tip. No interpolation to trust; both known-safe
//     endpoints hulled straight to the danger-zone target.
yoke_riser_y0 = yoke_root_y0;
yoke_riser_y1 = p([0, band_y1])[1] + 2 * eps;
// ⚠ THIS IS ALSO THE ONLY "arm root stays on the band" GUARD. Since
// yoke_riser_y0 is just yoke_root_y0 by another name, this margin (root's
// edge to band edge, less 4*eps) is strictly tighter than plainly requiring
// yoke_root_y0 >= the band edge — so this is the check that actually fires
// first for that failure too. See the note after the fillet assert above.
assert(yoke_riser_y1 < yoke_riser_y0 - 2 * eps,
  str("RISER TOO SHORT: yoke_riser_y0 (", yoke_riser_y0, ") to yoke_riser_y1 (",
      yoke_riser_y1, ") leaves no real span once both waypoints' own 2*eps ",
      "thickness is accounted for — the root barely clears the band with ",
      "too little margin left for this riser to fit ahead of it."));

// Convex hull of the three bolt pads. "Y-truss" (task goal) describes the
// STRUCTURAL layout — three legs off a shared span — not the outline: this
// stays a plain hull(), so it is provably convex (chamfer_slab() below
// requires that of whatever profile it's given, and a notched literal Y
// would violate it silently).
module yoke_profile() {
  hull() {
    for (h = [holes[0], holes[1]]) translate(p(h)) circle(d = yoke_pad_d);
    translate(p(hole_lone)) circle(d = 24);
  }
}

// The flat band, as a 2D rectangle in model space: full display width (never
// the binding edge — yoke_profile() is already narrower than disp_w) by the
// band's own Y extent. Clipping the truss hull to this is what keeps the
// bearing face inside band_y0..band_y1 (criterion 1) — hole_lone's own Ø24
// pad alone reaches past band_y1 without it (see FLAT BAND header comment).
module yoke_band_2d() {
  translate([-disp_w/2, p([0, band_y1])[1]])
    square([disp_w, band_y1 - band_y0]);
}

// This part's own top edge along the boot's X-band, for boot_slot()'s
// top_y contract — NOT band_y0's model-Y top. The two yoke_pad_d pads share
// a Y centre, so the hull's flat cap between them (well inside the boot's
// own ±boot_clear_d/2 X-band, which sits nowhere near either pad) tops out
// at that shared centre plus the pad's own radius — short of the band's
// own upper limit, which is never actually reached by this profile at all.
// Derived from yoke_pad_d, not a second "11" literal — see yoke_pad_d's
// own comment for why that duplication is exactly the failure mode
// boot_slot()'s top_y warning exists to prevent.
yoke_top_y = p(holes[0])[1] + yoke_pad_d/2;

// Bore height: just enough to clear the arm-tip stack and the spline boss's
// own base at the pivot's (x,y) — nothing else of this part reaches that far
// south, so this is the true local material height, not an overshoot
// guess. The boss's teeth get their own through-bore inside face_spline()
// itself (its own eps overshoot), so this bore doesn't need to reach that
// far either.
yoke_pivot_bore_h = yoke_t + yoke_standoff + 3 + spline_h + 2 * eps;

assert(pivot_bolt_clear_d < spline_id,
  str("PIVOT BORE TOO WIDE: exceeds the spline's own bore id — would break ",
      "into the spline's tooth root instead of just clearing the pivot bolt."));

// See yoke_root_len's own comment: at exactly 2*fillet_vis this rectangle's
// offset(r)/offset(delta=-r) fillet returns EMPTY for the whole zone
// H <= 2*fillet_vis, not just exactly at that value (measured — see
// yoke_root_len's own comment for the sweep), which silently drops the
// whole arm root and splits the part in two. A strict margin, not just
// "!=", because 4.01mm (barely over the empty zone) is already a
// different, thinner-than-intended fillet — this needs real clearance,
// not a hair.
assert(yoke_root_len > 2 * fillet_vis + 1,
  str("ARM ROOT TOO SHORT FOR ITS OWN FILLET: yoke_root_len (", yoke_root_len,
      ") leaves < 1mm clearance over 2*fillet_vis (", 2 * fillet_vis,
      ") — the offset() round-trip that fillets it returns EMPTY for the ",
      "whole zone at or under that value, not just a smaller radius, and ",
      "the arm root silently vanishes."));

// The other dimension of the SAME rectangle, and the SAME trap: fixing it
// for yoke_root_len alone did not generalise to yoke_arm_w, and a
// rectangle's offset(r)/offset(delta=-r) collapse hits whichever of its two
// dimensions is smaller. Confirmed the same way: yoke_arm_w=4 with
// everything else unchanged renders clean (exit 0, no warning), CGAL
// `Volumes: 3`, bbox still a plausible 103x90.1x20.5 — check_stl.py's bbox
// check would not catch it either.
assert(yoke_arm_w > 2 * fillet_vis + 1,
  str("ARM ROOT TOO NARROW FOR ITS OWN FILLET: yoke_arm_w (", yoke_arm_w,
      ") leaves < 1mm clearance over 2*fillet_vis (", 2 * fillet_vis,
      ") — same offset() trap as yoke_root_len above, on the rectangle's ",
      "other dimension: EMPTY for the whole zone at or under that value, ",
      "and the arm root silently vanishes."));

// ⚠ NOTE: there is deliberately no separate "arm root off the band" check
// here. yoke_riser_y0 (below) is DEFINED as yoke_root_y0, and RISER TOO
// SHORT's own margin (yoke_riser_y0 must clear yoke_riser_y1, itself
// band_edge + 2*eps, by a further 2*eps) is strictly tighter than simply
// requiring yoke_root_y0 to stay on the band — any yoke_root_len big enough
// to push the root past the band trips RISER TOO SHORT first, every time
// (confirmed: raising yoke_root_len and separately lowering band_y1 both
// hit RISER TOO SHORT before any looser "off the band" threshold could
// fire). A second assert stating the looser condition would never be the
// one that actually catches anything — dead code that reads as a safety
// net — so RISER TOO SHORT is the one guard for both failure modes.

module yoke() {
  difference() {
    union() {
      // 1. Bearing face: the truss hull, clipped to the flat band, with
      //    every edge broken — in-plane (fillet_vis) and top/bottom
      //    (yoke_ch, via chamfer_slab()).
      chamfer_slab(yoke_t, yoke_ch)
        offset(r = fillet_vis) offset(delta = -fillet_vis)
          intersection() {
            yoke_profile();
            yoke_band_2d();
          }

      // 2. Lower arm: a flush, chamfered root at hole_lone (still on the
      //    band), then TWO separate, purpose-built hulls down to the pivot
      //    tip — never one hull spanning the whole run. See the block
      //    comments above yoke_root_y0 and yoke_riser_y0/y1 for the two
      //    independent reasons: a single hull(root, tip) both (a)
      //    measurably pulls the root's own flat top above yoke_t right
      //    where the lone M5's socket needs to pass (up to 2.5mm of extra
      //    material at the root's own southern edge, measured — see
      //    yoke_root_y0's block comment), and (b) leaves the taper sitting
      //    near z=0 for a long stretch of the danger zone beyond the band
      //    (measured minimum z=0.65 across the whole
      //    band-edge-to-display-bottom span — see yoke_riser_y0/y1's block
      //    comment). Each waypoint below is a thin (2*eps) slice of the arm's
      //    own rectangular footprint, existing only to pin where one hull
      //    ends and the next begins — never rendered as a feature in its
      //    own right.
      translate([p(hole_lone)[0] - yoke_arm_w/2, yoke_root_y0, 0])
        chamfer_slab(yoke_t, yoke_ch)
          offset(r = fillet_vis) offset(delta = -fillet_vis)
            square([yoke_arm_w, yoke_root_len]);

      // Stage A: root -> riser top. Confined to y in
      // [yoke_riser_y1-eps, yoke_riser_y0+eps] (a convex hull cannot exceed
      // its inputs' own y-range) — north of the band edge by construction
      // (yoke_riser_y1's own guard), so this stage can plunge from z=0 (the
      // root's own bottom) up to yoke_t+yoke_standoff without any of that
      // low-z material ever reaching the danger zone.
      hull() {
        taper_wp(p(hole_lone)[0], yoke_arm_w, yoke_riser_y0, 0, yoke_t);
        taper_wp(p(hole_lone)[0], yoke_arm_w, yoke_riser_y1, yoke_t + 1, yoke_t + yoke_standoff);
      }

      // Stage B: riser top -> pivot tip. BOTH inputs already sit at
      // z >= yoke_t (the riser top by construction above; the tip by
      // yoke_standoff's own guard) — a convex hull of two inputs that both
      // satisfy z >= yoke_t is itself entirely z >= yoke_t, no matter how
      // it interpolates in between, which is the one guarantee this whole
      // south-of-the-band run (all the way to the tip) actually needs.
      hull() {
        taper_wp(p(hole_lone)[0], yoke_arm_w, yoke_riser_y1, yoke_t + 1, yoke_t + yoke_standoff);

        translate(concat(p(pivot_c), [yoke_tip_z0])) {
          // Bottom rim broken the same way hole_pattern() breaks a hole's
          // rim: a short lead-in frustum, not a bare disc edge. The top
          // stays a plain full-diameter disc — it butts directly against
          // the spline boss above at the same spline_od, so that join is
          // already internal, with nothing exposed left to break there.
          // The two are overlapped by `eps`, not stacked edge-to-edge: a
          // union of two solids meeting at an exactly coincident plane is
          // the same degenerate case hole_pattern()'s own through-cuts
          // overshoot to avoid (see the `eps` comment above) — verified
          // here, not just assumed: without the overlap this split the part
          // into two disjoint bodies (CGAL `Volumes: 3`, caught by
          // check_stl.py's single-body check).
          cylinder(d1 = spline_od - 2*yoke_ch, d2 = spline_od, h = yoke_ch);
          translate([0, 0, yoke_ch - eps])
            cylinder(d = spline_od, h = yoke_tip_h - yoke_ch + eps);
        }
      }

      // 3. Female spline, centred at p(pivot_c), base flush on the arm tip
      //    — overlapped by `eps` for the same coincident-face reason as the
      //    frustum/disc join just above (also verified by the same
      //    Volumes:3 split before this line existed).
      translate(concat(p(pivot_c), [yoke_t + yoke_standoff - eps]))
        face_spline(male = false, base = 3);
    }

    hole_pattern(yoke_t);
    boot_slot(yoke_t, slot_reach, yoke_top_y);
    // Pivot bolt clearance — same diameter Task 4's arm must drill.
    translate(concat(p(pivot_c), [-eps]))
      cylinder(d = pivot_bolt_clear_d, h = yoke_pivot_bore_h);
    // Lead-in where that bore first breaks through real material (the
    // tip-stack frustum's own bottom face, the lowest solid surface at the
    // pivot's own x,y) — same "chamfer, not a bare edge" treatment as
    // hole_pattern()'s M5 countersinks, sized the same way (+1mm over
    // 0.5mm). Everywhere else the bore only ever widens into the spline's
    // own already-open Ø(spline_id) bore, so this one lead-in is the only
    // edge this cut actually exposes.
    translate(concat(p(pivot_c), [yoke_tip_z0]))
      cylinder(d1 = pivot_bolt_clear_d + 1, d2 = pivot_bolt_clear_d, h = 0.5);
  }
}

// Still to come, each in its own task, landing here and wired into the
// selector below:
//   module arm()       — standoff linking the yoke's pivot to the cowl
//   module cap()       — clamp cap that closes the yoke around the bar
//   module cowl()      — rear cowl: brow, reveal, boot clearance, fillets
//                         (DESIGN — COWL above)
//   module brow_test() — throwaway print of the cowl's brow alone, to prove
//                         the 18-20 mm projection before committing the cowl
//   module plate()     — flat test plate carrying just the hole pattern

/* ---- selector ------------------------------------------------ */
part = "gauge";

// ⚠ THE `else assert(false, ...)` IS LOAD-BEARING — do not drop it, and do not
// replace it with a separate list of valid names. An unmatched `part` must fail
// LOUDLY: STL export already exits non-zero on an empty top-level object, but
// PNG export does not — it writes a blank image with no console output at all,
// and Task 6 batches PNG renders, so a typo'd or not-yet-wired part would sit
// in a run of six as a silent blank.
//
// This was first written as a separate `implemented_parts` allow-list checked
// before the chain. That version had two artifacts that could drift: putting a
// name in the list without adding its branch let `part` pass the check, fall
// through the chain unmatched, and reproduce the exact silent-PNG bug the guard
// existed to prevent (verified, 2026-09-13). Keeping the guard as the chain's
// own `else` collapses it to ONE artifact, so there is nothing left to drift.
//
// To add a part: add its `else if` above this line. The guard needs no edit
// to keep WORKING — but its message below is a plain hardcoded string, not
// derived from the chain, so update that string in the same commit or the
// hint text (only the hint, not the logic) goes stale.
if (part == "gauge") gauge();
else if (part == "spline_test") spline_test();
else if (part == "yoke") yoke();
else assert(false,
  str("UNKNOWN PART \"", part, "\" — implemented so far: gauge, spline_test, yoke"));
