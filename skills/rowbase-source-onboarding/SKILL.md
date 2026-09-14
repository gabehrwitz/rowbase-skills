---
name: rowbase-source-onboarding
description: |
  Checklist for taking a new REST API source (dlt landing + dbt conformance + Prefect
  schedule) from fixture-green to its first successful production backfill in a Rowbase
  brain. Use when: (1) a source's integration tests pass on a fixture and the first
  production run is next, (2) a production load fails with an HTTP 400/404/403 on its
  first request, (3) foreign keys land as JSON strings or every join is excluded as an
  invalid reference, (4) a Prefect flow shows Crashed instead of retrying, (5) a Docker
  image build fails with "/dir: not found" after adding a shipped directory, (6) a CI
  test races a fixture HTTP server. Distilled from the Crelate onboarding in the Elliot
  Group brain (2026-09-14), where each item cost a failed production run or a review finding.
author: Claude Code
version: 1.0.0
date: 2026-09-14
---

# Rowbase source onboarding

Load `rowbase-data-principles` first. This skill adds the steps between "green on the
fixture" and "landed in production" that the fixture cannot prove.

## Problem

A source built from an OpenAPI document and a synthetic fixture passes every local test
and still fails on its first production request, because the fixture encodes the
builder's assumptions rather than the API's behaviour. Each assumption costs a failed
backfill, an alarm page, and a fix-release cycle.

## Trigger conditions

- The integration lane is green and the next step is a production dispatch.
- A production run fails on its first request: `400 Value must be between 0 and 100
  (Parameter 'limit')`, `404` on a helper endpoint, `403 Insufficient privileges`.
- Landed foreign-key columns hold JSON text like `{"Id": ..., "Title": ...}`; the
  conformance layer excludes almost every row as `invalid_reference`.
- Prefect reports `Crashed` with `Concurrency lease renewal failed ... 410 Gone`.
- `docker build` fails with `"/guidance": not found` after a new `COPY`.
- A unit test asserting on a fixture server's request log fails only in CI.

## Solution

### 1. Probe the live API with the production parameters, before the first dispatch

Run a handful of paced requests from the developer machine using the key from the
secret store, and print only status codes, key names, and value shapes. Never print a
value or the key.

- Send the exact query the client will send: the real page size (`limit=100`, not
  `limit=1`), `sort_by`, the window bounds, the cursor format with microseconds and
  offset. A probe at `limit=1` proved nothing about the `limit=500` the client used.
- For every field a model reads, print the value shape (`{Id,Title}`, `[{Id,Title}]`,
  `str`, `float`, `bool`, `NoneType`) from three records sorted by `ModifiedOn desc`.
  Reference fields commonly arrive as `{Id, Title}` objects, parent references add
  `EntityName`, owners are lists, and list endpoints omit body fields (`Body` absent,
  text in `Display`).
- Call every helper endpoint the source depends on for every entity (`/<entity>/count`,
  `/<entity>/info`). They exist for some entities and answer 404 or 403 for others.
- Fetch the schema catalogue if one exists (`/customfields`, `/custompicklistsets`,
  `/custompicklistitems`, `/<entity>/info`) and generate the field-map seed from it.
  Display names and types come from the API; do not assume meanings.

### 2. Model references so the object stays in the payload

Read a reference by path, `AliasPath("AccountId", "Id")`, with a validator that accepts
a scalar or a `{Id, ...}` object. A path alias leaves the whole object in the landing
`payload` column (lossless); a string alias consumes it. Never let a dict reach a text
column: `json.dumps` of a reference silently becomes a foreign key that matches nothing.

### 3. Never make a backfill depend on a helper endpoint

A windowed first backfill starts from the oldest `ModifiedOn` (one `limit=1` sorted
request) and steps forward in fixed windows. If a `/count` is only an optimisation,
drop it; if a count is required, read `Metadata.TotalRecords` from the list envelope.

### 4. Make the fixture server as strict as the API

Mirror every cap and error shape the probe found: reject `limit` above the cap with the
API's own envelope error, return the reference-object shapes, omit fields the list
endpoint omits, and answer 404 on helper endpoints the API lacks. Record a request in
the server's log **before** writing the response; appending after `wfile.write` races a
fast client and fails only on slow CI runners.

### 5. Schedule and retry settings that survive Prefect

- Keep `retry_delay_seconds` at 60. A flow-level retry sleeps in-process; a 300 s sleep
  outlived the deployment concurrency lease and the run ended `Crashed` with
  `410 Gone` instead of retrying.
- Use cron schedules, not intervals: `prefect deploy` re-anchors an interval schedule at
  deploy time, so every release moves the clock and a frequent release cadence can
  starve an hourly flow.
- If the first production load must be a full mode (reference vocabularies load only
  there), say so in the orchestration spec and dispatch that mode first; an incremental
  first run followed by a publish fails inside dbt rather than blocking with a reason.

### 6. Ship the new directories

`.dockerignore` in these repositories is an allowlist (`*` then `!dir/` entries). Every
new top-level directory the image needs (`guidance/`, `seeds/`, `semantic/`, `vendor/`)
needs `!dir/` and `!dir/**`, and `tests/integration/test_container_image.py` must run
locally (about 50 s) whenever the Dockerfile or a shipped directory changes; it is the
test most often deselected locally and the one CI fails on.

### 7. Protect the acceptance window

Freeze the candidate and hold every release until the panel verdict is in. A release
during an open panel displaces the candidate (`DEPLOY-01`/`CODE-01` fail) and, with
interval schedules, resets the operating cycle the panel is trying to observe.

## Verification

- The probe script prints only statuses, key names, and shapes; a `grep` of its output
  for `@`, a record id, or the key returns nothing.
- The first production dispatch reaches `<source>_entities_completed` and the publish
  that follows reports `published`; `data_status` lists the source as `Current`.
- The fixture server rejects the over-cap page size with the same status and message
  the API returned in the probe.
- `flow-failed-<source>` returns to OK within an hour of the successful run.

## Example

Crelate, 2026-09-14: the source passed 13 integration tests on the fixture. Production
attempt 1 failed on `limit=500` (cap 100). Attempt 2 failed on `/notes/count` (404) and
crashed instead of retrying (300 s retry delay). A shape probe between attempts showed
every reference as `{Id, Title}` and note text in `Display`; without that fix every
candidacy, placement, and search would have been excluded as an invalid reference. The
catalogue endpoints supplied 57 custom-field definitions and 121 picklist items, so the
field map was generated rather than guessed. Attempt 3 ran.

## Notes

- Per-request audit lines written through a plain `logging` logger do not reach the
  Prefect run log in production; pass the run logger into the client if the spec
  requires per-request audit visibility.
- A vendored private package (`vendor/<name>` with a `UPSTREAM` file, `[tool.uv.sources]`
  path) needs no build token; fieldcap-etl and elliot-group-etl both use it. Exclude
  `vendor/` from repository checks (file length, boundary, suppressions).
- Related skills: `rowbase-data-principles`, `rowbase-data-modeling`,
  `rowbase-full-acceptance`.
