# Policy

> Status: in force · 2026-11-05 · the plugin's behaviour and how changes to it are checked

## The plugin

**P1. morla never runs a command it wrote.** It writes the command into
`q:` or onto the `:` line; Enter is the operator's. *Why:* translations are
wrong often enough that each needs a look, even a glance at the explanation
(`tested/2026-11-05-1915-live.md`; ARCHITECTURE D1). *Checked by:*
`tests/e2e.sh` ("still in q:"), review.

**P2. The history file is only appended to.** A correction is a new line
(a mark), never an edit. *Why:* marks name runs by `id`, and the file is the
operator's record of what ran (ARCHITECTURE D10). *Checked by:* review;
`lua/morla/history.lua` opens the file only to append or read.

**P3. No dependencies beyond Neovim 0.10 and the `claude` CLI.** *Why:*
nothing to install or keep in step (ARCHITECTURE D7). *Checked by:* review.

## Changes

**P4. Unit and end-to-end tests pass before a PR.**
`nvim --headless --clean -l tests/run.lua && tests/e2e.sh`. *Why:* there is
no CI. *Checked by:* the PR's author.

**P5. A change to the prompt, the reply format or the default model is
checked by a live run against `claude -p`, reported in `md/tested/`.**
*Why:* the tests use a fake backend and cannot judge a translation.
*Checked by:* review.

**P6. A change to `SCHEMA.md` is named in its commit's first line and
leaves older history files readable.** *Why:* the operator's config and
history file are its readers (`SCHEMA.md` §3). *Checked by:* review;
`tests/run.lua` loads the fixture.

**P7. No tracked file names a private project.** The repo is public.
*Why:* the operator's other repos are not all public. *Checked by:* a scan
of tracked files against the operator's private-terms list before a push
(`LOCAL.md` says where it is).

---

<!-- pinned from repo-template md/governance/POLICY.md @ 0232674; refresh from the template, do not edit by hand -->
## About this file (repo-template `0232674`)

**What this file is for.** The rules in force. A policy is followed or
violated, and something checks it: a tool, a review, or nobody yet, which
each rule says. The rules are numbered and the numbers are never reused, so
other documents cite them (`P4`) and a retired rule leaves a gap that says
it was retired.

**Changed by:** a ruling by the operator.

**Belongs here:** a rule that binds anyone working in the repo, person or
agent; why it holds, in a sentence; what checks it; the doctrine it serves,
if `DOCTRINE.md` is in use.

**Does not:** a principle nothing enforces (`DOCTRINE.md`); a method
(`PROCEDURE.md`); a format (`SCHEMA.md`); a rule that applies to one tool
only (that tool's document in `../docs/`); the global rules every repo
shares (`~/.dotfiles/agents/AGENTS.md`), which this file cites and does not
repeat.

**Form.**

```
# Policy

> Status: in force · YYYY-MM-DD · <one line on scope>

## <group>

**P1. <the rule, as a sentence that can be broken>.** <one or two sentences
of detail>. *Why:* <reason>. *Checked by:* <tool | review | nothing yet>.
```

A rule whose check is "nothing yet" is still a rule; the gap is the thing
to close. When a rule is retired, its line becomes `**P3.** Retired
YYYY-MM-DD: <why>.`
