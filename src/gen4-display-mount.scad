// ============================================================
//  Chaojie Gen 4 5" display (CJ-V5-04) — BAR MOUNT + REAR COWL
//
//  Design notes: docs/design-notes.md
//  Geometry: docs/display-geometry.md
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
//  ⚠ "gauge", "spline_test", "yoke", "arm" and "cap" are implemented so far
//     (below). "cowl", "brow_test" and "plate" land in later tasks, each
//     wired into the `part = "..."` selector at the same spot. spline_test
//     is a throwaway proof piece for the toothed tilt joint (face_spline(),
//     shared geometry) — it is not one of the assembled parts above; yoke
//     and arm call face_spline() directly and never appear as "spline_test"
//     themselves.
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
base_female = 3;                 // the yoke's own female pedestal thickness
                                // (docs/spline-verification.md §6: "base=3
                                // is the number to build against, not
                                // yoke_t" -- the spline's base is decoupled
                                // from the bearing plate's own thickness on
                                // purpose). Named so yoke()'s own
                                // face_spline() call and Task 6's assembly
                                // seating transform can never drift apart
                                // by one being a literal and the other a
                                // separately-typed copy of the same fact.

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

/* [DESIGN — ARM] the handlebar-side part: clamps the tapered bar, carries the
   male spline that mates the yoke's, and cranks the pivot back over the
   bike's centreline. Measured on the bike — docs/bike-fitment.md. */
bar_d0    = 32.0;   // Ø at the bracket face (the x=0 reference bore_at() uses)
bar_taper = 0.1;    // Ø lost per mm outward. ⚠ THE BORE IS A CONE, NOT A
                    //   CYLINDER: a 1:10 taper, half-angle 2.86°. Across an
                    //   18mm clamp the diameter changes 1.8mm — ~9x print
                    //   tolerance — so a round bore would touch on a LINE at
                    //   its large end only. See bore_at() below.
bar_run   = 20;     // usable straight length before the bar curves upward and
                    // becomes unusable (measured, docs/bike-fitment.md)
clamp_w   = 18;     // clamp width along the bar. ⚠ MUST be <= bar_run
                    // (asserted below) — it is nearly all of it on purpose,
                    // for the longest bearing length the bar allows
clamp_x0  = 1;      // clamp's inboard face, from the bracket face — 1mm of
                    // air so the clamp's own edge never touches the bracket
                    // itself (the taper means it can only creep outboard from
                    // here if it ever moves, never inboard — the bracket
                    // blocks that mechanically)
shim_t    = 1.2;    // inner-tube rubber inside the bore (docs/assembly.md) —
                    // folded into bore_at() so the PRINTED bore is sized for
                    // the rubber-wrapped bar, not the bare metal
arm_len   = 45;     // pivot centre above the BAR CENTRELINE. ⚠ NOT free — see
                    // the assertion below. The clamp body's own top sits
                    // clamp_od/2 above the bar centreline and the spline is
                    // Ø40; below ~45 the spline fouls the clamp and the arm
                    // would have to reach backward instead of up. 45 is the
                    // lowest value that clears it (docs/bike-fitment.md).
arm_crank = 32.5;   // inboard offset (toward the bike's centreline, i.e. -Y in
                    // this part's own frame) so the screen centres on the
                    // bike instead of sitting off to one side of it. The
                    // bracket's right face is 22.5mm off the bike's
                    // centreline and this 18mm clamp centres 10mm beyond
                    // that face, so the clamp's own centre is 32.5mm off —
                    // the arm carries that whole distance back.
function bore_at(x) = bar_d0 - bar_taper*x + 2*shim_t;   // Ø of the PRINTED
                    // bore at distance x from the bracket face (same x as the
                    // table above) — the bare-bar taper plus shim_t of rubber
                    // on both sides of the bore.

clamp_od  = 48;     // clamp body OD. Sets the floor under arm_len above: the
                    // clamp's own top sits clamp_od/2 (24mm) over the bar
                    // centreline, so the spline (Ø40) needs arm_len -
                    // spline_od/2 - clamp_od/2 >= 1mm of air (asserted below)
                    // to clear it — matches the >=45 mm figure in
                    // docs/bike-fitment.md. Also generous enough radial wall
                    // ((48 - bore_at(clamp_x0))/2 ~= 6.85mm at the bore's own
                    // largest end) to carry the two ear bosses below.
pinch_gap = 2.0;    // gap at EACH of the two ear bosses (arm to cap) with the
                    // clamp at rest. ⚠ THE MECHANISM THAT MAKES THIS A CLAMP,
                    // not a rigid ring: without this gap the two ear faces
                    // would meet before the bore ever closed on the bar, and
                    // the two M5s would just crush plastic-on-plastic with
                    // zero squeeze on the bar. Tightening draws the gap shut
                    // and the two half-bores close in on the bar.
ear_d     = 14;     // Ø of each bolt boss (both ears identical). Wraps the
                    // Ø5.5 M5 clearance hole with (14-5.5)/2 = 4.25mm of ASA
                    // on every side — plenty for a boss taking modest clamp
                    // preload, well over the >=3mm engagement/wall figures
                    // used elsewhere in this file.
ear_h     = 10;     // each ear's own reach off the split plane (Z). The CAP's
                    // half (Z from -ear_h to -pinch_gap/2) is the one that
                    // carries the counterbore, so it is the one sized against
                    // ear_cbore_h below (asserted).
ear_x     = clamp_od/2 + ear_d/2 - 3;   // ear centre, off the bore axis (X).
                    // -3mm so the boss overlaps 3mm into the round clamp body
                    // for a solid union instead of two solids just kissing at
                    // a point — same "overlap, don't just touch" reasoning as
                    // every eps-overshoot cut elsewhere in this file, sized
                    // up because this is a structural boss, not a boolean
                    // safety margin.
ear_bolt_d  = 5.5;  // M5 clearance — same figure hole_pattern() uses above
ear_head_d  = 9.5;  // counterbore for the M5 socket head (m5_head_d=8.5) with
                    // 0.5mm of radial air, same margin m5_socket_d gives the
                    // yoke's own tool clearance
ear_cbore_h = 4.5;  // counterbore depth — leaves >=4.5mm of the ~9mm ear
                    // height below it before the clearance hole breaks
                    // through, so the head seats on real material, not air
arm_w       = 20;   // the rising rib's own structural width (Y in this part's
                    // frame) — same role as the yoke's yoke_arm_w, sized the
                    // same way (comfortably over 2*fillet_vis+1, asserted via
                    // taper_wp()'s own shared guard, not repeated here)
arm_tip_h   = 6;    // tip puck height at the pivot before the spline boss —
                    // same construction and same reasoning as the yoke's own
                    // yoke_tip_h (a small lead-in chamfer's worth of material,
                    // not a taper in its own right)
