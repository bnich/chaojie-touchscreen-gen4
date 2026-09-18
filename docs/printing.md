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
| `arm` (×2) | ⭐ **LAID FLAT — clamp bore vertical** (rotate −90° about X in the slicer, or 'place on face' and pick the big flat side). 70 × 65 mm footprint, **18 mm tall** | ⚠️ **Changed 2026-09-16, after two prints in a row turned to spaghetti.** Standing upright it is a **65 mm tower on 262 mm² of bed contact** — 4 mm² per mm of height, where every other part in this repository is 11 to 515. Laid flat: **868 mm² of contact and 18 mm tall**, 2.8× the grip and a third of the height. Cost: two small islands (17 mm² each) start 2 mm up and want support. ⭐ It also settles the layer-direction question that was left open here — the rib's bending load now lies *within* the layer plane instead of across it, which is the stronger way to stack it |
| `cap` (×2) | ⭐ **LAID FLAT**, same rotation as the arm (−90° about X) | ⚠️ **Changed 2026-09-16.** Bore-side down it is 312 mm² on the bed (13 mm² per mm of height) with 593 mm² laid over air. Flat it is **868 mm² on the bed and only 223 mm² over air** — better on *both* counts, unlike the arm where flat costs some overhang. Its two ear bosses start 1 mm up either way; that gap is the clamp's pinch gap and is functional |
| `cowl` | **visible face down on a textured sheet** | ⭐ this is the whole reason the cowl is a separate part. The surface people see becomes one uniform moulded-looking texture rather than stacked layer lines. Ribs and bosses face up. Its bottom opening is now one symmetric notch (⭐ 2026-09-15) wide enough for both legs and both clamps |
| `insert_coupon` | flat, pockets facing up | throwaway; the pockets must print upward or their diameter is at the mercy of bridging |
| `brow_test` | **riser end on the bed, visor pointing up** — the same way up as the cowl | measured **0 mm² of overhang**, because the visor narrows all the way up. ⚠️ This used to say "flat", which is the **worst of the six axis-aligned orientations** (8874 mm² of steeply down-facing area). Footprint 161 × 22.5 mm, 67 mm tall — use a brim |

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

## Supports — what was actually measured

⚠️ **This section used to claim every part prints unsupported. That was never measured.** What follows
is, for each part in its orientation above, the area of surface facing steeply downward (under 45° to
the bed) and not sitting on the plate, plus how high the highest such face sits.

| Part | Down-facing area | Highest | What it is |
|---|---|---|---|
| `gauge` | **0 mm²** | — | genuinely support-free |
| `insert_coupon` | 71 mm² | 1 mm | the chamfer on its own rounded end |
| `brow_test` | **0 mm²** | — | genuinely support-free, in the corrected orientation above |
| `cap` | 703 mm² (13 %) | 17 mm | mostly the clamp bore's own ceiling |
| `yoke` | 2946 mm² (11 %) | 36 mm | the two sideways spline pucks |
| `arm` | 1287 mm² (13 %) | 62 mm | the bore's ceiling, plus the sideways male spline disc |
| `cowl` | 5148 mm² (7 %) | 89 mm | the shell's internal ribs, bosses and side pads |

⚠️ **Down-facing is not the same as needs-support.** A horizontal bore's ceiling is self-supporting to
about 45° and then a short bridge, which is why the bore dominates the `arm`/`cap` figures without
being a problem. **Put each part through your own slicer and look at the support preview** before
committing filament — the table above is a geometric screen, not a slicer.

⚠️ **Bed size.** The yoke's footprint is **143.8 × 107.1 mm** — the largest single part. The cowl is
161.0 × 107.5 mm.

### ⚠️ ASA on a part this wide

The yoke is 144 mm across and the cowl 161 mm, both in a material that shrinks. Warping shows up at
the far corners first.

- **Enclosure, and no draught.** This is the single biggest factor for ASA.
- **Bed 100–110 °C**, and clean it — ASA lifts off residue long before it lifts off glass.
- **Fan off, or under 20 %.** ASA warps and delaminates with high fan. Only bridge and overhang fan
  should ever go above that.
- **Brim, 8–10 mm.** Cheap insurance on both wide parts.
- Slow the first layer and give it a little extra squish.

### ⛔ The cowl and the yoke REQUIRE support — turn it on

**The cowl is the worst of the set**, despite having the best bed adhesion (11807 mm²). Measured:
**4472 mm² laid over air**, dominated by a single **2092 mm² region that begins 22.4 mm up** — the sun
visor's riser, which is full-width and reaches 12.5 mm beyond the box's own top edge, so it appears in
mid-air — followed by **1183 mm² more at 30.4 mm** as the visor carries on past the front rim. Nothing
sits under either, all the way down to the bed, so **support on build plate only** reaches them.

### ⛔ The yoke REQUIRES support — turn it on

Measured with `tools/check_print.py`: **2171 mm² of the yoke is laid over air**, including two
**390 mm² patches 9.2 mm up**, where each leg begins a 45 mm horizontal cantilever out to its pivot.

