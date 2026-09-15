# Fitting it to the bike

What the clamps need from your handlebar, and where the screen ends up. Measured on a
**Ride1Up REVV1 FS**; the numbers are parameters, so adapting to another bar is a matter of
remeasuring rather than remodelling.

⭐ **Two-clamp mount (2026-09-15).** The mount clamps the bar on **both** sides of the centre
bracket — one clamp butting each of its two faces — instead of a single clamp on one side. The owner
rejected the original one-sided design as structurally inadequate ("a tiny sliver of plastic
supporting the entire display"); see `docs/design-notes.md` for the full reasoning. **Both clamps are
the same printed part** (`arm`/`cap`), so print two of each.

---

## ⚠️ The bar is tapered

This is the fact the clamps turn on, and it is easy to miss because the *grip* ends of these bars are
a constant 22.2 mm.

A **45 mm wide bracket** clamps the bar to the bike, on the centreline, with a clamp butting each of
its two faces. Measuring outward from the bracket's **right-hand** face:

| Distance from the bracket face | Bar Ø |
|---|---|
| 0 mm | **32.0** |
| 10 mm | **31.0** |
| 20 mm | **30.0** |
| beyond 20 mm | the bar curves upward — unusable |

Perfectly linear: **Ø = 32.0 − 0.1·x**. A **1:10 taper on diameter**, half-angle ≈ **2.86°**. 32 mm is
1.25″, so this is a standard oversize moto bar tapering toward 22.2 mm at the grips.

⬜ **TEMPORARY VALUE — the left side has not been measured.** Only the right side (above) was put
under calipers. The left side's `bar_d0`/`bar_taper`/`bar_run` are **assumed to mirror the right**
exactly, flagged in `src/gen4-display-mount.scad` at their definition. **Confirm the left side on the
bike before printing the left clamp for real** — measure the diameter at 0/10/20 mm from the
bracket's left face, at more than one clock angle. If it differs even slightly, the two clamps stop
being one shared part: split `bar_d0`/`bar_taper`/`bar_run` into `_r`/`_l` pairs and give the left
clamp its own `bore_at()`.

### What it forces

**The bore is a cone, not a cylinder.** A cylindrical bore on a tapered bar contacts on a *line* at
its large end only. Across an 18 mm clamp the diameter changes 1.8 mm — roughly nine times print
tolerance, far too much to take up by squeezing. In the model:

```openscad
bar_d0    = 32.0;   // Ø at the bracket face
bar_taper = 0.1;    // Ø lost per mm outward
bar_run   = 20;     // usable straight length
```

**Each clamp is 18 mm wide**, because 20 mm is the entire usable run on each side.

**Butt each clamp against its own face of the bracket.** The taper means a clamp can only creep
*outboard*, into a smaller diameter; the bracket blocks the inboard direction mechanically. So if one
ever does move it goes **visibly loose** rather than failing quietly. ⚠️ That is a reason to inspect
it, not a reason to trust it.

---

## ⚠️ Reroute the cables first

On this bike at least two cables cross the bar through the clamp zones. **Move them behind or under
the bar before either clamp goes on.** A cable trapped under a clamped bore chafes through
eventually, and the damage is invisible until it is not.

---

## Where the screen ends up

Nothing obstructs above the bar on this bike, so height is an ergonomic choice — but there is a hard
floor. Each clamp body is about Ø48 over a Ø34.3 bore, so its top sits **24 mm above the bar's
centreline**, and the tilt spline is Ø40. For the spline to clear its own clamp the pivot must be at
least ~45 mm above the centreline. Lower than that and the leg has to reach backward instead of up,
which is a different part. This is a **per-clamp** clearance fact — it doesn't depend on how far
apart the two clamps sit — so it is unchanged by the two-clamp rework.

The lowest workable position is the default:

| | mm |
|---|---|
| `arm_len` — each pivot's centre above its own clamp's bar centreline | **45** |
| Display **bottom** edge above the bar's top surface | **52** |
| Display **top** edge above the bar's top surface | 146 |

⭐ **No crank any more.** The old single-clamp design needed `arm_crank` (32.5 mm) to drag its one
off-centre clamp's pivot back to the bike's centreline. With a clamp — and a spline — on **each**
side, the display centres itself between the two pivots by construction: the yoke's two female
splines sit at `±pivot_x_r`, mirror images of each other, and there is no crank parameter left to
drift out of sync with the bracket width. `pivot_x_r` is **derived** from the bracket's own 45 mm
width, not chosen — see `src/gen4-display-mount.scad`'s own comment above `pivot_x_r` for the closed
form.

The 52/146 mm figures are **unchanged from the single-clamp design** — the two-clamp rework only
moved things sideways (X: where the clamps and the two pivots sit relative to the bracket), never up,
down, forward or back (Y/Z: `arm_len`, `bar_d0`, `pivot_y` are all the same numbers as before), so the
screen's height above the bar carries over exactly.

⚠️ **Height above the bar is no longer independent of tilt.** A joint that actually pitches means
tilting the display swings its centroid — and so the whole assembly's reach — up/down and back/forth
around the pivot axis. The 52/146 mm figures above are for the **reference pose**
(`arm_seat_theta = 0` in `src/gen4-display-mount.scad`, the pose every render and clearance check in
this repo uses); a different one of the 48 valid 7.5° click positions puts the screen at a measurably
different height. This is expected — it is the whole point of a working tilt joint — not a modelling
error.

---

## Grip spread

The old single clamp gripped the bar over 18 mm, on one side of the bracket only. The two-clamp mount
grips over **~81 mm total** — an 18 mm clamp on each side of the 45 mm bracket (`45 + 2×18`) — spread
across both sides of the steering axis instead of hanging everything off a cantilever on one side of
it. This is the structural point of the rework, not a side effect of it.

---

## Adapting to a different bar

Remeasure and change four numbers (**on both sides** — see the ⬜ flag above):

```openscad
bar_d0    = 32.0;   // Ø where each clamp's inboard face will sit
bar_taper = 0.1;    // 0 for a parallel bar
bar_run   = 20;     // usable straight length
arm_len   = 45;     // pivot above the bar centreline — see the floor above
```

**Measure the diameter at three points along the run, on BOTH sides, not one reading on one side.** A
single reading cannot tell a tapered bar from a parallel one, and the difference decides whether the
bore is a cone or a cylinder. Take each reading at more than one clock angle too — a used bar goes
oval where clamps have sat. If the two sides differ, split `bar_d0`/`bar_taper`/`bar_run` into
`_r`/`_l` pairs — the two clamps are no longer one shared part.

If your bar is parallel, set `bar_taper = 0` and the bore becomes a cylinder; nothing else changes.
