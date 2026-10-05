#!/usr/bin/env python3
"""
Run every SQL script in queries/ against a Chinook SQLite database and
export each numbered query (1.1, 1.2, ... 5.8) to its own CSV in results/.

Usage (from the project root):
    python3 run_all.py                         # uses database/chinook.sqlite
    python3 run_all.py database/other.sqlite   # or pass another file
"""
import csv
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "database" / "Chinook_Sqlite.sqlite"
QUERIES = ROOT / "queries"
RESULTS = ROOT / "results"

# Queries to export as CSV (the ones that answer the task).
# Every query is still EXECUTED, because 3.1, 4.1 and 5.1 create the views
# that later queries rely on. Add or remove numbers here to change the output.
KEEP = {
    "2.1", "2.2", "2.3", "2.4",   # top-selling products
    "3.1", "3.4",                 # revenue per country / region
    "4.1", "4.2", "4.3",          # monthly performance
    "5.2", "5.3",                 # window functions (bonus)
}

HEADER = re.compile(r"^--\s*(\d+\.\d+)\s+(.+?)\s*$")


def slug(text):
    text = re.sub(r"\(.*?\)", "", text)            # drop "(with share of total)"
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text)
    return text.strip("_").lower()


def split_sections(sql_text):
    """Split a script into (number, title, sql) using the '-- X.Y TITLE' headers."""
    sections, current = [], None
    for line in sql_text.splitlines():
        m = HEADER.match(line)
        if m:
            current = [m.group(1), m.group(2), []]
            sections.append(current)
        elif current is not None:
            current[2].append(line)
    return [(n, t, "\n".join(body)) for n, t, body in sections]


def split_statements(sql):
    """Split a block into complete SQL statements."""
    statements, buf = [], ""
    for line in sql.splitlines(keepends=True):
        buf += line
        if sqlite3.complete_statement(buf):
            if buf.strip():
                statements.append(buf.strip())
            buf = ""
    if buf.strip() and re.sub(r"--.*", "", buf).strip():
        statements.append(buf.strip())
    return statements


def main():
    if not DB.exists():
        sys.exit(f"Database not found: {DB}")
    conn = sqlite3.connect(DB)
    total = 0
    for old in RESULTS.glob("*/*.csv"):          # remove stale CSVs from earlier runs
        old.unlink()
    for script in sorted(QUERIES.glob("*.sql")):
        out_dir = RESULTS / slug(script.stem)
        print(f"\n{script.name}")
        for number, title, body in split_sections(script.read_text(encoding="utf-8")):
            rows, cols = None, None
            for stmt in split_statements(body):
                cur = conn.execute(stmt)
                if cur.description:                 # a SELECT: keep its output
                    cols = [d[0] for d in cur.description]
                    rows = cur.fetchall()
            conn.commit()
            if rows is None:
                print(f"  {number}  {title}: no output (creates a view)")
                continue
            if number not in KEEP:
                print(f"  {number}  {title}: executed, not exported")
                continue
            out_dir.mkdir(parents=True, exist_ok=True)
            path = out_dir / f"{number}_{slug(title)}.csv"
            with open(path, "w", newline="", encoding="utf-8") as f:
                w = csv.writer(f)
                w.writerow(cols)
                w.writerows(rows)
            total += 1
            print(f"  {number}  {title}: {len(rows)} rows -> {path.relative_to(ROOT)}")
    conn.close()
    print(f"\nDone: {total} CSV files written to {RESULTS.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()