# External Skills

Skills we use but do **not** vendor into this repo, because their source repos
ship no redistribution license (no `LICENSE` file = all rights reserved).
Install them from source instead. This file is the curated manifest.

## Gooseworks GTM picks (ready-to-use, no paid keys)

From <https://github.com/gooseworks-ai/gooseworks-skills> (`skills/capabilities/`).
These run with no API keys or external infra (the scrapers need only free APIs
and standard pip packages like `requests`).

| Skill | What it does |
| --- | --- |
| `email-drafting` | Cold email copy with proven frameworks (pure reasoning). |
| `brainstorming-partner` | Interactive idea / research thought partner. |
| `brand-voice-extractor` | Reads a company's content → brand voice profile. |
| `icp-identification` | Define the Ideal Customer Profile, route to next step. |
| `icp-persona-builder` | Build 4–6 synthetic buyer personas as a reusable asset. |
| `icp-website-review` | Run a site/landing page through those personas. |
| `customer-discovery` | Discover who a company sells to (BuiltWith key optional). |
| `create-html-slides` | HTML presentations (invoke as `frontend-slides`). |
| `create-html-carousel` | LinkedIn carousels as 1080×1080 PNGs. |
| `create-workflow-diagram` | FigJam-style diagrams as PNGs. |
| `hacker-news-scraper` | Search HN via the free Algolia API. |
| `web-archive-scraper` | Wayback Machine CDX search (free). |
| `youtube-watcher` | Fetch and read YouTube transcripts. |

**Caveat:** `lead-qualification` is great for its conversational qualify-logic,
but its batch-enrichment step needs an Apify key. `blog-scraper` is excluded —
its only script hard-requires `GOOSEWORKS_API_KEY` at import.

### Install (OpenClaw)

```bash
# Easiest: install everything from the repo, ignore the ones needing keys
npx skills add gooseworks-ai/gooseworks-skills -g --all --full-depth

# Or run the helper script in this repo to install just the picks:
bash install-external.sh
```

## Notes

- `npx skills list -g --json` lists globally installed skills.
- If a per-skill `-s` path fails for the nested `skills/capabilities/<name>`
  layout, install `--all` and remove the ones you don't want.
