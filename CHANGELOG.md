# Changelog

Dates are ISO. This project is pre-1.0; parts land as they are verified.

## Unreleased

### Changed
- **Two-clamp rework (2026-09-15).** The mount now clamps the bar on **both** sides of the centre
  bracket, not one. Owner's verdict on the one-sided design: "we should be attaching on both sides
  of the handlebars. There is a tiny sliver of plastic supporting the entire display" — correct, and
  a two-sided mount had been wrongly argued against at design time.
  **`arm_crank` removed.** Each clamp roots its own spline at its own bare `clamp_x0+clamp_w/2`
  (no offset); the display centres itself between two mirrored pivots instead of being cranked back
  to one. `clamp_x0` changed 1→0 — the clamps now **butt** the bracket's faces rather than standing
  1mm clear of them.
  **`arm_seat()` → `clamp_seat(side)`.** `side=1` (right) is the same translate/rotate this file has
  always used, with `pivot_x` replaced by the new, DERIVED `pivot_x_r` (closed form: solve "what X
  lands the clamp's inboard face exactly on the bracket's own face" for the spline position, instead
  of solving `arm_crank` and checking `bracket_w` against 45mm after the fact — that check is gone,
  replaced by nothing needing to drift). `side=-1` (left) is `mirror([1,0,0])` of that exact result —
  proven, not assumed, safe: the clamp's own solid and the spline's own tooth phase are each provably
  self-symmetric under this mirror (`docs/design-notes.md`), and mirroring about the plane
  perpendicular to the shared hinge axis commutes with the `theta` pitch rotation (so both clamps use
  the same `theta`, not opposite-signed ones) — confirmed against real exported geometry, not the
  algebra alone.
  **Yoke: one female spline → two, mirrored.** New `yoke_leg()` (was the single "lower arm" inside
  `yoke()`) builds the right leg; the left is `mirror([1,0,0]) yoke_leg()`. `yoke_profile()`'s hull
  gained two more anchor circles (one per leg root) so both union onto the (now wider) bearing plate
  generously rather than by a graze. New `leg_w` (18mm, was `yoke_arm_w`=26) — narrower, to clear the
  lone M5's own socket sweep now that neither leg is centred under it (new assertion). New
  `pivot_x_r`/`pivot_x_l` (`=-pivot_x_r`), coaxial with the unchanged `pivot_y`/`pivot_z`.
  **Cowl opening: asymmetric → symmetric again**, `open_x0`/`open_x1` now `±open_half`, sized off
  the same seated-clamp-reach formula (`clamp_seat_x_reach`, was `arm_seat_x_reach`) for one side and
  mirrored — simpler than the single-clamp design's own one-sided opening. M3 boss positions follow.
  **New test parts** `yoke_leg_test` (one leg alone) and `yoke_plate_test` (bearing plate alone) —
  measured by isolation, the same method `spline_test`/`pivot_puck_test` already use, so the
  whole-yoke fill-sanity check in `tools/build.sh` is built from real measurements of the new
  sub-assemblies rather than reused numbers from a differently-shaped design.
  **Screen height above the bar is unchanged (52/146mm)** — the rework only moved things sideways
  (X); every number the height depends on (`arm_len`, `bar_d0`, `pivot_y`) is untouched.
  ⬜ **Left side of the bar is unmeasured** — `bar_d0`/`bar_taper`/`bar_run` are a TEMPORARY
  assumption (mirror the measured right side); flagged at their own definition and in
  `docs/bike-fitment.md`.
  Verified: every part (gauge, spline_test, pivot_puck_test, yoke_leg_test, yoke_plate_test, yoke,
  arm, cap, cowl, brow_test) watertight, 0 boundary edges, 0 non-manifold edges, 1 connected
  component. Whole-yoke volume 66534.6mm³ (0.91× the plate+2×leg overestimate). Cowl clearance CLEAR
  against yoke, both positioned clamps, the display, and the two clamps against each other — each
  positioned clamp's bbox also checked against an independently hand-derived per-axis expectation
  (matched to the mm on the first run). **Pitch acceptance test unchanged and still passing**: three
  7.5° clicks move elevation by exactly 22.500°, roll stays at 0.0000000, hinge-axis drift 0.000000°.
  Every assertion (existing and new) reconfirmed to fire when deliberately broken.

