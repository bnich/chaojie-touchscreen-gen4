# CLAUDE.md — Chaojie Gen 4 display mount

Parent guidance: `../CLAUDE.md` — repo map, conventions, public-repo hygiene, and the ⚠️ OpenSCAD
traps. All three of those traps were found in this repo's work; do not rediscover them.

## What this is

One OpenSCAD file, `src/gen4-display-mount.scad`, producing a fit gauge, a structural yoke, a toothed
tilt joint, a bar clamp and a cosmetic cowl. 🚧 **In progress** — the README's status table is
authoritative about what exists.

## The canonical display geometry is `docs/display-geometry.md`

⚠️ **Do not restate a dimension from it anywhere else**, in this repo or another. The model reads its
numbers from its own parameter header, which cites that document.

## Constraints are `assert()`s, not comments

Eight of them. If you change a parameter and one fires, **the number was wrong — not the assertion.**
When you add a constraint, add the assertion, then **verify it fires by deliberately breaking it.**
An assertion that never fires is not a test.

⚠️ Check assertions with a **solid** export. A tree format or a PNG exits 0 on a failed assert.

## The traps this design is built around

1. **The boot slot opens upward.** A downward slot cuts off the lone M5.
2. **The pivot sits below the housing.** Anywhere higher buries that bolt's head under the toothed
   face and it can never be fitted.
3. **Bolt length minus part thickness must land in 3–4 mm.** The thread is 5 mm deep. `gauge_t` is
   **derived from `yoke_t`** so the gauge tests the real joint, not a proxy — do not replace it with
   a literal.

## Measuring interference

⛔ Not with a whole-shape boolean. See `../CLAUDE.md` — intersect one solid at a time against a thin
probe rod.
