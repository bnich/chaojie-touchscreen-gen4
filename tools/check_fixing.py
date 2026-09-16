#!/usr/bin/env python3
"""Does the screw actually go through one part and into the other?

⭐ WHY THIS EXISTS
------------------
The cowl shipped with no working attachment at all. Owner: "how does the cowl
attach? it has no bolts?" It did not. Two independent failures, either fatal:

  1. THE BOSSES WERE DELETED ON EXPORT. They were unioned into the shell, and
     the cavity subtraction then erased every part of them inside it. Measured:
     the exported cowl's volume was IDENTICAL, to 0.00 mm^3, with the boss
     module enabled and forced off.
  2. THEY LANDED IN AIR. The bosses sat at x=+-52.5, z=24.5; the mating part
     reached x=+-51.5, z=0..8. Nearest material to the screw's midpoint:
     21.8 mm.

Every assertion in that block passed, both times — they checked the boss's
position, its fillet and its reach, all properties of a parameter rather than
of the exported solid. An assertion cannot see a feature that a later boolean
removed.

So this walks the screw's own axis through both exported meshes and reports
what is actually there: how much of part A the screw passes through, how big
the gap is, and how far it penetrates part B. It is the difference between
"the boss is defined at the right place" and "the screw lands in material".

Usage:
    check_fixing.py A.stl B.stl --at X,Y,Z --along X,Y,Z [--probe-r MM]
                    [--min-grip MM] [--max-gap MM] [--label NAME]

--at/--along give a point on the screw axis and its direction. The walk is
offset --probe-r off the axis (default 3), because ON the axis is the hole.
"""
import argparse
import sys

import numpy as np
import trimesh


def runs(mesh, pts):
    """Contiguous [start, end] spans of `pts` (a 1-D walk) inside `mesh`."""
    inside = mesh.contains(pts)
    out, start = [], None
    for i, v in enumerate(inside):
        if v and start is None:
            start = i
        elif not v and start is not None:
            out.append((start, i - 1))
            start = None
    if start is not None:
        out.append((start, len(inside) - 1))
    return out


def _vec(s):
    v = [float(x) for x in s.split(",")]
    if len(v) != 3:
        raise argparse.ArgumentTypeError(f"need X,Y,Z — got {s!r}")
    return np.array(v)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("part_a"); ap.add_argument("part_b")
    ap.add_argument("--at", type=_vec, required=True)
    ap.add_argument("--along", type=_vec, required=True)
    ap.add_argument("--probe-r", type=float, default=3.0)
    ap.add_argument("--min-grip", type=float, default=0.0)
    ap.add_argument("--max-gap", type=float, default=1.0)
    ap.add_argument("--span", type=float, default=40.0)
    ap.add_argument("--step", type=float, default=0.1)
    ap.add_argument("--label", default="")
    a = ap.parse_args()

    A = trimesh.load(a.part_a, process=True)
    B = trimesh.load(a.part_b, process=True)
    for m, p in ((A, a.part_a), (B, a.part_b)):
        if not m.is_watertight:
            print(f"    UNTRUSTED: {p} is not watertight; containment is unreliable")
            return 2

    d = a.along / np.linalg.norm(a.along)
    # a probe offset perpendicular to the axis: the axis itself is the hole
    perp = np.cross(d, [0, 0, 1.0])
    if np.linalg.norm(perp) < 1e-6:
        perp = np.cross(d, [0, 1.0, 0])
    perp = perp / np.linalg.norm(perp) * a.probe_r

    ts = np.arange(0.0, a.span, a.step)
    pts = a.at + perp + np.outer(ts, d)

    ra, rb = runs(A, pts), runs(B, pts)
    tag = f" ({a.label})" if a.label else ""
    if not ra:
        print(f"    FAIL{tag}: the screw passes through NO material of "
              f"{a.part_a}. The feature is missing from the exported part — "
              f"most likely unioned in and then erased by a later boolean.")
        return 1
    if not rb:
        print(f"    FAIL{tag}: the screw reaches NO material of {a.part_b}. "
              f"It is threading into air.")
        return 1

    a_end = ts[ra[-1][1]]
    b_start, b_end = ts[rb[0][0]], ts[rb[0][1]]
    gap = b_start - a_end
    grip = b_end - b_start
    a_thick = sum(ts[e] - ts[s] for s, e in ra)

    print(f"    {a.part_a.split('/')[-1]} -> {a.part_b.split('/')[-1]}{tag}: "
          f"through {a_thick:.1f} mm of the first, {gap:.2f} mm gap, "
          f"{grip:.1f} mm of grip in the second")
    ok = True
    if gap > a.max_gap:
        print(f"    FAIL: {gap:.2f} mm gap exceeds the {a.max_gap:.2f} mm limit — "
              f"the screw spans air between the parts.")
        ok = False
    if grip < a.min_grip:
        print(f"    FAIL: {grip:.1f} mm of grip is under the {a.min_grip:.1f} mm "
              f"floor — not enough thread engagement to hold.")
        ok = False
    if not ok:
        return 1
    print(f"    OK - gap <= {a.max_gap:.2f} mm, grip >= {a.min_grip:.1f} mm.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
