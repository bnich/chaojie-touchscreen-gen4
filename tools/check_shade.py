#!/usr/bin/env python3
"""Does the sun visor actually shade the screen?

⭐ WHY THIS EXISTS
------------------
The brow shipped for two rounds against the acceptance criterion

    "brow projects `brow` mm over the glass"

and passed — while projecting **minus 7 mm**. It stopped behind the glass
plane, pointing up and backwards, and shaded exactly nothing. The criterion
measured the *mechanism* instead of the *job*, which is how this project also
shipped a tilt joint that rolled instead of pitching.

This measures the job: it fires rays at the screen from a given sun elevation
and reports what fraction of it the cowl actually blocks.

⚠️ THE LEVER IS WIDTH, NOT PROJECTION
Going from 33 mm to 60 mm of centre projection moves 45° shade only
14.8% → 20.4%, because the visor's tapered outer columns are never shaded at
any projection. If more shade is wanted, widen the visor's useful span before
reaching for a longer nose.

Usage:
    check_shade.py <cowl.stl> [--min-45 PCT]

Exits non-zero if the 45° figure falls below --min-45.

⚠️ Needs `rtree` as well as trimesh — it backs trimesh's ray engine. Without
it this fails with a bare ModuleNotFoundError from deep inside trimesh, so
it is checked for here (and in tools/build.sh's own preflight) instead.
"""
import math
import sys

import numpy as np
import trimesh

try:
    import rtree  # noqa: F401  (imported for the check, used via trimesh)
except ImportError:
    sys.exit("check_shade.py needs rtree (it backs trimesh's ray engine): "
             "pip install rtree")

# The display, from docs/display-geometry.md. The glass — the surface that
# needs shading — is the front face, at z = -DISP_D.
DISP_W, DISP_H, DISP_D = 159.99, 93.98, 26.0


def shade_fraction(cowl, elevation_deg, nx=61, ny=41):
    """Fraction of the glass the cowl shades, and how far the shadow reaches.

    A point is shaded if the ray from it toward the sun meets the cowl first.
    """
    xs = np.linspace(-DISP_W / 2, DISP_W / 2, nx)
    ys = np.linspace(-DISP_H / 2, DISP_H / 2, ny)
    # 0.05 clear of the glass, so a sample never starts inside the display solid
    pts = np.array([[x, y, -DISP_D - 0.05] for y in ys for x in xs])

    e = math.radians(elevation_deg)
    toward_sun = np.array([0.0, math.sin(e), -math.cos(e)])
    dirs = np.tile(toward_sun, (len(pts), 1))

    hit = cowl.ray.intersects_any(ray_origins=pts, ray_directions=dirs)
    frac = hit.sum() / len(pts)

    # Depth is reported only for rows that are mostly shaded, so a visor
    # covering a narrow centre strip cannot claim a deep shadow.
    rows = [ys[i] for i in range(ny) if hit[i * nx:(i + 1) * nx].mean() > 0.5]
    depth = (DISP_H / 2 - min(rows)) if rows else 0.0
    return frac, depth


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    floor = 0.0
    if "--min-45" in sys.argv:
        floor = float(sys.argv[sys.argv.index("--min-45") + 1])

    cowl = trimesh.load(path, process=True)
    if not cowl.is_watertight:
        print(f"    UNTRUSTED: {path} is not watertight; ray hits are unreliable")
        return 2

    lo = cowl.bounds[0][2]
    print(f"    visor reaches z = {lo:.1f}; the glass is at z = {-DISP_D:.1f}"
          f"  ->  {-DISP_D - lo:+.1f} mm of projection past it")

    frac45 = 0.0
    for elev in (45.0, 60.0, 75.0):
        frac, depth = shade_fraction(cowl, elev)
        if elev == 45.0:
            frac45 = frac * 100
        print(f"    sun {elev:4.0f}deg   shades {frac * 100:5.1f}% of the screen"
              f"   shadow {depth:5.1f} mm down from the top edge")

    if frac45 < floor:
        print(f"    FAIL: {frac45:.1f}% shaded at 45deg is below the {floor:.0f}% floor.")
        print("    The visor is not doing its job. Widen its useful span.")
        return 1
    print(f"    OK - {frac45:.1f}% at 45deg, floor {floor:.0f}%.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
