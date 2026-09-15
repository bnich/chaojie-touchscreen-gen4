# Design constraints

Read this before changing the model. Several things that look like arbitrary choices are forced by
the display, and "simplifying" them produces a part that renders fine and fails on the bike.

The model encodes each of these as an `assert()`, so if you change a parameter and break one, the
render stops and tells you which constraint you violated. **If an assertion fires, the number you
changed was wrong — not the assertion.**

---

## Two clamps, not one (2026-09-15)

The original design hung the whole display off **one** narrow yoke arm, necking down through the
cowl's opening to a **single** spline disc and **one** clamp on one side of the centre bracket — a
cantilever on a thin section, on a vehicle with no drivetrain damping. The owner rejected it:

> "That is a bad design. We should be attaching on both sides of the handlebars. There is a tiny
> sliver of plastic supporting the entire display."

Correct call — a two-sided mount was considered and discussed at design time, and it was wrongly
argued against then. Its advantages are exactly what a one-sided cantilever gives up:

- **Grip spread across ~81 mm** (an 18 mm clamp on each side of the 45 mm bracket) instead of 18 mm on
  one side of it.
- **The display centres itself.** With a spline on each side, mirror images of each other, there is no
  crank left to get wrong or drift out of sync with the bracket width — `pivot_x_r` (and its mirror
  `pivot_x_l`) is *derived* from the bracket's own measured 45 mm, not chosen and then checked against
  it after the fact.
- **A proper axle, not one disc taking the whole moment.** The tilt hinge is now a spline at *each* end
  of one shared axis, coaxial, each mating its own clamp — closer to a bicycle hub's two bearings than
  to a single boss cantilevered off a plate.
- **The load is shared and mostly in shear**, not a bending moment concentrated on one thin arm.

### One clamp part, mirrored, not two

`arm()`/`cap()` are unchanged in kind — still a two-piece bar clamp with a tapered bore and a male
spline — but there is now no `arm_crank`: each clamp roots its own spline at its own bare Y-midpoint
(`clamp_x0 + clamp_w/2`, no offset), and *the same printed part* is used on both sides. This works
because the clamp's own solid — round tube, symmetric ear bosses, a centred rib — is already
left-right symmetric about its own local X=0, and the male spline's tooth pattern (phase 0, an
arithmetic sequence of angles symmetric under negation) reproduces itself exactly under a mirror about
any plane containing its own axis. `clamp_seat(side)` (the renamed, generalised `arm_seat()`) seats the
right clamp with the same translate/rotate this file has always used, and seats the left one as
`mirror([1,0,0])` of that exact result — not a second, independently-solved rotation. The one subtlety
worth recording: mirroring about the plane **perpendicular to** the shared hinge axis (X=0, and the
hinge runs along X) **commutes** with the pitch rotation `theta`, because a reflection whose own axis
*is* the rotation axis negates both the axis and the angle, and the two negations cancel — so both
clamps use the *same* `theta`, not opposite-signed ones. Confirmed against the actual exported geometry
by the same pitch-acceptance test described below, not trusted on the algebra alone.

⚠️ **Left side of the bar is unmeasured.** Only the right side was put under calipers
(`docs/bike-fitment.md`). `bar_d0`/`bar_taper`/`bar_run` are **temporarily assumed** to mirror on the
left — flagged at their own definition in `src/gen4-display-mount.scad`. If the left side turns out to
differ, the two clamps stop being one shared part.

### Minimum cross-section in the load path

