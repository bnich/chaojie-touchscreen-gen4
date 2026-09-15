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

### Added
- **Four new renders** (`tools/render-gen4.sh`): `gen4-assembly-rider.png` (the view from the
  saddle), `gen4-assembly-threequarter.png`, and `gen4-visor-plan.png` / `gen4-visor-profile.png` —
  the two views the visor's shape is actually judged in (its plan silhouette, and how far it reaches
  past the glass).

### Fixed
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
