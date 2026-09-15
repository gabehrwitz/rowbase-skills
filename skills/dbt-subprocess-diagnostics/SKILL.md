---
name: dbt-subprocess-diagnostics
description: |
  Make a dbt build that runs as a subprocess (Prefect, Airflow, a CLI publish step) diagnosable
  without logging statements, values, or paths. Use when: (1) a publish or build step reports
  "dbt build failed" with no node named, (2) the run summary line is missing from the message,
  (3) you must not log SQL text or data values but still need to know which node failed and why,
  (4) dbt 1.12 output no longer matches a summary regex written for an older version (it adds
  REUSED= counters). Distilled from the Elliot Group brain, where four release cycles went to
  guessing before the output was logged safely (2026-09-15).
author: Claude Code
version: 1.0.0
date: 2026-09-15
---

# dbt subprocess diagnostics

## Problem

`subprocess.run(["dbt", "build", …], capture_output=True)` with a sanitized failure message
hides everything an operator needs. "No failed node named" was read as a killed child (memory
was raised, nothing changed), then as a parser bug, before the real cause surfaced: one singular
test failing with everything downstream skipped, then a Python gate failing after a clean build.

## Trigger conditions

- A message like `dbt build failed: no failed node named in the output`.
- Exit code 1 with no `Done.` summary captured, or a summary regex that stops matching after a
  dbt upgrade.
- A policy that forbids statements, values, and paths in logs (so raw stdout cannot be logged).

## Solution

1. Report how dbt exited: `killed by signal N` when `returncode < 0`, else `exit code N`.
2. Name failed nodes from progress lines, not only from the detail block dbt prints at the end:
   `^\d+ of \d+ (?:FAIL \d+|WARN \d+|ERROR(?: creating)?) (?:(?:sql \w+ model|test|seed file|snapshot|relation) )?(?P<node>[A-Za-z0-9_.]+)`,
   and strip the schema prefix so `validation_intermediate.int_x` and `int_x` are one node.
3. Match the summary with `^Done\.(?: [A-Z-]+=\d+)+$`; dbt 1.12 prints
   `Done. PASS=… WARN=… ERROR=… SKIP=… NO-OP=… REUSED=… TOTAL=…`.
4. On failure, log an allowlisted subset of stdout, one line each: progress lines, headings
   (`Encountered an error`, `Compilation|Database|Runtime|Parsing|Dependency Error in …` with the
   parenthesised path cut off), `Finished running`, `Completed with`, `Done.`, `Running with dbt=`,
   `Found N …`, `Concurrency:`. Never log an indented line: that is where statements, values,
   and compiled paths live. From stderr, log only the class name of the final exception.
5. Cap the log at about 80 lines (head and tail) and keep the sanitized message as the raised
   error.

## Verification

Unit tests over a fixture stdout: the message names the failed test and the errored model in
progress order with the summary; a three-line truncated output with `returncode=-9` reports the
signal and the last node started; a fixture with a fake statement, a fake value, and a fake path
never leaks any of them into the message or the diagnostic lines.

## Example

Production output after the change:

```
dbt: 191 of 225 FAIL 1 assert_duplicate_emails_are_both_published ... [FAIL 1 in 0.17s]
dbt: 195 of 225 SKIP relation validation_analytics.bridge_person_source_ids ... [SKIP]
dbt: Completed with 1 error, 0 partial successes, and 0 warnings:
dbt: Done. PASS=193 WARN=0 ERROR=1 SKIP=31 NO-OP=0 REUSED=0 TOTAL=225
```

That one line pointed at the identity model; the fix shipped in the next cycle.

## Notes

- A dbt failure named in the message does not end the search: the Python step after dbt (a
  coverage gate, a swap) can fail next, so wrap it with the same sanitized error reporting.
- A Prefect flow's retries rerun the whole build; three attempts of the same deterministic
  failure cost ten minutes, so read the first attempt's lines rather than waiting.
