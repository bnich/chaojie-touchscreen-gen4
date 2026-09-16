#!/usr/bin/env python3
"""Is any of this part hanging on by a thread?

⭐ WHY THIS EXISTS
------------------
Four defects in this project shipped green and were then found by eye, and
every one of them was the same shape: a feature attached to the rest of the
part by far less material than it looked like it had.

  · the clamp's rising rib   — a 0.2 mm knife edge (claimed ~160 mm²)
  · the yoke's legs          — a 36 mm² shear web (section scan said 194.6)
  · the cowl's mounting boss — deleted entirely by a later boolean (0.00 mm³)
  · the cowl's side ears     — 2.3 mm³ of bond out of a 6670 mm³ ear

Every existing check missed at least one of them. Mesh health passes on all
four. Whole-part volume barely moves. A section scan measures a neck but
cannot tell whether two solids are really one — the plane that comes closest
to separating a feature also slices material carrying none of its load.

THE METHOD, which needs no knowledge of what the features are: voxelise the
solid, erode it by `--erode` mm, and see what falls off. A feature joined by
less than 2×erode of material becomes its own island. Then report each island
by volume and position, so a real defect is distinguishable from the thin
features a part is supposed to have.

⚠️ ERODED ISLANDS ARE NOT AUTOMATICALLY DEFECTS. A 1.6 mm spline tooth and a
2.4 mm shell wall are meant to be thin and will separate at a large enough
erosion. Read the report; the number that matters is whether anything you
believed was structural shows up in it.

⛔ WHAT IT DOES NOT CATCH, checked against this project's own four defects:
  · 0.2mm knife edge in the arm's rib .... CAUGHT at 0.5mm erosion
  · 36mm^2 shear web in the yoke's leg ... CAUGHT, but only at 1.5mm
  · 2.3mm^3 bond on the cowl ear ......... NOT CAUGHT at any radius
  · boss deleted by a later boolean ...... NOT CAUGHT (nothing to erode)
The ear is the instructive one. It was not a thin NECK — it was two chunky
solids meeting over a small CONTACT AREA, which erosion cannot see because
there is no slender region anywhere. For "is this feature really attached",
measure the shared volume of the two solids (tools/build.sh's cowl-ear bond
gate). For "was it deleted", measure the exported part against the module
being enabled and disabled. This tool answers a third question only:
"is anything joined by a slender neck".

Usage:
    check_necks.py PART.stl [--erode MM] [--pitch MM] [--max-island MM3]

Exits non-zero if any island exceeds --max-island (default: reporting only).
"""
import argparse
import sys

import numpy as np
import trimesh


def islands(mesh, erode_mm, pitch):
    """Erode the solid and return (kept_fraction, [(volume, centroid), ...])."""
    from scipy import ndimage

    # ⚠ The radius is a whole number of VOXELS (see below).
    steps = max(1, int(round(erode_mm / pitch)))
    vox = mesh.voxelized(pitch=pitch).fill()
    grid = np.asarray(vox.matrix, dtype=bool)
    if not grid.any():
        return 1.0, [], steps * pitch

    # A ball structuring element, so erosion is isotropic rather than
    # favouring the grid axes (a box element under-erodes diagonals).
    r = steps
    zz, yy, xx = np.mgrid[-r:r + 1, -r:r + 1, -r:r + 1]
    ball = (xx**2 + yy**2 + zz**2) <= r * r
    eroded = ndimage.binary_erosion(grid, structure=ball)
    if not eroded.any():
        return 0.0, [], steps * pitch

    lab, n = ndimage.label(eroded)
    vcell = pitch**3
    out = []
    for i in range(1, n + 1):
        sel = lab == i
        cnt = int(sel.sum())
        idx = np.argwhere(sel)
        # ⚠ Voxel index -> model coordinates, through the grid's OWN transform.
        # A first version did `idx.mean()[::-1] * pitch + vox.translation`,
        # which reversed the axes and reported island centres outside the
        # part's own bounding box (z=71.6 on a part whose z tops out at 40).
        # trimesh's matrix is already indexed [x][y][z]; use its transform
        # rather than reconstructing the mapping by hand.
        centre = trimesh.transform_points(idx.mean(axis=0).reshape(1, 3),
                                          vox.transform)[0]
        out.append((cnt * vcell, centre))
    out.sort(key=lambda t: -t[0])
    total = sum(v for v, _ in out)
    return (out[0][0] / total if total else 0.0), out, steps * pitch


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stl")
    ap.add_argument("--erode", type=float, default=0.75,
                    help="erosion radius, mm; necks thinner than twice this part")
    ap.add_argument("--pitch", type=float, default=0.5, help="voxel pitch, mm")
    ap.add_argument("--max-island", type=float, default=None,
                    help="fail if any island other than the main body exceeds this mm^3")
    ap.add_argument("--label", default="")
    a = ap.parse_args()

    m = trimesh.load(a.stl, process=True)
    if not m.is_watertight:
        print(f"    UNTRUSTED: {a.stl} is not watertight")
        return 2

    keep, isl, eff = islands(m, a.erode, a.pitch)
    tag = f" ({a.label})" if a.label else ""
    name = a.stl.split("/")[-1]
    if not isl:
        print(f"    {name}{tag}: eroded to nothing at {eff} mm — the whole "
              f"part is thinner than that")
        return 1
    note = "" if abs(eff - a.erode) < 1e-9 else f" (asked {a.erode}, quantised to the {a.pitch}mm pitch)"
    print(f"    {name}{tag}: eroded {eff} mm{note} -> {len(isl)} island(s), "
          f"main body holds {keep*100:.1f}% of what survived")
    worst = 0.0
    for vol, c in isl[1:]:
        worst = max(worst, vol)
        print(f"        detached {vol:8.1f} mm^3 near "
              f"[{c[0]:7.1f} {c[1]:7.1f} {c[2]:7.1f}]")
    if a.max_island is not None and worst > a.max_island:
        print(f"    FAIL: an island of {worst:.1f} mm^3 detaches at {eff} mm "
              f"of erosion, over the {a.max_island:.0f} mm^3 limit.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
