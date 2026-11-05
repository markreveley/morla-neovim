# plans/

---

<!-- pinned from repo-template md/plans/README.md @ 0232674; refresh from the template, do not edit by hand -->
## About this folder (repo-template `0232674`)

What will be done, in what order, and what it waits on. A plan is the
bridge from an analysis's recommendations to the steps in `next-agents.md`.

**Belongs here:** a plan of work with its steps in order, the decisions it
rests on, and the questions it waits on; the reference material a plan
needs beside it.

**Does not:** findings (those are the analysis the plan links to), finished
work (delete the steps; git history holds them), the current next step
(that is `next-agents.md`, which links back to the plan it comes from).

**Names:** `YYYY-MM-DD-<slug>/<slug>.md`, the date being the day the plan
was written. The folder holds anything the plan carries with it.

**Form:** the first line after the title is a status line, updated when the
plan changes:

```
> Status: proposed · YYYY-MM-DD · from [<analysis>](../../analysis/...)
```

Status words: `proposed`, `accepted`, `in progress`, `done`, `dropped`.
Decisions are numbered (`D1`) so steps and other documents cite them;
outside the plan, cite them with its slug (`<plan-slug> D1`). A decision
adopted as design moves to `governance/ARCHITECTURE.md` under its next
number, and the plan links to it. A
question in a plan moves to `next-operator.md` when the step that waits on
it comes up.
