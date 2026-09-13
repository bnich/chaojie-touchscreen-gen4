# Chaojie Gen 4 5" touchscreen — handlebar mount and rear cowl

A parametric, 3D-printable handlebar mount for the **Chaojie `CJ-V5-04`** 5" touchscreen display —
the panel sold with FarDriver controllers by E-Conic, EMF and others. It ships with no bracket of any
kind.

Four printed parts: a structural yoke that bolts to the display's three M5 inserts, a toothed-spline
tilt joint that **cannot creep**, a two-piece handlebar clamp, and a cosmetic rear cowl with an
integrated sun brow — because on a moped the back of this display faces the world.

<p align="center">
  <img src="renders/display-rear-geometry.svg" width="88%" alt="Dimensioned rear-face drawing of the Chaojie CJ-V5-04, showing the three M5 mounting holes at (39.50, 40.9), (120.50, 40.9) and (80.00, 63.28), the Ø21.7 cable-boot collar at the centre, and the flat bearing band between Y 23.0 and Y 71.6">
</p>

---

## 🚧 Status

**Work in progress — not yet printable end to end.** Built and verified so far:

| Part | State |
|---|---|
| **Fit gauge** | ✅ done, **printed and proven on a real display** — [`stl/gen4-gauge.stl`](stl) |
| Face spline (tilt joint) | 🔨 in progress |
| Yoke | ⬜ next |
| Arm + clamp cap | ⬜ |
| Cowl + sun brow | ⬜ |
| Assembly renders | ⬜ — arrive with the parts |

**The fit gauge is printable today**, and it is the right thing to print first regardless (see below).
Watch the repo or check [CHANGELOG.md](CHANGELOG.md) for the rest.

> The photorealistic mocks of the finished mount, and of the whole thing assembled on a display, go
> here as soon as the parts they depict actually exist. No renders of vapourware.

---

## Does this fit my display?

It fits the **`CJ-V5-04`** — the 5", 800 × 480, DC 12–96 V panel with a `DJ7091A-2.8-11` 9-pin main
lead and a cable bundle emerging from the middle of its back.

It does **not** fit the 3" `CJ-V3-01` or the Gen 3 touchscreen; different housings, different hole
patterns.

Measure before you print. The drawing above is the whole test: three M5 holes, 81.0 mm apart with a
third 22.39 mm below the centre of that pair.

---

## Start here: print the fit gauge

Everything in this design hangs off a three-hole pattern that was measured off the factory manual's
dimensioned drawing and cross-checked four ways. It is almost certainly right. **Prove it on your own
unit anyway**, for the cost of a short print:

```bash
# pre-built, or rebuild it yourself:
openscad -o stl/gen4-gauge.stl -D 'part="gauge"' src/gen4-display-mount.scad
```

Print it flat, no supports, any filament you have loaded. Then:

1. **Does it sit flat** on the raised band on the display's back, without rocking?
2. **Do three M5 × 12 bolts thread in** and pull the gauge tight — *by hand*, before any tool?
3. **Does the slot clear the cable boot** with the loom in place?

If all three pass, the hole pattern is proven and everything else can be built on it.

⚠️ **On question 2, the answer matters more than it looks.** Those inserts give **5 mm of usable
thread — one bolt diameter.** A bolt that bottoms out feels tight and is holding nothing at all. This
is why the gauge is 8 mm thick rather than a thin plate: at 8 mm it tests the exact engagement the
real parts use, instead of a proxy for it. See [docs/assembly.md](docs/assembly.md).

---

## Making it fit your bike

One number is yours to supply:

```openscad
bar_d = 22.2;   // your handlebar diameter at the clamp point
```

**Measure it at three clock angles.** A used bar goes oval where clamps have sat, and a round printed
bore on an oval bar touches in only two places.

Everything else is derived. Change a parameter and the model's `assert()` guards will stop the render
and name the constraint you broke, rather than quietly producing a part that does not work.

---

## Documentation

| | |
|---|---|
| **[docs/display-geometry.md](docs/display-geometry.md)** | Every measurement of the display's back, how it was derived, and the three things that catch people out. **Read this if you are designing your own bracket rather than printing ours** — it is the genuinely reusable part of this repo |
| **[docs/design-notes.md](docs/design-notes.md)** | Why it is shaped like this. Two constraints are forced by the display and look arbitrary until explained |
| **[docs/printing.md](docs/printing.md)** | Material, per-part orientation, settings, print order |
| **[docs/assembly.md](docs/assembly.md)** | Hardware list, order of assembly, the 5 mm thread warning, setting the tilt |

## Layout

```
src/      gen4-display-mount.scad   — the whole model; every part, one file
stl/      pre-built exports
renders/  drawings and preview images
docs/     the four documents above
tools/    build.sh (export + verify everything) · check_stl.py
```

## Building from source

Needs [OpenSCAD](https://openscad.org/) (developed against 2021.01) and Python 3.

```bash
./tools/build.sh
```

Exports every part and checks each bounding box. Individual parts:

```bash
openscad -o out.stl -D 'part="yoke"' src/gen4-display-mount.scad
```

Valid names: `gauge`, `spline_test`, and — as they land — `yoke`, `arm`, `cap`, `cowl`, `brow_test`,
`plate`. An unrecognised name fails loudly on purpose.

---

## A note on the design's stubbornness

Three things in this model are guarded by assertions and should not be "simplified":

1. **The cable-boot slot opens upward.** A downward slot cuts off the lone M5.
2. **The pivot sits below the housing.** Anywhere higher and the toothed face covers that bolt's head,
   so it can never be fitted.
3. **Bolt length minus part thickness must land in 3–4 mm.** The thread is 5 mm deep.

Each of these was found the hard way. [docs/design-notes.md](docs/design-notes.md) explains all three.

---

## Contributing

Issues and pull requests welcome — especially **measurements from other units**, which would upgrade
the drawing-derived figures to confirmed ones, and **photos of it fitted**. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

[CC BY-SA 4.0](LICENSE). Print it, modify it, sell prints of it — credit the source and share your
changes under the same terms.

The Chaojie factory manual is **not** redistributed here; it is Chaojie's document. The measurements
derived from it are facts and are published freely.

## Disclaimer

This mounts an electronic display to a moving vehicle. Nothing here has been tested to any standard.
**Proof-load it before you trust it, and re-check every fastener after the first ride.** You are
responsible for what you bolt to your own bike.