⭐ **The pivot discs now land on a flat** (2026-09-16). They used to stand on their own mathematical
tangent — `yoke_standoff` had been set to bring the Ø40 disc's lowest point to *exactly* z=0, which
avoided clipping the bed and created the worst possible first layer: a 40 mm disc balanced on a line,
the two of them sharing 184 mm² of contact. A small foot now fills the sliver between bed and arc, so
each disc lands on a real **20 × 6 mm flat**: contact at that end went **184 → 317 mm²**.
⛔ **The foot stops at the female spline's root plane.** A first version ran the full disc
stack and filled the tooth valleys over about 40° — the yoke read x=28.45 in the bottom sector
where every other angle reads 26.75 — so the male teeth had nowhere to go. A print aid that
blocks the joint it is printed for is not an aid.

Use **support on build plate only** (everything needing it sits over bare bed), and keep a brim.
Without support those legs droop, and the drooped material is what the nozzle then catches.

### ⚠️ Curling edges, and the nozzle knocking the part

The yoke is the widest flat part here — a 144 mm bearing plate in a material that shrinks. Corners lift
first, then the nozzle strikes the raised edge and walks the part off the bed.

- **Fan off for the first 3–5 layers, then 20 % maximum.** A PLA profile at 100 % fan will curl ASA on
  its own, and this is the most common single cause.
- **Enclosure, lid shut, no draught** — passive 40–50 °C in the chamber is enough.
- **Bed 100–110 °C, held all print.** Clean it with IPA; ASA lifts off finger oil long before glass.
- **Brim 10–15 mm, OUTER ONLY.** The yoke's first layer is **three separate islands** — the plate
  and its ears at 3512 mm², and the two pivot feet at **183.7 mm² each**, alone out at (±23, −70). An
  outer brim rings all three, which is what those two small ones need. ⛔ **Not inner or both**: the
  only holes in that layer are the three M5 clearance holes, so an inner brim just fills the bolt
  holes with material you then have to pick out.
- **Z-hop 0.2–0.4 mm on travel.** This does not stop curling, but it stops the nozzle *hitting* what
  has curled — which is the difference between a blemish and a part on the floor.
- First layer slower, nozzle +10 °C, a little extra squish.
- ⚠️ **Do not halve your speeds to fix this.** Slower means each layer has longer to cool and contract
  before the next one lands on it, which makes ASA curl slightly **worse** — and it doubles what a
  failure costs you. Moderate speed in a warm chamber beats slow speed in a cold one.

⭐ **The yoke's cowl-fixing ears used to lift, and that was the model's fault, not a setting.** Their
undersides sat 0.8–2.4 mm above the bed, sloping only 5° — a 21 mm unsupported shelf per side at the
part's outermost corners, which is where shrinkage pulls hardest. They now sit **coplanar with the
bearing face**, flat on the bed: the part's footprint reaches its full ±71.9 mm, bed contact went from
3133 to **3745 mm²**, and no column of either ear begins in mid-air. If you are printing an older
export and see them curl, that is why.

⬜ **Not slicer-checked.** The `yoke` and `arm` spline orientations have been an open question since
the tilt-axis fix (each pivot boss now faces sideways, so its Ø40 disc stands with its face vertical).
These numbers say the question is real rather than theoretical.

**Why the orientations are what they are**, where the answer is not "least overhang":
- `cowl` — **surface finish wins.** Laying it on its side nearly halves the down-facing area
  (2843 mm²) but puts the one surface people actually see against a support interface. Not worth it.
- `yoke` — **the bearing face must be flat and dimensionally true**; it is what seats against the
  display. Standing the yoke on edge is marginally better on overhang (1993 mm²) and worse at the job.
- `arm` — the six axis orientations span 1093–1413 mm², i.e. nothing to choose between them on
  overhang. ⬜ **Layer direction is the better argument and has not been settled:** bore-side down puts
  the layers perpendicular to the bending load in the clamp→spline rib, which is the weakest way to
  stack them. If a printed arm ever fails, it will fail there, and re-orienting is the first thing to
  try.

If you re-orient something for your own reasons, check the overhangs yourself — the model does not
enforce print orientation.

## Print in this order

The order exists to catch mistakes cheaply. Do not skip ahead.

0. **`insert_coupon`** — eight pockets, two fits each for M3/M4/M5/M6, all 13 mm deep so only the
   diameter is under test. Press one insert of each size in and find which pocket seats square and
   flush without bulging the boss. ⚠️ **The chamfered end is M3**, and the order from there is
   M3−0.1, M3−0.3, M4−0.1, M4−0.3, M5−0.1, M5−0.3, M6−0.1, M6−0.3. Then set `insert_fit` (and
   `insert_m5_od` if your inserts differ from the kit's Ø7 × 5) and re-export. Minutes to print.
1. **`gauge`** — proves the hole pattern, the slot, the flat-band assumption and your bolt length
   against the real display. Short print. Everything downstream inherits that hole pattern, so if it
   is wrong you want to know now.
2. **`brow_test`** — the riser and visor alone; 0 mm² of overhang, no supports. Confirms the visor's reach and shape against the
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
