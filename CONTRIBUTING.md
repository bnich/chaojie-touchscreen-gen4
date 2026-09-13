# Contributing

## Most valuable contribution: measurements

The display's dimensions here are derived from the factory manual's §III drawing, calibrated and
cross-checked, but taken from **one unit**. Confirmed measurements from another `CJ-V5-04` would
upgrade several ⬜ figures to ✅. Especially wanted:

- The Y position of the upper hole row (currently drawing-derived at 40.9).
- The flat band's real limits (20.0 / 74.6).
- Whether the Ø21.7 collar is raised or flush.
- The display's weight.

Photos of the mount fitted to a bike are also genuinely useful.

## Changing the model

`src/gen4-display-mount.scad` is one file with a heavily commented parameter header. The house style
is that **every number carries its reasoning** — not what it is, but why. Please match that; a bare
literal in this file is a bug waiting to happen.

Before opening a PR:

```bash
./tools/build.sh          # exports every part and checks every bounding box
```

If you change a design constraint, **add or update the matching `assert()`** — and verify it actually
fires by deliberately breaking it. An assertion that never fires is not a test.

> ⚠️ Check assertions with a **solid** export format. OpenSCAD exits 0 on a failed `assert()` for tree
> formats (`echo`, `csg`, `ast`, `term`) and PNG, and only non-zero for `stl` / `off` / `3mf` / `amf`.

## Scope

This repo is the mount. Wiring, controller configuration and vehicle-specific work belong elsewhere —
except for `docs/display-geometry.md` §5, which carries the connector and signal facts people
predictably ask for next.

## Licence

Contributions are accepted under [CC BY-SA 4.0](LICENSE), the project's licence.
