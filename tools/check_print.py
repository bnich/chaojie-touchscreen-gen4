#!/usr/bin/env python3
"""Does any layer of this part start in mid-air?

⭐ WHY THIS EXISTS
------------------
Two prints in this project failed for the same reason, and neither the
overhang-area figure nor anything else in the build caught it:

  · the yoke's cowl ears sat 0.8-2.4mm above the bed, sloping 5 degrees --
    21mm of shelf per side printed into thin air.
  · the yoke's two Ø40 spline discs stand on their own TANGENT, ~92mm^2 each
    at the first layer, fanning out to 1745mm^2 by z=10 -- and its legs
    cantilever 45mm horizontally at z=9 with nothing underneath.

"Total down-facing area" does not answer the question that matters. A part
can have a large down-facing area that is entirely fine (a horizontal bore
ceiling bridges; a boss sits on a wall) and a tiny one that is fatal (a
feature that begins with nothing underneath it at all).

THE QUESTION THIS ASKS: slice the part, and for every island of material in
every layer, is there ANY material in the layer below it? If not, the slicer
is being asked to start that region in the air. It will either drop supports
there or extrude into space -- and on a wide part in a shrinking material,
that is where a print lets go and turns into spaghetti.

Reported per part:
  · bed contact area, and where the footprint reaches
  · every region of every layer that is under 20% supported by the layer
    below -- islands (0% held) and severe overhangs alike
  · the tallest unsupported span

Usage:
    check_print.py PART.stl --up X,Y,Z [--pitch MM] [--max-island MM2]

--up is the PRINT direction in the part's own coordinates, e.g. 0,0,1 if the
part prints as exported, or 0,0,-1 if it prints flipped.
"""
import argparse
import sys

import numpy as np
import trimesh


def analyse(mesh, up, pitch):
    from scipy import ndimage

    # Rotate so the print direction is +Z, then voxelise.
    m = mesh.copy()
    up = np.array(up, dtype=float)
    up /= np.linalg.norm(up)
    if not np.allclose(up, [0, 0, 1]):
        m.apply_transform(trimesh.geometry.align_vectors(up, [0, 0, 1]))
    m.apply_translation(-m.bounds[0])

    vox = m.voxelized(pitch=pitch).fill()
    g = np.asarray(vox.matrix, dtype=bool)
    nz = g.shape[2]
    cell = pitch * pitch

    bed = g[:, :, 0].sum() * cell
    # ⭐ FIRST-LAYER ISLANDS, each on its own. This is how a tangent contact
    # shows itself: a round feature resting on its own lowest point lands as a
    # tiny isolated patch that the rest of the part cannot help hold down. The
    # yoke's two Ø40 pivot discs read 92mm^2 each this way before they were
    # given a flat to land on.
    lab0, n0 = ndimage.label(g[:, :, 0])
    first = []
    for i in range(1, n0 + 1):
        sel = lab0 == i
        idx = np.argwhere(sel)
        c = idx.mean(axis=0)
        first.append((sel.sum() * cell,
                      c[0] * pitch + m.bounds[0][0],
                      c[1] * pitch + m.bounds[0][1]))
    first.sort(key=lambda t: -t[0])
    floats = []
    for k in range(1, nz):
        layer = g[:, :, k]
        if not layer.any():
            continue
        below = g[:, :, k - 1]
        # ⚠ MEASURE PER VOXEL, NOT PER REGION. Two earlier versions asked
        # whether a connected REGION of the layer touched anything below --
        # first "any contact at all", then "at least 20% held". Both pass the
        # yoke, whose legs cantilever 45mm and whose Ø40 discs stand on their
        # own tangent, because all of it is joined IN-LAYER to the bearing
        # plate and the plate's own area dominates the fraction. What the
        # nozzle experiences is per-position: this bit of this layer, is there
        # anything under it? So count unsupported VOXELS.
        unsup = layer & ~below
        if not unsup.any():
            continue
        lab, n = ndimage.label(unsup)
        for i in range(1, n + 1):
            sel = lab == i
            area = sel.sum() * cell
            if area < 3.0:            # a normal sloped wall sheds a voxel or two
                continue
            idx = np.argwhere(sel)
            c = idx.mean(axis=0)
            floats.append((area, k * pitch,
                           c[0] * pitch + m.bounds[0][0],
                           c[1] * pitch + m.bounds[0][1], 0.0))
    return bed, floats, m.extents, first


def _vec(s):
    v = [float(x) for x in s.split(",")]
    if len(v) != 3:
        raise argparse.ArgumentTypeError(f"need X,Y,Z — got {s!r}")
    return v


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stl")
    ap.add_argument("--up", type=_vec, required=True)
    ap.add_argument("--pitch", type=float, default=0.4)
    ap.add_argument("--max-island", type=float, default=None,
                    help="fail if any patch laid over air exceeds this mm^2")
    ap.add_argument("--min-first-island", type=float, default=None,
                    help="fail if any FIRST-LAYER island is under this mm^2. A "
                         "tiny one is a tangent contact -- a round feature "
                         "resting on its own lowest point, which is what put "
                         "the yoke's pivot discs on the floor")
    ap.add_argument("--label", default="")
    a = ap.parse_args()

    m = trimesh.load(a.stl, process=True)
    if not m.is_watertight:
        print(f"    UNTRUSTED: {a.stl} is not watertight")
        return 2

    bed, floats, ext, first = analyse(m, a.up, a.pitch)
    name = a.stl.split("/")[-1]
    tag = f" ({a.label})" if a.label else ""
    print(f"    {name}{tag}: {ext[0]:.0f} x {ext[1]:.0f} mm footprint, "
          f"{ext[2]:.0f} mm tall, {bed:.0f} mm^2 on the bed "
          f"({bed/ext[2]:.0f} mm^2 per mm of height)")
    print(f"        first layer is {len(first)} island(s):", end="")
    for area, cx, cy in first[:5]:
        warn = "  <-- SMALL" if area < 120 else ""
        print(f"\n          {area:8.1f} mm^2 near [{cx:7.1f} {cy:7.1f}]{warn}", end="")
    print(f"\n          ... and {len(first)-5} more" if len(first) > 5 else "")
    if a.min_first_island is not None and first and first[-1][0] < a.min_first_island:
        area, cx, cy = first[-1]
        print(f"    FAIL: a first-layer island of only {area:.1f} mm^2 near "
              f"[{cx:.1f} {cy:.1f}], under the {a.min_first_island:.0f} mm^2 floor. "
              f"That is a feature standing on a tangent; give it a flat.")
        return 1
    if not floats:
        print("        nothing is laid over air")
        return 0

    floats.sort(key=lambda t: -t[0])
    total = sum(f[0] for f in floats)
    print(f"        {len(floats)} unsupported patch(es), {total:.0f} mm^2 of material\n        laid over air across the whole print:")
    for area, h, cx, cy, frac in floats[:6]:
        print(f"          {area:7.1f} mm^2 at {h:6.2f} mm up, over air, "
              f"near [{cx:7.1f} {cy:7.1f}]")
    if len(floats) > 6:
        print(f"          ... and {len(floats)-6} more")
    worst = floats[0][0]
    if a.max_island is not None and worst > a.max_island:
        print(f"    FAIL: a {worst:.1f} mm^2 island begins with nothing under it, "
              f"over the {a.max_island:.0f} mm^2 limit. That region is printed "
              f"into the air.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
