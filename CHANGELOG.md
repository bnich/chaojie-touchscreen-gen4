# Changelog

Dates are ISO. This project is pre-1.0; parts land as they are verified.

## Unreleased

### Added
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