base_male   = 3;    // this male spline's own base thickness. Free choice per
                    // docs/spline-verification.md §6 (the seating formula
                    // holds for any base_male) — 3 is chosen to match the
                    // value spline-verification.md §6 actually re-verified
                    // against the shipped yoke (base_female=3), so the
                    // seating check below is against numbers already proven,
                    // not a fresh, unverified pair.

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
   half-period away) — see `docs/spline-verification.md` for the mesh test
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
   method in enough detail to re-run it: `docs/spline-verification.md`.

   ORIENTATION (every caller relies on this): the flat, toothless face sits
   at z=0 — that is this instance's own mating/bonding face, whatever the
   caller bolts, glues, or grows it directly out of. Teeth occupy
   z ∈ [base, base+spline_h], trough to peak. To seat a male instance
   against a female one (own base = base_f), mirror the female in Z and
   translate it by `base + base_f + spline_h` — NOT `2*base+spline_h` unless
   the two share a base — so that the two flat backs end up that far apart
   and the root planes come into contact with the teeth fully interleaved
   (derivation, a worked check with two DIFFERENT base values, and the
   corrected seated/misaligned numbers: `docs/spline-verification.md`).

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
   restricted-intersection method in `docs/spline-verification.md` — not
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
  //
  // ⚠ TROUGH-VERTEX PULL-BACK — fixes a non-manifold union, does not touch
  // the tooth profile. Un-pulled-back (i.e. thetas running exactly to
  // ±half), the ring was NON-MANIFOLD: 0 boundary edges (nothing is open)
  // but dozens of edges shared by >2 faces (11 at spline_n=12, 80 at
  // spline_n=48) — `docs/spline-verification.md` §7 has the full isolation
  // trail. Root cause: the k=±nseg sample sits at exactly theta=±half,
  // height 0 — the SAME point (mathematically) that the ADJACENT tooth's
  // own copy lands on at its own ±half, since every tooth is the same
  // `tooth()` reached through a DIFFERENT `rotate()` call. Two independent
  // trig paths to a "same" point are not bit-identical, so CGAL's exact
  // arithmetic sees two near- but not exactly-coincident faces meeting
  // face-to-face and leaves a degenerate seam instead of merging them.
  // Confirmed by isolation, not guessed: a lone tooth() is watertight, a
  // tooth() unioned with the base disc is watertight, but two adjacent
  // tooth()s alone (no disc at all) already reproduce the defect — so the
  // fault is specifically the tooth-to-tooth vertex, not the intra-tooth
  // chain (proven fine by the same test) and not the tooth-to-disc join
  // (also proven fine).
  //   Tried and REJECTED: extending each tooth past ±half to overlap the
  // neighbour's first chord (with the wrapped triangular-wave formula, so
  // the extension's height matches the neighbour's real geometry exactly)
  // made it WORSE (4 non-manifold edges on the 2-tooth isolation, up from
  // 1) — two independently-rotated near-duplicate surfaces crossing each
  // other throughout the whole overlap band gives CGAL more to disagree
  // with, not less. Also rejected: enlarging just the shared boundary
  // vertex into a small cube — same failure, same reason (still two
  // independently-rotated near-duplicates, just bigger ones).
  //   The fix that actually works: stop each tooth a HAIR short of the
  // shared boundary instead of reaching it, so the two neighbours never
  // have a vertex at the same place at all. `trough_pullback` moves ONLY
  // the k=±nseg sample inward in theta by a small fraction of the finest
  // existing chord (half/nseg); its height stays exactly 0, so the tooth
  // still touches the disc (still ONE connected body — verified by
  // component count, not just `is_watertight`, after an early version of
  // this fix that changed height too and silently detached every tooth
  // into its own separate island). The sliver this opens up between
  // neighbouring teeth is covered by the disc's own flat top, already at
  // height 0 there, so nothing is left open. No sample other than this one
  // moves — every interior node (everything spline-verification.md probes:
  // half/2, 0, and their mirrors) is untouched, so the tooth PROFILE away
  // from the exact trough point is bit-for-bit what it was.
  //   Sized as a fraction of half/nseg, not a fixed angle, so it scales
  // with both nseg and spline_n automatically. Swept 0.001-0.08 (fraction
  // of one chord) at spline_n = 4, 6, 8, 12, 24, 36, 48, 72, 96, 180: still
  // non-manifold at 0.001 (within CGAL's own numerical noise — barely
  // pulled back at all), clean from 0.005 up at every n tried. 0.05 keeps
  // 10x margin over that measured threshold while moving the trough vertex
  // by well under 0.02mm at spline_od/2 — an order of magnitude below the
  // 0.004-0.026mm contact spread spline-verification.md §5 already treats
  // as FDM-invisible.
  trough_pullback = (half / nseg) * 0.05;

  // ⚠ EVERY SEGMENT NEEDS A z=base SAMPLE TOO, OR THE TOOTH IS HOLLOW.
  // A convex hull's z-extent is bounded by its OWN vertices — so a segment
  // built only from its two profile-height corners (the 4-point hull this
  // used to be: 2 radii x 2 thetas, both at base+height) never reaches any
  // LOWER than min(z_k, z_k+1). Only the one segment adjacent to each
  // trough (whose low end is height 0, i.e. z=base) ever actually touched
  // the disc; every other segment floated a thin (sub-mm) shell above it
  // with nothing filling the gap underneath — a ribbon following the
  // ramp's top surface, not the solid ridge the mesh-proof and the tilt-
  // moment claim both assume. Measured on the bare part before this fix:
  // 3472mm³ total against a ~3431mm³ disc-minus-bore — the teeth were
  // contributing only ~246mm³ of a ~915-930mm³ solid Hirth ridge set (a
  // rod probe at the quarter point found solid material in only a
  // 0.077mm shell out of the local tooth's full height, the rest air).
  //   Fix: hull() 8 points per segment, not 4 — the same 2 radii x 2
  // thetas as before, but at BOTH z=base and z=base+height at each. This
  // does not change the TOP surface at all (a convex hull's upper envelope
  // is set by its highest points; adding points strictly below cannot
  // pull it down, and the same 4 profile points are still in the set) —
  // the mating flank proven in `docs/spline-verification.md` is untouched.
  // It adds a proper bottom face at z=base and sloped side walls down to
  // it, so every segment is a solid prism reaching the disc across its own
  // full theta span, not just at the chain's two ends. Confirmed on the
  // bare face_spline(): teeth now contribute ~934mm³ (n=48), matching the
  // expected solid-ridge figure; still watertight, still 0 non-manifold,
  // still 1 connected component (see docs/spline-verification.md §7 for
  // why: every segment in this loop shares its theta-boundary vertices
  // with its immediate neighbour via the SAME `thetas`/`heights` array —
  // one object, one rotate(), no independently-rotated near-duplicate
  // geometry — the failure mode §7 documents needs two SEPARATE tooth()
  // instances to trigger, and none of that changed here).
  module tooth() {
    thetas  = [ for (k = [-nseg : nseg])
                  (k == -nseg) ? -(half - trough_pullback) :
                  (k ==  nseg) ?  (half - trough_pullback) :
                  k * half / nseg ];
    heights = [ for (k = [-nseg : nseg])
                  (k == -nseg || k == nseg) ? 0 :
                  spline_h * (1 - abs(k * half / nseg) / half) ];
    for (k = [0 : len(thetas) - 2])
      hull()
        for (r = [spline_id/2, spline_od/2], j = [k, k + 1],
             z = [base, base + heights[j]])
          translate(spline_pt(r, thetas[j], z))
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
        face_spline(male = false, base = base_female);
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

/* ---- DESIGN — ARM assertions -----------------------------------
   Bar-fitment and clamp-geometry constraints, local to the arm/cap pair —
   same placement pattern as the yoke's own local assertions above: these
   read values the top-of-file params-only section can't check on its own. */

assert(clamp_x0 + clamp_w <= bar_run,
  str("CLAMP EXCEEDS THE USABLE BAR: clamp_x0+clamp_w (", clamp_x0 + clamp_w,
      "mm) reaches past bar_run (", bar_run, "mm) — beyond that the bar ",
      "curves upward and is unusable. See docs/bike-fitment.md."));

assert(arm_len - spline_od/2 - clamp_od/2 >= 1,
  str("SPLINE FOULS CLAMP: arm_len (", arm_len, ") leaves only ",
      arm_len - spline_od/2 - clamp_od/2, "mm between the Ø", spline_od,
      " spline (straight up off the clamp — the worst case, before any ",
      "inboard crank has moved it clear) and the clamp body's own top. ",
      "Needs >=1mm of air. docs/bike-fitment.md: 45mm is the lowest ",
      "arm_len that clears it."));

assert(ear_x - ear_d/2 > bore_at(clamp_x0)/2 + 1,
  str("EAR BREACHES THE BORE: the ear boss's own inner edge (x=",
      ear_x - ear_d/2, ") comes within 1mm of the bore's own largest ",
      "radius (", bore_at(clamp_x0)/2, ") — the bolt boss would cut into ",
      "the bore instead of standing clear of it."));

assert(ear_head_d + 2 <= ear_d,
  str("COUNTERBORE TOO WIDE FOR ITS OWN EAR: ear_head_d (", ear_head_d,
      ") leaves < 1mm of ASA on a side of the Ø", ear_d, " boss — the M5 ",
      "head counterbore would break out through the boss's own wall."));

assert(ear_cbore_h + 1 <= ear_h - pinch_gap/2,
  str("COUNTERBORE TOO DEEP FOR ITS OWN EAR: ear_cbore_h (", ear_cbore_h,
      "mm) leaves < 1mm of the CAP ear's own ", ear_h - pinch_gap/2,
      "mm of material before the head would punch through the split face."));

// ⚠ LAYERED WITH "EAR BREACHES THE BORE" ABOVE, same as yoke_root_len's own
// layered guards further up this file: at today's values the ear (sitting
// at radius 21, inside clamp_od/2=24) trips EAR BREACHES first for any
// bore growth that would ALSO thin the wall, so this one currently reads
// as never the first to fire. It still protects a different, independently
// derivable fact (material exists between bore and OD at all, regardless
// of whether an ear happens to sit in that gap) and becomes the binding
// check the moment ear_x/ear_d change — verified reachable on its own by
// overriding ear_x=40 (moving the ear out of the way) with bar_d0=44
// (thickening only the bore): EAR BREACHES stays clear (33mm > 24.15mm)
// and this one fires (48-46.3=1.7mm < 4mm) on its own.
assert(clamp_od - bore_at(clamp_x0) >= 4,
  str("CLAMP WALL TOO THIN: clamp_od (", clamp_od, ") over the bore's own ",
      "largest diameter (", bore_at(clamp_x0), ") leaves < 2mm of radial ",
      "wall at the clamp's tightest point."));

arm_pivot_y = clamp_x0 + clamp_w/2 - arm_crank;   // pivot centre, along the
                    // bar axis (this part's own Y) — the clamp's own
                    // Y-midpoint, cranked arm_crank inboard. See
                    // arm_crank's own header comment for the derivation.

tube_ch = 1;    // lead-in bevel on the clamp tube's two open (Y) ends —
                // cosmetic/assembly only (nothing seats against it), same
                // magnitude as yoke_ch elsewhere in this file
ear_ch  = 1;    // edge-break on each ear boss's own two Z-facing ends
arm_ch  = 1;    // edge-break on the tip puck's own lead-in — same role as
                // yoke_ch on the yoke's own tip stack

/* ---- shared geometry: bar clamp ---------------------------------
   arm() and cap() share every one of these so the two halves' bore, OD and
   ear positions can never drift apart the way two hand-typed copies could —
   "one fact, one home" applied inside the file, not just across documents. */

// The tapered through-bore. Ø = bore_at(x) at bike-fitment distance x from
// the bracket face; eps-overshoot at both open ends, same through-cut
// convention as hole_pattern()/boot_slot() above.
// ⚠ NO SEPARATE LEAD-IN CHAMFER HERE, DELIBERATELY. Every other through-hole
// in this file gets one (hole_pattern(), the ear bolts below) because a
// straight bore presents a sharp 90° step to whatever is entering it. This
// bore is already a taper along its ENTIRE length — every point on its own
// wall is already an inclined lead-in surface, by construction, so adding a
// separate chamfer feature would only complicate the one dimension this
// part is measured on (see the "bore is a cone" acceptance check) for no
// real assembly benefit.
module bar_bore() {
  translate([0, clamp_x0 - eps, 0])
    rotate([-90, 0, 0])
      cylinder(d1 = bore_at(clamp_x0), d2 = bore_at(clamp_x0 + clamp_w),
                h = clamp_w + 2 * eps);
}

// The Z>=0 (upper=true) or Z<=0 (upper=false) half of the round clamp
// body — OD only, no bore (bar_bore() is cut once, later, from the union
// of everything, so the half-tube and the bore can never end up cut at
// slightly different places). A constant-clamp_od tube with a small
// lead-in bevel at each open (Y) end, intersected against a half-space box
// to keep only the requested half.
// ⚠ THE MAIN CYLINDER AND EACH END HULL OVERLAP BY eps, NOT JUST TOUCH.
// A first version stopped the main cylinder exactly at clamp_x0+tube_ch and
// started the hull's own full-diameter disc at the SAME Y — two solids
// meeting at an exactly coincident face, the same degenerate case
// hole_pattern()'s and face_spline()'s own eps/pull-back comments warn
// about elsewhere in this file (it happened to render fine here too, per
// CGAL's own `Volumes: 2` == "one healthy solid" convention, confirmed by
// checking it against the already-known-good yoke and gauge — but a
// coincident face is still a fragile thing to leave sitting in the tree
// for a future parameter change to land on). Overshooting by eps, the same
// convention every through-cut in this file already uses, costs nothing
// and removes the class of failure rather than trusting it not to bite.
module clamp_od_half(upper) {
  intersection() {
    union() {
      translate([0, clamp_x0 + tube_ch - eps, 0])
        rotate([-90, 0, 0])
          cylinder(d = clamp_od, h = clamp_w - 2 * tube_ch + 2 * eps);
      hull() {
        translate([0, clamp_x0 - eps, 0])
          rotate([-90, 0, 0]) cylinder(d = clamp_od - 2 * tube_ch, h = 0.001);
        translate([0, clamp_x0 + tube_ch + eps, 0])
          rotate([-90, 0, 0]) cylinder(d = clamp_od, h = 0.001);
      }
      hull() {
        translate([0, clamp_x0 + clamp_w - tube_ch - eps, 0])
          rotate([-90, 0, 0]) cylinder(d = clamp_od, h = 0.001);
        translate([0, clamp_x0 + clamp_w + eps, 0])
          rotate([-90, 0, 0]) cylinder(d = clamp_od - 2 * tube_ch, h = 0.001);
      }
    }
    translate([-clamp_od, clamp_x0 - 1, upper ? 0 : -clamp_od])
      cube([2 * clamp_od, clamp_w + 2, clamp_od]);
  }
}

// One ear's bolt cut, in the ear's OWN local frame (caller translates to
// the boss centre in X,Y; Z=0 here is always the split plane).
// arm_side=true:  plain M5 clearance through the ARM's ear (Z pinch_gap/2
//   .. ear_h), with a small lead-in where the nyloc nut seats on top.
// arm_side=false: the M5 HEAD counterbore, sunk into the CAP's own
//   underside, clearance the rest of the way up to the split face — ⚠
//   "heads counterbored" means the CAP side, so the bolts insert from
//   underneath and the nyloc nuts tighten from on top of the ARM's ears,
//   both accessible without disturbing anything above them.
module ear_bolt_cut(arm_side) {
  if (arm_side) {
    translate([0, 0, pinch_gap/2 - eps])
      cylinder(d = ear_bolt_d, h = ear_h - pinch_gap/2 + 2 * eps);
    translate([0, 0, ear_h - 0.5])
      cylinder(d1 = ear_bolt_d, d2 = ear_bolt_d + 1, h = 0.5 + eps);
  } else {
    translate([0, 0, -ear_h - eps])
      cylinder(d = ear_head_d, h = ear_cbore_h + eps);
    translate([0, 0, -ear_h + ear_cbore_h - eps])
      cylinder(d = ear_bolt_d, h = ear_h - pinch_gap/2 - ear_cbore_h + 2 * eps);
  }
}

// Both ear bosses — round, Z-extruded, so chamfer_slab() applies directly —
// centred on the clamp's own Y-midpoint, symmetric about the bore axis.
//
// ⚠ THE BOSS ALONE ONLY MARGINALLY TOUCHES THE TUBE. ear_x was first
// picked from a tangency check AT Z=0 (the tube's own equator, its widest
// point) — but the boss's own Z-range starts at pinch_gap/2, not 0, and the
// tube's available radius SHRINKS with |Z| (it is round, not a slab). At
// the boss's own far Z (z=ear_h=10) the tube's radius is only
// sqrt((clamp_od/2)^2 - ear_h^2) = 21.8mm — under a millimetre past the
// boss's own inner edge. That sliver still rendered as one connected body
// (checked against the yoke's own `Volumes: 2` == "healthy" baseline), but
// it is exactly the kind of thin, curvature-dependent graze this file
// elsewhere refuses to rely on (the trough-pullback note above, the
// hull()-leak notes on taper_wp()). ear_web() below removes the class of
// failure the same way those fixes do: don't rely on two curved surfaces
// grazing each other — add an explicit, generously-overlapping bridge.
module ears(upper) {
  for (sx = [-1, 1]) {
    translate([sx * ear_x, clamp_x0 + clamp_w/2, upper ? pinch_gap/2 : -ear_h])
      chamfer_slab(ear_h - pinch_gap/2, ear_ch)
        circle(d = ear_d);
    ear_web(upper, sx);
  }
}

// The bridge: a plain hull() between a thin slice AT the boss's own centre
// and a thin slice well inside the tube (clamp_od/2 - 4, i.e. 4mm past the
// tube's own surface at Z=0 — real, unambiguous solid, not a graze), over
// the boss's own Z-span less 1mm at each end (so the bridge stays inside
// the boss's and the tube's own silhouettes and adds no new exposed edge).
// Deliberately narrower in Y than the boss (ear_d - 6) for the same reason.
module ear_web(upper, sx) {
  z0 = (upper ? pinch_gap/2 : -ear_h) + 1;
  z1 = (upper ? ear_h : -pinch_gap/2) - 1;
  hull() {
    translate([sx * ear_x, clamp_x0 + clamp_w/2, (z0 + z1)/2])
      cube([0.02, ear_d - 6, z1 - z0], center = true);
    translate([sx * (clamp_od/2 - 4), clamp_x0 + clamp_w/2, (z0 + z1)/2])
      cube([0.02, ear_d - 6, z1 - z0], center = true);
  }
}

module ear_cuts(arm_side) {
  for (sx = [-1, 1])
    translate([sx * ear_x, clamp_x0 + clamp_w/2, 0])
      ear_bolt_cut(arm_side);
}

/* ---- PART: arm -----------------------------------------------------
   Clamps the tapered bar (its own upper half-tube plus one ear each side),
   carries the male spline up and cranked inboard to the pivot.
   docs/printing.md's own "spline face down" note is right about WHICH way
   up to print (this file authors the part with the spline at high Z — the
   print orientation flips that so the spline's toothed face sits near the
   bed and the clamp bore stays horizontal either way, since the bore's own
   axis is Y here, unaffected by a Z flip) — see the rib comment below for
   why the rib itself is built as a riser + bridge rather than one diagonal,
   which is the detail that actually decides whether this needs support. */
module arm() {
  difference() {
    union() {
      clamp_od_half(upper = true);
      ears(upper = true);

      // Rising rib, in TWO stages rather than one diagonal hull — not for
      // clearance (nothing along this run needs to stay clear the way the
      // yoke's lone-M5 socket and display chamfer did; both waypoints sit
      // at z0 >= clamp_od/2-5 = 19, comfortably clear of the bore, whose
      // own radius never exceeds bore_at(clamp_x0)/2 = 17.15), but for
      // PRINTABILITY. ⚠ NOT BENCH-VERIFIED — this is an angle calculation,
      // not a confirmed print; flag it if a real print disagrees. A single
      // hull from the root (Y=10, z~19-27) straight to the tip
      // (Y=arm_pivot_y=-22.5, z~34-42) rises only ~15-23mm over a 32.5mm
      // run — 55-65° off vertical by either measure, past the ~45° a
      // standard slicer prints unsupported — and the shape is neither a
      // steep member (self-supporting) nor a true bridge (anchored at the
      // SAME height at both ends), which is the shallow overhang FDM
      // handles worst. Splitting the SAME two endpoints into a vertical
      // riser (same Y=10 throughout, root up to the tip's own z-range) then
      // a level bridge (same z-range throughout, root's own Y across to the
      // tip's Y) turns one bad-angle diagonal into one plain vertical wall
      // (trivially self-supporting) plus one true horizontal bridge
      // (32.5mm — inside what stock FDM cooling settings typically span) —
      // same net rise and run, same connected volume, printable without
      // support either way it splits. ⬜ Print `arm` and confirm before
      // trusting this over a real slicer preview.
      hull() {
        taper_wp(0, arm_w, clamp_x0 + clamp_w/2, clamp_od/2 - 5, clamp_od/2 + 3);
        taper_wp(0, arm_w, clamp_x0 + clamp_w/2, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
      }
      hull() {
        taper_wp(0, arm_w, clamp_x0 + clamp_w/2, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
        taper_wp(0, arm_w, arm_pivot_y, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
      }

      // Tip puck (lead-in frustum + disc), then the male spline, flush
      // back at arm_len — same construction and same eps overlaps as the
      // yoke's own tip stack just above.
      translate([0, arm_pivot_y, arm_len - arm_tip_h]) {
        cylinder(d1 = spline_od - 2 * arm_ch, d2 = spline_od, h = arm_ch);
        translate([0, 0, arm_ch - eps])
          cylinder(d = spline_od, h = arm_tip_h - arm_ch + eps);
      }
      translate([0, arm_pivot_y, arm_len - eps])
        face_spline(male = true, base = base_male);
    }

    bar_bore();
    ear_cuts(arm_side = true);

    // Pivot bolt clearance through the tip puck only — face_spline() cuts
    // its own Ø(spline_id) bore through the spline itself, so this covers
    // just the puck below it; the rib further down is never needlessly
    // drilled.
    translate([0, arm_pivot_y, arm_len - arm_tip_h - eps])
      cylinder(d = pivot_bolt_clear_d, h = arm_tip_h + base_male + spline_h + 2 * eps);
    translate([0, arm_pivot_y, arm_len - arm_tip_h])
      cylinder(d1 = pivot_bolt_clear_d + 1, d2 = pivot_bolt_clear_d, h = 0.5);
  }
}

/* ---- PART: cap -------------------------------------------------------
   Closes the clamp around the bar: the lower half-tube plus one ear each
   side, counterbored so the M5 heads sit flush on the underside. Mates
   arm() at the bore and at both ear faces (pinch_gap apart, at rest) —
   both halves are built from the same bar_bore()/clamp_od_half()/ears()
   so there is nothing for the two to disagree about. */
module cap() {
  difference() {
    union() {
      clamp_od_half(upper = false);
      ears(upper = false);
    }
    bar_bore();
    ear_cuts(arm_side = false);
  }
}

/* ---- DESIGN — COWL: additional geometry (Task 5) -----------------
   The header block ([DESIGN — COWL] near the top of the file) already
   carries cowl_wall / brow / reveal / fillet_out / fillet_vis / fillet_in —
   the numbers the acceptance criteria name directly, and NONE of them are
   redefined below. Everything here is DERIVED local geometry the cowl and
   brow_test need that the header doesn't already carry — same placement
   pattern as yoke_arm_w/arm_pivot_y/etc. above: local constants declared
   just before the part(s) that use them. */

// How deep the shell reaches behind the display's rear face (model +Z, same
// sense as boot_proud). Sized on the DEEPEST thing it must clear within its
// own XY footprint: the Ø13 boot standing boot_proud=22.3mm proud — not the
// yoke's own riser, which only reaches yoke_t+yoke_standoff=16mm within this
// footprint (the yoke's own yoke_riser_y0/y1 comments: nothing south of the
// flat band adds height until well outside this footprint, at the pivot).
// +8 leaves the boot 8mm of air before the back cap, and clears the riser by
// ~14mm. Both margins are checked below (CAVITY TOO SHALLOW), and the yoke/
// arm clearance itself is proven for real against the actual STLs, not just
// this arithmetic — see the verify block in the report for check_fit.py.
cowl_depth = boot_proud + 8;

assert(cowl_depth - cowl_wall > boot_proud + 1,
  str("CAVITY TOO SHALLOW FOR THE BOOT: cowl_depth-cowl_wall (",
      cowl_depth - cowl_wall, ") leaves < 1mm of air over the Ø", boot_d,
      " boot standing boot_proud=", boot_proud, "mm proud."));
// ⚠ LAYERED WITH THE BOOT GUARD ABOVE, same as yoke_root_len's own layered
// guards elsewhere in this file: at today's values boot_proud+1 (23.3) is
// always looser than yoke_t+yoke_standoff+2 (18), so shrinking cowl_depth
// alone always trips the BOOT assert first and this one currently reads as
// unreachable. It still protects a different, independently derivable fact
// (the riser fits) and becomes the binding check the moment boot_proud
// shrinks or yoke_standoff grows — confirmed reachable on its own by
// overriding boot_proud=5 (moving the boot out of the way) with
// cowl_depth=15 (thinning only the cavity): BOOT stays clear
// (15-2.4=12.6 > 5+1=6) and this one fires (12.6 < 8+8+2=18) on its own.
assert(cowl_depth - cowl_wall > yoke_t + yoke_standoff + 2,
  str("CAVITY TOO SHALLOW FOR THE YOKE RISER: cowl_depth-cowl_wall (",
      cowl_depth - cowl_wall, ") leaves < 2mm of air over the riser's own ",
      yoke_t + yoke_standoff, "mm reach within this footprint."));
// ⚠ ALSO LAYERED WITH THE BOOT GUARD ABOVE: raising cowl_wall alone shrinks
// cowl_depth-cowl_wall too, so a plain `cowl_wall=10` trips CAVITY TOO
// SHALLOW FOR THE BOOT first (confirmed) — this one still fires on its own
// given a cowl_depth override big enough to clear that guard out of the way
// (confirmed: boot_proud=1, cowl_depth=100, cowl_wall=9.5 clears BOOT and
// hits this one).
assert(disp_corner_r > cowl_wall,
  str("WALL TOO THICK FOR THE CORNER RADIUS: cowl_wall (", cowl_wall,
      ") must stay under disp_corner_r (", disp_corner_r, ") or the inner ",
      "cavity's own corner erosion has no radius left to erode."));

// Bevels ONLY the top (z=h) edge of a linear_extrude(h) of the 2D child —
// the bottom (z=0) stays FULL SIZE and flat, unlike chamfer_slab() which
// erodes both ends. Needed for exactly one reason, found by measuring, not
// guessed: chamfering the main box's FRONT (z=0, open, mating) end at
// fillet_out=3 erodes the OUTER profile there faster than the INNER
// cavity's own constant cowl_wall=2.4 erosion — so right at the tip the
// outer profile becomes a SUBSET of the inner cavity, and outer-minus-inner
// is EMPTY. Confirmed on the exported STL by slicing at y=0: no material
// at all from z=0 to ~z=0.7 in the flat side-wall band, wall thickness
// climbing 0.4 -> 0.9 -> 1.4 -> 1.9 -> 2.3mm from z=1.0 to z=2.9 and only
// reaching the intended 2.4mm at z=3.0 (=fillet_out). The open front rim
// must stay full size; only the closed back cap (whose "inner" boundary is
// the cavity stopping cowl_wall short in Z, not a competing XY erosion)
// can safely take the same treatment on both ends — same hull()-of-slices
// technique as chamfer_slab(), just with the first slice at full size
// instead of eroded.
module chamfer_slab_top(h, ch) {
  assert(ch < h,
    str("CHAMFER TOO DEEP: ch (", ch, ") must be < h (", h, ")."));
  hull() {
    linear_extrude(0.01) children(0);
    translate([0, 0, h - ch]) linear_extrude(0.01) children(0);
    translate([0, 0, h - 0.01]) linear_extrude(0.01) offset(delta = -ch) children(0);
  }
}

// ⚠ THE OUTLINE, ONE PLACE, ONE PARAMETRISED MODULE. inset=0 is the OUTER,
// visible surface: exactly disp_w+2*reveal x disp_h+2*reveal, corner radius
// disp_corner_r. inset=cowl_wall is the INNER cavity: the SAME shape,
// uniformly eroded by cowl_wall — not a second, hand-derived profile, so the
// wall can never drift from cowl_wall by construction rather than by
// coincidence (criterion: "Wall is cowl_wall throughout — uniform, no
// thick-to-thin transitions").
//   Nesting order matters and was VERIFIED, not assumed, before relying on
// it: `offset(delta=-inset) offset(r=disp_corner_r) offset(delta=-disp_corner_r)
// square(...)` on a 160.99x94.98 test case gave EXACTLY R9.000 corners and
// the full 160.99x94.98 bbox at inset=0, and EXACTLY R6.600 (=9-2.4) corners
// and a bbox shrunk by exactly 2*2.4 on each axis at inset=2.4 — a true
// uniform erosion (moves straight edges AND shrinks arc radius by the same
// amount), not a per-vertex miter (which would have collapsed the rounded
// corners to sharp points instead of smaller arcs — the wrong shape for a
// constant-thickness wall).
module cowl_outline(inset = 0) {
  offset(delta = -inset)
    offset(r = disp_corner_r) offset(delta = -disp_corner_r)
      square([disp_w + 2*reveal, disp_h + 2*reveal], center = true);
}

// ---- Brow: a RISER (entirely at z>=0, behind the display's own rear
// face, where it can never collide with the display's own housing) carrying
// a CANTILEVER that projects `brow` mm forward at z<0, confined in Y to
// stay clear of the display's own top edge.
//   NOT a flat slab flush with the box's own top wall projecting straight
// out over z=0 — that was tried first and MEASURED to collide: checked with
// check_fit.py against a plain disp_w x disp_h x disp_d display stand-in
// (the confirmed housing envelope), it reported 14230mm^3 of interference
// spanning the display's own full z<0 depth. The reason is structural, not
// a tuning mistake: the display is a solid block from z=0 back to z=-disp_d
// across its ENTIRE disp_h height, so anything with material at z<0 AND a Y
// within the display's own Y-range (-disp_h/2..disp_h/2) passes straight
// through it. A brow rooted at the box's own top edge (Y up to
// disp_h/2+reveal, well inside the display's own Y-range) can only ever
// reach over the glass by first tunnelling through the housing.
//   The fix: keep the ENTIRE z<0 cantilever at Y > disp_h/2 (clear of the
// display's own footprint), and do all the Y-travel from the box's edge up
// to that safe band at z>=0 instead, where there is nothing to collide
// with. Same "riser then bridge" split as the arm's own rising rib
// elsewhere in this file (see arm()'s own block comment) — there for
// printability, here for clearance, same shape of fix either way: one
// bad-geometry diagonal replaced by two axis-aligned stages.
brow_clear = 3;    // Y clearance the CANTILEVER keeps above the display's
                   // own CONFIRMED top edge (disp_h/2) — deliberately not
                   // zero: this repository has no data on the housing's
                   // edge/bezel profile beyond the overall disp_h envelope
                   // (display-geometry.md confirms the overall size, not a
                   // bezel margin), so a real margin is kept rather than
                   // designing to the very edge of what's confirmed.
brow_root  = 10;   // Y-depth of the CANTILEVER's own footprint (X = full
                   // display width) — comfortably over 2*fillet_vis+1, its
                   // own edge-break never hits the offset() collapse that
                   // bit yoke_root_len/yoke_arm_w elsewhere in this file.
brow_y0 = disp_h/2 + brow_clear;   // cantilever's near (root) edge, Y
brow_y1 = brow_y0 + brow_root;     // cantilever's far edge, Y

riser_y0 = disp_h/2 + reveal - 10;   // riser's own low edge, Y — 10mm into
                   // the box's own still-full-width flat top (>=
                   // disp_corner_r=9, same margin reasoning the old
                   // single-piece brow had), so the union with the box is a
                   // solid, full-width bond, not a corner graze.
riser_h  = 8;      // riser depth, Z (0..riser_h) — comfortably more than the
                   // cantilever's own lap below, so the riser's own far end
                   // is a real cap past where the cantilever stops, not a
                   // coincident face.
cant_lap = 2 * cowl_wall;   // cantilever's own overlap into the riser, past
                   // z=0 — same "overlap, don't just touch" reasoning as
                   // ear_web()'s bridge elsewhere in this file. The riser's
                   // own Y-range fully contains the cantilever's
                   // (riser_y0 <= brow_y0 and brow_y1 is shared), and
                   // riser_h > cant_lap, so this overlap sits entirely
                   // inside the riser's own solid volume — a guaranteed
                   // bond, not a graze.

assert(cant_lap < riser_h,
  str("BROW LAP TOO DEEP: cant_lap (", cant_lap, ") must stay under riser_h (",
      riser_h, ") or the cantilever's own overlap reaches past the riser's ",
      "own far end, into territory that is not actually solid there."));
assert(brow_root > 2*fillet_vis + 1,
  str("BROW ROOT TOO NARROW FOR ITS OWN FILLET: brow_root (", brow_root,
      ") leaves < 1mm clearance over 2*fillet_vis (", 2*fillet_vis,
      ") — same offset() collapse as yoke_root_len/yoke_arm_w elsewhere in ",
      "this file: EMPTY for the whole zone at or under that value, not a ",
      "smaller radius, and the brow's own root silently vanishes."));
assert(2*fillet_vis < brow + cant_lap,
  str("BROW TOO SHORT FOR ITS OWN CHAMFER: brow (", brow, ") + cant_lap (",
      cant_lap, ") = ", brow + cant_lap, " must exceed 2*fillet_vis (",
      2*fillet_vis, ") or chamfer_slab's own top/bottom bevels invert into ",
      "each other. Still true at the low end of the unproven 18-20mm range."));

// The riser: PART OF THE SAME UNIFORM-cowl_wall SHELL as the box and the
// cantilever, not a solid gusset — its own cavity (below) overlaps BOTH the
// box's main cavity (at its low, riser_y0 end) AND the cantilever's cavity
// (at its high, brow_y1 end) in 3D, so all three become ONE continuous void
// with ONE connected outer boundary.
//   ⚠ THIS MATTERS, NOT JUST FOR THE WALL CRITERION. A first version made
// the riser SOLID and stopped the cantilever's own cavity dead at z=0 —
// that cavity, capped at every side (tip, walls, AND the solid riser),
// became a fully SEALED internal void with no path to the outside. CGAL
// reported `Volumes: 3` and a direct check (trimesh split) found 2
// disconnected watertight shells — the cowl's own outer skin, and a second,
// separate, negative-volume shell bounding the orphaned cavity. Both
// pieces individually pass every other check (watertight, 0 boundary, 0
// non-manifold — a sealed internal bubble is a perfectly valid closed
// surface on its own), so ONLY the connected-component count catches it.
// Hollowing the riser too — so every cavity in this part connects to every
// other — fixes both problems (the wall criterion and the component count)
// with the same change, matching how the box's own cavity already stays
// open to the exterior rather than sealed.
module cowl_brow_riser_outer() {
  translate([0, (riser_y0 + brow_y1)/2, 0])
    linear_extrude(riser_h)
      offset(r = fillet_vis) offset(delta = -fillet_vis)
        square([disp_w + 2*reveal, brow_y1 - riser_y0], center = true);
}

module cowl_brow_riser_inner() {
  translate([0, (riser_y0 + brow_y1)/2, -eps])
    linear_extrude(riser_h - cowl_wall + eps)
      offset(delta = -cowl_wall)
        offset(r = fillet_vis) offset(delta = -fillet_vis)
          square([disp_w + 2*reveal, brow_y1 - riser_y0], center = true);
}

// Outer (visible) cantilever surface: R2 (fillet_vis) edge-break at both Z
// ends — the leading tip (the one that actually matters) and the buried lap
// end (harmless, embedded in the riser either way).
module cowl_brow_outer() {
  translate([0, (brow_y0 + brow_y1)/2, -brow])
    chamfer_slab(brow + cant_lap, fillet_vis)
      offset(r = fillet_vis) offset(delta = -fillet_vis)
        square([disp_w + 2*reveal, brow_root], center = true);
}

// Inner cavity, uniformly eroded by cowl_wall from the outer — same
// principle as cowl_outline(), applied to the cantilever's own smaller
// profile. Stops cowl_wall short of the leading tip (z=-brow) so a solid
// end-cap remains there (same "cap it like the box's own back" idea as the
// main box), and runs PAST z=0 into the riser's own cavity (cowl_brow_riser_
// inner(), above) so the two connect into one air space rather than two
// separately-sealed pockets — see that module's own comment for why a
// sealed pocket here is a real defect, not a cosmetic nitpick.
module cowl_brow_inner() {
  translate([0, (brow_y0 + brow_y1)/2, -brow + cowl_wall])
    linear_extrude(brow - cowl_wall + eps)
      offset(delta = -cowl_wall)
        offset(r = fillet_vis) offset(delta = -fillet_vis)
          square([disp_w + 2*reveal, brow_root], center = true);
}

// ---- Bottom opening: ONE wide notch, the yoke's arm through the middle,
// the loom beside it — not two notches (criterion). Open to the display's
// own bottom edge and well beyond (the arm and loom both continue past the
// cowl's own footprint, down to the pivot and the handlebar).
open_w  = 50;    // half of this, 25, clears the Ø40 spline puck's own R20 by
                 // 5mm — checked for real against the exported yoke/arm
                 // STLs with check_fit.py (see the report), not trusted from
                 // this arithmetic alone: a hull()-based taper does not
                 // interpolate its cross-section linearly along its own
                 // axis, per taper_wp()'s own block comment on exactly this
                 // failure mode.
open_y0 = -22;   // upper edge of the opening, model Y. Below this (more
                 // negative than yoke_riser_y1=-24.41) the yoke's Stage-B
                 // taper actually widens toward the pivot and needs the
                 // material gone; above it (Stage A, yoke_riser_y0=-22.29
                 // down to -24.41) the riser only reaches z=16 — comfortably
                 // inside cowl_depth — so a plain wall clears it with no
                 // opening needed. -22 sits north of that boundary by
                 // 2.41mm (an intentional small margin, not the boundary
                 // itself) and clear of the M3 boss band below it.

assert(open_w/2 > spline_od/2 + 3,
  str("OPENING TOO NARROW: open_w/2 (", open_w/2, ") clears the Ø", spline_od,
      " spline puck by only ", open_w/2 - spline_od/2, "mm — needs >3mm."));

// Rounded on its two upper (visible, re-entrant) corners at fillet_vis —
// "every other visible edge". The two lower corners run off the model into
// open air (y=-200, never reached by any real geometry) and have nothing to
// round; letting the SAME offset() round-trip touch them is harmless and
// avoids hand-picking which two of four corners get circle primitives.
module cowl_opening_cut() {
  translate([0, 0, -1])
    linear_extrude(cowl_depth + 2)
      offset(r = fillet_vis) offset(delta = -fillet_vis)
        polygon([
          [-open_w/2, open_y0], [ open_w/2, open_y0],
          [ open_w/2,    -200], [-open_w/2,    -200] ]);
}

// ---- Top retention hook: a small interference tab, not a structural joint
// (the two M3s below are that). Reaches hook_engage past the display's own
// TRUE edge (disp_h/2, doc-Y 0 — a confirmed housing dimension, not a
// guessed chamfer/step detail this repository doesn't have) so the thin ASA
// wall can flex over it on installation: tilt the cowl, hook this tab past
// the display's top edge, then rotate down and drive the M3s (assembly.md:
// "hook the top lip first, then two M3 up through the bottom rim").
hook_engage = 1.5;   // modest, deliberately — an anti-lift locator, not the
                     // retention itself; assembly.md's own two-step order
                     // (hook, THEN screw) says the hook only has to hold
                     // until the M3s go in.
hook_w      = 40;    // centred. Comfortably inside the case-screw pockets at
                     // doc (33.1,84.2)/(127.3,84.2) — display-geometry.md §3
                     // — so it can never foul them regardless of their exact
                     // depth (this file does not model those pockets).

module cowl_hook() {
  translate([0, disp_h/2 + (reveal - hook_engage)/2, cowl_wall/2])
    cube([hook_w, hook_engage + reveal, cowl_wall], center = true);
}

// ---- Two M3s, upward (model +Y) through the bottom rim, into the yoke
// (assembly.md's hardware table). Reachable from the SAME opening the arm
// and loom already use — nothing about this fastener is visible or
// reachable from the front (criterion).
m3_clear_d  = 3.4;   // M3 free-fit clearance, not "close fit" 3.2 — FDM
                     // holes print undersized, and this is a part that
                     // should never need redrilling to assemble.
m3_lead_d   = m3_clear_d + 1;   // same +1mm lead-in convention as
                     // hole_pattern()'s own M5 countersinks above.
m3_boss_d   = 8;     // (8-3.4)/2 = 2.3mm of ASA on every side of the
                     // clearance hole — comfortably over hole_pattern()'s
                     // own margin conventions elsewhere in this file.
m3_boss_len = 14;    // real bearing length for the screw, not just a thin
                     // washer-plate.
m3_x   = open_w/2 + m3_boss_d/2 + 2;   // boss centre, X — just outside the
                     // opening's own flanking wall, with 2mm of solid wall
                     // between the opening's cut edge and the boss's own
                     // bore, so the M3 clearance hole never breaks into the
                     // opening.
m3_y0  = open_y0 - 2;                  // boss's lower (open, driver-access)
                     // end — reachable from the same opening the arm and
                     // loom already use.
m3_y1  = m3_y0 + m3_boss_len;
m3_z_overlap = 0.6;  // how far the boss's PLAIN cylinder reaches past the
                     // back cap's own inner face (z=cowl_depth-cowl_wall) —
                     // a real bond, not a graze (same "overlap, don't just
                     // touch" reasoning as ear_web()'s bridge elsewhere in
                     // this file), kept modest because the root fillet below
                     // reaches further still and both have to stay clear of
                     // the visible outer face.
m3_z_c = cowl_depth - cowl_wall - m3_boss_d/2 + m3_z_overlap;
m3_z_max = m3_z_c + m3_boss_d/2 + fillet_in;   // ⚠ the boss's TRUE highest
                     // reach — NOT m3_z_c+m3_boss_d/2. cowl_m3_boss() below
                     // hulls the plain-diameter run against a WIDER disc
                     // (d=m3_boss_d+2*fillet_in) right at the cap end, for
                     // the R1 root fillet — so the root fillet's own radius
                     // (m3_boss_d/2+fillet_in), not the plain cylinder's, is
                     // what actually decides how close this gets to the
                     // visible surface. Missing this the first time round
                     // let the fillet poke 0.1mm through the back cap
                     // (found by checking the exported bbox against
                     // cowl_depth, not by trusting the assert below alone —
                     // the assert used m3_boss_d/2 only and passed anyway).

assert(m3_x + m3_boss_d/2 < disp_w/2 + reveal - fillet_out - 2,
  str("M3 BOSS TOO FAR OUT: boss edge at x=", m3_x + m3_boss_d/2,
      " comes within 2mm of the shell's own R", fillet_out, " outer chamfer ",
      "(starts at x=", disp_w/2 + reveal - fillet_out, ")."));
assert(m3_z_max < cowl_depth - 0.5,
  str("M3 BOSS BREAKS THE VISIBLE SURFACE: the root fillet reaches z=",
      m3_z_max, ", within 0.5mm of the back cap's own outer face at z=",
      cowl_depth, " — this must include the R1 root fillet's own radius ",
      "(m3_boss_d/2+fillet_in), not just the plain boss diameter, or a ",
      "0.1mm bump on the visible surface passes silently (found once)."));

module cowl_m3_boss() {
  for (sx = [-1, 1])
    // A short root fillet (fillet_in, R1 — "internal fillets at wall-to-rib
    // junctions") where the boss meets the back cap: hull() a slightly
    // larger, shorter disc at the cap end against the plain-diameter run —
    // same 3-point-hull shape chamfer_slab() itself uses, just built by
    // hand here because the boss's own axis (Y) isn't chamfer_slab's native
    // Z, and this fillet is one-sided (only the cap end, not the open end).
    hull() {
      translate([sx * m3_x, m3_y0, m3_z_c]) rotate([-90, 0, 0])
        cylinder(d = m3_boss_d, h = m3_boss_len - fillet_in);
      translate([sx * m3_x, m3_y1 - eps, m3_z_c]) rotate([-90, 0, 0])
        cylinder(d = m3_boss_d + 2*fillet_in, h = eps);
    }
}

module cowl_m3_cut() {
  for (sx = [-1, 1]) {
    translate([sx * m3_x, m3_y0 - eps, m3_z_c]) rotate([-90, 0, 0])
      cylinder(d = m3_clear_d, h = m3_boss_len + 2*eps);
    translate([sx * m3_x, m3_y0 - eps, m3_z_c]) rotate([-90, 0, 0])
      cylinder(d1 = m3_lead_d, d2 = m3_clear_d, h = 0.5);
  }
}

/* ---- PART: cowl --------------------------------------------------
   The visible surface (design-notes.md: "the back of this display faces
   forward on a moped ... a surface people see, not a bracket hidden behind
   a screen"). A uniform cowl_wall shell over the whole rear face, R9
   (disp_corner_r)-cornered footprint with the deliberate reveal gap, a flat
   brow over the glass, ONE bottom opening, and no fastener visible or
   reachable from the front. */
module cowl() {
  difference() {
    union() {
      // Outer shell: R3 (fillet_out) on the BACK (visible, z=cowl_depth)
      // edge only — "the cowl's outer perimeter", read as the silhouette
      // edge you actually see standing in front of the bike. The FRONT
      // (z=0, mating) rim stays full size/flat — see chamfer_slab_top()'s
      // own comment for why: chamfering it too erodes the outer profile
      // there faster than the inner cavity's own erosion, and the wall
      // vanishes for the first ~0.7mm (found by measuring the exported
      // part, not guessed). The front rim is mostly hidden by the 0.5mm
      // reveal anyway, so losing its own edge-break costs nothing visible.
      chamfer_slab_top(cowl_depth, fillet_out) cowl_outline(0);

      cowl_brow_riser_outer();
      cowl_brow_outer();
      cowl_hook();
      cowl_m3_boss();
    }

    // Hollow it — the SAME cowl_outline(), just inset by cowl_wall, so the
    // wall can never drift from cowl_wall by construction. Stops
    // cowl_wall short of z=cowl_depth so a solid back cap remains; open at
    // z=0, the mating face around the display.
    translate([0, 0, -eps])
      linear_extrude(cowl_depth - cowl_wall + eps) cowl_outline(cowl_wall);
    cowl_brow_riser_inner();
    cowl_brow_inner();

    cowl_opening_cut();
    cowl_m3_cut();
  }
}

/* ---- PART: brow_test ----------------------------------------------
   Throwaway strip carrying the brow (riser + cantilever) — the real
   cowl_brow_riser_outer()/cowl_brow_outer() geometry, not a hand-
   approximated stand-in, so what gets held against the screen on the bike
   is the actual feature (including its real standoff off the display), not
   a proxy that could drift from it. ⬜ brow=19 is UNPROVEN (18-20mm is the
   range); print this, hold it against the screen on the bike seated
   normally, and confirm before cowl() is treated as final. Printed SOLID
   (no cavity, unlike the real cowl) — it is a bench check held against
   glass for a minute, not a load-bearing part, and printing it solid is
   simpler and just as fast at this size. */
module brow_test() { cowl_brow_riser_outer(); cowl_brow_outer(); }

/* ---- shared geometry: assembly stand-ins ---------------------------
   Not printed -- context only, so assembly() reads as an installed part
   rather than pieces floating in space. */

// The display itself: disp_w x disp_h x disp_d, corner radius
// disp_corner_r (docs/display-geometry.md), with the Ø(boot_d) cable boot
// standing boot_proud off its back -- the two numbers Task 6 was asked to
// show. Rear face at z=0, the SAME frame yoke()/cowl() already build in via
// p(); the glass sits at z=-disp_d, the boot stands into +z, the same
// direction the cowl and yoke's own riser reach.
module display_stub() {
  translate([0, 0, -disp_d])
    linear_extrude(disp_d)
      offset(r = disp_corner_r) offset(delta = -disp_corner_r)
        square([disp_w, disp_h], center = true);
  translate([p(boot_c)[0], p(boot_c)[1], 0])
    cylinder(d = boot_d, h = boot_proud);
}

// The handlebar: Ø = bar_d0 - bar_taper*x over x = 0..bar_run
// (docs/bike-fitment.md's own table), x measured from the bracket's own
// right face -- which is exactly arm-local Y=0, the same reference
// bar_bore() already builds against (its own cylinder runs Y=clamp_x0 to
// Y=clamp_x0+clamp_w using the identical bore_at(x), x=that same Y). Drawn
// bar_stub_over past bar_run purely so the stand-in does not read as if
// the bar stops dead at the clamp -- that extra length carries no fact of
// its own, unlike everything else in this module.
bar_stub_over = 70;   // presentation only: long enough that the
                      // stand-in reads as a handlebar rather than a stump.
                      // Has no effect on any printed part.
module bar_stub() {
  rotate([-90, 0, 0])
    cylinder(d1 = bar_d0,
              d2 = bar_d0 - bar_taper * (bar_run + bar_stub_over),
              h  = bar_run + bar_stub_over);
}

// The 45 mm centre bracket the clamp butts against (docs/bike-fitment.md).
// Width is DERIVED, not retyped: arm_crank cranks the pivot back from the
// clamp's own midpoint (arm-local Y=clamp_x0+clamp_w/2) past the bracket's
// own right face (Y=0) to the true bike centreline -- so that centreline
// sits bracket_half behind Y=0, and a bracket centred on it, reaching back
// out to its own right face, is 2*bracket_half wide.
bracket_half = arm_crank - clamp_x0 - clamp_w/2;
bracket_w    = 2 * bracket_half;
assert(abs(bracket_w - 45) < 0.01,
  str("BRACKET WIDTH DRIFTED FROM docs/bike-fitment.md's STATED 45mm: got ",
      bracket_w, "mm from arm_crank/clamp_x0/clamp_w -- the doc and the ",
      "model have gone out of sync."));
module bracket_stub() {
  translate([-25, -bracket_w, -25])
    cube([50, bracket_w, 50]);
}

// Seats the arm assembly's male spline against the yoke's female spline.
// The rotate([180,0,0]) at its core is tools/build.sh's own
// "cowl clearance vs yoke/arm/display" block's exact transform, reused
// verbatim (Task 6's own instruction), not re-derived: a 180 deg turn
// about the arm's own local X axis mirrors the arm's Y (bar axis) and Z
// (its own "up off the bore" axis) at once, landing the male spline's own
// flat back (arm Z=arm_len) `base_female+base_male+spline_h` behind the
// yoke's female flat back (shared-frame Z=yoke_t+yoke_standoff) --
// face_spline()'s own ORIENTATION seating formula
// (docs/spline-verification.md §4/§6). This ALONE satisfies the one hard
// requirement a correct seating has (arm-local Z -> shared -Z,
// marker-rod-verified) -- but it is not the only rotation that does: it
// also happens to send arm-local Y (the bar's own axis) to shared Y, which
// reads as the handlebar running the same direction as the DISPLAY's own
// up/down axis instead of its left/right one. arm_seat() below adds
// exactly the remaining freedom (a further turn about the now-shared Z
// axis, the only freedom a correct seating has left) to fix that, without
// touching this hard requirement. Everything built in the arm's local
// frame -- arm(), cap(), bar_stub(), bracket_stub() -- passes through
// arm_seat() to land in the shared display-rear-face frame assembly()
// otherwise builds in directly.
// ⚠ CORRECTED 2026-09-14 (coordinator review, caught by looking at a
// render -- see the task report). The original version below (theta always
// 0) mismeshed nothing -- the spline itself was, and remains, correctly
// seated (rotate([180,0,0]) alone already satisfies the ONE hard
// requirement, arm-local Z -> shared -Z; ground-truth-verified with marker
// rods, not just algebra: a 10mm rod on arm-local +Z lands running along
// shared -Z). But rotate([180,0,0]) alone is only ONE of 48 equally valid
// "clock positions" the spline allows (any multiple of 360/spline_n = 7.5
// deg about the now-shared Z axis re-meshes exactly, since the teeth's
// relative phase comes from face_spline()'s own `male` parameter, not from
// this outer rotation) -- and theta=0 happens to be a bad one to render:
// it puts the bar's own axis (arm-local Y, marker-rod-verified to run
// along shared -Y under rotate([180,0,0]) alone) parallel to the DISPLAY's
// own up/down axis instead of its left/right one, so the assembly render
// showed the handlebar running vertically. theta=90 (=12 steps, still an
// exact multiple of 7.5) turns that same already-correct seating to put
// the bar along shared X instead, matching the display's own "X =
// left/right" convention.
//   theta CANNOT, at any value, bring arm_len ("pivot centre above the BAR
// CENTRELINE", docs/bike-fitment.md -- an arm-local Z quantity) onto
// shared Y instead of shared Z: a rotation about the (already Z-aligned)
// spline axis only ever rotates the OTHER two axes within the plane
// perpendicular to it, by the closed form of SO(3)'s stabiliser of a fixed
// axis -- every valid seating rotation is Rz(theta) composed with this
// same R0, for SOME theta, and none of them moves what R0 already sends to
// Z. So arm_len necessarily lands along shared Z in this render, at every
// mechanically valid theta -- see the task report for what that implies
// (and does not imply) about the pivot's own placement, which is Task 2/3
// design, not this module's to silently re-decide.
module arm_seat() {
  theta = 90;   // see the block comment above -- exact multiple of
               // 360/spline_n, so this re-meshes the spline exactly, not
               // approximately.

  seat_z = yoke_t + yoke_standoff + base_female + base_male + spline_h + arm_len;
  // Re-derived for general theta, not just theta=0's old formula copied
  // over: the male spline's own local position within the arm is
  // (0, arm_pivot_y, arm_len), NOT the arm's local origin, so the
  // translate has to cancel out where THAT point lands under
  // rotate([0,0,theta]) rotate([180,0,0]) -- (0,arm_pivot_y,arm_len) ->
  // (arm_pivot_y*sin(theta), -arm_pivot_y*cos(theta), -arm_len). At
  // theta=0 this collapses to (0, -arm_pivot_y, -arm_len), recovering the
  // original, already-verified translate exactly (p(pivot_c)[1] +
  // arm_pivot_y) -- checked algebraically here and re-checked against a
  // real marker-rod + bar_stub() export (task report), not trusted from
  // the algebra alone.
  translate([
    p(pivot_c)[0] - arm_pivot_y * sin(theta),
    p(pivot_c)[1] + arm_pivot_y * cos(theta),
    seat_z
  ])
    rotate([0, 0, theta])
      rotate([180, 0, 0])
        children();
}

/* ---- PART: assembly -------------------------------------------------
   Every part positioned as it actually assembles (docs/assembly.md's own
   order), plus stand-ins for the display, the handlebar and the bracket it
   clamps to -- distinct colour per part (house rule: same material, a
   monochrome render is hard to interpret) so the pieces read separately.
   The display/yoke/cowl already share one frame with no transform between
   them (docs/design-notes.md); the arm/cap/bar/bracket are seated by
   arm_seat() above. */
module assembly() {
  color("DimGray")      display_stub();
  color("Gold")         yoke();
  color("Crimson")      cowl();
  arm_seat() {
    color("RoyalBlue")    arm();
    color("SeaGreen")     cap();
    color("Silver")       bar_stub();
    color("SaddleBrown")  bracket_stub();
  }
}

/* ---- PART: plate -----------------------------------------------------
   The 4 assembled, printable parts (not gauge/spline_test/brow_test --
   those are throwaway bench proofs, already printed and done per
   docs/printing.md's own print-order list), laid flat in the print
   orientation docs/printing.md specifies, side by side on one plate.
     Every transform below is a plain mirror([0,0,1]) of the part's own Z
   axis, translated first only where the face that must be "down" does not
   already sit at that part's own Z=0 -- verified against the real exported
   bboxes (tools/check_stl.py on stl/gen4-{yoke,arm,cap,cowl}.stl,
   2026-09-14), not guessed:
     - yoke's bearing face is ALREADY at Z=0 as authored (bbox Z 0..20.5)
       -- no flip needed, docs/printing.md's own "bearing face on the bed".
     - cap's split (bore-opening) face is ALSO already at its own Z=0
       (bbox Z -24..0) -- mirroring alone (no extra translate) lands it on
       the bed, docs/printing.md's "bore-side down".
     - arm's spline teeth sit at arm's OWN Z MAXIMUM (bbox Z 0..49.5 =
       arm_len+base_male+spline_h) -- needs mirror AND a translate by that
       same maximum to bring the teeth down to the bed, "spline face down".
     - cowl's visible back cap sits at ITS OWN Z MAXIMUM too (bbox Z
       -19..30.3 = -brow..cowl_depth) -- same mirror-plus-translate-by-max
       treatment, by cowl_depth, "visible face down".
*/
plate_gap = 15;   // clear air between parts -- generous on purpose. This is
                  // a layout aid, not a bed-packing optimiser; the margin
                  // absorbs the parts' own silhouettes not being simple
                  // rectangles (round corners, the yoke's own Y-truss) and
                  // a modest future parameter change, rather than a tight
                  // nest that a small growth could silently overlap.

module plate() {
  // Measured bboxes (tools/check_stl.py, 2026-09-14) -- for spacing only.
  yoke_bb_w = 103.0;  yoke_bb_d = 90.1;   yoke_bb_x0 = -51.49; yoke_bb_y0 = -73.01;
  arm_bb_w  =  70.0;  arm_bb_d  = 61.6;   arm_bb_x0  = -35.00; arm_bb_y0  = -42.50;
  cap_bb_w  =  70.0;  cap_bb_d  = 18.2;   cap_bb_x0  = -35.00; cap_bb_y0  =   0.90;
  cowl_bb_w = 161.0;  cowl_bb_d = 107.48; cowl_bb_x0 = -80.50; cowl_bb_y0 = -47.49;

  row1_y = 0;
  row2_y = cowl_bb_d + plate_gap;
  col1_x = 0;
  col2_x = col1_x + yoke_bb_w + plate_gap;
  col3_x = col2_x + arm_bb_w  + plate_gap;

  // Row 1: cowl alone -- the widest part.
  translate([col1_x - cowl_bb_x0, row1_y - cowl_bb_y0, 0])
    translate([0, 0, cowl_depth]) mirror([0, 0, 1]) cowl();

  // Row 2: yoke, arm, cap.
  translate([col1_x - yoke_bb_x0, row2_y - yoke_bb_y0, 0])
    yoke();
  translate([col2_x - arm_bb_x0, row2_y - arm_bb_y0, 0])
    translate([0, 0, arm_len + base_male + spline_h]) mirror([0, 0, 1]) arm();
  translate([col3_x - cap_bb_x0, row2_y - cap_bb_y0, 0])
    mirror([0, 0, 1]) cap();
}

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
else if (part == "arm") arm();
else if (part == "cap") cap();
else if (part == "cowl") cowl();
else if (part == "brow_test") brow_test();
else if (part == "assembly") assembly();
else if (part == "plate") plate();
else assert(false,
  str("UNKNOWN PART \"", part, "\" — implemented so far: gauge, spline_test, yoke, arm, cap, cowl, brow_test, assembly, plate"));
