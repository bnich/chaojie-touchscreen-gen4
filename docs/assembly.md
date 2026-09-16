# Assembly

## Hardware you need

| Where | Part | Note |
|---|---|---|
| Display → yoke | **3 × M5 × 12** socket cap | ⚠️ **no washer, never longer** — see below |
| Pivot | **2 × M6 × 35** + nyloc + plain washer | one per side. ⛔ **not an insert** — see `docs/design-notes.md`. 26.0 mm of grip, 7.3 mm into the nut |
| Bar clamp | **4 × M5 × 16** + **4 × M5 heat-set inserts** | 2 per clamp, and there are two clamps. Inserts go in the **arm's** ears, from the top. No nuts |
| Cowl → yoke | **2 × M5 × 12** + **2 × M5 heat-set inserts** | inserts go in the **yoke's side ears**. Heads recess into the cowl's side walls |
| Heat-set inserts | **6 × M5 (Ø7 × 5 long)** | 4 across the two arms, 2 in the yoke. ⬜ print `insert_coupon` first and confirm the pocket fit |
| Clamp bore | a strip of **inner-tube rubber** | protects the bar and takes up ovality |

Medium-strength threadlocker for the three display bolts.

If you print the parts at a different thickness, **recompute the bolt length**: length minus part
thickness must land in 3–4 mm. The model asserts this, so change `yoke_t` and it will tell you what
`m5_len` it now demands, or refuse to render.

---

## ⚠️ The one that bites: 5 mm of thread

The display's inserts give **5 mm of usable thread — one bolt diameter.** With 8 mm parts and M5 × 12
you get **4 mm engaged and 1 mm of air**.

- **Never fit a longer bolt.** M5 × 16 into an 8 mm part bottoms out.
- **Never add a washer under the head.** It eats engagement you do not have.
- **Run each bolt down by hand first** and confirm it pulls the yoke tight rather than stopping
  against the bottom of the hole. **A bolt that bottoms feels tight and is holding nothing.**
- **Modest torque, spread over three points.** Threadlocker is doing the retention work here, not
  clamp force.

---

## Order

1. **Fit the yoke to the display.** Slide it on so the cable boot passes up the slot, then bring it
   down until the three holes line up. The loom stays *behind* the yoke — nothing threads through
   the slot.
2. **Three M5 × 12, by hand, then threadlocker, then modest torque.** Check each pulls tight.
3. **Clamp the arm to the handlebar.** Rubber strip in the bore first. Snug the two clamp bolts
   evenly so the gap stays parallel — do not close one side first.
4. **Join the spline, both sides.** Choose your angle, mesh the teeth, and run an **M6 × 35** through
   from the clamp side with a **plain washer under the nyloc** — the nut turns against printed ASA and
   its corners dig in without one. The bolt enters a counterbored seat in the arm's tip puck and lands
   on a flat pad on the yoke leg's inboard face. The teeth carry
   the load, so this bolt only needs to hold them together — it is not a friction joint and does not
   want to be cranked.
5. **Route the loom** down behind the arm, leaving a service loop so the bars can reach full lock
   without tugging the connectors.
6. **Fit the cowl last.** Hook the top lip over the display's top edge first, rotate the cowl down,
   then drive one **M5 × 12** in through each side wall into the yoke's ear. The heads recess below
   the side face; nothing shows on the back.

**Press the inserts before any assembly.** Six M5s: two in each clamp arm, in the top face of each
ear — and there are two arms — plus one in each of the yoke's two side ears, from the outer face. Iron at ~240 °C for ASA,
straight and slow, and let it cool before loading the thread. ⬜ **Print `insert_coupon` first** —
insert fit is the one dimension in this project that depends on your supplier rather than on the
display, and a pocket that is 0.2 mm out either spins or splits.

**Service order is the reverse:** cowl → arm → yoke. The lone M5's head is clear, but the arm must
come off before the yoke can.

---

## Before you ride

- ⚠️ **Check the bars reach full lock** without the display fouling the frame, the tank, your hands,
  or the loom pulling tight.
- ⚠️ **Proof-load it on the bench** before trusting it — hang the display and shake it hard.
- **Re-check every fastener after the first ride.** Vibration finds everything.
- A paint witness line across each bolt head and the part makes any movement visible at a glance.

---

## Setting the angle later

The spline is **7.5° steps**, 48 teeth. Slacken the M6, lift the faces apart, rotate, re-mesh,
re-tighten. You do not need to touch the display bolts or the bar clamp.

Once you have ridden it enough to know the angle you want, you can print the joint **solid** — set
`teeth = false` and re-export the yoke and arm. Same file, same geometry, no teeth and nothing to
loosen.
