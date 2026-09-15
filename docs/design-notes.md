# Design constraints

Read this before changing the model. Several things that look like arbitrary choices are forced by
the display, and "simplifying" them produces a part that renders fine and fails on the bike.

The model encodes each of these as an `assert()`, so if you change a parameter and break one, the
render stops and tells you which constraint you violated. **If an assertion fires, the number you
changed was wrong — not the assertion.**

---

## The two forced constraints

### 1. The boot slot opens upward

Covered in [display-geometry.md §4.3](display-geometry.md). Short version: the loom exits the middle
of the back, its connectors are too big to thread through any closed hole, and a downward slot would
cut off the lone M5. Up the centreline is the only direction that works.

This is why the yoke is a **Y-truss** — two arms down from the upper bolts meeting at a pad on the
lone bolt — rather than a plate.

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

## The sun brow

The cowl carries a short brow over the glass. It is not decoration. Chaojie does not publish this
panel's brightness, and it is a 5" glossy screen on an open vehicle — daylight readability is its
real weakness. A ~19 mm brow is the cheapest fix available and costs nothing to print as part of a
cowl you are making anyway. It also keeps rain and low winter sun off the glass.

⬜ **The projection is unproven.** Print the `brow_test` piece and hold it against the screen on the
bike, seated normally, before committing. Too little does nothing; too much reads as a peaked cap and
eats the top of the screen from an upright riding position. 18–20 mm is the range to try.

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
