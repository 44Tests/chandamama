#!/usr/bin/env bash
# Add a Chandamama edition to the site.
#
#   scripts/add-edition.sh <pdf> <id> <title> [price]
#
#   <pdf>    path to the source PDF (keep sources in archive/, gitignored)
#   <id>     edition id in the form YYYY-MM-lang, e.g. 2012-12-te
#   <title>  display title, e.g. "డిసెంబర్ 2012"
#   [price]  optional cover price, e.g. "₹ 25/-"
#
# Renders every page to editions/<id>/pages/page-NNN.webp, writes a small
# cover.webp, and appends the edition to data/editions.json.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDF="$1"; ID="$2"; TITLE="$3"; PRICE="${4:-}"

if [[ ! -f "$PDF" ]]; then echo "PDF not found: $PDF" >&2; exit 1; fi
if [[ ! "$ID" =~ ^[0-9]{4}-[0-9]{2}-[a-z]{2}$ ]]; then
  echo "id must look like YYYY-MM-lang (e.g. 2012-12-te), got: $ID" >&2; exit 1
fi
command -v pdftoppm >/dev/null || { echo "pdftoppm missing (brew install poppler)" >&2; exit 1; }
command -v cwebp    >/dev/null || { echo "cwebp missing (brew install webp)" >&2; exit 1; }

ED="$ROOT/editions/$ID"
if [[ -e "$ED" ]]; then echo "edition already exists: $ED (delete it to re-ingest)" >&2; exit 1; fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$ED/pages" "$ED/thumbs"

echo "→ rendering $PDF ..."
pdftoppm -png -r 55 "$PDF" "$TMP/p"

echo "→ encoding WebP pages + thumbs ..."
n=0
for png in "$TMP"/p-*.png; do
  n=$((n+1))
  out=$(printf "%s/pages/page-%03d.webp" "$ED" "$n")
  thumb=$(printf "%s/thumbs/page-%03d.webp" "$ED" "$n")
  cwebp -quiet -q 78 "$png" -o "$out"
  cwebp -quiet -q 70 -resize 220 0 "$png" -o "$thumb"
done
if [[ $n -eq 0 ]]; then echo "no pages rendered" >&2; exit 1; fi

first="$TMP/$(ls "$TMP" | sort | head -1)"
cwebp -quiet -q 80 -resize 480 0 "$first" -o "$ED/cover.webp"

echo "→ updating manifest ..."
PAGES=$n ID="$ID" TITLE="$TITLE" PRICE="$PRICE" ROOT="$ROOT" python3 - <<'PY'
import json, os
root = os.environ["ROOT"]
path = os.path.join(root, "data", "editions.json")
os.makedirs(os.path.dirname(path), exist_ok=True)
try:
    with open(path) as f: data = json.load(f)
except FileNotFoundError:
    data = {"baseUrl": "", "editions": []}
eid = os.environ["ID"]
data["editions"] = [e for e in data["editions"] if e["id"] != eid]
year, month, lang = eid.split("-")
entry = {"id": eid, "lang": lang, "year": int(year), "month": int(month),
         "title": os.environ["TITLE"], "pages": int(os.environ["PAGES"])}
if os.environ["PRICE"]: entry["price"] = os.environ["PRICE"]
data["editions"].append(entry)
data["editions"].sort(key=lambda e: (e["year"], e["month"], e["lang"]))
with open(path, "w") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f"  {eid}: {entry['pages']} pages")
PY

SIZE=$(du -sh "$ED" | cut -f1)
echo "✓ $ID added — $n pages, $SIZE at editions/$ID"
echo "  next: git add editions/$ID data/editions.json && git commit"
