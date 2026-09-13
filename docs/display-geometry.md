# Chaojie `CJ-V5-04` — measured geometry

Everything a mount needs to know about the back of this display. If you are designing your own
bracket rather than printing ours, this page is the useful part of the repository.

> **Source.** These figures come from the factory manual's **§III Installation dimensions** drawing,
> plus direct measurement of one unit. The manual itself is Chaojie's copyrighted document and is
> **not redistributed here** — ask your reseller for it. Dimensions are facts; the document is not
> ours to share.

---

## 1. How reliable these figures are

**Confirmed on a physical unit:** the hole pattern (a printed gauge bolted to a display), the thread
size and depth, the up/down orientation, that the Ø13 stub is the cable bundle, and the flat bearing
band.

**Taken from the manual's §III dimensioned drawing:** everything else — the Y of the upper hole row,
the boot and collar diameters, the microphone position, the case-screw positions.

The drawing is true to scale: its own printed 159.99 and 93.98 give 5.6754 and 5.6608 px/mm at
600 dpi, agreeing to 0.26 %, and figures measured off it match every printed callout to within a line
width. Treat the drawing-derived figures as good to a few tenths, and the confirmed ones as exact.

---

## 2. Datum

**Stand the display upright, screen facing away from you, so you are looking at its back.**
**X** runs from the left edge as you see it, **Y** runs *down* from the top edge.

⭐ **Every feature on the rear face is mirror-symmetric about X = 80**, to within 0.3 mm — both upper
holes, the lone hole, the cable boot, the microphone and all five case screws. **So left/right cannot
be got wrong.** Only the up/down orientation matters, and the lone hole is **below** the pair.

---

## 3. The numbers

| | mm | Notes |
|---|---|---|
| Housing | **159.99 × 93.98 × 26** | the 26 is rear face → glass and **excludes the cable boot** |
| Corner radius | **9** | reuse it on your cowl and the two read as one object |
| Mounting holes | **M5 × 3, 5 mm deep** | ⚠️ see §4 |
| — upper left | **(39.50, 40.9)** | |
| — upper right | **(120.50, 40.9)** | the pair is **81.0 apart and dead level** |
| — lone hole | **(80.00, 63.28)** | **on the centreline**, 22.39 below the pair |
| — triangle sides | slant sides **46.46** each | isosceles |
| Flat bearing band | **Y 23.0 … 71.6** | 48.6 mm strip; outside it the shell chamfers away. See §4.2 |
| Cable boot | **Ø13.0 × 22.3 proud**, in a **Ø21.7** collar, at **(80.0, 40.9)** | total depth over it **47.8** |
| Microphone | **(80.2, 76.0)** | labelled 送话器孔 on the drawing |
| Case screws | (10.8, 11.0) · (80.1, 9.9) · (149.5, 11.0) · (33.1, 84.2) · (127.3, 84.2) | ~Ø8.5 pockets |

---

## 4. ⚠️ The three things that will catch you out

### 4.1 The threads are 5 mm deep — one bolt diameter

That is **short**. Bolt length minus your part's thickness must land in **3–4 mm**: enough engagement
to hold, with at least 1 mm of air so the bolt can never bottom.

**A bolt that bottoms feels tight and is holding nothing.** Run each one down by hand and confirm it
pulls the bracket tight rather than stopping against the bottom of the hole. Use a medium
threadlocker and modest torque spread across three points — this is not a joint to crank on.

This repository's parts are **8 mm** thick and use **M5 × 12** (4 mm engaged). M5 × 8 with 5 mm parts
works equally well if that is what you stock. **No washer under the head** — it eats engagement you
do not have.

### 4.2 You can only bear on the flat band, Y 23.0 … 71.6

Outside that 48.6 mm strip the shell chamfers away. A bracket that touches beyond it is rocking on
two lines instead of sitting on a face, and it will work the bolts loose. All three holes sit inside
the band — the lone one with 8.3 mm to spare.

⚠️ **If you derive this yourself from the manual, you will get 20.0 … 74.6 and it is ~3 mm optimistic
at each end.** The side elevation shows where the surface *begins* to chamfer; the genuinely flat area
stops inboard of that line. Use the measured figures above.

⬜ Measured off a fitted gauge by eye, good to ~±1 mm.

### 4.3 The cable boot is **inside** the bolt triangle

The whole loom — 9-pin main, speaker, camera, USB — leaves the display through a **Ø13 boot standing
22.3 mm proud** at (80.0, 40.9). That is 22.4 mm above the lone hole and 40.7 from each upper one.

**So a flat plate cannot bolt to this display.** You need a central opening of at least **Ø24** (size
it on the collar, not the boot).

And the opening **must run out to an edge**. The connectors on that loom are all larger than any hole
the bolt pattern leaves room for, so you cannot thread them through. It cannot run *downward* — the
lone M5 is on the centreline directly below the boot and a downward slot cuts it off. **Up the
centreline severs nothing**, because the upper holes are ±40.5 out.

⭐ The good news: the slot is only needed to get the bracket **on and off**. The boot stands 22.3 mm
proud of an 8 mm plate, so the wires fan out *behind* the bracket and route freely. Nothing passes
through the slot in service.

---

## 5. Electrical, for context

Not needed to mount the thing, but it is what people ask next.

| | |
|---|---|
| Operating voltage | **DC 12–96 V** |
| Screen | 5", 800 × 480, touch |
| Protection | IP65, −20 … +70 °C |
| Main connector | `DJ7091A-2.8-11`, 9-pin |
| Controller link | one-line on **pin 9** (0–15 V) |
| Pins 7 / 8 | CAN, described by the manual as **battery**-facing (BMS), not controller |
| Audio | 10 W / 4 Ω, one speaker, on a 2-pin `DJ7021-2.8-21` |
| Other leads | round 4-pin camera, USB-A for firmware |

⚠️ **Pin 9 idles at ground (~9 mV) and does not bias the line** — whatever drives it must supply the
high level itself. Its input is **≈6.4 kΩ to ground**, not high impedance, so the driver has to source
real current.

⚠️ **The flying leads are stranded.** Pushed into a solderless breadboard they splay and make no
contact while looking perfectly seated. Tin, ferrule or solder to solid-core first.
