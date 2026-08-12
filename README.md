# చందమామ · The Bus-Stand Book Stall

A nostalgic web archive of *Chandamama* magazine, read the way it was meant to be read:
bought at a bus-stand book stall, opened on your lap as the bus rolls toward
grandma's village. Palmyra trees and electric poles pass the window, a roadside
milestone counts down one kilometre per page, and dusk turns to night as you read.

Live at [chandamama.co](https://chandamama.co).

Pure static site — no framework, no build step. Deploys anywhere; built for Vercel.

## An honest note about this project

I grew up in what is now Telangana, when it was still part of undivided Andhra
Pradesh. My clearest childhood memories are of bus journeys to my grandparents'
village during Dasara, Sankranthi, and the summer holidays — and at the bus stand,
I would always buy two things: a packet of popcorn and the latest Telugu
*Chandamama*. This site exists to keep that feeling alive. Nothing more.

So, plainly:

- **I do not own Chandamama.** Not the name, not the stories, not the art, not
  the scans. I am just someone who loved reading it as a child.
- **This is completely free.** No ads, no payments, no accounts, no tracking.
  It costs you nothing and it earns me nothing.
- **I claim no rights over anything here.** The magazine pages belong to whoever
  rightfully holds them. The only thing I made is the reading experience around
  them — the bus, the ticket, the milestone.
- **If you hold rights to Chandamama and want this taken down, I will take it
  down immediately, no argument.** Please open an issue on this repository and
  I will remove the content as soon as I see it.

If you are here because you also remember reading Chandamama on a bus — welcome.
This is for you too.

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

