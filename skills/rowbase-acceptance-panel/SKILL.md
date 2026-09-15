---
name: rowbase-acceptance-panel
description: |
  Run an independent, read-only acceptance panel against a frozen production candidate of a
  Rowbase brain (MCP server + warehouse) using headless Claude sessions as panelists, then
  reconcile the receipts and fix forward. Use when: (1) a contract in docs/acceptance names
  cases (CRL-nn, QRY-nn, …) that need production evidence, (2) the owner asks for "acceptance"
  of a release, (3) a candidate must be judged without the panel changing production. Covers the
  panelist brief, the headless MCP call pattern, lens split, receipt schema, the freeze rule,
  reconciliation, and the worktree rule for docs agents. Distilled from three panels on the
  Elliot Group brain (2026-09-11 to 2026-09-15).
author: Claude Code
version: 1.0.0
date: 2026-09-15
---

# Rowbase acceptance panel

## Problem

A release that "works" for its author still has to be judged by someone who did not build it,
against the contract's cases, on the exact artifact that serves. The judgement must not change
production, must be reproducible, and must end in a written receipt the owner can act on.

## Trigger conditions

- A contract file lists cases with expected outcomes and a YAML receipt schema.
- The candidate is live (release run id, image digest, publication id known).
- The owner has asked for acceptance, or a remediation needs a fresh verdict.

## Solution

1. Freeze the candidate: record commit, release run, image digest, task-definition revisions,
   publication id. Do not merge, release, or dispatch a data operation until every receipt is in;
   a load inside the window is a recorded discrepancy, a release invalidates the panel.
2. Launch one background agent per lens (business logic / UI-UX, data / source, integration +
   security, deployment + operations, code review; split integration and security, or
   deployment and operations, when the contract is large). Each brief carries: the contract
   path, the candidate identity, the authority boundary (read-only AWS profile, `gh run view`,
   no dispatch, no writes, never print a secret value), known quirks already logged, a timebox,
   and the receipt schema.
3. MCP calls run as fresh headless sessions so the tool table is current:
   `claude -p "<instruction>" --allowedTools "mcp__<server>__<tool>,…" --output-format json`.
   A long-lived session keeps the tool list and instructions it had at start.
4. Write access is limited to one labelled test submission per panel (for example a
   `PANEL TEST` review row) and only where the contract allows it.
5. Extract each receipt's final message from the agent transcript into a file, then have a
   docs-only agent in its own git worktree reconcile them: whole-suite verdict, per-case table in
   a dated companion file (`docs/acceptance/<date>-<contract>-panel-vN.md`), and a short receipt
   section plus reconciled findings in the contract. Every Markdown file stays under the
   repository's line cap. The lead's rulings (which fails are contract drift, which are fixed in
   which PR, which are follow-ups) are stated as rulings.
6. Fix forward in small PRs, each naming the case and lens that found it; release once when the
   window has closed; then read the post-remediation state as the release owner's observation,
   not as a re-run of the panel.

## Verification

Receipts agree on the candidate identity and on the root causes independently (the same
traceback line, the same count gap); each per-case row cites a source of truth; the whole-suite
verdict is fail, blocked, or pass with the cases that drove it.

## Example

Elliot brain, 2026-09-15: ten lenses over two contracts found one crash (unqualified hidden
column hashing pydantic models), one data defect worth two thirds of the Searches (a seed mapped
strings where the source sends a byte), one gate gap (unreported source admitted under
allow_delayed), and contract drift (the acceptance identity had gained a permission). Three PRs,
one release, one publish: Searches 1,570 to 5,109, Placements 202 to 2,078.

## Notes

- Never let a docs agent work in the main checkout while you branch there: `git checkout -b`
  carries its uncommitted files across and `git add -A` sweeps them into your commit.
- A pipeline `pytest … | grep … | tail -1` returns tail's exit code; read the pass line before
  `&& git commit`.
- A cancelled `gh run watch` says nothing about the ECS task behind a flow; read the flow
  stream's `Finished in state` line.
- Prefect never retries a Crashed run, so a termination must count as the final attempt on
  every attempt or the failure line and the page never happen.
- Panelists should count a named column, not `count(*)`, when the validator forbids wildcards.
