# Changelog

Dates are ISO. This project is pre-1.0; parts land as they are verified.

## Unreleased

### Fixed
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