### Audit (2026-09-16)

A full pass over every part, joint, assertion and document. What it found:

- **A tautological assertion.** `VISOR WIDER THAN THE COWL` read
  `brow_edge_x + brow_d_s/2 <= disp_w/2 + reveal`, and `brow_edge_x` is *derived* as
  `disp_w/2 + reveal - brow_d_s/2` — the two sides are identically equal, so no parameter could ever
  break it. Written when `brow_edge_x` was independent, never revisited when it became derived. ⛔ **An
  assertion that cannot fail is not a test.** Replaced with two that can: the visor must stay at least
  as wide as the cowl's corner radius allows, and its edge section must be thinner than its centreline.
  Found by trying to break all 59 assertions; this was the only one that could not be broken.
- **A hardcoded number that would have gone stale.** The cowl-ear/socket clearance assert carried the
  literal `45.25` — `p(holes[1])[0] + m5_socket_d/2` worked out by hand. Now derived.
- **The whole-yoke fill expectation had stopped over-estimating.** It was `plate + 2×leg`, written
  before the yoke grew a gusset, two pivot nut pads and two cowl ears. The ratio had climbed to
  **0.995 against a 1.05 ceiling** — passing because the formula did not know about a third of the
  part, and one more gram of material would have failed the build for no reason. Now includes the ears
  (measured) and the nut pads (analytic, deliberately double-counting what is buried in each leg):
  ratio **0.850**.
- **The insert count was wrong in two documents.** README said 8, `docs/assembly.md` said 4. Counted
  on the exported parts: **6** — two per clamp arm (and there are two arms), two in the yoke.
- **The pivot hardware row said `1 × M6`** when there is one per side, and "length set by your stack"
  when the length is now derived and asserted. Now `2 × M6 × 35` + nyloc + plain washer.
- **Stale printability figures.** The yoke's down-facing area is **3560 mm²**, not the 2644 recorded
  before it grew ears (+35 %); cowl 4902 → 5148; arm 1276 → 1287. Added the `insert_coupon` row and a
  bed-size note: the yoke's footprint is now **143.8 × 107.1 mm**, the largest single part.
- **`docs/design-notes.md`'s arm throat** 234 → 236.9 mm², after the pivot head seat was counterbored.

Verified clean, with measurements rather than assertions:

- All seven printable parts watertight, one connected component, no non-manifold edges.
- **Neck scan** (new): every part survives 0.5 mm of erosion in one piece.
- **All three display bolts**: clear bore, head seat flat to 0.00 mm across its annulus, socket sweep
  unobstructed.
- **All four clamp bolts**: head seats at z = −5.5 in the cap, crosses the 2 mm pinch gap, engages
  5.0 mm of insert — matching the model's own derived `ear_bolt_engage`.
- **Both pivots**: bore clear through, both bearing faces flat to 0.00 mm, 26.00 mm of measured grip
  against 26.1 derived.
- **Both cowl screws**, every clearance pair, the pitch test and the shade test: unchanged and green.
- A **clean `git archive` export** builds end to end under a venv holding exactly the packages CI
  installs.

### Added
- **`tools/check_necks.py`** — voxelise a part, erode it, and report what falls off. ⚠️ Validated
  against this project's own four defects rather than assumed to work: it catches the arm's 0.2 mm
  knife edge (at 0.5 mm) and the yoke's 36 mm² shear web (at 1.5 mm), and **does not** catch the
  cowl-ear bond or the deleted boss. Those are different failure modes and have their own gates; the
  docstring says so.
- **`--sweep all` on `tools/check_throat.py`** — plane normals over a whole hemisphere, including
  normals along X that the Y-Z sweep never tried. ⛔ It still does **not** catch a corner-graze bond,
  and the tool now says why: the plane that comes closest to separating a feature also slices a large
  area of parent carrying none of that feature's load.

