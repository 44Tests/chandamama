# చందమామ · The Bus-Stand Book Stall

A nostalgic web archive of *Chandamama* magazine, read the way it was meant to be read:
bought at a bus-stand book stall, opened on your lap as the bus rolls toward
grandma's village. Palmyra trees and electric poles pass the window, a roadside
milestone counts down one kilometre per page, and dusk turns to night as you read.

Pure static site — no framework, no build step. Deploys anywhere; built for Vercel.

## Structure

```
index.html            the book stall (library home)
reader.html           the bus-journey flipbook reader (?e=<edition-id>)
data/editions.json    manifest of all editions
editions/<id>/        cover.webp + pages/page-NNN.webp per edition
assets/               shared photos
scripts/              ingest tooling
archive/              source PDFs (gitignored, keep locally)
```

## Adding an edition

Requirements (macOS): `brew install poppler webp`

```bash
scripts/add-edition.sh archive/July_1962.pdf 1962-07-te "జులై 1962" "రూ. 1/-"
git add editions/1962-07-te data/editions.json
git commit -m "Add July 1962"
git push        # Vercel auto-deploys
```

Edition ids are `YYYY-MM-lang` (e.g. `2012-12-te`). The script renders every PDF
page to WebP (~20 MB per edition), writes a small cover, and updates the manifest.
The stall groups editions by year automatically; decade filters and search appear
once the library grows past a dozen issues.

## Scaling plan (~500 editions)

The repo comfortably holds the first ~15–20 editions (~300–400 MB). Beyond that,
move page images to object storage — the site is already wired for it:

1. Create a Cloudflare R2 bucket (free tier: 10 GB storage, unlimited egress)
   with a public custom domain.
2. Upload the `editions/` tree: `rclone copy editions/ r2:chandamama/editions/`
   (covers can stay in the repo; the stall always reads covers from the repo).
3. Set `"baseUrl": "https://<your-r2-domain>"` in `data/editions.json`.
4. Delete `editions/*/pages/` from the repo. Done — the reader builds page URLs
   from `baseUrl`, nothing else changes.

## Vercel setup

Import the GitHub repo at vercel.com → framework preset **Other**, no build
command, output directory = repo root. `vercel.json` already sets immutable
caching for `/editions/*`.

## A note on the scans

These are scans of a magazine with a complicated rights history. This project
exists as personal memory-keeping; if you republish it, that judgment — and any
takedown request that follows — is yours to own.
