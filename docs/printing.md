# Printing

## Material

**ASA.** The build rule is ASA / PC / PETG-CF and **never PLA**.

PLA creeps under sustained load and softens around 60 °C — a dark bracket in direct summer sun
reaches that, and it is carrying a screen on a moving vehicle. ASA earns its place twice over here:
it also does not go chalky under UV, which matters for a part living in the sun on the front of a
vehicle. PETG-CF is a good alternative if you want a flatter, more granular texture that hides layer
lines well; PC if you have the enclosure for it.

**The fit gauge is the exception** — print it in whatever is loaded. It is a bench check held against
the display for a minute and then thrown away. It never sees load, heat or UV.

## Orientation, per part

⭐ **Two-clamp mount (2026-09-15): print TWO of `arm` and TWO of `cap`, one clamp per side of the
bracket.** Both sides are the same STL — see `docs/design-notes.md` for why the part needs no
left/right variant.

| Part | Orientation | Why |
|---|---|---|
| `gauge` | flat, as exported | trivial |
| `yoke` | **bearing face on the bed** | that face must be flat and dimensionally true — it is what seats against the display. Now carries a spline at EACH end (mirrored) rather than one off to a side; the bearing face itself is unaffected by that. ⬜ **Spline orientation open** since the tilt-joint fix (`docs/design-notes.md`'s DM-6): each pivot boss faces sideways (its axis parallel to the bar), so with the bearing face down each Ø40 disc stands with its face vertical, a puck hanging off its own leg, rather than the flat "teeth as vertical walls off a horizontal disc" of the pre-fix geometry. Whether that needs support has not been slicer-checked |
| `arm` (×2) | bore-side down (clamp bore horizontal) | ⬜ **Spline orientation open**, same reason as the yoke above — the male spline's own disc is no longer a flat face at either Z extreme (it faces sideways, arm-local Y), so there is no single flip that puts it flat on the bed alongside the bore. Not slicer-checked |
| `cap` (×2) | bore-side down | no supports needed |
| `cowl` | **visible face down on a textured sheet** | ⭐ this is the whole reason the cowl is a separate part. The surface people see becomes one uniform moulded-looking texture rather than stacked layer lines. Ribs and bosses face up. Its bottom opening is now one symmetric notch (⭐ 2026-09-15) wide enough for both legs and both clamps |
| `brow_test` | flat | throwaway |

## Settings

Nothing exotic. Starting points:

- **Layer height** 0.2 mm for structural parts, **0.16 mm for the cowl** (it is the visible one).
- **Walls** 4 minimum on the yoke and arm; the cowl is designed around **2.4 mm = 6 perimeters at
  0.4 mm**, so set perimeters to match rather than letting infill do the work.
- **Infill** 40–50 % on yoke and arm (both clamp halves — print two of each). They are small parts and
  this is not where to save filament.
- **Supports** none required for any part in its stated orientation. If your slicer wants supports,
  the part is oriented wrong.
- **Brim** helps on ASA, which likes to lift.

## No supports by design

Every part is shaped so it prints unsupported in the orientation above. If you re-orient something
for your own reasons, check the overhangs yourself — the model does not enforce print orientation.

## Print in this order

The order exists to catch mistakes cheaply. Do not skip ahead.

1. **`gauge`** — proves the hole pattern, the slot, the flat-band assumption and your bolt length
   against the real display. Short print. Everything downstream inherits that hole pattern, so if it
   is wrong you want to know now.
2. **`brow_test`** — the riser and visor alone. Confirms the visor's reach and shape against the
   real screen, seated normally, before the cowl's shape is committed. ⚠️ Check both things it can get
   wrong: that it shades the screen in sun, **and** that it does not cut into the top of the screen
   from your own riding position (`docs/design-notes.md`, "The underside is flat on purpose").
3. **`yoke`**
4. **`arm`** + **`cap`**, **×2 each** — needs your handlebar diameter measured **on both sides** first
   (`docs/bike-fitment.md` — the left side is a temporary assumption until confirmed). Print one pair,
   confirm it clamps and mates its spline correctly, before committing filament to the second.
5. **`cowl`** — last, because it is the only part whose shape depends on all the others being settled.

## Building the STLs yourself

Pre-built STLs are in [`stl/`](../stl). To regenerate them, or to build after changing a parameter:

```bash
./tools/build.sh
```

That exports every part and checks each exported bounding box. It needs OpenSCAD on `PATH`.

> ⚠️ **OpenSCAD gotcha, if you script around this.** A failed `assert()` still **exits 0** when
> exporting a "tree" format (`echo`, `csg`, `ast`, `term`). It only returns non-zero for a **solid**
> format (`stl`, `off`, `3mf`, `amf`). So an assertion checked with the wrong export format silently
> reports success. `build.sh` exports solid formats for exactly this reason. **PNG renders never catch
> assertion failures** — do not rely on a render alone as a check.
>
> Related: `openscad -o /dev/null` fails for *any* `.scad` file, because `/dev/null` has no extension
> to infer a format from. Pass `--export-format=asciistl`.
