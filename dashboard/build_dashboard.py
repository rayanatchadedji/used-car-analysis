#!/usr/bin/env python3
"""Regenerate the data block embedded in dashboard/index.html from used_cars.db.

The dashboard is a standalone page: an Artifact can't fetch a sibling file, so
the rows have to live inside the HTML. That makes the data a derived artifact
like any other in this repo -- so it gets a build step instead of being pasted
in by hand and left to drift from the database.

Rewrites only the contents of <script id="car-data">...</script>, leaving the
rest of the page untouched. Run it after any change to the cleaned data.
"""

from __future__ import annotations

import json
import re
import sqlite3
from pathlib import Path

HERE = Path(__file__).resolve().parent
DB = HERE.parent / "data" / "processed" / "used_cars.db"
PAGE = HERE / "index.html"

# Brands under this many listings fold into "other": a mean over 1-4 rows is
# noise, and a bar chart with a 26-category tail is unreadable.
MIN_BRAND_N = 10

REGION_ORDER = ["Midwest", "Northeast", "West", "South", "Canada"]
TITLE_ORDER = ["clean vehicle", "salvage insurance"]


def build_payload(conn: sqlite3.Connection) -> dict:
    rows = conn.execute("""
        SELECT l.price, l.mileage, l.year, l.title_status, l.brand, r.region
        FROM listings l JOIN regions r ON l.state = r.state
    """).fetchall()

    counts: dict[str, int] = {}
    for _, _, _, _, brand, _ in rows:
        counts[brand] = counts.get(brand, 0) + 1
    kept = {b for b, n in counts.items() if n >= MIN_BRAND_N}
    folded = sorted(b for b in counts if b not in kept)

    brands = sorted(kept) + ["other"]
    bi = {b: i for i, b in enumerate(brands)}
    ri = {r: i for i, r in enumerate(REGION_ORDER)}
    ti = {t: i for i, t in enumerate(TITLE_ORDER)}

    packed = [
        [price, mileage, year, ti[title], bi[brand if brand in kept else "other"], ri[region]]
        for price, mileage, year, title, brand, region in rows
    ]
    return {
        "brands": brands,
        "regions": REGION_ORDER,
        "titles": TITLE_ORDER,
        "minBrandN": MIN_BRAND_N,
        "foldedCount": sum(counts[b] for b in folded),
        "foldedNames": folded,
        "rows": packed,
    }


def main() -> int:
    if not DB.exists():
        raise SystemExit(f"error: {DB} not found -- run notebook 02 to build it first")
    with sqlite3.connect(DB) as conn:
        payload = build_payload(conn)

    blob = json.dumps(payload, separators=(",", ":"))
    html = PAGE.read_text()
    pattern = re.compile(
        r'(<script id="car-data" type="application/json">)(.*?)(</script>)', re.S
    )
    if not pattern.search(html):
        raise SystemExit('error: no <script id="car-data"> block in index.html')
    PAGE.write_text(pattern.sub(lambda m: m.group(1) + blob + m.group(3), html, count=1))

    print(f"embedded {len(payload['rows'])} rows, {len(payload['brands'])} brand groups "
          f"({payload['foldedCount']} listings folded into 'other') -> {PAGE.name} "
          f"[{len(blob)/1000:.0f} KB of data]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
