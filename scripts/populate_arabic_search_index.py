#!/usr/bin/env python3
"""Populate the Arabic full-text-search column of the shipped azkar database.

The `azkar_search` FTS5 table has a `text_ar` column that ships empty, which is
why Arabic search never returned results. This script fills it from the Arabic
text in the `azkar` table, applying the same normalization the app uses at query
time (see `String.arabicSearchNormalized` in
`Packages/Core/Sources/Extensions/String.swift`).

Normalization (must stay in sync with the Swift implementation):
  * drop tashkeel / Quranic annotation marks and the tatweel
  * unify alef/hamza variants (آ أ إ ٱ -> ا), alef maqsura (ى -> ي),
    ta marbuta (ة -> ه)

Run after editing the source Arabic text or changing the normalization rules:

    python3 scripts/populate_arabic_search_index.py

By default it edits `Azkar/Resources/azkar.db` in place.
"""

import os
import sqlite3
import sys

DEFAULT_DB = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Azkar",
    "Resources",
    "azkar.db",
)


def arabic_search_normalized(text: str) -> str:
    out = []
    for ch in text:
        o = ord(ch)
        # Drop tashkeel / Quranic annotation marks and the tatweel.
        if (
            0x0610 <= o <= 0x061A
            or 0x064B <= o <= 0x065F
            or o == 0x0670
            or 0x06D6 <= o <= 0x06ED
            or o == 0x0640
        ):
            continue
        if o in (0x0622, 0x0623, 0x0625, 0x0671):  # آ أ إ ٱ -> ا
            out.append("ا")
        elif o == 0x0649:  # ى -> ي
            out.append("ي")
        elif o == 0x0629:  # ة -> ه
            out.append("ه")
        else:
            out.append(ch)
    return "".join(out)


def main() -> int:
    db_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DB
    if not os.path.exists(db_path):
        print(f"Database not found: {db_path}", file=sys.stderr)
        return 1

    con = sqlite3.connect(db_path)
    try:
        rows = con.execute("SELECT id, text FROM azkar").fetchall()
        updated = 0
        for zikr_id, text in rows:
            normalized = arabic_search_normalized(text or "")
            con.execute(
                "UPDATE azkar_search SET text_ar = ? WHERE rowid = ?",
                (normalized, zikr_id),
            )
            updated += 1
        con.commit()
        print(f"Populated text_ar for {updated} rows in {db_path}")
    finally:
        con.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