⭐ **Corrected 2026-09-15, after a real defect.** This table used to claim no station on the path was a
thin cantilevered sliver, including a rising-rib figure (`arm_w × ~8mm = 160mm²`) that was never
actually measured — a hand guess from the two end profiles, not a scan of the part in between. The
owner found the truth by eye: *"Ensure that there is enough material holding the clamp to the
handlebars to the toothed piece. It looks very thin."* They were right. A station-by-station section
scan (`tools/build.sh`, added the same day — intersect the part with a 1mm slab at each station,
volume ÷ thickness) confirmed it: the clamp's own rising rib had a "vertical riser" stage built from
two `taper_wp()` waypoints at the *same* Y, which cannot gain any real Y-thickness — a `hull()` between
two same-Y markers stays confined to that marker's own 0.2mm thickness for its entire run (the
mechanism, not just the number: `src/gen4-display-mount.scad`'s own block comment above `arm()`'s Stage
1). Measured minimum: **4 mm²** — a 20mm-wide, 0.2mm-thick knife edge — not the claimed 160. Every
other check stayed green throughout: watertight, 0 boundary, 0 non-manifold, 1 component, a plausible
total volume, clearance clean, a normal-looking render. None of them measure a cross-section; volume
catches a hollow part, nothing was watching minimum section. Fixed by widening that riser to a real
Y-span (`clamp_riser_y0`..`clamp_riser_y1`, 14mm, inboard of the clamp tube's own edges) instead of a
single Y. `tools/build.sh` now scans every station along both this path and the yoke leg's own, and
fails the build if either drops below a floor — the permanent check the project didn't have before.

The same pass corrected the yoke leg's own figure too: its true minimum is **~119 mm²**, not the 144
this table used to quote (`leg_w × yoke_t`, a hand estimate that missed a small dip during the root's
own taper into the riser — the identical kind of miss as the rib's, just a much smaller one). That
number is a reasoned, accepted trade (below), not a defect, and the fix above does not touch it.

Walking the path today, every figure measured by the same section scan, not estimated from end
profiles:

| Station | Cross-section (measured) |
|---|---|
| Bearing plate (bolted to the display) | `yoke_t` (8 mm) full-thickness slab, widened at its base to root both legs |
| Each leg's own root/riser (where it leaves the plate) | **~119 mm² minimum**, per leg — the tightest single cross-section on the whole path |
| The spline (each pivot) | Ø40 Hirth coupling, all 48 teeth engaging at once across a ~1144 mm² annulus — a distributed contact, not a point |
| Each clamp's own rising rib | **~284 mm² minimum** (widened 2026-09-15 from a 4 mm² knife edge — see above) |
| Each clamp body | Ø48 tube over a ≥Ø28 bore — a ring, not a sliver |

**The leg root, ~119 mm², is the minimum on the whole path** — narrower than the old single arm's own
root (26 × 8 = 208 mm²) taken in isolation, but there are now **two of them, in parallel**, for a
combined ~238 mm² carrying a load that used to be a full cantilever on the old single 208 mm² — a wider
total section carrying a smaller share each, not a thinner one carrying it all. Reducing `leg_w` from
the old arm's 26 mm to 18 mm was a deliberate trade for clearance from the lone M5's own socket sweep
(the two legs are no longer centred under it — see `pivot_x_r`'s own assertion in the model), not a
structural economy; there is headroom to widen it again if a print or a ride ever calls for it.
`tools/build.sh`'s own load-path scan holds this leg to a 100 mm² floor — real margin under the
measured ~119 mm² minimum — so any further narrowing gets caught by the build, not found by eye a
second time.

---

## The two forced constraints

### 1. The boot slot opens upward

Covered in [display-geometry.md §4.3](display-geometry.md). Short version: the loom exits the middle
of the back, its connectors are too big to thread through any closed hole, and a downward slot would
cut off the lone M5. Up the centreline is the only direction that works.

This is why the bearing plate is a wide, gusseted shape — three bolt pads plus two more hull anchors
(one per leg root, ⭐ 2026-09-15) — rather than a plain rectangle: every anchor has to stay clipped to
the flat band and clear of the boot's own upward slot.

### 2. The pivot sits well below the housing — DM-6, re-derived for a bar-parallel axis

**The tilt joint's axis has to be parallel to the handlebar**, not the display's own normal. A hinge
that swings the display's pitch (up/down, the whole point of a tilt mount) needs its axis running
across the bike, the same line the bar lies on — turning about the display's own normal instead just
rolls the screen in its own plane, which is a defect this design carried and fixed once (2026-09-14),
documented here so the reasoning survives, not the mistake.

That axis choice changes what "the pivot sits below the housing" has to defend against. With the axis
along the bar (model X), the toothed face's own reach along its axis is only a few millimetres — it
sits deep inside the display's own width, with no sideways offset to hide behind the way a normal-axis
boss could hide behind standoff depth. Clearance for both the display and the lone M5 has to come from
where the disc sits in the OTHER two axes (Y and Z), not from how far it stands off in Z.

**The display.** The disc is a Ø40 circle in the Y-Z plane. Placed entirely below the display's own
bottom edge in Y (rather than split across a Y/Z diagonal — simpler to build and reason about, and it
costs nothing since there is open air below the display anyway), it needs no Z clearance to avoid the
housing at all: its bottom edge is at model Y −70, 23 mm below the display's own bottom edge, so even
at the disc's nearest point (Y −50) there is a full 3 mm of air past the housing.

**The lone M5.** Automatically satisfied by the same margin — the bolt sits at model Y −16.3, deep
inside the display's own footprint, far closer to the display than to a pivot 70 mm below it. The
connecting arm's own root/riser staging (unchanged by this rework) still keeps material flush at the
bearing-plate thickness until it is past the bolt's own Y, exactly as before, so nothing between the
plate and the disc can shadow the bolt either.

**The cost, twice over.** The display's centre of mass now sits **70 mm** above the pivot (was 53 mm)
— on a ~0.4 kg display, ~0.34 N·m static, still comfortably inside what this spline is sized for. And
because both clearances (display, and the clamp-vs-spline check in `docs/bike-fitment.md`) now stack
on the SAME axis instead of two independent ones, the display sits **52 mm** above the bar's top
surface at the reference (theta=0) pose instead of the originally-chosen 35 mm — see
`docs/bike-fitment.md` for the full number and why a more compact, diagonal-clearance placement was
not pursued.

---

## Why a toothed face spline, not friction

A friction pivot — a bolt clamping two smooth faces — is the obvious cheap answer and it is the wrong
one here. Plastic-on-plastic under vibration relaxes; on a hub-motor vehicle with no drivetrain
damping it will need re-nipping, and eventually the faces polish and it stops holding at all. A
screen that droops at 40 mph is a permanent small annoyance.

A face spline carries the moment on **teeth** instead of friction, so an angle set today is still set
in a year. You trade infinite adjustment for 7.5° steps.

**Why a printed spline is trustworthy:** a face spline engages *every tooth at once*. With 48 teeth
the per-tooth load is tiny, so FDM's weakness across layer lines stops governing — which is what lets
the yoke print flat on its bearing face, the orientation its plate and bolt pads want anyway.

The model carries a **`teeth = false`** switch. Once you have settled on an angle from riding, the
same file prints the joint solid, with nothing left to loosen.

---

## Why two parts instead of one

The back of this display faces forward on a moped — it is a surface people see, not a bracket hidden
behind a screen. So there is a cosmetic cowl over the structural yoke.

Splitting them lets each be optimised separately:

- the **yoke** is oriented and ribbed for strength, and printed bearing-face-down;
- the **cowl** is thin-walled and printed **face-down on a textured sheet**, so the surface people see
  is one uniform moulded-looking texture instead of stacked layer lines.

It also means the cowl comes off for service **without ever disturbing those 5 mm threads**, which is
the fastener you least want to cycle.

---

## The sun visor

The cowl carries a visor over the glass. It is not decoration. Chaojie does not publish this panel's
brightness, and it is a 5" glossy screen on an open vehicle — daylight readability is its real
weakness. The visor costs nothing to print as part of a cowl you are making anyway, and it keeps rain
and low winter sun off the glass too.

### What it measures

`tools/check_shade.py` fires rays at the glass from a given sun angle and reports what fraction of
the screen the cowl actually blocks. The angle is measured **from the screen's own normal**, not from
the horizon — so "45°" means the sun is 45° off the direction the screen is pointing, whatever the
tilt joint is set to. That is the quantity that decides shading; world elevation is not.

| Sun, off the screen normal | Screen shaded | Shadow reaches, from the top edge |
|---|---|---|
| 45° | **27.7 %** | 28.2 mm |
| 60° | 49.3 % | 49.3 mm |
| 75° | 94.0 % | 94.0 mm |

Projection past the glass is **33 mm**. `tools/build.sh` holds a 20 % floor at 45°.

### ⚠️ Width is the lever, not projection

The obvious way to shade more is a longer nose. It does almost nothing here, and this was measured
rather than argued. On the earlier straight-taper visor, stretching projection from 33 mm to 45 mm
moved 45° shade 14.8 % → 17.2 %, and 60 mm reached only 20.4 % — while the shadow's depth down the
screen did not move at all, staying at 14.1 mm in every case. A row of screen is shaded only where
the visor is actually *over* it, so a visor that has tapered to a 2 mm spike by mid-projection leaves
the screen's outer columns in full sun however far that spike reaches.

So the plan curve is a **superellipse** (`brow_plan_n = 3`): full width at the glass plane, holding
most of it for most of the run, then turning back to a blunt rounded nose over the last few
millimetres. Same projection, same rounded silhouette, 27.7 % instead of 14.8 %. Raising the exponent
squares the curve off — more shade, blockier nose; lowering it toward 2 gives a sleek ellipse and
less shade. Move it and re-run the shade test.

### The underside is flat on purpose

Every station's profile sits on one shared plane, `brow_y0` (3 mm above the display's top edge).
Drooping the nose would shade more, and it is tempting — but the visor extends *toward the rider*,
and anything that shades the sun at a given angle also blocks the rider's eye at that angle. A drooped
nose eats the top of the screen from an upright riding position. Shade above ~45° is what the tilt
joint is for: point the screen at your eyes and the sun goes off-normal without the visor moving.

⬜ **Not bench-verified.** Print `brow_test` and hold it against the screen on the bike, seated
normally, before committing the cowl. The numbers above are ray-cast measurements of the model, not
of a printed part in sunlight.

---

## Making it look like a product rather than a print

Applied without exception:

| | |
|---|---|
| **R3 / R2 / R1** | **No edge is left sharp.** R3 on the cowl's outer perimeter, R2 on every other visible edge, R1 internal fillets at every wall-to-rib junction. The internal ones are not cosmetic — a sharp internal corner is where a printed part cracks |
| **R9 corners** | the cowl's corner radius **is the display's own**, so the two read as one object rather than two stacked ones |
| **0.5 mm reveal** | a **deliberate, even shadow gap** where the cowl meets the display, all the way round — not an attempt at zero. A consistent reveal reads as designed; a gap wandering from 0 to 0.6 reads as a bad fit. ⭐ This single detail does more than any other to separate "professional" from "printed" |
| **Uniform wall** | 2.4 mm throughout the cowl (6 perimeters at 0.4). Constant wall keeps the surface even and avoids dimpling where a thick section meets a thin one |
| **No visible fixings** | from the front there is nothing but shell. Both cowl screws go **upward through the bottom rim**, where only the road sees them |
| **Chamfered lead-ins** | 0.5 × 45° on every bolt hole and mating edge — assembly feels positive, and first-layer elephant-foot cannot foul the fit |

---

## Things deliberately not done

**No quick-release.** **The loom is moulded into the display**, with no connector at the screen end,
so a lift-off mount would hand you a screen still tethered to the bike. It only becomes worth building
if you put a connector in the loom yourself.

**No microphone port.** The cowl covers the mic hole at (80.2, 76.0) and it stays covered, keeping the
visible face unbroken. The cost is that CarPlay call audio into the display's own mic is gone. If you
want it, add a short slot or a group of Ø1.5 holes over that position — but a phone or helmet mic is
the better answer than cutting this shell.

---

## Origin

Designed for a Ride1Up REVV1 FS converted to a 5 kW hub motor, where this display replaces the stock
dash. Nothing in the mount is specific to that bike except the handlebar clamp diameter, which is a
parameter.
