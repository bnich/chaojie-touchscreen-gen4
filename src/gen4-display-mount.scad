// ============================================================
//  Chaojie Gen 4 5" display (CJ-V5-04) — TWO-SIDED BAR MOUNT + REAR COWL
//
//  Design notes: docs/design-notes.md
//  Geometry: docs/display-geometry.md
//    — taken off the factory manual's §III installation drawing, rendered at
//      600 dpi and calibrated on its own printed dimensions (0.26% agreement).
//      Thread, depth and orientation confirmed on the unit 2026-09-13.
//
//  ⭐ TWO-CLAMP REWORK, 2026-09-15. The original design hung the whole display
//     off ONE narrow yoke arm, necking down through the cowl's opening to a
//     SINGLE spline disc and one clamp — a cantilever on a thin section, on a
//     vehicle with no drivetrain damping. Rejected by the owner: "we should be
//     attaching on both sides of the handlebars. There is a tiny sliver of
//     plastic supporting the entire display." Correct call. The bracket this
//     mount clamps to is 45mm wide; there are now TWO clamps, one butting each
//     of the bracket's two faces, joined by a cross-member that carries the
//     display and grows a spline boss on EACH side — a proper axle with a
//     spline at each end, not one disc taking the whole moment. Grip spreads
//     ~85mm along the bar (2x18mm clamps either side of the 45mm bracket)
//     instead of 18mm on one side of it, and the display centres itself
//     between the two pivots with no crank needed.
//  ⚠ LEFT SIDE OF THE BAR IS UNMEASURED — TEMPORARY VALUE. Only the RIGHT side
//     (docs/bike-fitment.md) was put under calipers. `bar_d0`/`bar_taper`/
//     `bar_run` are ASSUMED to mirror on the left (see the ⬜ flag at their
//     definition below). If the owner measures the left side and it differs,
//     the two clamps are NOT identical parts any more — split `bar_d0_l` etc.
//     out and re-print the left clamp against its own numbers before trusting
//     this mount on the road.
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
//  PARTS:  gauge | yoke | arm | cap | cowl | brow_test | plate | spline_test |
//          pivot_puck_test | yoke_leg_test | yoke_plate_test | assembly |
//          pitch_probe_fixed | pitch_probe_arm
//  Export: openscad -o out.stl -D 'part="gauge"' gen4-display-mount.scad
//  ⚠ `arm`/`cap` are now a SHARED, SYMMETRIC clamp half — the same STL is
//     used on BOTH sides of the bracket (proof: docs/design-notes.md's
//     "why the clamp needs no left/right variant"). Print TWO of each. `yoke`
//     now carries a female spline at EACH end, mirrored about its own
//     vertical centreline, instead of one off to a side.
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
// ⚠ DM-6, RE-DERIVED 2026-09-14 for a spline axis along X (parallel to the
// bar) instead of Z (the display's own normal) — see docs/design-notes.md
// for why the OLD (Z-axis) pivot placement was a defect, not a tunable
// number. With the axis along X the boss's own reach along the axis (a few
// mm, `yoke_tip_h+base_female+spline_h`) sits deep inside the display's own
// X-envelope ([-disp_w/2,disp_w/2]) — there is no X-offset to hide behind
// the way the old design hid behind yoke_standoff's Z-offset. Clearance has
// to come entirely from where the disc sits in Y and Z (see the ⚠ CLEAR THE
// DISPLAY assertion below, right after `holes`/`disp_h` are in scope).
//
// ⭐ TWO-CLAMP REWORK, 2026-09-15: there is no longer a SINGLE `pivot_x`.
// Two splines now grow from the display's centreline, one toward each
// clamp — `pivot_x_r` (right, +X) and `pivot_x_l` (=-pivot_x_r, mirrored).
// Both are DERIVED, not chosen: they have to land each clamp's inboard
// (bracket-butting) face exactly at the real bracket's own two faces
// (±bracket_half — docs/bike-fitment.md's measured 45mm bracket), which
// needs `yoke_tip_h` and `arm_pivot_y`, both defined later in this file —
// so, same reasoning as `pivot_z` below (a plain top-level variable resolves
// in FILE ORDER, unlike a module/function name), the actual assignment sits
// right after `arm_pivot_y`, near the clamp/bracket geometry it depends on,
// not here. `pivot_y`/`pivot_z`/`pivot_clear` stay single values — the two
// splines are coaxial (same Y, same Z), only X differs, by sign.
pivot_y = -70;      // ⚠ CLEAR THE DISPLAY: the minimum that satisfies the
                    // assert below is -(disp_h/2+spline_od/2+pivot_clear) =
                    // -68.99 — -70 clears it with just over 1mm to spare, a
                    // deliberate round number rather than shaving the margin
                    // to the last hundredth. The disc's own near edge
                    // (pivot_y+spline_od/2) must clear the display's bottom
                    // edge (-disp_h/2) by pivot_clear, and that automatically
                    // clears the lone M5's head too (its head sits at doc Y
                    // 63.28, deep inside the display's own footprint — far
                    // closer to the display than to a pivot this far below
                    // it). Re-checked by a SECOND, independent assert against
                    // the M5 head directly, not just inferred.
// pivot_z is defined further down (DESIGN — YOKE, by yoke_standoff) —
// OpenSCAD resolves a plain top-level variable in file order, unlike a
// function/module name (hoisted), so it cannot be defined here: it needs
// yoke_standoff, which itself is not in scope yet at this point in the
// file. Kept out of this block rather than reordering yoke_standoff up to
// here — yoke_standoff belongs with the rest of [DESIGN — YOKE], not pulled
// out of it for one dependency.
pivot_clear = 2;    // margin held past the display's own bottom edge and
                    // (independently) past the lone M5's head — same
                    // magnitude as the old DM-6's own "+2".
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
brow       = 33;                // ⭐ DERIVED, 2026-09-15 (was 19, UNPROVEN —
                                //   see docs/design-notes.md's "The sun brow"
                                //   for why an unverified projection is
                                //   exactly what let the old brow ship
                                //   shading nothing). The TRUE forward
                                //   projection PAST the glass plane
                                //   (z=-disp_d), not off the cowl's own rear
                                //   face — the old `brow` meant the latter,
                                //   which is why 19mm of "projection" left
                                //   the tip 7mm SHORT of the glass instead of
                                //   over it. Chosen so a 45° sun still shades
                                //   ~30mm (~32% of disp_h) of the screen,
                                //   accounting for the visor's own underside
                                //   sitting brow_clear (3mm) above the
                                //   screen's own top edge — shadow =
                                //   brow*tan(E) - brow_clear, not the flush
                                //   brow*tan(E) a zero-offset assumption
                                //   would give. Proven by the permanent shade
                                //   test in tools/build.sh, not just this
                                //   arithmetic.
reveal     = 0.5;               // ⚠ DELIBERATE even shadow gap, cowl to display.
                                //   Not an attempt at zero. A consistent reveal
                                //   reads as designed; a wandering one reads as
                                //   a bad fit. This is the single detail that
                                //   most separates "professional" from "printed".
fillet_out = 3;                 // cowl outer perimeter
fillet_vis = 2;                 // every other visible edge
fillet_in  = 1;                 // internal wall-to-rib junctions (anti-crack)

/* [DESIGN — CLAMP] the handlebar-side part, ⭐ TWO OF THESE NOW (2026-09-15
   two-clamp rework): each clamps the tapered bar and butts one face of the
   centre bracket, carrying the male spline that mates ITS OWN end of the
   yoke's axle. The SAME part is used on both sides — see
   docs/design-notes.md for why mirroring it needs no separate model.
   Measured on the bike — docs/bike-fitment.md. */
bracket_w    = 45;          // the centre bracket's own width — a MEASURED
                            // fact (docs/bike-fitment.md), not derived from
                            // anything below. Both clamps butt its two
                            // faces, ±bracket_half off the bike's centreline.
bracket_half = bracket_w/2;

bar_d0    = 32.0;   // Ø at the bracket face (the x=0 reference bore_at() uses)
bar_taper = 0.1;    // Ø lost per mm outward. ⚠ THE BORE IS A CONE, NOT A
                    //   CYLINDER: a 1:10 taper, half-angle 2.86°. Across an
                    //   18mm clamp the diameter changes 1.8mm — ~9x print
                    //   tolerance — so a round bore would touch on a LINE at
                    //   its large end only. See bore_at() below.
                    // ⬜ MEASURED ON THE RIGHT SIDE ONLY. The left side is
                    //   TEMPORARILY ASSUMED to mirror it exactly (same
                    //   bar_d0/bar_taper/bar_run) — confirm on the bike
                    //   before printing the left clamp for real. If it
                    //   differs, the two clamps stop being one shared part;
                    //   split these three into `_r`/`_l` pairs and give the
                    //   left clamp its own bore_at().
bar_run   = 20;     // usable straight length before the bar curves upward and
                    // becomes unusable (measured, docs/bike-fitment.md;
                    // ⬜ right side only, see bar_d0's own flag above)
clamp_w   = 18;     // clamp width along the bar. ⚠ MUST be <= bar_run
                    // (asserted below) — it is nearly all of it on purpose,
                    // for the longest bearing length the bar allows
clamp_x0  = 0;      // clamp's inboard face, AT the bracket face — ⭐ the two
                    // clamps now BUTT the bracket (owner's own fix: "attach
                    // on both sides of the handlebars"), not stand 1mm clear
                    // of it. The taper still means the clamp can only creep
                    // OUTBOARD if it ever moves (never inboard — the bracket
                    // blocks that mechanically), so butting costs nothing and
                    // buys real end-location + a face the tightened clamp can
                    // bear against instead of floating in a 1mm gap.
shim_t    = 1.2;    // inner-tube rubber inside the bore (docs/assembly.md) —
                    // folded into bore_at() so the PRINTED bore is sized for
                    // the rubber-wrapped bar, not the bare metal
arm_len   = 45;     // pivot centre above the BAR CENTRELINE. ⚠ NOT free — see
                    // the assertion below. The clamp body's own top sits
                    // clamp_od/2 above the bar centreline and the spline is
                    // Ø40; below ~45 the spline fouls the clamp and the arm
                    // would have to reach backward instead of up. 45 is the
                    // lowest value that clears it (docs/bike-fitment.md).
                    // UNCHANGED by the two-clamp rework — this is a per-side
                    // clearance fact (spline vs. ITS OWN clamp body), nothing
                    // to do with how far apart the two clamps sit.
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
arm_w       = 20;   // the rising rib's own structural width — X in this
                    // part's frame (not Y: that stale claim predates the
                    // ⚠ DM-6 axis rework and is corrected here, 2026-09-15,
                    // having been found wrong while tracking down the waist
                    // defect below — taper_wp()'s own `w` argument, which
                    // arm_w feeds, sets the X-span of its profile; every
                    // measured export confirms it (arm.stl's own X bbox is
                    // exactly ±arm_w/2 through the rib)). Same role as the
                    // yoke's leg_w, sized the same way (comfortably over
                    // 2*fillet_vis+1, asserted via taper_wp()'s own shared
                    // guard, not repeated here).