### Added
- **Exploded view** (`part="exploded"`, `renders/gen4-exploded.png`) — every part pulled apart along
  the axis it actually assembles on, with all 17 fasteners and 8 inserts shown in place.
- **`insert_coupon`** — heat-set insert fit gauge: eight pockets, two fits each for M3/M4/M5/M6.
- **`tools/check_fixing.py`** — walks a screw's axis through two exported meshes and reports what is
  actually there.
- **`tools/check_throat.py`** — smallest verified load-bearing section, sweeping the cutting plane's
  angle instead of picking one.
- **Four new renders** (`tools/render-gen4.sh`): `gen4-assembly-rider.png` (the view from the
  saddle), `gen4-assembly-threequarter.png`, and `gen4-visor-plan.png` / `gen4-visor-profile.png` —
  the two views the visor's shape is actually judged in (its plan silhouette, and how far it reaches
  past the glass).

### Fixed
- **The cowl's side ears were barely attached to the yoke (found by eye, 2026-09-15).** Owner, from
  the top view: *"the new ears are barely connected."* Measured: each ear shared **2.3 mm³** with the
  bearing plate, out of its own 6670 mm³. It was effectively a floating wing touching at a corner.
  **Cause: the plate is a truss, not a rectangle**, and its outer edge runs diagonally — measured on
  `yoke-plate-test.stl` it reaches x=51.5 at y=+6, x=46.0 at y=−4 and x=39.0 at y=−12. The ear was
  placed at y=−4 starting at x=51, which put its root **5 mm outboard of the plate altogether**.
  **Fixed** by moving the joint to **y=+6**, the plate's own widest line, and rebuilding the ear as
  three hulled stations instead of a constant-section bar: a root at x=40 buried inside the plate, a
  mid station at x=49 still flush within `yoke_t`, then the cantilever out to the boss at x=71.8. The
  root→mid leg stays at or below `yoke_t` deliberately — above it lies the Ø9.5 socket sweep of the
  upper M5 at (40.5, 6.09), and a rib crossing that makes the display bolt impossible to drive
  (asserted). Bond **2.3 → 2607.8 mm³** (30.5 % of the ear now inside the plate); minimum section
  along the run 84.1 → 110.8 mm².
  ⛔ **No section scan can catch this, at any angle.** `check_throat.py` was extended with `--sweep
  all` (Fibonacci-hemisphere plane normals, including normals along X, which the Y-Z sweep never
  tried) and it still reported a healthy **112 mm²** on the broken geometry. That is not a gap in the
  sweep: the plane that comes closest to separating an ear also slices a large area of *plate* that
  carries none of the ear's load, and the cut reports that area. **A section measures a neck; it
  cannot measure whether two solids are really one.**
  ⭐ **New cowl-ear bond gate** in `tools/build.sh`: exports the ear alone (new `yoke_ear_test` part)
  and the plate alone, intersects them, and requires ≥1500 mm³ of shared volume. The broken geometry
  scores 2.3.
  ⚠️ Moving the joint also invalidated the cowl-fixing gate's hardcoded probe axis, which still read
  y=−4 — and the gate said so immediately ("34.60 mm gap … the screw spans air"), which is the right
  failure to get from a stale probe rather than a silent pass.
