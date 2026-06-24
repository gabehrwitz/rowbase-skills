#!/usr/bin/env bash
# Install the ready-to-use Gooseworks GTM skills (no paid keys needed) from source.
# See EXTERNAL_SKILLS.md for the list and caveats.
set -euo pipefail

REPO="gooseworks-ai/gooseworks-skills"
PICKS=(
  email-drafting brainstorming-partner brand-voice-extractor
  icp-identification icp-persona-builder icp-website-review
  customer-discovery create-html-slides create-html-carousel
  create-workflow-diagram hacker-news-scraper web-archive-scraper
  youtube-watcher
)

echo "Installing ${#PICKS[@]} Gooseworks picks from $REPO ..."
for s in "${PICKS[@]}"; do
  echo "  -> $s"
  npx skills add "$REPO" -g -s "$s" --full-depth || \
    echo "     (skipped: adjust the -s path if your npx skills version needs skills/capabilities/$s)"
done
echo "Done. Run: npx skills list -g"