clamp_riser_margin = 2;   // ⭐ WAIST FIX, 2026-09-15 — see the block comment
                    // in arm() above Stage 1 for the defect this closes.
                    // Inboard margin the widened riser keeps off the clamp
                    // tube's own two Y edges (clamp_x0, clamp_x0+clamp_w), so
                    // the riser's own flat Y walls sit INSIDE the tube's real
                    // footprint the whole way up and weld into it, rather
                    // than overhang it — the "fillet into the clamp tube"
                    // shape the task asked for, not a wider free-floating fin.
clamp_riser_y0 = clamp_x0 + clamp_riser_margin;          // 2
clamp_riser_y1 = clamp_x0 + clamp_w - clamp_riser_margin; // 16
                    // 14mm span, centred on the clamp's own Y-midpoint
                    // (arm_pivot_y = clamp_x0+clamp_w/2 = 9) the same way the
                    // old, defective single-Y riser was — this just gives it
                    // real thickness either side instead of none.
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

// Separates the two flat backs once mated — face_spline()'s own ORIENTATION
// seating formula (docs/spline-verification.md §4/§6). A top-level name
// (not a local inside arm_seat(), where this used to live) because the
// cowl's own opening sizing (⚠ DM-6 rework) also needs it, to place its
// right edge against the seated clamp's real reach.
spline_seat = base_male + base_female + spline_h;

$fn = 96;

/* ===================== ASSERTIONS =========================
   These encode the spec's constraints. If you change a number above and one
   of these fires, the number was wrong — not the assertion. */

assert(m5_len - yoke_t <= m5_depth - 1,
  "BOLT BOTTOMS OUT: m5_len - yoke_t must leave >=1mm of air in a 5mm thread.");
assert(m5_len - yoke_t >= 3,
  "TOO LITTLE ENGAGEMENT: need >=3mm of thread engaged.");

// ⚠ DM-6, RE-DERIVED for the X-axis spline (2026-09-14). Two INDEPENDENT
// clearances, not one — with the old Z-axis boss, standing off in Z cleared
// BOTH the display and the M5 head at once (see docs/design-notes.md's
// history of the defect). With the axis along X the boss no longer has a
// Z-offset to hide behind, so each has to be checked in the plane that
// actually matters now — Y and Z, not X.
//
// 1. THE DISC MUST CLEAR THE DISPLAY. The display occupies
// y ∈ [-disp_h/2, disp_h/2], z ∈ [-disp_d, 0], and the boss's own X-extent
// (a few mm around pivot_x) sits deep inside the display's X-envelope, so
// there is no X separation to rely on — only Y, or Z, or both. This model
// clears it in Y alone (pivot_y is far enough below the display that the
// WHOLE disc, at any Z, has y < -disp_h/2): simpler to build and to reason
// about than relying on a diagonal Y+Z margin, and it costs nothing since
// there is open air below the display anyway.
assert(pivot_y + spline_od/2 <= -disp_h/2 - pivot_clear,
  str("PIVOT DISC FOULS THE DISPLAY: the Ø", spline_od, " disc's near edge (y=",
      pivot_y + spline_od/2, ") must clear the display's own bottom edge (y=",
      -disp_h/2, ") by pivot_clear (", pivot_clear, "mm) — Y is the only ",
      "separation available now the axis no longer stands off in Z."));

// 2. THE DISC (AND THE ARM CARRYING IT) MUST CLEAR THE LONE M5's HEAD.
// Automatically satisfied once (1) holds — the M5 sits at doc Y 63.28, deep
// inside the display's own footprint, so anything already clear of the
// display's bottom edge by pivot_clear is clear of the M5 by a much wider
// margin — but re-checked directly and independently, the same way the old
// DM-6 assert checked it directly rather than trusting it to follow from
// something else. This is also the constraint the connecting arm's own
// root/riser staging (yoke_root_y0/yoke_riser_y0/y1 below) exists to
// satisfy for the material BETWEEN the plate and the disc, not just the
// disc itself: that staging keeps the arm flush at <=yoke_t until it is
// past this same Y, exactly as it did for the old design.
assert(pivot_y + spline_od/2 < p(hole_lone)[1] - m5_head_d/2 - pivot_clear,
  str("PIVOT TOO HIGH: re-derived DM-6 — the disc's near edge (y=",
      pivot_y + spline_od/2, ") must clear the lone M5's head (y=",
      p(hole_lone)[1], ", Ø", m5_head_d, ") by pivot_clear (", pivot_clear,
      "mm), or the connecting arm's own reach toward the disc would have to ",
      "cross back over the bolt."));

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

/* ---- PART: pivot_puck_test -----------------------------------------
   Throwaway print of the pivot puck alone (lead-in frustum + full disc,
   yoke_pivot_puck() — see the block comment above pivot_x/pivot_y/pivot_z)
   — proves it is a SOLID disc, not a hollow shell, before it is buried
   inside the yoke where a repeat of the historical hollow-tooth defect
   (docs/spline-verification.md §8: 44mm³ of teeth against a ~915mm³
   expectation, every mesh-health check green anyway) would be far more
   expensive to notice. tools/build.sh checks its volume against the exact
   closed-form frustum+disc formula. */
module pivot_puck_test() { yoke_pivot_puck(); }

/* ---- PART: yoke_leg_test -----------------------------------------------
   ⭐ TWO-CLAMP REWORK: throwaway print/measurement of ONE connecting leg
   alone (root, Stage A/B/C hulls, pivot puck, female spline — yoke_leg(),
   right side) — proves the whole leg is a solid, connected body, not just
   its two already-separately-proven sub-primitives (spline_test,
   pivot_puck_test), before it is buried (twice, mirrored) inside the yoke.
   tools/build.sh checks its volume against those two sub-primitives' own
   measured volumes as a lower bound (a hollow or disconnected leg would
   measure close to puck+spline alone; a solid one measures well past it). */
module yoke_leg_test() { yoke_leg(); }

/* ---- PART: yoke_plate_test ----------------------------------------------
   ⭐ TWO-CLAMP REWORK: throwaway print/measurement of the bearing plate
   alone (yoke_profile() clipped to the flat band, chamfered) — the widened
   version of the plate (two more hull anchors, one per leg root) needs its
   own volume checked independently before trusting the whole-yoke fill
   sanity check that is built from it and yoke_leg_test's own volume. */
module yoke_plate_test() {
  chamfer_slab(yoke_t, yoke_ch)
    offset(r = fillet_vis) offset(delta = -fillet_vis)
      intersection() {
        yoke_profile();
        yoke_band_2d();
      }
}

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

leg_w    = 18;   // ⭐ TWO-CLAMP REWORK (2026-09-15): width of EACH leg's own
                       // root, off the display's centreline at ±pivot_x_r —
                       // no longer under hole_lone's own Ø24 pad (that pad
                       // stays on the plate as a bolt land only; neither leg
                       // grows out of it any more, see yoke_profile()'s own
                       // widened hull below for how the two still union
                       // cleanly onto the plate). 18, not the old 26: narrow
                       // enough that both roots clear the lone M5's own
                       // Ø9.5 socket sweep by a real margin (asserted near
                       // pivot_x_r, below the clamp/bracket geometry it also
                       // needs) — still comfortably over 2*fillet_vis+1
                       // (asserted just below, same offset() trap as ever).
                       // ⚠ MUST ALSO clear 2*fillet_vis (asserted below,
                       // mirroring yoke_root_len's own guard just below): the
                       // root is `square([leg_w, yoke_root_len])`, a
                       // rectangle has TWO dimensions, and the offset(r)/
                       // offset(delta=-r) collapse hits whichever one is
                       // smaller — `square([4,6])` and `square([6,4])` both
                       // come back empty. Fixing this for yoke_root_len alone
                       // left this dimension with the identical failure,
                       // unguarded (confirmed on the old single-arm value:
                       // yoke_arm_w=4 rendered clean, exit 0, no warning,
                       // `Volumes: 3` — check_stl.py's bbox check would not
                       // have caught it either).
yoke_root_len =  6;    // how far (+Y, toward the plate) each leg's flush root
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
yoke_standoff = 12;    // how far the connecting arm lifts clear (+Z, away
                       // from the display) of the chamfer beyond the flat
                       // band, on its way past it. Outside band_y0/band_y1
                       // the shell is no longer flat (see the FLAT BAND
                       // header comment); a rib still sitting at yoke_t there
                       // risks bearing on that chamfer instead of standing
                       // off it. UNCHANGED by the ⚠ DM-6 rework (2026-09-14)
                       // — this concern was always about the material
                       // BETWEEN the plate and the pivot, never about which
                       // way the spline axis itself points, and pivot_z is
                       // still defined as yoke_t+yoke_standoff for exactly
                       // this reason.
                       // ⚠ THIS GUARD USED TO LIVE HERE, ON THE TIP'S OWN Z:
                       // before the rework the tip climbed FURTHER in Z
                       // beyond this standoff (yoke_tip_h more), and a
                       // dedicated assert (long since folded into the
                       // ⚠ DM-6 rework — see pivot_z's own block comment)
                       // checked that its own lowest point still cleared
                       // yoke_t. The rework's tip no longer climbs in Z at
                       // all (it sits AT pivot_z for its whole reach — see
                       // yoke_tip_h's own comment) so that guard's JOB is now
                       // done structurally, by construction, rather than by
                       // a runtime check: there is no longer a "tip's own
                       // lowest point" that could independently sit too low.
                       // Swept historically (pre-rework) at yoke_standoff =
                       // 1, 3, 5: all rendered clean with NO assertion and
                       // produced CGAL `Volumes: 3` (a real two-body split);
                       // 6 and 7 already gave `Volumes: 2` — kept here as the
                       // reason 8 (not something smaller) is still the
                       // chosen value, even though the specific guard that
                       // number used to satisfy no longer exists as such.
                       // ⚠ 6 clears that historical threshold but fails a
                       // DIFFERENT, independent one: taper_wp()'s own
                       // fillet-margin guard, on the second riser waypoint's
                       // height (yoke_standoff-1). At standoff=6 that height
                       // is exactly 5, inside the same 1mm safety margin
                       // yoke_root_len's own comment explains (empty only
                       // for H<=4, but a bare 4.01 is already "a different,
                       // thinner-than-intended fillet" — this file asks for
                       // real clearance everywhere, not just clearing the
                       // exact math boundary). So the PRACTICAL minimum is
                       // yoke_standoff >= 7, not 6.
                       // ⚠ RAISED FROM 8 TO 12, ⚠ DM-6 rework (2026-09-14):
                       // the pivot puck (yoke_pivot_puck()) is now a Ø40
                       // disc CENTRED at z=pivot_z=yoke_t+yoke_standoff, not
                       // a flat face sitting ON TOP of it — so its own
                       // lowest point reaches z=pivot_z-spline_od/2, not
                       // yoke_t+yoke_standoff itself. At the old value (8)
                       // that lowest point was pivot_z-20 = 16-20 = -4: BELOW
                       // the bearing face's own z=0, i.e. below the print
                       // bed in the "bearing face on the bed" orientation
                       // docs/printing.md specifies (caught by checking the
                       // exported bbox, min z=-4.00, not by any assert — see
                       // the new PIVOT BELOW THE BED guard just below). 12
                       // brings the puck's own lowest point to EXACTLY
                       // z=0 (pivot_z-20=20-20=0): touching, not clipping.
