#!/usr/bin/env python3
"""How thin is the load path, measured on the plane that actually cuts it?

⭐ WHY THIS EXISTS, ON TOP OF THE SECTION SCAN
----------------------------------------------
tools/build.sh already scans cross-sections along a part's long axis. That
scan reported the yoke's leg at a healthy **194.6 mm²** while the leg was in
fact hanging off the bearing plate by a **36.4 mm²** shear web — because the
scan cuts perpendicular to Y, and Y is the one direction that web looks thick
in. Tilt the cutting plane ~72° toward Z, the way the load actually peels the
leg off the plate, and the real number appears.

The owner found it by eye, from a side view, after the section scan had
passed it. That is the third defect in this project found that way.

    A section scan is only as honest as the plane it cuts on.

`--sweep all` samples plane normals over a whole hemisphere instead of only
within the Y-Z plane; use it whenever the load path is not confined to one
plane.

⛔ BUT A PLANAR SECTION CANNOT MEASURE A CORNER GRAZE, AT ANY ANGLE. When the
yoke grew side ears for the cowl, one was joined to the bearing plate over
**2.3 mm^3** out of its own 6670 -- effectively floating -- and this tool
reported a healthy 112 mm^2 on the hemisphere sweep. It is not a blind spot in
the sweep: the plane that comes closest to separating an ear also slices a
large area of PLATE that carries none of the ear's load, and the cut reports
that area. Sections measure a neck; they cannot measure whether two solids are
really one.
  ⭐ For "is this feature actually attached", measure the SHARED VOLUME of the
two solids instead -- tools/build.sh's own COWL EAR BOND gate.

So this does not pick a plane. It sweeps the cutting plane and reports the
smallest section that genuinely SEPARATES two named points — one at the load's origin, one at its
destination. "Separates" is verified, not assumed: the part is cut at the
plane and the piece containing the destination must not also contain the
origin. Without that check the search just finds the part's own edges, where
a plane clips a corner and the area tends to zero.

Usage:
    check_throat.py PART.stl --from X,Y,Z --to X,Y,Z [--min MM2]
                    [--clip-x-min V] [--sweep yz|all] [--step DEG]
                    [--offset-step MM]

Both --from and --to must be points INSIDE the solid; the script says so if
they are not, rather than reporting a meaningless number.

⚠️ Needs rtree (trimesh's ray/containment path) and manifold3d.
"""
import argparse
import math
import sys

import numpy as np
import trimesh


def _slab(mesh, n, d, t):
    box = trimesh.creation.box(extents=[400.0, 400.0, t])
    box.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], n))
    box.apply_translation(n * d)
    r = trimesh.boolean.intersection([mesh, box], engine="manifold")
    return (r.volume / t) if r is not None and len(r.faces) else 0.0


def _separates(mesh, n, d, origin, dest):
    """Cut at the plane; the piece holding `dest` must not hold `origin`."""
    box = trimesh.creation.box(extents=[400.0, 400.0, 400.0])
    box.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], n))
    box.apply_translation(n * (d + 200.0))
    far = trimesh.boolean.intersection([mesh, box], engine="manifold")
    if far is None or not len(far.faces):
        return False
    for piece in far.split(only_watertight=False):
        if len(piece.faces) and piece.contains([dest])[0]:
            return not piece.contains([origin])[0]
    return False


def _directions(sweep, step_deg):
    """Candidate plane normals."""
    if sweep == "yz":
        return [np.array([0.0, -math.cos(math.radians(d)), math.sin(math.radians(d))])
                for d in np.arange(0.0, 90.0, step_deg)]
    # A Fibonacci hemisphere: even coverage, no pole clustering, and it
    # includes directions with an X component -- which the yz sweep never did.
    n = max(16, int(round(180.0 / step_deg)))
    ga = math.pi * (3.0 - math.sqrt(5.0))
    out = []
    for i in range(n):
        z = 1.0 - (i + 0.5) / n          # 1 .. 0, upper hemisphere only
        r = math.sqrt(max(0.0, 1.0 - z * z))
        a = ga * i
        out.append(np.array([r * math.cos(a), r * math.sin(a), z]))
    return out


