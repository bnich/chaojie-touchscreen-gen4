#!/usr/bin/env python3
"""Can the two halves of the tilt joint actually close on each other?

⭐ WHY THIS EXISTS
------------------
This is the one part pair `tools/build.sh` deliberately never intersected.
`docs/spline-verification.md` is explicit that a whole-ring boolean on this
geometry is not trustworthy — CGAL and manifold3d both give wrong answers on
48 interleaved teeth, in both directions — so yoke-vs-arm was skipped and the
mate was proven by rod probe instead. That was right about the boolean and
wrong about the conclusion: it left the pair with **no automated check at
all**, and a 3.45 mm interference shipped.

The arm's rising rib ran from y=2 to y=16 while the male spline's root plane
is y=9, so 7 mm of rib stood proud of the mating face, straight into the
space the yoke's female disc occupies. Owner, looking at the part: "there is
a solid rectangle that will prevent the arm grooves from interlocking with
the yoke grooves."

THE METHOD, which is the trustworthy one: at a fixed radius and angle, fire a
rod along the pivot axis and ask how far each part's material reaches. Two
solids that mesh must be complementary at every (r, θ) — the yoke's outermost
material must not pass the arm's innermost. No boolean, no tooth-vs-tooth
topology, just two independent depth readings compared.

⚠️ KEEP IT SMALL. An early version fired 628 rays x 900 samples at a 6 MB mesh
in one `contains()` call and was OOM-killed on a box with no swap — taking the
session with it. The defaults here are ~34,000 points, which is ample to catch
a sector-sized defect, and the query is chunked besides.

⚠️ SAMPLE OFF THE TOOTH PITCH. The teeth repeat every 7.5°, so sampling at 15°
(exactly two pitches) hits the same phase every time and reports an identical
height at every angle — which looks like a flat disc and hides the relief.
The default step here is deliberately not a divisor of 7.5.

Usage:
    check_mate.py YOKE.stl ARM_POSITIONED.stl --axis Y,Z [--radii ...]
                  [--step DEG] [--clearance MM]
"""
import argparse
import math
import sys

import numpy as np
import trimesh


def reach(mesh, pts_per_ray, n_rays, outermost, chunk=40000):
    """Depth each ray reaches, as an index into the sample line.

    ⚠ CHUNKED. Querying ray by ray is far too slow, but handing trimesh every
    sample of every ray in one call is how the first version got OOM-killed:
    4 radii x 157 angles x 900 samples is over half a million points, and the
    containment path allocates several arrays that size. Batch it instead.
    """
    n_samp = len(pts_per_ray) // n_rays
    hits = np.empty(len(pts_per_ray), dtype=bool)
    for lo in range(0, len(pts_per_ray), chunk):
        hits[lo:lo + chunk] = mesh.contains(pts_per_ray[lo:lo + chunk])
    hits = hits.reshape(n_rays, n_samp)
    out = np.full(n_rays, -1)
    for i in range(n_rays):
        h = hits[i]
        if not h.any():
            continue
        out[i] = (len(h) - 1 - np.argmax(h[::-1])) if outermost else np.argmax(h)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("yoke")
    ap.add_argument("arm")
    ap.add_argument("--axis", required=True,
                    help="the pivot axis's own (Y,Z) in the assembled frame")
    ap.add_argument("--span", default="12,38",
                    help="X range to walk -- keep it tight round the mate; the cost is rays x samples")
    ap.add_argument("--radii", default="8,12,15,18")
    ap.add_argument("--step", type=float, default=11.0,
                    help="angle step, deg -- keep it off the 7.5 deg tooth pitch")
    ap.add_argument("--pitch", type=float, default=0.1)
    ap.add_argument("--clearance", type=float, default=0.05,
                    help="overlap beyond this is interference, mm")
    a = ap.parse_args()

    ay, az = (float(v) for v in a.axis.split(","))
    x0, x1 = (float(v) for v in a.span.split(","))
    radii = [float(v) for v in a.radii.split(",")]
    xs = np.arange(x0, x1, a.pitch)
    angs = np.arange(0.0, 360.0, a.step)

    yk = trimesh.load(a.yoke, process=True)
    arm = trimesh.load(a.arm, process=True)
    for m, p in ((yk, a.yoke), (arm, a.arm)):
        if not m.is_watertight:
            print(f"    UNTRUSTED: {p} is not watertight")
            return 2

    rays = [(r, ang) for r in radii for ang in angs]
    pts = np.array([[x, ay + r * math.cos(math.radians(ang)),
                     az + r * math.sin(math.radians(ang))]
                    for r, ang in rays for x in xs])
    y_reach = reach(yk, pts, len(rays), outermost=True)
    a_reach = reach(arm, pts, len(rays), outermost=False)

    worst, worst_at, n_bad, relief = 0.0, None, 0, []
    for i, (r, ang) in enumerate(rays):
        if y_reach[i] < 0 or a_reach[i] < 0:
            continue
        ov = xs[y_reach[i]] - xs[a_reach[i]]
        if r == radii[len(radii) // 2]:
            relief.append(xs[y_reach[i]])
        if ov > a.clearance:
            n_bad += 1
            if ov > worst:
                worst, worst_at = ov, (r, ang)

    print(f"    {len(rays)} rod probes at r = {radii}, every {a.step} deg")
    if relief:
        rl = np.array(relief)
        print(f"    tooth relief seen at r={radii[len(radii)//2]:.0f}: "
              f"{rl.max()-rl.min():.2f} mm of variation across the ring "
              f"(spline_h is 1.6)")
    if n_bad:
        print(f"    FAIL: {n_bad} of {len(rays)} probe positions interfere; "
              f"worst {worst:.2f} mm at r={worst_at[0]:.0f}, {worst_at[1]:.1f} deg.")
        print(f"    The joint cannot close. Something is proud of the mating face.")
        return 1
    print(f"    OK - the two halves are complementary at every probe position.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