// ⚠ DM-6: the pivot's Z coordinate — see the block comment above
// pivot_x/pivot_y/pivot_clear (near yoke_t) for the full re-derivation.
// Defined here rather than there because it needs yoke_standoff, which is
// not yet in scope at that earlier point in the file.
pivot_z = yoke_t + yoke_standoff;

assert(pivot_z - spline_od/2 >= 0,
  str("PIVOT BELOW THE BED: the pivot puck's own lowest point (z=",
      pivot_z - spline_od/2, ") sits below the bearing face's own z=0 — in ",
      "the \"bearing face on the bed\" print orientation (docs/printing.md) ",
      "that is below the bed, not merely unsupported. Needs yoke_standoff >= ",
      spline_od/2 - yoke_t, "."));

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

// The pivot puck's own reach along ITS OWN axis before the spline boss
// proper begins (frustum lead-in + disc, see yoke_pivot_puck() below) —
// same value and role it had before the ⚠ DM-6 rework, just along a
// different axis. It no longer needs a "yoke_tip_z0 / TIP TOO LOW" guard:
// with the axis along X (not Z) the puck sits AT z=pivot_z for its ENTIRE
// reach instead of climbing through a Z-range of its own — Stage A below is
// the only thing that still climbs in Z, and it already arrives at the full
// pivot_z (=yoke_t+yoke_standoff) before Stage B (constant Z) or Stage C
// (the transition into the puck) ever run, so there is no "does the tip's
// own lowest point sit below yoke_t" question left to guard.
//
// Why 6, not 4 or 8: it needs to clear yoke_ch (1) by enough that the
// frustum lead-in reads as a small chamfer on the puck, not a taper that IS
// the puck — at 6 the lead-in is 1/6 (~17%) of the total, in the same
// ballpark as hole_pattern()'s own countersink-to-hole-depth proportion.
yoke_tip_h  = 6;

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

// ⚠ A THIRD stage, new with the ⚠ DM-6 rework: from the riser top down to
// where the round pivot puck begins (yoke_pivot_puck() below). This is a
// DIFFERENT hull() hazard from the two above — the puck's own Z bounding
// box ([pivot_z-spline_od/2, pivot_z+spline_od/2], a full spline_od tall,
// since the puck is a round boss of that diameter) is far taller than the
// riser's own [yoke_t+1, yoke_t+yoke_standoff] band, so a hull() straight
// from the riser to the puck is bounded (per hull()'s own "confined to its
// inputs' own range" rule, the same rule yoke_riser_y0/y1 already lean on)
// by the UNION of both Z-ranges throughout the whole Y-span between them —
// exactly the kind of leak yoke_riser_y0/y1 exists to prevent, just on Z
// instead of the fillet/socket failure those two guard.
//
// The fix here is not another Z-confined waypoint (there is no safe
// intermediate Z to confine to — the puck's own Z-range is what it is) but
// a Y-confined one: yoke_approach_y sits at (just past) the display's own
// bottom edge, and EVERYTHING south of it — the puck included — is already
// past the display's entire housing, where a Z-range leak has nothing left
// to collide with (no chamfer, no shell, nothing). So Stage B (below, a
// second riser-top waypoint slid down to yoke_approach_y at the SAME
// [yoke_t+1, yoke_t+yoke_standoff] Z-range as the first — a pure extension,
// leak-proof for the same reason Stage A's own "both inputs already sit at
// z>=yoke_t" argument is) carries the safe, narrow-Z material all the way
// to the display's edge, and only Stage C (riser-top-at-yoke_approach_y to
// the puck) — the one hull() that actually spans the mismatched Z-ranges —
// runs entirely south of it, where the leak is real but harmless.
yoke_approach_y = -disp_h/2 - 1;
assert(pivot_y + spline_od/2 <= yoke_approach_y,
  str("PIVOT TOO CLOSE: the puck's own near edge (y=", pivot_y + spline_od/2,
      ") must reach at least as far as yoke_approach_y (", yoke_approach_y,
      ") or Stage C's hull() would span back across the display's own edge, ",
      "into territory where its Z-range leak is NOT harmless."));

