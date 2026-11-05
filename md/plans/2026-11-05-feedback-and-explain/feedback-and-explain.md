# Feedback in plain English, and a plain-English line beside each command

> Status: accepted · 2026-11-05 · from the operator's use case (thread of 5 Nov 2026)

The operator does not read or write Vimscript. Two things the first version
assumed do not hold for them: that a wrong translation gets corrected by
hand, and that the line is read before Enter. This plan lets them complain
in plain English ("didn't work, rerun") and tells them in plain English
what each command will do.

## Decisions

### D1. The reply is one JSON object: command, explanation, feedback flag

`{"command": "...", "explain": "...", "feedback": true|false}`. One call
gives the command, a short description for someone who cannot read
Vimscript, and whether the line was a complaint about the last command.
A reply that is not JSON is read the old way, as a bare command with no
explanation. Lost: a second call to explain (slower, and a second model
reading the command adds little when the same reply can say what it meant);
keyword matching for complaints ("didn't", "rerun"), which misses "no, only
the second one" and fires on "rerun the tests".

### D2. The model sees the last command that ran, and judges

Every request carries the last command run in this Neovim session: its
instruction, the command, and whether it failed and how. The model sets
`feedback` when the new line is about that command, and then answers the
original instruction, not the complaint. If the last command changed text
the wrong way, the new command starts with `undo`. Pressing the key on a
failed command's line becomes the same case ("That failed. Fix it."),
replacing the first version's separate fix path.

### D3. A complaint marks the last run wrong by appending, never rewriting

The history stays append-only (ARCHITECTURE §4). Each run gets an `id`; a
complaint appends a mark `{"marks": <id>, "ok": false, "note": "..."}`.
Reading the file applies marks, so a run the operator called wrong is never
sent as an example. The retry's record carries `retry_of` and the original
instruction, so the history pairs what was asked with what finally worked.

### D4. The explanation sits beside the line, before the flags

`deletes every line containing TODO` or `⚠ shell · opens htop in a terminal
split`. `:Morla` shows it as a message. It is the model's account of its
own command, so it can be wrong in the same way; the flags are computed
from the command and do not depend on it.

## Steps

1. Prompt and parse (D1, D2); context carries the last run.
2. History: `id`, marks, `retry_of`, `explain` (D3); `SCHEMA.md`.
3. In `q:` and `:Morla`: show the explanation, handle `feedback` (D2, D4).
4. Tests: unit and end to end.
5. A live run against `claude -p`, reported in `md/tested/`.
6. Decisions to `ARCHITECTURE.md`; README; this plan to `done`.