def throat(mesh, origin, dest, step_deg, offset_step, thickness=0.4, cap=80,
           sweep="yz"):
    """Smallest verified separating section, sweeping the plane's normal."""
    candidates = []
    for n in _directions(sweep, step_deg):
        deg = float(np.degrees(math.atan2(n[2], -n[1])) if sweep == "yz" else 0.0)
        if n @ origin > n @ dest:
            n = -n
        lo, hi = n @ origin, n @ dest
        d = lo + offset_step
        while d < hi - offset_step:
            a = _slab(mesh, n, d, thickness)
            if a > 0:
                candidates.append((a, n.copy(), float(d), float(deg)))
            d += offset_step
    # Smallest first, then verify — most tiny readings are the part's own
    # edges and will fail the separation test, so verify lazily.
    candidates.sort(key=lambda c: c[0])
    for a, n, d, deg in candidates[:cap]:
        if _separates(mesh, n, d, origin, dest):
            return a, deg, d
    return None, None, None


def _point(s):
    v = [float(x) for x in s.split(",")]
    if len(v) != 3:
        raise argparse.ArgumentTypeError(f"need X,Y,Z — got {s!r}")
    return np.array(v)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stl")
    ap.add_argument("--from", dest="origin", type=_point, required=True,
                    help="a point inside the solid where the load starts")
    ap.add_argument("--to", dest="dest", type=_point, required=True,
                    help="a point inside the solid where the load ends")
    ap.add_argument("--min", type=float, default=0.0, help="floor, mm^2")
    ap.add_argument("--clip-x-min", type=float, default=None,
                    help="keep only x >= V, to isolate one of a mirrored pair")
    ap.add_argument("--sweep", choices=("yz", "all"), default="yz",
                    help="'yz' sweeps the normal in the Y-Z plane; 'all' samples "
                         "a whole hemisphere, including normals along X")
    ap.add_argument("--step", type=float, default=3.0, help="angle step, degrees")
    ap.add_argument("--offset-step", type=float, default=1.0, help="offset step, mm")
    ap.add_argument("--label", default="")
    a = ap.parse_args()

    m = trimesh.load(a.stl, process=True)
    if not m.is_watertight:
        print(f"    UNTRUSTED: {a.stl} is not watertight; containment is unreliable")
        return 2
    if a.clip_x_min is not None:
        half = trimesh.creation.box(extents=[400.0, 400.0, 400.0])
        half.apply_translation([a.clip_x_min + 200.0, 0, 0])
        m = trimesh.boolean.intersection([m, half], engine="manifold")

    for name, pt in (("--from", a.origin), ("--to", a.dest)):
        if not m.contains([pt])[0]:
            print(f"    CANNOT MEASURE: {name} {tuple(pt)} is not inside the solid. "
                  f"Pick a point in real material, or the search is meaningless.")
            return 2

    area, deg, off = throat(m, a.origin, a.dest, a.step, a.offset_step,
                            sweep=a.sweep)
    tag = f" ({a.label})" if a.label else ""
    if area is None:
        print(f"    CANNOT MEASURE{tag}: no verified separating plane found. "
              f"Widen --step/--offset-step, or check the two points really are "
              f"on opposite sides of a load path.")
        return 2
    where = (f"cut plane {deg:.0f} deg from Y toward Z, offset {off:.1f}"
             if a.sweep == "yz" else f"offset {off:.1f} on a swept normal")
    print(f"    throat{tag}: {area:7.1f} mm^2   ({where})")
    if area < a.min:
        print(f"    FAIL: below the {a.min:.0f} mm^2 floor. The load path has a "
              f"thin spot that a single-axis section scan will not see.")
        return 1
    print(f"    OK - floor {a.min:.0f} mm^2.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