// Convex hull of the three bolt pads. "Y-truss" (task goal) describes the
// STRUCTURAL layout — three legs off a shared span — not the outline: this
// stays a plain hull(), so it is provably convex (chamfer_slab() below
// requires that of whatever profile it's given, and a notched literal Y
// would violate it silently).
module yoke_profile() {
  hull() {
    for (h = [holes[0], holes[1]]) translate(p(h)) circle(d = yoke_pad_d);
    translate(p(hole_lone)) circle(d = 24);
    // ⭐ TWO-CLAMP REWORK: two more hull anchors, one under each leg's own
    // root (±pivot_x_r, centred on the root's own Y-span) — WITHOUT these
    // the plate's silhouette at yoke_root_y0 is set by hole_lone's own Ø24
    // pad alone, which only reaches to about half of leg_w/2 there (a
    // circle, not a rectangle): the root would still UNION onto the plate
    // (they overlap), but only by a couple of mm — a graze, not the
    // generous, unambiguous overlap this file insists on everywhere else
    // (ear_web()'s own bridge exists for exactly this reason). Sized
    // leg_w+4 (2mm bigger than the root on each side) so the hull's own
    // bulge there comfortably outgrows the root rectangle it has to cover,
    // not just touch it.
    for (sx = [-1, 1])
      translate([sx * pivot_x_r, yoke_root_y0 + yoke_root_len/2])
        circle(d = leg_w + 4);
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
// Bore LENGTH along X now (the bore runs along the pivot's own axis, ⚠ DM-6
// re-derived) — just enough to clear the puck plus a little of the spline's
// own base; the teeth get their own through-bore inside face_spline() itself.
yoke_pivot_bore_len = yoke_tip_h + base_female + spline_h + 2 * eps;

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
// for yoke_root_len alone did not generalise to leg_w, and a rectangle's
// offset(r)/offset(delta=-r) collapse hits whichever of its two dimensions
// is smaller. Confirmed the same way on the old single-arm value:
// yoke_arm_w=4 with everything else unchanged rendered clean (exit 0, no
// warning), CGAL `Volumes: 3` — check_stl.py's bbox check would not have
// caught it either.
assert(leg_w > 2 * fillet_vis + 1,
  str("LEG ROOT TOO NARROW FOR ITS OWN FILLET: leg_w (", leg_w,
      ") leaves < 1mm clearance over 2*fillet_vis (", 2 * fillet_vis,
      ") — same offset() trap as yoke_root_len above, on the rectangle's ",
      "other dimension: EMPTY for the whole zone at or under that value, ",
      "and the leg root silently vanishes."));

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

// ⭐ TWO-CLAMP REWORK: ONE connecting leg, built once for the RIGHT side
// (positive X, `pivot_x_r`) — root, Stage A/B/C hulls, pivot puck and female
// spline, otherwise IDENTICAL to how the old single arm was built (see the
// block comments above `yoke_root_y0`/`yoke_riser_y0`/`yoke_riser_y1`/
// `yoke_approach_y` for why each stage exists — none of that changed, only
// WHERE in X it happens: `pivot_x_r` in place of the old, single, display-
// centred `p(hole_lone)[0]`). `yoke()` below calls this once directly for
// the right leg and once through `mirror([1,0,0])` for the left — NOT a
// second, hand-derived copy. This is safe (produces the CORRECT, not just a
// plausible, left leg) for two independent reasons, both argued in
// docs/design-notes.md: (1) every piece built here — the rectangular
// root/risers and the round puck — is already left-right symmetric about its
// own local X=0 axis, so mirroring reproduces the identical shape; (2) the
// female spline's own tooth pattern (phase=0, `face_spline(male=false,...)`
// starts its ring at theta=0 with step=7.5°, an arithmetic sequence
// symmetric under negation) is provably self-symmetric under a mirror about
// any plane containing its own growth axis — so the mirrored female half
// mates its own (also self-symmetric) mirrored male half exactly as well as
// the un-mirrored pair does, without re-deriving a second rotation by hand.
module yoke_leg() {
  // Root: a flush, chamfered pad on the flat band, still at yoke_root_y0
  // (hole_lone's own Y — shared by BOTH legs, unaffected by the X move) but
  // centred at pivot_x_r instead of under hole_lone. yoke_profile()'s own
  // hull was widened (above) so this unions onto the plate generously, not
  // by a graze.
  translate([pivot_x_r - leg_w/2, yoke_root_y0, 0])
    chamfer_slab(yoke_t, yoke_ch)
      offset(r = fillet_vis) offset(delta = -fillet_vis)
        square([leg_w, yoke_root_len]);

  // Stage A: root -> riser top. Confined to y in
  // [yoke_riser_y1-eps, yoke_riser_y0+eps] (a convex hull cannot exceed
  // its inputs' own y-range) — north of the band edge by construction
  // (yoke_riser_y1's own guard), so this stage can plunge from z=0 (the
  // root's own bottom) up to yoke_t+yoke_standoff without any of that
  // low-z material ever reaching the danger zone.
  hull() {
    taper_wp(pivot_x_r, leg_w, yoke_riser_y0, 0, yoke_t);
    taper_wp(pivot_x_r, leg_w, yoke_riser_y1, yoke_t + 1, yoke_t + yoke_standoff);
  }

  // Stage B: riser top -> the display's own edge, at the SAME Z-range
  // as Stage A's own ending waypoint — a pure Y-extension, not a taper,
  // so it cannot leak in Z (both inputs share one Z-range) the same way
  // Stage A cannot. See yoke_approach_y's own block comment for why this
  // stage stops exactly there and hands off to Stage C rather than
  // reaching the puck directly.
  hull() {
    taper_wp(pivot_x_r, leg_w, yoke_riser_y1, yoke_t + 1, yoke_t + yoke_standoff);
    taper_wp(pivot_x_r, leg_w, yoke_approach_y, yoke_t + 1, yoke_t + yoke_standoff);
  }

  // Stage C: the display's own edge -> the pivot puck. The one hull() that
  // spans mismatched Z-ranges (rectangle vs the full-diameter round puck) —
  // safe ONLY because yoke_approach_y's own assert keeps this ENTIRE stage
  // at y <= yoke_approach_y, past the display's own housing, where a Z leak
  // has nothing to touch (see yoke_approach_y's block comment).
  hull() {
    taper_wp(pivot_x_r, leg_w, yoke_approach_y, yoke_t + 1, yoke_t + yoke_standoff);
    yoke_pivot_puck();
  }

  // Female spline, growing +X off the puck. rotate([0,90,0]) turns
  // face_spline()'s own local Z (its growth axis) into world +X; its local X
  // and Y (the disc's own plane) land in world -Z and Y respectively, so the
  // disc ends up in the Y-Z plane as required. Root at x=pivot_x_r+
  // yoke_tip_h, overlapped by `eps` back into the puck for the same
  // coincident-face reason as every other stacked-solid join in this file.
  translate([pivot_x_r + yoke_tip_h - eps, pivot_y, pivot_z])
    rotate([0, 90, 0])
      face_spline(male = false, base = base_female);
}

// The right leg's own pivot-bolt clearance cuts — mirrored by yoke() below
// for the left, same reasoning as yoke_leg() itself.
module yoke_leg_bore() {
  translate([pivot_x_r - eps, pivot_y, pivot_z])
    rotate([0, 90, 0])
      cylinder(d = pivot_bolt_clear_d, h = yoke_pivot_bore_len);
  // Lead-in where the bore first breaks through real material (the puck's
  // own root face, the end AWAY from the spline — the near face as the bolt
  // is offered up from that side).
  translate([pivot_x_r, pivot_y, pivot_z])
    rotate([0, 90, 0])
      cylinder(d1 = pivot_bolt_clear_d + 1, d2 = pivot_bolt_clear_d, h = 0.5);
}

module yoke() {
  difference() {
    union() {
      // 1. Bearing face: the truss hull, clipped to the flat band, with
      //    every edge broken — in-plane (fillet_vis) and top/bottom
      //    (yoke_ch, via chamfer_slab()). UNCHANGED by the two-clamp rework
      //    other than yoke_profile()'s own widened hull, above.
      chamfer_slab(yoke_t, yoke_ch)
        offset(r = fillet_vis) offset(delta = -fillet_vis)
          intersection() {
            yoke_profile();
            yoke_band_2d();
          }

      // 2. TWO legs, mirrored about the display's own centreline (X=0) —
      //    see yoke_leg()'s own block comment for why mirroring the whole
      //    leg (root, risers, puck AND its female spline) is correct, not
      //    just convenient.
      yoke_leg();
      mirror([1, 0, 0]) yoke_leg();
    }

    hole_pattern(yoke_t);
    boot_slot(yoke_t, slot_reach, yoke_top_y);
    // Pivot bolt clearance, both legs.
    yoke_leg_bore();
    mirror([1, 0, 0]) yoke_leg_bore();
  }
}

// The pivot puck: frustum lead-in + full disc, built exactly as before (the
// same two cylinder() calls, same yoke_ch/yoke_tip_h reasoning) but wrapped
// in rotate([0,90,0]) so it grows along world X from (pivot_x_r,pivot_y,
// pivot_z) instead of along Z from a flat plate — see docs/design-notes.md
// for the full history of the defect this fixes. Right side only — the left
// puck is `mirror([1,0,0])` of this same shape, inside yoke_leg()'s own
// mirrored call, not a second instance built here.
module yoke_pivot_puck() {
  translate([pivot_x_r, pivot_y, pivot_z])
    rotate([0, 90, 0]) {
      // Bottom rim broken the same way hole_pattern() breaks a hole's rim: a
      // short lead-in frustum, not a bare disc edge. The top stays a plain
      // full-diameter disc — it butts directly against the spline boss
      // beyond it at the same spline_od, so that join is already internal,
      // with nothing exposed left to break there. The two are overlapped by
      // `eps`, not stacked edge-to-edge, for the same coincident-face reason
      // as everywhere else in this file (verified by the same Volumes:3
      // split before this line existed).
      cylinder(d1 = spline_od - 2*yoke_ch, d2 = spline_od, h = yoke_ch);
      translate([0, 0, yoke_ch - eps])
        cylinder(d = spline_od, h = yoke_tip_h - yoke_ch + eps);
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

// ⭐ WAIST FIX, 2026-09-15. clamp_riser_margin must leave a real span, or
// clamp_riser_y0/y1 invert and the riser collapses back toward the exact
// defect this whole rework exists to remove — a hull() between two
// waypoints at (nearly) the same Y is a paper-thin fin (measured on the
// pre-fix geometry: 0.2mm, 4mm² — see arm()'s own block comment above
// Stage 1). A strict margin, not just ">0", so a future edit gets a real
// riser, not a technically-nonzero sliver.
assert(clamp_riser_y1 - clamp_riser_y0 >= 10,
  str("RISER TOO NARROW: clamp_riser_y1-clamp_riser_y0 (",
      clamp_riser_y1 - clamp_riser_y0, "mm) is too close to the single-Y ",
      "knife-edge this fix exists to avoid — need a real, load-bearing span."));

// ⚠ SAME FORMULA, DIFFERENT (STRONGER) REASON since the ⚠ DM-6 rework. Before,
// the spline's disc lay in the local X-Y plane (axis Z) while the clamp's own
// round cross-section lies in the local X-Z plane — different planes, so
// this was a deliberately CONSERVATIVE stand-in ("as if" the two were
// coplanar circles) for the worst case (no crank). Now the male spline's
// disc ALSO lies in the local X-Z plane (axis Y, ⚠ DM-6 re-derived — see the
// block comment above pivot_x/pivot_y/pivot_z), so at the worst-case Y (no
// crank, straight above the clamp) the two really ARE two coplanar circles
// in the exact same X-Z plane: the clamp (radius clamp_od/2, centred on the
// bore axis) and the spline (radius spline_od/2, centred at Z=arm_len). The
// same inequality that used to be a conservative bound is now an EXACT
// clearance condition for that worst case, which is why the number (45mm)
// did not need to change even though the axis did.
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

// The joint's own "which of 48 clock positions" choice — clamp_seat() (near
// the assembly modules below) reads this, not a hard-coded local. A plain
// top-level parameter, not baked into clamp_seat() itself, so
// `openscad -D arm_seat_theta=7.5 ...` can render or export the assembly at
// a different mesh-exact tilt WITHOUT editing the file — exactly what
// tools/build.sh's own pitch-test needs to do repeatably. Must stay an
// exact multiple of 360/spline_n (7.5°) to re-mesh the teeth exactly rather
// than approximately (docs/spline-verification.md's meshing proof only
// holds there); 0 is the reference pose every OTHER render/check in this
// file uses.
arm_seat_theta = 0;

arm_pivot_y = clamp_x0 + clamp_w/2;   // pivot centre, along the bar axis
                    // (this part's own Y) — the clamp's own Y-midpoint. ⭐ NO
                    // CRANK any more (2026-09-15 two-clamp rework): the old
                    // single arm cranked this inboard so its one spline
                    // landed on the display's own centreline; now each
                    // clamp's spline lands wherever its own Y-midpoint seats
                    // to (see pivot_x_r below) and the display centres
                    // itself between the TWO pivots instead.

// ⭐ TWO-CLAMP REWORK — the two pivot X-positions, DERIVED here (not chosen)
// now that this file's own file-order rule (see pivot_y's own block comment,
// near the top of [DESIGN — YOKE]) is satisfied: `yoke_tip_h` (1117) and
// `spline_seat` (320) are both already assigned above this point, and so is
// `bracket_half` (near bar_d0). This is the same closed-form clamp_seat()
// (near the assembly modules below) always solved for the OLD single
// arm_crank — "what local-Y offset makes the seated clamp's inboard
// (Y=clamp_x0) face land exactly at the real bracket's own face (shared
// X=bracket_half)" — just solved directly for pivot_x_r instead of solving
// for arm_crank and hoping bracket_w came out to 45 (the OLD assert two
// screens down used to check that after the fact; there is nothing left to
// drift now, so that assert is gone too).
//   Setting local Y = clamp_x0 = 0 (the clamp's own inboard, bracket-butting
// face) in clamp_seat()'s translate formula and solving
// bracket_half == 0 + (pivot_x_r + yoke_tip_h + spline_seat - arm_pivot_y)
// for pivot_x_r gives the line below. pivot_x_l is its mirror image — see
// docs/design-notes.md for why mirroring the whole joint (not re-deriving a
// second rotation) is what this file actually builds.
pivot_x_r = bracket_half - yoke_tip_h - spline_seat + arm_pivot_y;
pivot_x_l = -pivot_x_r;

// LEG ROOT CROWDS THE LONE M5's SOCKET: each leg's root (yoke_leg(), above
// the arm/clamp assertions) sits at pivot_x_r ± leg_w/2 in X, at the SAME Y
// hole_lone's own Ø9.5 socket sweep (m5_socket_d, defined with the yoke's
// own assertions) occupies — the Y-only "SOCKET REACHES THE TILTED ZONE"
// assert up there says nothing about whether the roots also crowd the
// socket sideways, now that they are no longer centred under hole_lone.
assert(pivot_x_r - leg_w/2 > m5_socket_d/2 + 2,
  str("LEG ROOT CROWDS THE LONE M5's SOCKET: the leg root's own inner edge ",
      "(x=", pivot_x_r - leg_w/2, ") comes within ",
      pivot_x_r - leg_w/2 - m5_socket_d/2, "mm of the Ø", m5_socket_d,
      " socket sweep centred on hole_lone (x=0) — needs >2mm clear. Narrow ",
      "leg_w, or accept a larger pivot_x_r."));

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
      // (Y≈arm_pivot_y+arm_tip_h=-16.5, z~34-42) rises only ~15-23mm over a
      // ~26.5mm run — still well past the ~45° a
      // standard slicer prints unsupported — and the shape is neither a
      // steep member (self-supporting) nor a true bridge (anchored at the
      // SAME height at both ends), which is the shallow overhang FDM
      // handles worst. Splitting the SAME two endpoints into a vertical
      // riser (same Y throughout, root up to the tip's own z-range) then
      // a level bridge (same z-range throughout, root's own Y across to the
      // tip's Y) turns one bad-angle diagonal into one plain vertical wall
      // (trivially self-supporting) plus one true horizontal bridge
      // (inside what stock FDM cooling settings typically span) —
      // same net rise and run, same connected volume, printable without
      // support either way it splits. ⬜ Print `arm` and confirm before
      // trusting this over a real slicer preview.
      //
      // ⭐ WAIST DEFECT, found by eye by the owner ("enough material holding
      // the clamp to the handlebars to the toothed piece... It looks very
      // thin") and confirmed by a section scan (tools/build.sh, added
      // 2026-09-15): this Stage-1 "vertical riser" used to be built from TWO
      // taper_wp() waypoints at the SAME y (clamp_x0+clamp_w/2) — one at the
      // root's own z-band, one at the bridge's. taper_wp() is ALWAYS thin
      // (2*eps = 0.2mm) in Y by construction (it is a hull() waypoint
      // marker, not a solid — see its own block comment); hull()ing two
      // marker slices that share the SAME y therefore CANNOT gain any real Y
      // thickness (a convex hull is bounded by the union of its inputs' own
      // Y-range, the same rule this file leans on everywhere else — here it
      // was working against the design instead of protecting it). The result
      // measured as a genuine 0.2mm-thick, 20mm-wide fin — 4mm² of holding
      // cross-section — running from z=19 (where the round clamp tube's own
      // section has already tapered to nothing) up to z=27, the ENTIRE
      // structural link from the clamp to the spline for a stretch of the
      // load path where the spline puck itself hasn't yet grown wide enough
      // to make up the difference. Every existing check passed: watertight,
      // 0 boundary, 0 non-manifold, 1 component, a plausible total volume,
      // clearance clean, render pixel-normal — because none of them measured
      // a cross-section, only the whole part's outer skin or its total fill.
      //   Fix: give the riser a REAL Y-span (clamp_riser_y0..clamp_riser_y1,
      // defined with arm_w above) instead of a single Y, by hull()ing FOUR
      // waypoints (two Y positions x the same two z-bands as before) rather
      // than two. Both Y positions sit 2mm inboard of the clamp tube's own
      // edges (clamp_riser_margin), so the riser's flat Y walls weld into
      // real tube material the whole way up rather than overhang it — the
      // "fillet into the clamp tube" the task asked for, not a wider
      // free-floating fin. Measured after the fix (tools/build.sh's new
      // load-path scan): minimum cross-section in this rib is now ~280mm²,
      // comfortably over the 200mm² floor and in line with its neighbours.
      hull() {
        taper_wp(0, arm_w, clamp_riser_y0, clamp_od/2 - 5, clamp_od/2 + 3);
        taper_wp(0, arm_w, clamp_riser_y1, clamp_od/2 - 5, clamp_od/2 + 3);
        taper_wp(0, arm_w, clamp_riser_y0, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
        taper_wp(0, arm_w, clamp_riser_y1, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
      }
      // ⚠ DM-6 RE-DERIVED: ending waypoint moves from arm_pivot_y to
      // arm_pivot_y+arm_tip_h — the puck now grows along Y (below), so its
      // own ROOT (the end that unions into this bridge) sits arm_tip_h
      // further from the clamp than the spline's own start, not AT
      // arm_pivot_y the way the old Z-growing puck's root was.
      hull() {
        taper_wp(0, arm_w, clamp_x0 + clamp_w/2, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
        taper_wp(0, arm_w, arm_pivot_y + arm_tip_h, arm_len - arm_tip_h - 5, arm_len - arm_tip_h + 3);
      }

      // Tip puck (lead-in frustum + disc), then the male spline. ⚠ DM-6
      // RE-DERIVED: the axis is now Y, not Z (see the block comment above
      // pivot_x/pivot_y/pivot_z on the yoke side) — rotate([90,0,0]) turns
      // this stack's own local Z (its growth axis) into local -Y, so it
      // grows from the puck's root at (0,arm_pivot_y+arm_tip_h,arm_len) down
      // to the spline's own flat back at (0,arm_pivot_y,arm_len) instead of
      // climbing in Z off a flat plate. clamp_seat() below is what lines this
      // local-Y axis up with the bar (and the yoke's own pivot axis) once
      // seated. Same construction and same eps overlaps as before.
      translate([0, arm_pivot_y + arm_tip_h, arm_len])
        rotate([90, 0, 0]) {
          cylinder(d1 = spline_od - 2 * arm_ch, d2 = spline_od, h = arm_ch);
          translate([0, 0, arm_ch - eps])
            cylinder(d = spline_od, h = arm_tip_h - arm_ch + eps);
        }
      translate([0, arm_pivot_y, arm_len])
        rotate([90, 0, 0])
          face_spline(male = true, base = base_male);
    }

    bar_bore();
    ear_cuts(arm_side = true);

    // Pivot bolt clearance through the tip puck only, along Y now — same
    // reach as before (arm_tip_h + base_male + spline_h, plus 2*eps
    // overshoot), just along the axis that changed. face_spline() cuts its
    // own Ø(spline_id) bore through the spline itself, so this covers just
    // the puck; the rib further down is never needlessly drilled.
    translate([0, arm_pivot_y + arm_tip_h + eps, arm_len])
      rotate([90, 0, 0])
        cylinder(d = pivot_bolt_clear_d, h = arm_tip_h + base_male + spline_h + 2 * eps);
    // Lead-in at the bore's entry face (the puck's own root, away from the
    // spline — the bolt is offered up from that side).
    translate([0, arm_pivot_y + arm_tip_h, arm_len])
      rotate([90, 0, 0])
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
// a VISOR that projects forward at z<0, past the glass itself, confined in
// Y to stay clear of the display's own top edge.
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
//   The fix: keep the ENTIRE z<0 visor at Y > disp_h/2 (clear of the
// display's own footprint), and do all the Y-travel from the box's edge up
// to that safe band at z>=0 instead, where there is nothing to collide
// with. Same "riser then bridge" split as the arm's own rising rib
// elsewhere in this file (see arm()'s own block comment) — there for
// printability, here for clearance, same shape of fix either way: one
// bad-geometry diagonal replaced by two axis-aligned stages.
//
// ⭐ VISOR REWORK, 2026-09-15 (Task 2). The RISER above got the clearance
// right; the CANTILEVER it used to carry got the JOB wrong. Owner: "The
// 'brow' doesn't even reach across the top, the point of it was to block
// sunlight, that blocks nothing." Measured: the old cantilever's forward
// tip sat at z=-19; the glass is at z=-disp_d=-26. The old brow stopped
// 7mm SHORT of the screen's own plane and never reached it, let alone
// overhung it — the "brow projects `brow` mm" criterion this used to be
// checked against measured the CANTILEVER's own reach off the riser, not
// where that reach LANDED relative to the glass it was supposed to shade.
// Zero shading, passing every check that existed (see docs/design-notes.md
// for the fuller story and the permanent shade test in tools/build.sh that
// exists because of it).
//   Fix, in two parts: (1) project far enough that the tip actually clears
// the glass plane by a real margin (see `brow`'s own derivation, top of
// file); (2) shape it as a VISOR, not a shelf — curved in plan (a
// superellipse: full width at the glass plane, holding most of that width
// for most of the run, then turning back to a blunt rounded nose over the
// last few millimetres — see brow_plan_n for why the curve is full rather
// than the straight taper this first was) and curved in section (thinner at
// the sides than the centre) — built as a chain of hull()s between successively
// smaller, forward-shifted 2D profiles, NEVER one hull() spanning root to
// tip directly (the same convex-hull-leak discipline as taper_wp()'s own
// waypoints and chamfer_slab()'s own multi-slice bevel — a single hull
// between a tall root rectangle and a small forward tip would leak height
// forward and depth backward exactly the way this file's own historical
// yoke-arm bugs did). Every station's own profile keeps its UNDERSIDE
// tangent at the SAME Y (brow_y0) by construction (each circle's own centre
// sits brow_y0+radius above brow_y0, so its bottom is always exactly
// brow_y0) — deliberate, not incidental: it is the one surface the shading
// derivation is measured against, and it stays level and known across the
// whole visor, not just at the centreline.
//   The visor is SOLID, not a hollow cowl_wall shell like the rest of the
// part. A shape that tapers from a 10mm-tall root down to a ~2mm sliver at
// the sides and a single small circle at the tip cannot support a uniform
// 2.4mm wall without the offset() collapsing to nothing partway along it —
// the same offset()-collapse trap yoke_root_len/leg_w/brow_root's own
// fillet guards exist to catch, here avoided by not attempting a wall at
// all where the material itself is already thinner than one. This is the
// SAME choice the original design already made at its own tip ("a solid
// end-cap remains there"), just applied over more of the feature because
// this shape tapers throughout rather than only at the very end. The RISER
// keeps its own full cowl_wall shell, unchanged — only the part that is too
// thin to hollow honestly goes solid. Checked, not assumed: the riser's own
// cavity still reaches the exterior through its Y-overlap with the MAIN
// BOX's cavity (riser_y0 sits inside the box's own footprint — see
// riser_y0's own comment), independent of whatever the visor does, so
// making the visor solid cannot reproduce the historical sealed-cavity
// defect described below — confirmed by the exported part's own component
// count, not just this argument.
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

// ⭐ THE PLAN CURVE IS A SUPERELLIPSE, AND ⭐ WIDTH — NOT PROJECTION — IS
// WHAT SHADES. Both facts are measured, by tools/check_shade.py, not
// reasoned:
//   · An earlier visor put two hand-placed stations on a straight taper
//     (half-width 50 at 10mm past the glass, 30 at 25mm, a point at 33mm).
//     It shaded 14.8% of the screen at 45 degrees of sun elevation.
//   · Stretching THAT shape's projection from 33mm to 45mm moved 45-degree
//     shade to 17.2%, and to 60mm moved it to 20.4% — while the shadow's
//     own depth down the screen did not move at all (14.1mm in every case).
//     Nearly doubling the nose bought ~5 points of shade.
// The reason is geometric: a row of screen is shaded only where the visor
// is actually OVER it, so a visor that has already tapered to a 2mm-wide
// spike by mid-projection leaves the screen's own outer columns in full
// sun no matter how far that spike reaches.
//
// So the taper is now a superellipse in plan — half-width brow_halfw(p) at
// projection p past the glass — which holds close to full width for most
// of the run and then turns back over the last few millimetres into a
// blunt, rounded nose. Same total projection, same rounded silhouette the
// owner asked for, roughly 25% shade at 45 degrees instead of 14.8%.
// ⚠️ The exponent is the lever: RAISING brow_plan_n squares the plan curve
// off (more shade, blockier nose), LOWERING it toward 2 makes a sleek
// ellipse (less shade). Move it and re-run tools/check_shade.py — the
// build gate's own 20% floor at 45 degrees is what holds the tradeoff.
brow_plan_n   = 3;    // superellipse exponent of the visor's own plan curve
brow_stations = 14;   // lofted stations from the glass plane to the tip;
                      // spaced by sin() so they CLUSTER at the nose, where
                      // the curve turns fastest and a coarse spacing would
                      // read as a chamfered beak instead of a round one.
                      // 14, not 8: each hull() between two stations is a
                      // RULED (straight-sided) surface, so the station count
                      // is the curve's own resolution. At 8 the facets were
                      // visible along the nose in a profile render.
brow_d_c      = 7;    // section thickness (Y) on the centreline
brow_d_s      = 3;    // section thickness (Y) at the visor's own outer edge
                      // — 3, not the old 2: the outer edge now carries real
                      // span rather than dying as a spike, so it is a
                      // cantilevered wing and gets wall, not a witness line.

brow_edge_x = disp_w/2 + reveal - brow_d_s/2;   // half-width of the visor's
                   // own widest station (at the glass plane), chosen so that
                   // station comes out EXACTLY as wide as the full-width root
                   // slab it grows from: 2*brow_edge_x + brow_d_s == the
                   // cowl's own outside width.
                   //   ⚠ THIS WAS disp_w/2 - disp_corner_r (= 71), on the
                   // reasoning that the cowl's own R9 top corners are already
                   // curving away past that X. That reasoning does not apply
                   // to this feature: the visor's whole Y-range (brow_y0 ..
                   // brow_y1) sits ABOVE the box's own top edge
                   // (disp_h/2 + reveal), where what carries it is the RISER —
                   // which is a plain full-width slab with no corner radius at
                   // all. So 71 left the visor 9.5mm per side narrower than
                   // its own support for no reason, and the width step where
                   // the root met the first station showed as a visible crease
                   // in plan view. Matching them removes the crease and is
                   // worth ~4 points of measured shade (tools/check_shade.py).
brow_tip_z  = -(disp_d + brow);   // the visor's own forward-most point, Z
                   // — `brow` (top of file) is now the TRUE forward
                   // projection PAST the glass plane (z=-disp_d), not off
                   // the cowl's own rear face; see its own derivation.

// Projection (mm past the glass) of station i, and the half-width there.
// pow()'s own argument is clamped at 0 so the tip station cannot go
// imaginary on a rounding error at p == brow.
function brow_p(i)     = brow * sin(90 * i / brow_stations);
function brow_halfw(p) = brow_edge_x *
    pow(max(0, 1 - pow(p / brow, brow_plan_n)), 1 / brow_plan_n);
function brow_z(p)     = -(disp_d + p);

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
assert(brow_tip_z < brow_z(0) && brow_z(0) < cant_lap,
  str("VISOR RUN OUT OF ORDER: root (z=", cant_lap, ") -> glass plane (z=",
      brow_z(0), ") -> tip (z=", brow_tip_z, ") must strictly deepen, or the ",
      "hull() chain between them folds back on itself instead of reaching ",
      "forward over the glass."));
for (i = [0 : brow_stations - 1])
  assert(brow_p(i) < brow_p(i + 1) &&
         brow_halfw(brow_p(i)) > brow_halfw(brow_p(i + 1)),
    str("VISOR STATIONS DON'T SWEEP FORWARD AND IN: station ", i, " (p=",
        brow_p(i), ", half-width ", brow_halfw(brow_p(i)), ") -> station ",
        i + 1, " (p=", brow_p(i + 1), ", half-width ",
        brow_halfw(brow_p(i + 1)), ") must both deepen AND narrow. A station ",
        "that widens makes the lofted surface bulge outward partway along ",
        "the visor instead of sweeping back to the corner."));
assert(brow_edge_x + brow_d_s/2 <= disp_w/2 + reveal,
  str("VISOR WIDER THAN THE COWL: the widest station reaches x=",
      brow_edge_x + brow_d_s/2, ", past the cowl's own half-width (",
      disp_w/2 + reveal, "). The visor would overhang the box's own side ",
      "wall as a lip instead of blending into its rounded corner."));

// The riser: PART OF THE SAME UNIFORM-cowl_wall SHELL as the box, not a
// solid gusset — its own cavity overlaps the box's main cavity (at its low,
// riser_y0 end) so both become ONE continuous void with ONE connected outer
// boundary, independent of the (solid) visor beyond it.
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
// Hollowing the riser and letting it reach the box's own (already-open)
// cavity through their Y-overlap — rather than depending on a hollow visor
// beyond it, which no longer exists — is what keeps this fixed now.
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

// One station's own 2D profile (X-Y plane), drawn directly at world Y (not
// centred — every circle's own centre is placed brow_y0+radius up, so its
// OWN bottom tangent is always exactly brow_y0, the visor's one shared,
// known underside — see the block comment above for why that is load-
// bearing for the shading derivation, not incidental). `pts` is a list of
// [x, d] pairs; hull() of circles is the same "smooth, provably convex
// silhouette" technique yoke_profile() already uses for the bearing plate's
// own truss, applied here instead of a hand-rolled curve — inherently
// smooth everywhere, no separate fillet_vis edge-break needed on top of it.
module brow_station(pts) {
  hull()
    for (pt = pts)
      translate([pt[0], brow_y0 + pt[1]/2])
        circle(d = pt[1]);
}

// A thin (2*eps) Z-slice of a 2D profile, positioned at world Z=z — the
// same "hull() waypoint" role taper_wp() plays elsewhere in this file, just
// extruded along Z (this part's own established loft axis) instead of Y.
module brow_slice(z) {
  translate([0, 0, z]) linear_extrude(2 * eps) children(0);
}

// The station at projection p: a lens spanning the superellipse's own
// half-width there, thick on the centreline and thin at its own two edges.
// At the tip the half-width is 0 and the lens collapses to the single
// centreline circle — asked for explicitly rather than left to a zero-
// offset hull(), which OpenSCAD would take as two coincident circles.
module brow_station_at(p) {
  w = brow_halfw(p);
  brow_station(w < brow_d_s/2
                 ? [[0, brow_d_c]]
                 : [[0, brow_d_c], [w, brow_d_s], [-w, brow_d_s]]);
}

// Outer (visible) visor surface: a chain of PAIRWISE hull()s — root ->
// glass plane -> station 1 -> ... -> tip — never one hull() spanning the
// whole run, which would span the superellipse's own concavity and hand
// back the straight taper this shape exists to replace. Solid; see the
// block comment above for why this feature does not get its own cowl_wall
// shell.
module cowl_brow_outer() {
  // Root: the full-width slab where the visor leaves the riser, swept
  // forward to the glass plane — this stretch is over the display's own
  // box and shades nothing; it is the wrap into the cowl's rounded corner.
  hull() {
    brow_slice(cant_lap - eps)
      translate([0, (brow_y0 + brow_y1)/2])
        offset(r = fillet_vis) offset(delta = -fillet_vis)
          square([disp_w + 2*reveal, brow_root], center = true);
    brow_slice(brow_z(0)) brow_station_at(0);
  }
  // Everything past the glass plane: the part that actually shades.
  for (i = [0 : brow_stations - 1])
    hull() {
      brow_slice(brow_z(brow_p(i)))     brow_station_at(brow_p(i));
      brow_slice(brow_z(brow_p(i + 1))) brow_station_at(brow_p(i + 1));
    }
}

// No cavity for the visor any more — it is SOLID (see the block comment
// above cowl_brow_outer()'s own history for why); cowl()'s own difference()
// simply subtracts nothing for this feature. Kept as a callable no-op, not
// deleted, so cowl()'s own difference() list does not need to know whether
// this feature happens to be hollow this week.
module cowl_brow_inner() {}

// ---- Bottom opening: ONE wide notch, BOTH legs and BOTH clamps through the
// middle, the loom beside them — not four notches. Open to the display's own
// bottom edge and well beyond (the legs, clamps and loom all continue past
// the cowl's own footprint, down to the two pivots and the handlebar).
//
// ⭐ SYMMETRIC again, ⭐ TWO-CLAMP REWORK (2026-09-15) — simpler than the
// single-arm design's own asymmetric opening (docs/design-notes.md's DM-6
// history): with a leg AND a clamp reaching out to EACH side now, by
// construction the same distance (pivot_x_l = -pivot_x_r), the opening only
// needs one half-width, mirrored, instead of two independently-derived
// edges. clamp_seat_x_reach is the same "clamp tube's own far end, mapped
// through the seating transform" quantity the old design used, just without
// the asymmetric bookkeeping arm_pivot_y's own crank used to need.
clamp_seat_x_reach = pivot_x_r + yoke_tip_h + spline_seat - arm_pivot_y + clamp_x0 + clamp_w;
                 // the clamp tube's own far (local Y=clamp_x0+clamp_w) end,
                 // mapped through clamp_seat()'s own (theta-independent-in-X)
                 // formula — not eyeballed. Checked for real against the
                 // positioned/exported yoke+arm+cap STLs with check_fit.py
                 // (see the task report for the measured bbox), not trusted
                 // from this arithmetic alone.
open_half = clamp_seat_x_reach + 6;   // half-width: clears the seated clamp
                 // with 6mm to spare (same margin the old design used on its
                 // one open side) — also clears the Ø40 spline puck
                 // (pivot_x_r+yoke_tip_h+base_female+spline_h, well inside
                 // clamp_seat_x_reach) with room to spare, asserted below.
open_x0 = -open_half;
open_x1 =  open_half;
open_y0 = -22;   // upper edge of the opening, model Y. Below this (more
                 // negative than yoke_riser_y1=-24.41) the yoke's Stage-B
                 // taper actually widens toward the pivot and needs the
                 // material gone; above it (Stage A, yoke_riser_y0=-22.29
                 // down to -24.41) the riser only reaches z=16 — comfortably
                 // inside cowl_depth — so a plain wall clears it with no
                 // opening needed. -22 sits north of that boundary by
                 // 2.41mm (an intentional small margin, not the boundary
                 // itself) and clear of the M3 boss band below it. UNCHANGED
                 // by the two-clamp rework — this is Y-only staging, the
                 // same for both legs.

assert(open_half > pivot_x_r + yoke_tip_h + base_female + spline_h + 3,
  str("OPENING TOO NARROW FOR THE SPLINE PUCK: open_half (", open_half,
      ") clears the puck's own far reach (",
      pivot_x_r + yoke_tip_h + base_female + spline_h, ") by only ",
      open_half - (pivot_x_r + yoke_tip_h + base_female + spline_h),
      "mm — needs >3mm."));
assert(open_half > clamp_seat_x_reach + 1,
  str("OPENING TOO NARROW FOR THE SEATED CLAMP: open_half (", open_half,
      ") clears the seated clamp's own reach (", clamp_seat_x_reach,
      ") by only ", open_half - clamp_seat_x_reach, "mm — needs >1mm."));

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
          [open_x0, open_y0], [open_x1, open_y0],
          [open_x1,    -200], [open_x0,    -200] ]);
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
// ONE PER SIDE OF THE OPENING — symmetric again, ⭐ TWO-CLAMP REWORK
// (open_x0/open_x1 are now ±open_half): each boss sits just outside ITS OWN
// edge, with 2mm of solid wall between the opening's cut edge and the
// boss's own bore, so the M3 clearance hole never breaks into the opening
// on either side. Written from open_x0/open_x1 rather than ±open_half
// directly so nothing here needs to know or care that they are symmetric.
m3_x_left  = open_x0 - m3_boss_d/2 - 2;
m3_x_right = open_x1 + m3_boss_d/2 + 2;
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

assert(m3_x_right + m3_boss_d/2 < disp_w/2 + reveal - fillet_out - 2,
  str("M3 BOSS TOO FAR OUT (right): boss edge at x=", m3_x_right + m3_boss_d/2,
      " comes within 2mm of the shell's own R", fillet_out, " outer chamfer ",
      "(starts at x=", disp_w/2 + reveal - fillet_out, ")."));
assert(-m3_x_left + m3_boss_d/2 < disp_w/2 + reveal - fillet_out - 2,
  str("M3 BOSS TOO FAR OUT (left): boss edge at x=", m3_x_left - m3_boss_d/2,
      " comes within 2mm of the shell's own R", fillet_out, " outer chamfer ",
      "(starts at x=", -(disp_w/2 + reveal - fillet_out), ")."));
assert(m3_z_max < cowl_depth - 0.5,
  str("M3 BOSS BREAKS THE VISIBLE SURFACE: the root fillet reaches z=",
      m3_z_max, ", within 0.5mm of the back cap's own outer face at z=",
      cowl_depth, " — this must include the R1 root fillet's own radius ",
      "(m3_boss_d/2+fillet_in), not just the plain boss diameter, or a ",
      "0.1mm bump on the visible surface passes silently (found once)."));

module cowl_m3_boss() {
  for (x = [m3_x_left, m3_x_right])
    // A short root fillet (fillet_in, R1 — "internal fillets at wall-to-rib
    // junctions") where the boss meets the back cap: hull() a slightly
    // larger, shorter disc at the cap end against the plain-diameter run —
    // same 3-point-hull shape chamfer_slab() itself uses, just built by
    // hand here because the boss's own axis (Y) isn't chamfer_slab's native
    // Z, and this fillet is one-sided (only the cap end, not the open end).
    hull() {
      translate([x, m3_y0, m3_z_c]) rotate([-90, 0, 0])
        cylinder(d = m3_boss_d, h = m3_boss_len - fillet_in);
      translate([x, m3_y1 - eps, m3_z_c]) rotate([-90, 0, 0])
        cylinder(d = m3_boss_d + 2*fillet_in, h = eps);
    }
}

module cowl_m3_cut() {
  for (x = [m3_x_left, m3_x_right]) {
    translate([x, m3_y0 - eps, m3_z_c]) rotate([-90, 0, 0])
      cylinder(d = m3_clear_d, h = m3_boss_len + 2*eps);
    translate([x, m3_y0 - eps, m3_z_c]) rotate([-90, 0, 0])
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

// The 45 mm centre bracket both clamps butt against (docs/bike-fitment.md).
// bracket_w/bracket_half are defined early now (near bar_d0) as the MEASURED
// fact `pivot_x_r` is derived FROM — ⭐ TWO-CLAMP REWORK: there is nothing
// left to drift out of sync here (the old design derived bracket_w FROM
// arm_crank and asserted it still came out to 45; this design goes the other
// way, computing pivot_x_r from the measured 45mm directly, so a mismatch is
// no longer even expressible). Drawn centred on the bike's own centreline,
// reaching bracket_half either way — the RIGHT clamp butts its +Y-facing
// (right) face at local Y=0, the mirrored LEFT clamp butts the other.
module bracket_stub() {
  translate([-25, -bracket_w, -25])
    cube([50, bracket_w, 50]);
}

// Seats the arm assembly's male spline against the yoke's female spline.
// ⚠ REWRITTEN 2026-09-14 for the ⚠ DM-6 rework: the spline axis is now the
// arm's own local Y (the bar axis — see the block comment above
// pivot_x/pivot_y/pivot_z on the yoke side for why), not local Z, so the
// OLD base rotation (rotate([180,0,0]), chosen to satisfy "local Z -> shared
// -Z") no longer applies to anything — that requirement doesn't exist any
// more. This is rebuilt from the actual new requirement instead of patched.
//
// THE ONE HARD REQUIREMENT: local Y (the bar axis, and now the spline axis)
// must map to shared X (the bar's own length direction in the shared frame
// — the display's own left/right, since the display/yoke/cowl already share
// that frame with no transform of their own). Any rotation R0 satisfying
// R0·ŷ = x̂ works for the spline mesh; which ONE of those (they differ by a
// further spin about x̂, i.e. about the bar's own axis) also puts "up along
// the rising rib" (local Z, the direction the rib climbs FROM the clamp
// TOWARD the pivot) somewhere sensible is a second, independent choice,
// resolved the same way this file resolves every rotation choice: computed
// with matrices, not eyeballed against a render (a render cannot show a
// mismeshed spline OR a wrong "up" any more than it can show interference —
// docs/spline-verification.md and this file's own header trap list). The
// CORRECT sign is R0·ẑ = +ŷ: "toward the pivot" (local +Z) must map to
// "toward the display's own top edge" (shared +Y, since the display's top
// edge sits at model Y=+disp_h/2 — the display is fixed in this frame, so
// its own +Y really is "up"), not shared −Y.
// ⚠ CORRECTED 2026-09-14, same day as first written — an earlier version of
// this block solved R0·ẑ=−ŷ instead, by wrongly carrying over the OLD
// (pre-rework) design's own "arm-local Z -> shared -Z is real up" sign
// convention. That convention was never a physical fact to begin with: the
// OLD shared Z was the display's DEPTH axis, so "which sign is up" there was
// only ever a camera-framing choice for a render, not a claim about the
// display's own top/bottom edges — carrying its SIGN over to a genuinely
// different, physically-meaningful axis (shared Y, the display's real
// vertical) was the error. Caught by the render-gen4.sh clearance checks
// (not by the pitch test, which only cares about RELATIVE rotation and
// cannot tell "up" from "down"): with the wrong sign, the cap ended up
// ABOVE the pivot instead of below it, driving it back up into the display
// and yoke — display vs positioned cap/arm and yoke/cowl vs positioned cap
// all reported real (400-2700mm³) interference. Re-solved for R0·ŷ=x̂ AND
// R0·ẑ=+ŷ by searching compositions of 90°-multiple OpenSCAD rotate() calls:
// the simplest solution is `rotate([0, -90, -90])`, which gives
// local (x,y,z) -> shared (y, z, x) — verified by matrix multiplication,
// not asserted; re-verified against the ACTUAL exported geometry (the same
// render-gen4.sh clearance checks, now all CLEAR) before this was trusted.
//
// THE FREE CHOICE: `arm_seat_theta` (a top-level parameter, defined near
// arm_pivot_y — not a local here, so a build tool can override it with a
// plain `-D`), a further rotation about the now-shared X axis (the
// bar/spline axis) — this is the SAME "which of 48 valid clock positions"
// freedom the old design's own `theta` had, just carried out about a
// different final axis. Unlike the old design, this rotation now changes
// something real: it is the display's PITCH, the whole reason for this
// rework — tools/build.sh's own pitch test renders/positions the assembly
// at several values of it and checks exactly that. It must still be an
// exact multiple of 360/spline_n (7.5°) to re-mesh the teeth exactly rather
// than approximately — anything else collides the spline
// (docs/spline-verification.md's own meshing proof only holds at those
// angles). 0 is the reference pose used for every OTHER render, bbox and
// clearance check in this file; docs/bike-fitment.md documents that a
// WORKING tilt joint means the screen's height above the bar is a function
// of this angle, not a fixed fact independent of it the way the old
// (broken) design's roll axis left it.
//
// THE ROTATION MUST PIVOT ABOUT THE PIVOT LINE, NOT THE ORIGIN. `theta`
// has to fix the physical hinge axis (shared y=pivot_y, z=pivot_z, running
// along shared X) in place while it turns everything else — a bare
// rotate([theta,0,0]) instead rotates about the axis THROUGH THE ORIGIN
// (y=0,z=0). Composing translate -> rotate(theta) -> rotate(R0) with a
// theta-DEPENDENT translate (below) is the closed form of "rotate about the
// pivot line, then land the male spline's own flat-back centre exactly
// spline_seat beyond the FEMALE's own flat back" (⚠ NOT on top of the
// female's flat back — that was a bug caught by the rod-probe method
// mandated in docs/spline-verification.md §4, not by any render or
// check_fit.py run: those never boolean yoke against arm at all, precisely
// because a whole-spline-ring boolean is not trustworthy on this geometry
// — see docs/spline-verification.md §3/§5. The female's own flat back sits
// at shared x=pivot_x_r+yoke_tip_h (it grows from there, not from pivot_x_r
// itself — see yoke_pivot_puck()), so the male's target is
// pivot_x_r+yoke_tip_h+spline_seat, not pivot_x_r+spline_seat. The omission
// was a 6mm (=yoke_tip_h) error that put the male's own solid base disc
// 1.7mm deep into the female's, at every angle sampled — task report has the
// before/after rod-probe numbers) solved together, not two separate
// corrections layered on top of each other — derivation and the algebra
// that collapses it to this closed form: task report.
//
// ⭐ TWO-CLAMP REWORK — ONE side, mirrored, not two hand-derived seatings.
// `clamp_seat(side)` seats the SAME clamp (arm()+cap(), self-symmetric —
// see yoke_leg()'s own block comment for the argument) against EITHER
// female spline: `side=1` (right, `pivot_x_r`) runs exactly the translate/
// rotate derived above; `side=-1` (left) is `mirror([1,0,0])` of that same
// result, not a second rotation solved from scratch. This is safe for
// `theta` specifically because mirroring about the plane X=0 COMMUTES with
// a rotation about the shared X axis: writing M=diag(-1,1,1) (the mirror)
// and Rx(theta) (the rotate([theta,0,0]) below), M is a pure reflection
// (det M=-1) whose own axis (X) IS the rotation axis, and for any reflection
// M, M·Rx(theta)·M⁻¹ = Rx(M·x̂, -theta) = Rx(-x̂, -theta) = Rx(x̂, theta) —
// negating both the axis and the angle cancels, so M·Rx(theta) = Rx(theta)·M
// exactly. Physically: both clamps bolt to the SAME real, non-rotating bar,
// so their apparent motion in the yoke's own (fixed) frame has to be the
// IDENTICAL rotation, not mirror-opposite ones — which is exactly what this
// commutation gives, confirmed against the actual exported geometry by the
// SAME pitch-acceptance test this file already runs (tools/build.sh), not
// trusted on the algebra alone. See docs/design-notes.md for the parallel
// argument for WHY the mirrored clamp part itself, and its male spline's
// tooth phase, reproduce the correct shape with no re-derivation either.
module clamp_seat(side = 1) {
  assert(side == 1 || side == -1,
    "clamp_seat(): `side` must be 1 (right) or -1 (left) — no default beyond the right side, so a caller can never silently seat neither/both.");
  theta = arm_seat_theta;

  module seat_right() {
    // Re-derived for the corrected R0 (see the block comment above): with
    // R0·ẑ=+ŷ, pinning the pivot point fixed under Rx(theta) needs a MINUS
    // sign on the arm_len terms below (was +, under the old, wrong-signed
    // R0) — same "translate -> rotate(theta) -> rotate(R0)" closed form,
    // re-solved algebraically for the new R0 (task report has the algebra),
    // not just sign-flipped by guesswork.
    translate([
      pivot_x_r + yoke_tip_h + spline_seat - arm_pivot_y,
      pivot_y - arm_len * cos(theta),
      pivot_z - arm_len * sin(theta)
    ])
      rotate([theta, 0, 0])
        rotate([0, -90, -90])
          children();
  }

  if (side == 1) seat_right() children();
  else mirror([1, 0, 0]) seat_right() children();
}

/* ---- PARTS: pitch_probe_fixed / pitch_probe_arm ---------------------
   ⭐ THE ACCEPTANCE TEST tools/build.sh's own pitch check is built on: two
   pairs of marker rods, exported as real geometry (not algebra) at several
   `arm_seat_theta` values, the same "verify by isolation + real geometry"
   method this file already uses for the spline mesh
   (docs/spline-verification.md §4) and for render-gen4.sh's own camera
   derivation. NOT printable parts — bench/CI probes only.

   Different DIAMETERS (not just lengths) so the two rods in each export
   split apart (trimesh .split()) and are told apart unambiguously by
   volume/radius alone, with no fragile length- or position-based guessing.

   pitch_probe_fixed — built directly, untouched by clamp_seat(), so its two
   rods are the FIXED references every theta is measured against:
     - "normal" (Ø4, along shared -Z): the display's own face normal —
       display/yoke/cowl share this frame with no transform of their own.
     - "up" (Ø2, along shared +Y): the display's own "up" — used only to
       prove the hinge axis itself does not wander as theta changes (see
       pitch_probe_arm's own "axis" rod below); not itself expected to
       track pitch.

   pitch_probe_arm — carried through clamp_seat(), so its own two rods land
   wherever the CURRENT `arm_seat_theta` puts them:
     - "reach" (Ø4, arm-local Z — "up off the bore", the direction the
       rising rib climbs to reach the pivot): NOT parallel to the hinge
       axis, so its angle against the fixed "normal" rod is exactly the
       display's own elevation/pitch — this is the rod the acceptance test
       reads.
     - "axis" (Ø2, arm-local Y — the bar's own axis, and now the spline's
       too): PARALLEL to the hinge axis, so its own direction must stay
       IDENTICAL for every theta — a rotation about an axis cannot move
       that same axis. Checking this catches a DIFFERENT bug from the
       elevation check (theta implemented as a rotation about the right
       axis in the wrong PLACE — the pivot line itself wandering — rather
       than the original defect's "rotation about the wrong axis entirely").
   Neither rod's own angle against the fixed "normal" tests roll directly
   (two direction vectors, with no in-plane reference, cannot); the
   constant-axis property is the real-geometry stand-in this test uses for
   "no roll snuck in" — see the task report for the closed-form derivation
   (component of a fixed reference along the hinge axis, invariant under
   any rotation about that same axis) this rod check stands in for. */
// rod_gap: every rod starts this far from the shared origin along its OWN
// axis, not at it — two rods that share an exact origin vertex weld into
// ONE connected solid on export (confirmed: without this gap,
// pitch_probe_fixed() exported as a single 1-component, 467mm³ watertight
// body, not two separable rods — trimesh's `.split()` had nothing to
// split). rod_len is each rod's own length beyond that gap.
rod_gap = 3;
rod_len = 25;

// ⚠ cylinder()'s own axis is Z; a rod needing +Y or -Y is built along Z
// then rotated the same way bar_bore() etc. do elsewhere in this file
// (rotate([-90,0,0]) sends local Z -> local Y) — the gap-translate happens
// BEFORE that rotation (in the cylinder's own pre-rotation Z), so it ends
// up along the rotated axis instead of some other direction.
module pitch_probe_fixed() {
  // normal: -Z, gapped by mirroring a Z-axis rod that starts at rod_gap.
  color("Red")
    mirror([0, 0, 1])
      translate([0, 0, rod_gap])
        cylinder(d = 4, h = rod_len);
  // up: +Y.
  color("Blue")
    rotate([-90, 0, 0])
      translate([0, 0, rod_gap])
        cylinder(d = 2, h = rod_len);
}
// ⭐ TWO-CLAMP REWORK: probes the RIGHT clamp seat only (clamp_seat(1)) — the
// same one the pitch test always used. The LEFT clamp is proven to pitch
// IDENTICALLY by the commutation argument in clamp_seat()'s own block
// comment (mirroring about X=0 commutes with a rotation about the shared X
// axis), not by re-running this probe a second time; the spline-mesh proof
// for the LEFT joint specifically is the rod-probe method
// (docs/spline-verification.md §4) applied to the mirrored geometry — see
// the task report for that run.
module pitch_probe_arm() {
  clamp_seat(1) {
    // reach: arm-local +Z ("up off the bore").
    color("Orange")
      translate([0, 0, rod_gap])
        cylinder(d = 4, h = rod_len);
    // axis: arm-local +Y (the bar's own axis, and now the spline's too).
    color("Green")
      rotate([-90, 0, 0])
        translate([0, 0, rod_gap])
          cylinder(d = 2, h = rod_len);
  }
}

/* ---- PART: assembly -------------------------------------------------
   Every part positioned as it actually assembles (docs/assembly.md's own
   order), plus stand-ins for the display, the handlebar and the bracket it
   clamps to -- distinct colour per part (house rule: same material, a
   monochrome render is hard to interpret) so the pieces read separately.
   The display/yoke/cowl already share one frame with no transform between
   them (docs/design-notes.md); the two clamps/caps/bar segments are seated
   by clamp_seat(1) (right) and clamp_seat(-1) (left) above -- ⭐ TWO-CLAMP
   REWORK: both are the SAME arm()/cap() part (see yoke_leg()'s own block
   comment for why one part serves both sides), just seated twice. The
   bracket stand-in is drawn once only, under the right seat -- it is one
   real physical object spanning both clamps, not two. */
module assembly() {
  color("DimGray")      display_stub();
  color("Gold")         yoke();
  color("Crimson")      cowl();
  clamp_seat(1) {
    color("RoyalBlue")    arm();
    color("SeaGreen")     cap();
    color("Silver")       bar_stub();
    color("SaddleBrown")  bracket_stub();
  }
  clamp_seat(-1) {
    color("RoyalBlue")    arm();
    color("SeaGreen")     cap();
    color("Silver")       bar_stub();
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
     - yoke's bearing face is ALREADY at Z=0 as authored (bbox Z -4..36 as
       of the ⚠ DM-6 rework — the pivot disc now reaches below Z=0 too, but
       the BEARING face itself, what actually has to sit flat on the bed,
       is still at Z=0) -- no flip needed, docs/printing.md's own "bearing
       face on the bed".
     - cap's split (bore-opening) face is ALSO already at its own Z=0
       (bbox Z -24..0) -- mirroring alone (no extra translate) lands it on
       the bed, docs/printing.md's "bore-side down".
     - arm's split (bore-opening) face is ALSO already at its own Z=0 (bbox
       Z 0..65 as of the ⚠ DM-6 rework) -- no flip needed, same "bore-side
       down" reasoning as the cap. ⚠ THIS CHANGED: the male spline's own
       flat back used to sit at the arm's Z MAXIMUM (a flat disc
       perpendicular to Z, "spline face down" meant flipping it onto the
       bed) -- it no longer does. The spline's axis is now arm-local Y (⚠
       DM-6 rework), so its disc lies in a plane perpendicular to Y, not Z:
       there is no Z-flip that puts it "face down" any more, because it
       isn't a horizontal face at either Z extreme. docs/printing.md flags
       this as an open question rather than repeating stale guidance.
     - cowl's visible back cap sits at ITS OWN Z MAXIMUM (bbox Z
       -19..30.3 = -brow..cowl_depth) -- mirror-plus-translate-by-max,
       "visible face down". Unaffected by the rework.
*/
plate_gap = 15;   // clear air between parts -- generous on purpose. This is
                  // a layout aid, not a bed-packing optimiser; the margin
                  // absorbs the parts' own silhouettes not being simple
                  // rectangles (round corners, the yoke's own Y-truss) and
                  // a modest future parameter change, rather than a tight
                  // nest that a small growth could silently overlap.

module plate() {
  // Measured bboxes (tools/check_stl.py, re-measured 2026-09-14 for the
  // ⚠ DM-6 rework -- yoke and arm both changed; cap and cowl did not) --
  // for spacing only.
  yoke_bb_w = 103.0;  yoke_bb_d = 107.09; yoke_bb_x0 = -51.49; yoke_bb_y0 = -90.00;
  arm_bb_w  =  70.0;  arm_bb_d  =  46.20; arm_bb_x0  = -35.00; arm_bb_y0  = -27.10;
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

  // Row 2: yoke, arm, cap. Neither yoke nor arm is flipped any more (⚠ DM-6
  // rework) -- both already have their own split/bearing face at Z=0 as
  // authored (see the block comment above), same "bore/bearing-side down"
  // treatment the cap already used. See docs/printing.md for the arm's own
  // now-open question (the spline's disc is no longer a flat face at
  // either Z extreme, so there is no equivalent "spline face down" flip).
  translate([col1_x - yoke_bb_x0, row2_y - yoke_bb_y0, 0])
    yoke();
  translate([col2_x - arm_bb_x0, row2_y - arm_bb_y0, 0])
    arm();
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
else if (part == "pivot_puck_test") pivot_puck_test();
else if (part == "yoke_leg_test") yoke_leg_test();
else if (part == "yoke_plate_test") yoke_plate_test();
else if (part == "yoke") yoke();
else if (part == "arm") arm();
else if (part == "cap") cap();
else if (part == "cowl") cowl();
else if (part == "brow_test") brow_test();
else if (part == "assembly") assembly();
else if (part == "plate") plate();
else if (part == "pitch_probe_fixed") pitch_probe_fixed();
else if (part == "pitch_probe_arm") pitch_probe_arm();
else assert(false,
  str("UNKNOWN PART \"", part, "\" — implemented so far: gauge, spline_test, pivot_puck_test, yoke_leg_test, yoke_plate_test, yoke, arm, cap, cowl, brow_test, assembly, plate, pitch_probe_fixed, pitch_probe_arm"));