- **The pivot bolt could not be fitted (found by eye, 2026-09-15).** Owner: *"When I looked at the
  yoke, there was no hole to feed a bolt through."* Correct, and three separate things were wrong:
  **(1) The bore did not go through.** `yoke_leg_bore()` started at the puck's own root face and ran
  OUTWARD, on the reasoning that the puck's root is the near face "as the bolt is offered up from
  that side" — but the bolt is offered from the ARM, i.e. outboard, and has to exit the far side for
  its nyloc. The leg's Stage C material continues inboard of the puck and left a solid plug measured
  at x = 13.75–17.75: **4.25 mm of ASA between the bolt's tip and daylight.**
  **(2) The nut had nothing square to sit on.** Once bored through, the face the nyloc lands on was
  the leg's own taper flank, wandering **2.6 mm across the nut's Ø10 footprint** (11.60–15.95 across
  Ø20). A nut pulled onto a slope cocks, bears on one edge and relaxes as the ASA creeps — on the
  joint that holds the screen's angle.
  **(3) The head could not be inserted.** The rising rib joins the arm's tip puck 1.1 mm PROUD of its
  face, inside a Ø10 head's footprint and across its insertion path. Sinking a counterbored seat did
  not fix that on its own — the first attempt left the seat flat at x = 34.90 with the rib still at
  38.55, in front of it; the bore now runs `pivot_head_clear` outward past the face as well as into
  it. A second iteration was needed there too: the lead-in cone ran from the seat's full Ø11.5 down
  to the bore, which is not a lead-in but a 0.6 mm taper across the whole bearing face, and the gate
  measured 0.35 mm of slope where the nut read 0.00.
  ⛔ **The only assertion on this bore checked that it was not too WIDE** (`pivot_bolt_clear_d <
  spline_id`). Nothing asked whether it went through, landed on anything square, or admitted a head.
  **Fixed:** the bore starts at the leg's own inboard face; a `yoke_nut_pad()` boss gives the nut a
  flat out at the leg's nominal plane (chosen over a measured number so it stays proud if the taper
  is ever re-shaped); the arm gets a counterbored head seat that also clears the rib. Both faces now
  measure **flat to 0.00 mm** across their own bearing annulus.
  ⭐ The bolt's length is now **derived from the stack rather than carried by hand** — `pivot_grip =
  leg_w/2 + yoke_tip_h + spline_seat + arm_tip_h − pivot_head_sink` = 26.1 mm → **M6 × 35** with a
  1.6 mm washer, 7.3 mm into the nut, asserted against both a too-short and an absurdly-long bound.
  ⭐ **New pivot gate** in `tools/build.sh`: walks the real axis through the real exported parts in
  the assembled frame and checks all three failures at once — clear through, grip matching the
  model's own derived figure within 0.6 mm, and both bearing faces flat to 0.3 mm over the annulus
  the fastener actually touches (not inside it, where the bore's own chamfer lives).
  ⚠️ One more trap recorded in passing: `yoke_pivot_bore_x0` was first written as a top-level
  assignment reading `pivot_x_r`, which is defined much further down the file. It silently evaluated
  to `undef`, put the bore at x = 0, drilled through the middle of the bearing plate, and CGAL
  reported `Volumes: 4` — the part in three pieces. Module *bodies* resolve at instantiation;
  top-level assignments do not.
- **The yoke's legs hung off the bearing plate by a 36 mm² shear web (found by eye, 2026-09-15).**
  Owner, looking at the side view: *"there is only a thin bit of plastic connecting where the back of
  the part mounts to the display to the rest of the yoke, this should be thicker."* Correct.
  ⛔ **And the load-path section scan added the same day passed it at 194.6 mm².** That scan cuts
  perpendicular to Y; Y is the one direction the web looked thick in. Stage A has to climb 13 mm of Z
  across the 2.32 mm of Y the flat-band guard allows (a 5.6:1 slope), so the join was an 18 mm wide,
  ~2 mm thick sheared web. Cut at 72-78°, the way the load peels the leg off the plate, the verified
  plate→pivot throat is **36.4 mm²**.
  **Fixed** with a gusset, not a wider Stage A — the 2.32 mm is forced by a real clearance constraint
  (low-Z material must stay inside the display's flat band). The load now also runs through the one
  region with no clearance constraint at all, directly above the bearing plate: a wedge buried
  `yoke_gusset_bite` (3 mm) into the plate's top face, running north to `yoke_gusset_clear` (3 mm)
  short of the boot's relief pocket, ramping up to meet the riser. The plate is solid 18-of-18 mm
  under the leg's whole X band there — measured on `yoke-plate-test.stl`, not assumed — so the
  gusset's underside is fully carried: no overhang added, the yoke's down-facing area is unchanged at
  2644 mm², and it still prints with no support. Throat **36.4 → 182.2 mm² (5×)** for 4.3 cm³ of
  plastic (yoke volume 66534.6 → 70787.3 mm³). The minimum on the path is now the leg's own uniform
  run rather than a junction.
  ⭐ **New permanent throat search** (`tools/check_throat.py`, gated in `tools/build.sh`): sweeps the
  cutting plane's angle instead of picking one, and reports the smallest section that *verifiably
  separates* the load's origin from its destination — the part is cut and the piece holding the
  destination must not hold the origin. Without that separation test the search only finds the part's
  own edges, where area tends to zero. Gates the yoke at 150 mm² and the arm at 200 mm²; ~20 s per
  part. Proven to fire against the pre-gusset yoke (36.7 mm²). The arm was measured on the same swept
  basis rather than assumed healthy — it comes out at **234 mm²** against its 261.6 mm² axis-aligned
  minimum, so it has no hidden weak plane. That is a result, not a foregone conclusion.
- **`brow_test`'s stated print orientation was the worst of the six.** `docs/printing.md` said
  "flat", which measures **8874 mm²** of steeply down-facing area; standing it on its riser with the
  visor pointing up — the same way up as the cowl, since the visor narrows all the way to its tip —
  measures **0 mm²**. Corrected. The same section's blanket claim that "every part prints unsupported
  in the orientation above" had never been measured either; it is now replaced with the per-part
  numbers, the caveat that a horizontal bore's ceiling is not a support problem, and an explicit ⬜ on
  the `yoke`/`arm` spline orientations that have been open since the tilt-axis fix.
- **`tools/render-gen4.sh` could not run in a clean clone.** It still carried the two hazards
  `tools/build.sh` was fixed for on 2026-09-14: a hardcoded `/root/.venvs/revv1/bin/python`, and a
  `../tools/check_fit.py` path pointing **outside the repository**. Now resolves the interpreter the
  same way `build.sh` does (`$REVV1_PY` → local venv → `python3`) and uses the vendored
  `tools/check_fit.py`.
- **The sun visor shaded nothing, and then shaded too little (2026-09-15).** Owner: *"The 'brow'
  doesn't even reach across the top, the point of it was to block sunlight, that blocks nothing."*
  Two separate defects, found in that order.
  **(1) It pointed the wrong way.** `brow` was measured off the cowl's own rear face, not off the
  glass, so a "19mm brow" put its tip at z=-19 with the glass at z=-26 — **7mm behind the surface it
  was supposed to shade**, projecting backwards. Measured shade at every sun angle: **0.0%**. The
  acceptance criterion had been "the brow projects `brow` mm", which the part satisfied exactly; it
  measured the mechanism, not the job — the same failure mode as the tilt joint that rolled instead
  of pitching. `brow` is now the TRUE projection past the glass plane and is **33mm**.
  **(2) Reaching further did almost nothing.** With the tip out past the glass the visor still
  shaded only **14.8%** at 45°. Stretching projection to 45mm gave 17.2% and to 60mm gave 20.4% —
  and the shadow's depth down the screen did not move at all, 14.1mm in every case. The straight
  taper had narrowed to a 2mm spike by mid-projection, so the screen's outer columns were in full
  sun however far the spike reached. **Width, not projection, is the lever** — measured, not argued.
  **Fixed** by making the plan curve a **superellipse** (`brow_plan_n`=3, `brow_stations`=14 lofted
  sin-spaced stations clustered at the nose): full width at the glass plane, holding most of it for
  most of the run, then turning back to a blunt rounded nose. Same 33mm projection, same rounded
  silhouette the owner asked for. `brow_edge_x` also corrected from `disp_w/2 - disp_corner_r` (=71)
  to `disp_w/2 + reveal - brow_d_s/2` (=79): the old value applied the box's own R9 corner logic to
  a feature that sits entirely above the box, carried by the full-width **riser**, leaving the visor
  9.5mm per side narrower than its own support and a visible width crease in plan view.
  Result: **27.7% shaded at 45°** (was 0.0%, then 14.8%), 49.3% at 60°, 94.0% at 75°; shadow depth
  28.2mm (was 14.1mm). The visor's underside stays **flat**, deliberately — it extends toward the
  rider, so anything that shades the sun at a given angle also blocks the rider's eye at it; shade
  above ~45° is what the tilt joint is for.
  ⭐ **New permanent sun-visor shade test** (`tools/check_shade.py`, gated in `tools/build.sh`):
  ray-casts the glass from the sun at 45/60/75° **off the screen's own normal** and fails the build
  below 20% at 45°. Proven to fire — the shipped-and-committed old brow scores 0.0% and fails by 20
  points, and the straight-taper shape scores 14.8% and fails too.
  The cowl's own fill gate was re-derived for the new solid visor (its expectation still modelled a
  19mm hollow full-width prism) and its floor tightened 0.60 → 0.66: at the shipped 0.733, deleting
  the visor reads 0.51 and losing half of it 0.62 — both now fail, where the old floor passed the
  half-lost case.
- **The clamp-to-spline rib had collapsed to a 0.2mm knife edge (found by eye, 2026-09-15).** Owner:
  *"Ensure that there is enough material holding the clamp to the handlebars to the toothed piece.
  It looks very thin."* They were right — a station-by-station section scan of `arm()` (intersect
  with a 1mm slab, volume ÷ thickness) found the rising rib's "vertical riser" stage down to
  **4 mm²**, not the ~160mm² its own comment assumed: two `taper_wp()` waypoints at the *same* Y
  cannot gain any real Y-thickness from a `hull()` between them (a convex hull is bounded by the
  union of its inputs' own Y-range, the same rule this file leans on everywhere else — here it was
  working against the design). Every existing check — watertight, 0 boundary, 0 non-manifold, 1
  component, whole-part volume, clearance, a normal render — stayed green throughout; none of them
  measure a cross-section. **Fixed** by widening the riser to a real Y-span (new
  `clamp_riser_y0`/`clamp_riser_y1`, 14mm, inboard of the clamp tube's own edges) instead of a
  single Y — that stage now measures a flat **284.00mm²** across its whole z=24..26 floor,
  comparable to its neighbours (307-592mm² either side). The **scanned load path's** own minimum is
  **261.61mm² at z=0**, the clamp end — a different feature, and above the 200mm² floor. Also corrected in passing: the
  yoke leg's own documented minimum was itself a never-measured hand estimate (144mm² claimed,
  ~119mm² actual — `docs/design-notes.md`), and `arm_w`'s own comment had the wrong axis (claimed Y,
  is actually X) since the ⚠ DM-6 axis rework.
  ⭐ **New permanent load-path section scan** in `tools/build.sh`: the same slab-intersection method
  (no shapely needed), run at 1mm stations along `arm.stl`'s clamp→spline path (floor 200mm²) and
  `yoke-leg-test.stl`'s own path (floor 100mm², reflecting its different, already-reasoned minimum)
  — fails the build if either drops below its floor. Proven to fire: reproduces the 4mm² defect
  against the pre-fix geometry, and independently catches a synthetic `leg_w=6` yoke-leg thinning
  (~46-65mm²) that clears every pre-existing assertion.
- **The tilt joint now actually tilts (⚠ DM-6 re-derived).** The face spline's axis was the
  display's own normal, so rotating the joint rolled the screen in its own plane instead of
  pitching it — found 2026-09-14 during assembly rendering. Re-derived DM-6 for an axis parallel
  to the bar: the yoke's female spline boss now grows sideways (model +X) off a re-worked lower
  arm (new `yoke_approach_y`/`yoke_pivot_puck()` stages; `pivot_x`/`pivot_y`/`pivot_z` replace the
  old single `pivot_c` point); the arm's own tip stack and male spline are rotated onto the same
  axis; `arm_seat()` is rebuilt from scratch for the new seating geometry (base rotation
  `rotate([0,-90,-90])`, a theta-dependent translate that pivots about the physical hinge line
  rather than the origin). New top-level `arm_seat_theta` parameter (0 is the reference pose; any
  multiple of 7.5° re-meshes exactly and picks a different pitch).
  **Cowl opening widened and made asymmetric** (`open_x0`/`open_x1` replace the old symmetric
  `open_w`): with the axis fix the arm's clamp reaches out along shared X (the bar's own length)
  by a real, theta-independent amount instead of into depth, and the old ±25mm opening was too
  narrow on the clamp's own side (found via `check_fit.py`: 1361-2729mm³ of real interference,
  cowl/display vs the positioned arm and cap). M3 boss positions (`m3_x_left`/`m3_x_right`) follow
  the new asymmetric opening.
  **Screen height above the bar moves from 35mm to 52mm** (top edge 129→146mm) — the display's own
  clearance from the pivot and the pivot's own clearance from the clamp now stack on the same axis
  instead of two independent ones; see `docs/bike-fitment.md` and `docs/design-notes.md`'s DM-6.
  ⭐ **New permanent pitch acceptance test** in `tools/build.sh`: two pairs of marker rods
  (`pitch_probe_fixed`/`pitch_probe_arm`, new parts) exported at `arm_seat_theta` = 0/7.5/15/22.5°
  prove, on real geometry, that the display's elevation changes by exactly the click step (a
  3-step rotation moves pitch by 22.5°) while roll and the hinge axis itself stay fixed — this is
  the check that was missing before and the reason the defect survived every other one (mesh
  health, clearance, and the spline's own meshing proof all say nothing about which axis the joint
  turns on).
  ⚠ **Two bugs caught and fixed during this same rework, before either shipped, by the rod-probe
  method `docs/spline-verification.md` §4 mandates for this geometry** (neither a render nor
  `check_fit.py` could have caught them — the codebase's own established policy is that a
  whole-spline-ring boolean is never trustworthy, so yoke-vs-arm is deliberately never intersected):
  (1) `arm_seat()`'s base rotation had the wrong sign on which way "up the rib" maps to shared Y,
  putting the clamp cap back up inside the display/yoke (caught by `check_fit.py`, 400-2700mm³ of
  real interference on 4 pairs) — fixed to `rotate([0,-90,-90])` with a re-solved translate.
  (2) the male spline's own translate omitted `yoke_tip_h` (the female boss's own standoff from
  its root), landing the male's solid base disc 1.7mm deep into the female's at every angle sampled
  — invisible to every other check because nothing ever booleans yoke against arm. Both fixed and
  re-verified by rod probe (male/female overlap now ~0.09mm, closed by the M6 pivot bolt's own
  clamping — consistent with the same eps convention already used, unflagged, elsewhere in this
  construction).
  `yoke_standoff` raised 8→12mm: the pivot puck is now a full-diameter disc *centred* on
  `pivot_z`, not a flat cap sitting on top of it, so its own lowest point is `pivot_z-spline_od/2`
  — at the old value that was −4mm, below the bearing face's own z=0 in the "bearing face on the
  bed" print orientation (`docs/printing.md`). New assert (`PIVOT BELOW THE BED`) guards it.
  `docs/printing.md`'s arm/yoke orientation rows flag the spline's own print orientation as an open
  question (its disc is no longer a flat face at either Z extreme, so "spline face down" no longer
  has a direct equivalent) rather than repeat the stale pre-rework guidance; `plate()`'s bboxes
  re-measured and the arm's Z-flip removed (its bore-side is already at z=0, unchanged) to match.
  New `pivot_puck_test` part + build.sh check (puck volume vs. a closed-form frustum+disc formula,
  0.999 ratio) and a whole-yoke volume sanity check, guarding the new pivot geometry the same way
  the historical hollow-tooth defect is guarded.
  All clearance pairs re-verified CLEAR on the corrected geometry (`tools/build.sh` and
  `tools/render-gen4.sh`); `tools/render-gen4.sh`'s assembly camera angles re-derived (shared Y is
  now the display's vertical axis and shared Z is depth — swapped from before the fix; the old
  iso/side/front rotations looked along the wrong axis and showed the display edge-on).

### Added
- **Assembly view, print plate, and `tools/render-gen4.sh`.** `assembly()` positions every part as
  it actually assembles — display, yoke, cowl, arm, cap, handlebar and centre bracket (the last two
  as stand-ins; not printed), each a distinct `color()`. The arm/cap/bar/bracket are seated with
  `arm_seat()`, the same transform `tools/build.sh`'s own cowl-clearance check already derived and
  proved, reused verbatim rather than re-derived (confirmed bit-identical against that check's own
  positioned export before relying on it). `plate()` lays the 4 printable parts flat in the print
  orientation `docs/printing.md` specifies (yoke and cap need only a mirror or no transform at all —
  their "down" face is already at their own Z=0; arm and cowl need a mirror plus a translate by
  their own Z maximum — verified against each part's real exported bbox, not guessed). One new
  `assert()`: the handlebar bracket stand-in's width, derived from `arm_crank`/`clamp_x0`/`clamp_w`,
  must still equal `docs/bike-fitment.md`'s stated 45 mm.
  Verified: `display`/`yoke`/`cowl` vs the POSITIONED `arm`/`cap` all CLEAR with `tools/check_fit.py`
  (5 new pairs, plus 3 already covered by `build.sh`'s own check, re-confirmed) — every pair except
  yoke-vs-arm, whose only real contact is the spline teeth and is proven instead in
  `docs/spline-verification.md` (a whole-ring boolean there is not trustworthy either engine).
  `tools/render-gen4.sh` exports every STL and every PNG (7 single parts, the plate, and the
  assembly's iso/side/front) in one command; every PNG call greps openscad's own output for `ERROR`
  and fails the run on a match, since PNG export exits 0 on a fired `assert()` or an unrecognised
  `part` alike — demonstrated against a deliberately bogus part name.
- **Arm + clamp cap** — the handlebar-side mount. Bore is a tapered cone (`bore_at()`) matching the
  bar's own measured 1:10 taper (`docs/bike-fitment.md`), not a cylinder; split clamp with a
  `pinch_gap` at two M5 ear bosses (heads counterbored into the cap); the arm carries `arm_crank` so
  the screen centres on the bike and the male spline up to the pivot. Six new `assert()` guards.
  Verified: bore diameter measured at both ends against `bore_at()` (±0.01mm, facet tolerance); a
  cylindrical bore at the mean diameter shown to interfere with the real tapered bar by 219.5mm³
  (`tools/check_fit.py`); male spline proven CLEAR against the yoke's female when correctly seated,
  and a deliberate half-tooth-pitch misalignment shown to collide (1.5mm³, 96 contacts); arm and cap
  proven mutually CLEAR at the bore and both ears. Both parts watertight, 0 non-manifold edges, 1
  connected component.
- Repository structure, documentation and CC BY-SA 4.0 licence.
- **Fit gauge** — the first part to print. 101 × 48.6 × 8 mm, verified single body.
- Parametric model core: the display's canonical geometry, the `p()` doc-coords→model mapper,
  shared `hole_pattern()` / `boot_slot()` modules, and eight `assert()` design guards.
- `tools/check_stl.py` — bounding-box verification for exports.
- `docs/display-geometry.md` — the full measured geometry of the `CJ-V5-04`'s rear face.

### Confirmed on hardware (2026-09-13)
- **The hole pattern is confirmed** — a printed gauge bolted to a display with all three M5 × 12.
- **M5 × 12 into 8 mm parts is the right pairing** — 4 mm engaged, no bottoming.
- **The flat bearing band is 23.0 … 71.6**, ~6 mm narrower than the manual's side elevation implies.
  Yoke footprint narrows accordingly.

### Notes
- Bolts are **M5 × 12 into 8 mm parts** — 4 mm engaged in a 5 mm thread. The gauge is the same
  thickness as the yoke so it tests the real joint rather than a proxy.
