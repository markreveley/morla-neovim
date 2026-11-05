# Policy

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
