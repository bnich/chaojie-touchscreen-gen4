#!/usr/bin/env python3
"""Bounding-box check for STL exports. ASCII or binary."""
import argparse, struct, sys

def read_stl(path):
    with open(path, "rb") as f:
        data = f.read()

    if data[:5] == b"solid":
        txt = data.decode("utf-8", "replace")
        # "solid" is not proof the file is ASCII: some binary exporters stash
        # an arbitrary name -- occasionally even literally "solid" -- in the
        # free-form 80-byte header of an otherwise-binary file. The reliable
        # signal is a live "facet" line, which only a real ASCII STL has, so
        # we parse as ASCII only when one actually shows up.
        if "facet" in txt:
            v = [tuple(map(float, ln.split()[1:4]))
                 for ln in txt.splitlines() if ln.strip().startswith("vertex")]
            return v, len(v) // 3
        # No "facet" line. Either a legitimate zero-triangle ASCII STL
        # ("solid X\nendsolid X\n", nothing in between) or a file too short
        # to be a populated binary STL either. Report empty rather than
        # falling into the binary reader below, which would either misread
        # ASCII bytes as float data or crash on a header that isn't there.
        if "endsolid" in txt or len(data) < 84:
            return [], 0

    if len(data) < 84:
        raise ValueError(
            f"truncated STL: {len(data)} bytes, need at least 84 for a binary header")
    n = struct.unpack("<I", data[80:84])[0]
    need = 84 + 50 * n
    if len(data) < need:
        raise ValueError(
            f"truncated STL: header claims {n} triangles ({need} bytes needed) "
            f"but the file is only {len(data)} bytes")
    v = []
    for i in range(n):
        rec = data[84 + 50 * i : 84 + 50 * i + 50]
        d = struct.unpack("<12fH", rec)
        v += [d[3:6], d[6:9], d[9:12]]
    return v, n

def bbox(v):
    return ([min(p[i] for p in v) for i in range(3)],
            [max(p[i] for p in v) for i in range(3)])

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("stl")
    ap.add_argument("--expect", help="WxHxD expected size, e.g. 159.99x93.98x6")
    ap.add_argument("--tol", type=float, default=0.5)
    a = ap.parse_args()

    try:
        v, n = read_stl(a.stl)
    except FileNotFoundError:
        print(f"FILE NOT FOUND: {a.stl}"); return 1
    except (ValueError, struct.error, OSError) as e:
        print(f"COULD NOT READ STL: {e}"); return 1

    if not v:
        print("EMPTY GEOMETRY — the part produced no triangles"); return 1
    lo, hi = bbox(v)
    size = [hi[i] - lo[i] for i in range(3)]
    print(f"{a.stl}: {n} triangles")
    print(f"  min  {lo[0]:8.2f} {lo[1]:8.2f} {lo[2]:8.2f}")
    print(f"  max  {hi[0]:8.2f} {hi[1]:8.2f} {hi[2]:8.2f}")
    print(f"  size {size[0]:8.2f} {size[1]:8.2f} {size[2]:8.2f}")
    if a.expect:
        try:
            want = [float(x) for x in a.expect.lower().split("x")]
            if len(want) != 3:
                raise ValueError(f"need 3 axes WxHxD, got {len(want)}: {a.expect!r}")
        except ValueError as e:
            print(f"BAD --expect VALUE: {e}"); return 1
        bad = [i for i in range(3) if abs(size[i] - want[i]) > a.tol]
        if bad:
            print(f"  FAIL: axes {bad} differ from {want} by more than {a.tol}")
            return 1
        print(f"  OK: within {a.tol} of {want}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
