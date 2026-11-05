# tested/

---

<!-- pinned from repo-template md/tested/README.md @ 0232674; refresh from the template, do not edit by hand -->
## About this folder (repo-template `0232674`)

One report per run of something that can only be checked by running it: an
install, a load into a live system, a manual test pass. A report is opened
by the tool that starts the run, filled in while it is checked, and never
edited once the next run begins; corrections go in the next report or in
`../docs/`.

**Belongs here:** what was run, at which commit, what changed since the
last run, a results table with exact error text, findings, and what was not
tested.

**Does not:** a confirmed fact about the system under test once it is
settled (`../docs/`), the test code (the repo's tests folder), automated
test output (CI keeps it).

**Names:** `YYYY-MM-DD-HHMM-<kind>.md`, the time distinguishing runs on one
day.

**Form:** header (commit, what was loaded, when), "Changed since last run",
"Results" table, "Findings", "Not tested yet".
