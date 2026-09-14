#!/usr/bin/env python3
"""VENDORED. The original lives one level up in the revv1-build workspace and is
shared with the FarDriver mount project. This copy exists because a public clone
of this repository cannot reach outside its own tree, and tools/build.sh needs it.
If you change one, change both."""
"""Prove two printed parts do not interfere, using a boolean engine that is NOT
OpenSCAD's.

WHY THIS EXISTS
---------------
The OpenSCAD traps in CLAUDE.md all share one shape: the obvious check returns a
clean, confident, WRONG answer.

  - A render cannot show interference at all. Preview draws interpenetrating
    triangles without resolving the boolean, so a colliding assembly and a
    correct one are pixel-identical from every angle.
  - Whole-shape CGAL booleans lose accuracy on thin near-touching geometry.
    A 48-tooth spline intersection reported 0.006 mm^3 where a direct probe
    measured a 1.6 mm collision.
  - CGAL can refuse the boolean on a re-imported STL and still leave OpenSCAD
    exiting 0, so the result reads as empty -- indistinguishable from a genuine
    clearance. Reproduced on this machine 2026-09-13: two 48-tooth rings gave
    "CGAL error in CGAL_Nef_polyhedron3(): assertion violation", NO output file,
    and exit status 0. (It is conditional on the mesh, not on re-importing as
    such -- plain cubes round-trip fine. Which is worse, not better: the check
    works right up until the geometry gets interesting.)

This tool answers with a different engine (manifold3d, via trimesh) on the
exported meshes. That matters for two reasons:

  1. It is a genuine second opinion. When CGAL and manifold agree the parts are
     clear, that is evidence. When they disagree, one of them is wrong and you
     have learned something worth knowing before you print.
  2. manifold3d happily booleans a re-imported STL, so trap 7 does not apply
     here. Probing the exported mesh is exactly what this tool is for.

THE CONTROL PROBE IS NOT OPTIONAL, SO IT IS AUTOMATIC
-----------------------------------------------------
CLAUDE.md: "Always run a control probe -- one deliberately aimed at solid
material -- because a badly aimed probe returns empty too, and 'empty' is the
answer you are hoping for."

Every run of this tool self-tests first, against a pair of solids that overlap
by an exactly known volume. If the engine cannot find a collision it is TOLD
about, nothing it says about your parts is worth reading, and the run aborts.

"No interference" from this tool means the self-test passed, both meshes were
watertight, and the intersection was empty. Any one of those missing and it
says UNTRUSTED instead.

EXIT CODES -- 1 AND 2 MUST NEVER BE CONFLATED
---------------------------------------------
    0   CLEAR       proven: control passed, meshes watertight, intersection empty
    1   INTERFERENCE the parts collide, and by how much
    2   UNTRUSTED   the question was not answered. Control failed, a mesh would
                    not load, or a mesh is not watertight.

A script that treats 2 as 0 ships a colliding part.
"""

import argparse
import sys

try:
    import numpy as np
    import trimesh
except ImportError as exc:  # pragma: no cover
    sys.exit(
        f"FAIL: {exc}\n"
        "This tool needs trimesh + manifold3d. Run it with the project venv:\n"
        "    /root/.venvs/revv1/bin/python tools/check_fit.py ...\n"
    )

ENGINE = "manifold"

# Self-test geometry: two 10 mm cubes overlapping by exactly 2 x 10 x 10 mm.
CONTROL_OVERLAP_MM3 = 2.0 * 10.0 * 10.0


def _boolean_intersection(a, b):
    return trimesh.boolean.intersection([a, b], engine=ENGINE)


def self_test(verbose=True):
    """Positive control. Prove the engine finds a collision it is told about.

    A tool that reports 'no interference' without this having passed is just a
    tool that reports 'no interference'.
    """
    a = trimesh.creation.box(extents=(10, 10, 10))
    b = trimesh.creation.box(extents=(10, 10, 10))
    b.apply_translation((8, 0, 0))  # 2 mm of overlap in x

    try:
        hit = _boolean_intersection(a, b)
    except Exception as exc:
        print(f"CONTROL-FAILED: boolean engine '{ENGINE}' raised: {exc}", file=sys.stderr)
        return False

    vol = float(hit.volume) if hit is not None and len(hit.faces) else 0.0
    err = abs(vol - CONTROL_OVERLAP_MM3)

    if err > 0.01:
        print(
            f"CONTROL-FAILED: known {CONTROL_OVERLAP_MM3:.3f} mm^3 overlap "
            f"measured as {vol:.6f} mm^3 (error {err:.6f}).\n"
            "The engine cannot be trusted on this machine. Do not believe any "
            "clearance result it produces.",
            file=sys.stderr,
        )
        return False

    if verbose:
        print(f"CONTROL-OK    engine={ENGINE}  known overlap {CONTROL_OVERLAP_MM3:.1f} mm^3 "
              f"measured {vol:.4f} mm^3")
    return True


class Untrusted(Exception):
    """The answer cannot be trusted -- distinct from 'the parts interfere'.

    These must never share an exit code. A script that reads a load failure as
    'interference found' is merely wrong; one that reads it as 'clear' ships a
    colliding part.
    """


