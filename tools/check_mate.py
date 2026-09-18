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

⛔ NEVER USE mesh.contains() HERE. It crashed the owner's Claude Code session
twice. This box has no embree, so trimesh falls back to numpy ray tests:
contains() fires a DIAGONAL ray from every point, and a diagonal ray's
bounding box spans much of the mesh, so the broad phase hands back thousands
of candidate triangles per point. Memory scales as points x candidates. One
26,400-point call against the 135k-triangle yoke exhausted a 31 GB machine
with no swap. A 3,000-point call had survived, which is why it looked safe.
This tool now casts ONE ray per probe, ALONG the probe line itself, and reads
the exact surface crossings: 165 rays, and each one's bounding box is a thin
line, so the candidate set is small. It is also exact, not sampled at 0.1 mm.

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


def intervals(mesh, origins, direction):
    """Material intervals along each ray, as [(x_in, x_out), ...] per ray.

    Each crossing is classified by its own face normal (entering where the
    normal opposes the ray, leaving where it agrees), not by counting hits.
    A ray through a shared edge reports the crossing once per face, and
    counting parity would read that as in-out-in.
    """
    d = np.tile(direction, (len(origins), 1))
    locs, ray_i, tri_i = mesh.ray.intersects_location(origins, d, multiple_hits=True)
    out = [[] for _ in origins]
    for i in range(len(origins)):
        sel = ray_i == i
        if not sel.any():
            continue
        t = locs[sel] @ direction
        sgn = np.sign(mesh.face_normals[tri_i[sel]] @ direction)
        order = np.argsort(t, kind="stable")
        inside, start, last = False, None, None
        for tv, sv in zip(t[order], sgn[order]):
            if last is not None and abs(tv - last) < 1e-6:
                continue                      # same crossing, seen on 2 faces
            last = tv
            if sv < 0 and not inside:
                inside, start = True, tv
            elif sv > 0 and inside:
                inside = False
                out[i].append((start, tv))
    return out


def reach(ivs, x0, x1, outermost):
    """How far material reaches within [x0, x1], or None if it has none there."""
    clipped = [(max(a, x0), min(b, x1)) for a, b in ivs if b > x0 and a < x1]
    if not clipped:
        return None
    return max(b for _, b in clipped) if outermost else min(a for a, _ in clipped)


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
    ap.add_argument("--clearance", type=float, default=0.05,
                    help="overlap beyond this is interference, mm")
    a = ap.parse_args()

    ay, az = (float(v) for v in a.axis.split(","))
    x0, x1 = (float(v) for v in a.span.split(","))
    radii = [float(v) for v in a.radii.split(",")]
    angs = np.arange(0.0, 360.0, a.step)

    yk = trimesh.load(a.yoke, process=True)
    arm = trimesh.load(a.arm, process=True)
    for m, p in ((yk, a.yoke), (arm, a.arm)):
        if not m.is_watertight:
            print(f"    UNTRUSTED: {p} is not watertight")
            return 2

    # Start every ray outside both parts, so the first crossing is an entry.
    xs0 = min(yk.bounds[0][0], arm.bounds[0][0]) - 1.0
    rays = [(r, ang) for r in radii for ang in angs]
    origins = np.array([[xs0, ay + r * math.cos(math.radians(ang)),
                         az + r * math.sin(math.radians(ang))] for r, ang in rays])
    along = np.array([1.0, 0.0, 0.0])
    y_iv = intervals(yk, origins, along)
    a_iv = intervals(arm, origins, along)
    y_reach = [reach(v, x0, x1, outermost=True) for v in y_iv]
    a_reach = [reach(v, x0, x1, outermost=False) for v in a_iv]

    worst, worst_at, n_bad, relief = 0.0, None, 0, []
    for i, (r, ang) in enumerate(rays):
        if y_reach[i] is None or a_reach[i] is None:
            continue
        ov = y_reach[i] - a_reach[i]
        if r == radii[len(radii) // 2]:
            relief.append(y_reach[i])
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
