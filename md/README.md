# md/

---

<!-- pinned from repo-template md/README.md @ 0232674; refresh from the template, do not edit by hand -->
## About this folder (repo-template `0232674`)

The repo's documents about itself and its work. The seven folders below
exist in every repo, each with its README, whether or not anything is in it
yet (repo-template README, R5 and R6).

| folder | holds | file name |
|---|---|---|
| [`governance/`](governance/README.md) | the documents that govern the repo | the five fixed names |
| [`docs/`](docs/README.md) | how to use and work on what the repo holds | `<topic>.md` |
| [`plans/`](plans/README.md) | what will be done, in order, and what it waits on | `YYYY-MM-DD-<slug>/<slug>.md` |
| [`analysis/`](analysis/README.md) | dated findings and recommendations | `YYYY-MM-DD-<slug>/<slug>.md` |
| [`issues/`](issues/README.md) | dated findings against something | `YYYY-MM-DD-<slug>.md` |
| [`audits/`](audits/README.md) | a dated reading of the repo against what it claims to be | `YYYY-MM-DD-<slug>.md` |
| [`tested/`](tested/README.md) | one report per run of something only a run can check | `YYYY-MM-DD-HHMM-<kind>.md` |

Each folder's README says what belongs there and what does not. A repo may
add a folder here (`glossary/` exists elsewhere) if it gives it a README on the same pattern and a row in this table.

Where a document goes when it could go in two places:

- It says what to do next: a plan. It says what was found: an analysis. A
  document that does both is an analysis whose recommendations become a
  plan's steps, linked both ways.
- It records a problem in something: an issue. Something was learned from
  fixing it: `docs/`.
- It is a rule, a format, a method, a design or a principle that the repo
  lives by: governance. One that applies to one piece of the repo only:
  `docs/`.
- No document here holds an open question. A question that blocks the next
  step goes in `next-operator.md`; any other goes in a plan linked from it.
