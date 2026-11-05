# governance/

---

<!-- pinned from repo-template md/governance/README.md @ 0232674; refresh from the template, do not edit by hand -->
## About this folder (repo-template `0232674`)

The documents that govern the repo. All five are always present: one the
repo has no use for holds only its title and its pinned block, and is
never deleted (repo-template README, R10 and R12).

- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`POLICY.md`](POLICY.md)
- [`SCHEMA.md`](SCHEMA.md)
- [`PROCEDURE.md`](PROCEDURE.md)
- [`DOCTRINE.md`](DOCTRINE.md)

How they relate:

- Doctrine says why; policy says what is required; procedure says how it
  is done; schema says what the data looks like; architecture says how the
  parts fit.
- A rule nobody checks and nothing enforces is doctrine, not policy.
- A policy cites the doctrine it serves.
- A procedure cites the policies it satisfies.
- An architecture decision cites both.

**Does not belong here:** a guide or a document about one piece of the
repo (`docs/`), a plan (`plans/`), an analysis (`analysis/`).
