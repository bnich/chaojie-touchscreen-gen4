# Fitting it to the bike

What the clamp end needs from your handlebar, and where the screen ends up. Measured on a
**Ride1Up REVV1 FS**; the numbers are parameters, so adapting to another bar is a matter of
remeasuring rather than remodelling.

---

## ⚠️ The bar is tapered

This is the fact the clamp turns on, and it is easy to miss because the *grip* end of these bars is a
constant 22.2 mm.

A **45 mm wide bracket** clamps the bar to the bike, on the centreline. Measuring outward from its
right-hand face:

| Distance from the bracket face | Bar Ø |
|---|---|
| 0 mm | **32.0** |
| 10 mm | **31.0** |
| 20 mm | **30.0** |
| beyond 20 mm | the bar curves upward — unusable |

Perfectly linear: **Ø = 32.0 − 0.1·x**. A **1:10 taper on diameter**, half-angle ≈ **2.86°**. 32 mm is
1.25″, so this is a standard oversize moto bar tapering toward 22.2 mm at the grips.

### What it forces

**The bore is a cone, not a cylinder.** A cylindrical bore on a tapered bar contacts on a *line* at
its large end only. Across an 18 mm clamp the diameter changes 1.8 mm — roughly nine times print
tolerance, far too much to take up by squeezing. In the model:

```openscad
bar_d0    = 32.0;   // Ø at the bracket face
bar_taper = 0.1;    // Ø lost per mm outward
bar_run   = 20;     // usable straight length
```

**The clamp is 18 mm wide**, because 20 mm is the entire usable run.

**Butt the clamp against the bracket's face.** The taper means the clamp can only creep *outboard*,
into a smaller diameter; the bracket blocks the inboard direction mechanically. So if it ever does
move it goes **visibly loose** rather than failing quietly. ⚠️ That is a reason to inspect it, not a
reason to trust it.

---

## ⚠️ Reroute the cables first

On this bike at least two cables cross the bar through the 20 mm the clamp needs. **Move them behind
or under the bar before the clamp goes on.** A cable trapped under a clamped bore chafes through
eventually, and the damage is invisible until it is not.

---

## Where the screen ends up

Nothing obstructs above the bar on this bike, so height is an ergonomic choice — but there is a hard
floor. The clamp body is about Ø48 over a Ø34.3 bore, so its top sits **24 mm above the bar's
centreline**, and the tilt spline is Ø40. For the spline to clear the clamp the pivot must be at least
~45 mm above the centreline. Lower than that and the arm has to reach backward instead of up, which
is a different part.

The lowest workable position is the default:

| | mm |
|---|---|
| `arm_len` — pivot centre above the bar centreline | **45** |
| `arm_crank` — inboard offset so the screen centres on the bike | **32.5** |
| Display **bottom** edge above the bar's top surface | **35** |
| Display **top** edge above the bar's top surface | 129 |

`arm_crank` exists because the clamp cannot sit on the centreline — the bracket is there. The
bracket's right face is 22.5 mm out, and an 18 mm clamp centred 10 mm beyond it puts the clamp centre
32.5 mm off centre. The arm carries that back so the screen is centred on the bike rather than
sitting to one side of it.

---

## Adapting to a different bar

Remeasure and change four numbers:

```openscad
bar_d0    = 32.0;   // Ø where the clamp's inboard face will sit
bar_taper = 0.1;    // 0 for a parallel bar
bar_run   = 20;     // usable straight length
arm_len   = 45;     // pivot above the bar centreline — see the floor above
```

**Measure the diameter at three points along the run, not one.** A single reading cannot tell a
tapered bar from a parallel one, and the difference decides whether the bore is a cone or a cylinder.
Take each reading at more than one clock angle too — a used bar goes oval where clamps have sat.

If your bar is parallel, set `bar_taper = 0` and the bore becomes a cylinder; nothing else changes.
