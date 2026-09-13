# Changelog

Dates are ISO. This project is pre-1.0; parts land as they are verified.

## Unreleased

### Added
- Repository structure, documentation and CC BY-SA 4.0 licence.
- **Fit gauge** — the first part to print. 101 × 48.6 × 8 mm, verified single body.
- Parametric model core: the display's canonical geometry, the `p()` doc-coords→model mapper,
  shared `hole_pattern()` / `boot_slot()` modules, and eight `assert()` design guards.
- `tools/check_stl.py` — bounding-box verification for exports.
- `docs/display-geometry.md` — the full measured geometry of the `CJ-V5-04`'s rear face.

### Confirmed on hardware (2026-09-13)
- **The hole pattern is real.** A printed gauge went onto a display and all three M5 × 12 bolts
  pulled it tight. The three coordinates are no longer drawing-derived.
- **M5 × 12 into 8 mm parts is the right pairing** — 4 mm engaged, no bottoming.
- **The flat bearing band is narrower than the drawing implied**: **23.0 … 71.6**, not 20.0 … 74.6.
  The gauge overhung ~3 mm at each end. A side elevation shows where a surface *begins* to chamfer;
  the genuinely flat area stops inboard of that. Yoke footprint narrows accordingly.

### Notes
- Bolts are **M5 × 12 into 8 mm parts** (4 mm engaged in a 5 mm thread). Earlier drafts used
  M5 × 10 into 6 mm; changed to match commonly stocked lengths. The gauge is deliberately the same
  thickness as the yoke so it tests the real joint rather than a proxy.