def load(path):
    try:
        mesh = trimesh.load_mesh(path)
    except Exception as exc:
        raise Untrusted(
            f"could not read {path}: {type(exc).__name__}: {exc}\n"
            "  A mesh that will not load cannot be proven clear of anything.\n"
            "  Re-export it, and check the exporter actually wrote a solid format."
        ) from exc

    if isinstance(mesh, trimesh.Scene):
        mesh = trimesh.util.concatenate(tuple(mesh.geometry.values()))

    if not hasattr(mesh, "faces") or len(mesh.faces) == 0:
        raise Untrusted(
            f"{path} loaded with zero triangles.\n"
            "  ⛔ This is the trap, not a clearance: OpenSCAD exits 0 on a failed\n"
            "     assert() for tree formats and PNG, and a CGAL error can leave an\n"
            "     empty or missing file behind while still exiting 0."
        )
    return mesh


def describe(path, mesh):
    lo, hi = mesh.bounds
    size = hi - lo
    return (
        f"  {path}\n"
        f"    triangles  {len(mesh.faces)}\n"
        f"    bbox       {size[0]:.3f} x {size[1]:.3f} x {size[2]:.3f} mm\n"
        f"    min/max    [{lo[0]:.3f} {lo[1]:.3f} {lo[2]:.3f}] .. "
        f"[{hi[0]:.3f} {hi[1]:.3f} {hi[2]:.3f}]\n"
        f"    volume     {mesh.volume:.3f} mm^3\n"
        f"    watertight {mesh.is_watertight}\n"
    )


def cmd_report(args):
    ok = True
    for path in args.stl:
        try:
            mesh = load(path)
        except Untrusted as exc:
            print(f"UNTRUSTED: {exc}", file=sys.stderr)
            ok = False
            continue
        print(describe(path, mesh))
        if not mesh.is_watertight:
            print(f"    WARNING: {path} is not watertight. Any boolean against it "
                  f"is meaningless.\n", file=sys.stderr)
            ok = False
    return 0 if ok else 1


def cmd_intersect(args):
    if not self_test():
        return 2

    try:
        a, b = load(args.a), load(args.b)
    except Untrusted as exc:
        print(f"UNTRUSTED: {exc}", file=sys.stderr)
        return 2

    # A boolean against a non-watertight mesh is exactly trap 7: it returns
    # empty, and empty is the answer you were hoping for. Refuse instead.
    untrusted = [p for p, m in ((args.a, a), (args.b, b)) if not m.is_watertight]
    if untrusted:
        print(f"UNTRUSTED: not watertight: {', '.join(untrusted)}\n"
              "  An empty intersection here would prove nothing. Fix the mesh, or\n"
              "  probe by calling the part's module directly rather than re-importing.",
              file=sys.stderr)
        return 2

    hit = _boolean_intersection(a, b)
    vol = float(hit.volume) if hit is not None and len(hit.faces) else 0.0

    print(f"\n  A  {args.a}")
    print(f"  B  {args.b}")

    if vol <= args.max_volume:
        print(f"\nCLEAR         intersection {vol:.6f} mm^3 "
              f"(allowed {args.max_volume:.6f})")
        print("              self-test passed and both meshes watertight, so this "
              "is a real result.")
        return 0

    lo, hi = hit.bounds
    print(f"\nINTERFERENCE  {vol:.6f} mm^3  (allowed {args.max_volume:.6f})")
    print(f"              spans   x {lo[0]:.3f}..{hi[0]:.3f}  "
          f"y {lo[1]:.3f}..{hi[1]:.3f}  z {lo[2]:.3f}..{hi[2]:.3f}")

    # How many SEPARATE collisions, not just how big the bounding box is. A ring
    # of teeth touching in 48 places has a bbox the size of the whole ring, which
    # says nothing useful about any one contact -- and quoting that span as a
    # "depth" would be a lie of exactly the kind this tool exists to prevent.
    bodies = hit.split(only_watertight=False)
    print(f"              {len(bodies)} separate contact{'s' if len(bodies) != 1 else ''}")
    ranked = sorted(bodies, key=lambda m: -abs(m.volume))[:5]
    for i, body in enumerate(ranked, 1):
        blo, bhi = body.bounds
        thinnest = min(bhi - blo)
        print(f"                {i}. {abs(body.volume):9.4f} mm^3  "
              f"thinnest dimension {thinnest:.3f} mm  "
              f"at [{(blo[0]+bhi[0])/2:.2f} {(blo[1]+bhi[1])/2:.2f} {(blo[2]+bhi[2])/2:.2f}]")
    if len(bodies) > len(ranked):
        print(f"                ... and {len(bodies) - len(ranked)} more")

    if args.out:
        hit.export(args.out)
        print(f"              collision solid written to {args.out} -- open it to "
              f"see exactly what is touching")
    return 1


def cmd_selftest(args):
    return 0 if self_test() else 2


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("report", help="mesh health and bounding box for each STL")
    p.add_argument("stl", nargs="+")
    p.set_defaults(func=cmd_report)

    p = sub.add_parser("intersect", help="prove two parts do not interfere")
    p.add_argument("a")
    p.add_argument("b")
    p.add_argument("--max-volume", type=float, default=0.0,
                   help="mm^3 of overlap to tolerate (default 0)")
    p.add_argument("--out", help="write the collision solid here when it is not clear")
    p.set_defaults(func=cmd_intersect)

    p = sub.add_parser("selftest", help="run the positive control only")
    p.set_defaults(func=cmd_selftest)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
