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
   the same as inverting it (peak <-> trough), so hm(theta) + hf(theta| male,
   female) == spline_h identically, at every angle — see the mesh test in
   the Task 2 report for the derivation this geometry relies on, including
   the seating offset below.

   A tooth is built as hull() of 6 points: 4 at the trough height (this
   tooth's base — its two angular edges, at both radii) and 2 at the peak
   height (this tooth's own centre angle, at both radii). hull() of those
   six is a single ruled wedge whose flank is correctly scaled at every
   radius, because it is built from two already-correctly-scaled radial
   profiles rather than one profile shrunk toward a centroid as it gains
   height. (`linear_extrude(scale=...)` of one radial cross-section was
   tried first and rejected for exactly that reason: `scale` shrinks BOTH
   plan axes toward the centroid as it extrudes, so a ridge meant to run the
   full spline_id/2..spline_od/2 span collapses toward a single point at
   full height instead — a starburst of spikes meeting near the bore, not
   radial ridges reaching the tip. Confirmed by rendering it, not by
   inspection alone — see the Task 2 report.) The 6 hull points are dropped
   in as zero-size markers (`cube(0.001, center=true)`) rather than typed
   out as a hand-wound `polyhedron()`: the wedge is convex (a ridge line
   centred over its own base footprint always is), so hull() gets every
   face right without anyone hand-winding a face list.

   ORIENTATION (every caller relies on this): the flat, toothless face sits
   at z=0 — that is this instance's own mating/bonding face, whatever the
   caller bolts, glues, or grows it directly out of. Teeth occupy
   z ∈ [base, base+spline_h], trough to peak. To seat a male instance
   against a female one (own base = base_f), mirror the female in Z and
   translate it by `base + base_f + spline_h` — NOT `2*base+spline_h` unless
   the two share a base — so that the two flat backs end up that far apart
   and the root planes come into contact with the teeth fully interleaved
   (derivation and a worked check: Task 2 report). */
function spline_pt(r, a, z) = [ r*cos(a), r*sin(a), z ];

module face_spline(male = true, base = 3) {
  step  = 360 / spline_n;     // 7.5 deg at the default 48 teeth
  half  = step / 2;
  phase = male ? 0 : half;    // the ONLY difference between the two calls —
                              // see the block comment above for why a
                              // half-step shift is what makes two copies of
                              // the same wave nest instead of collide.

  // One tooth, drawn in its own LOCAL frame (peak at theta=0, base flush
  // with the disc top at z=base); rotate() below places n copies at
  // i*step + phase. Nested `for` cross-product: 4 base corners (2 angles x
  // 2 radii) plus 2 peak points (1 angle x 2 radii) = the 6 hull points
  // described above.
  module tooth() {
    hull() {
      for (a = [-half, half], r = [spline_id/2, spline_od/2])
        translate(spline_pt(r, a, base)) cube(0.001, center = true);
      for (r = [spline_id/2, spline_od/2])
        translate(spline_pt(r, 0, base + spline_h)) cube(0.001, center = true);
    }
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

// Still to come, each in its own task, landing here and wired into the
// selector below:
//   module yoke()      — bearing face + pivot + spline (DESIGN — YOKE above)
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
// To add a part: add its `else if` above this line. The guard needs no edit.
if (part == "gauge") gauge();
else if (part == "spline_test") spline_test();
else assert(false,
  str("UNKNOWN PART \"", part, "\" — implemented so far: gauge, spline_test"));
