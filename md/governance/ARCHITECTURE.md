# morla-neovim: architecture

> Status: built · 2026-11-05 · describes what is built (to D14)

## 1. Thesis

morla turns a plain-English instruction into one Ex command line, in place,
in the window where Ex commands are already edited (`q:`), and never runs it:
the operator, who need not read Vimscript, sees a plain-English account
beside it and presses Enter. If it did the wrong thing they say so in plain
English and get another try. Each translation that runs is kept, and the
ones the operator kept teach the next request.

## 2. Parts

| file | does |
|---|---|
| `plugin/morla.lua` | defines `:Morla` and `:MorlaHistory`; applies defaults if `setup()` has not run |
| `lua/morla/init.lua` | the key in `q:` and on the `:` line, the in-place edit, the record of what ran, the history picker |
| `lua/morla/context.lua` | reads the editor state sent with a request (§3) and renders it as text |
| `lua/morla/prompt.lua` | the system prompt, the request text, the reading of the reply |
| `lua/morla/client.lua` | one `claude -p` call per request (D2) |
| `lua/morla/history.lua` | appends to, reads and ranks the history file (`SCHEMA.md`) |
| `lua/morla/risk.lua` | flags a command that runs the shell, writes or deletes files, touches many files or runs Lua (D5) |
| `lua/morla/config.lua` | defaults and the merged options |
| `lua/morla/health.lua` | `:checkhealth morla` |

## 3. Flow

1. The operator types an instruction on a line in `q:` and presses the key
   (`<C-g>`). On the `:` line the same key opens `q:` with the line (the
   `'cedit'` key) and continues there (D3).
2. `context.gather` reads the window `q:` was opened from: file, filetype,
   cursor position, the buffer's lines with their numbers (up to 300,
   around the cursor; D12), the last visual selection (up to 20 lines), the
   listed buffers, the last 20 `:` commands, the working directory.
3. `history.examples` picks up to 8 past runs the operator kept (no error,
   not marked wrong), the same project and filetype first.
4. The request carries the last run of this session: its instruction,
   command, and whether it failed, changed the buffer, or changed nothing
   (D9). A line that is the command that just failed becomes "That failed.
   Fix it."
5. `client.translate` runs `claude -p` with the request on stdin, off the
   main loop. A mark at the end of the line says it is working.
6. The reply is JSON: the command, a plain-English explanation, and whether
   the line was about the last run (D8). The command replaces the line; the
   mark beside it shows `⚠` and the flags, then the explanation (D11). If
   the line was about the last run, that run is marked wrong and the new
   command answers its instruction (D10).
7. When `q:` closes or the `:` line is left, the `:` history number says
   whether a command ran. If it is the translation, or the operator's edit
   of it, a record is appended with `ok` from `v:errmsg` and `changed` from
   the origin buffer's `changedtick` (D4). If the run changed the last
   search pattern, `v:hlsearch` is cleared; with `stay`, `q:` opens again
   (D13).
8. Each time `q:` opens, lines that match a past run show its instruction
   beside them (D14).

## 4. Boundaries and invariants

- morla never runs a command. Enter is the operator's.
- The history file is only appended to.
- The model sees the buffer's lines (up to 300 around the cursor), never
  other files' contents (D12).
- The model call reads no CLAUDE.md, settings, hooks or MCP servers, has no
  tools, and keeps no session (D2).
- No dependencies beyond Neovim 0.10 and the `claude` CLI (D7).

## 5. Decisions

### D1. Translate in place in `q:`; never run

The command-line window is a buffer of past commands that Enter runs, so
writing the translation into it gives review, editing and running for free,
next to the history. Lost: a floating input window (remember.nvim's way),
which shows commands but leaves copying them to the operator; running at
once (genie.nvim's way), which removes the review, and a one-shot
translation is wrong often enough to need one.

### D2. `claude -p` with settings, tools and MCP off, in a folder of its own

The operator's Claude login, no API key. Sonnet by default: in the live run
of 5 Nov 2026 (`../tested/2026-11-05-1915-live.md`) Haiku misnumbered lines
after an undo and read "select" as "move", at the same speed (3 to 5 s).
Measured the same day with
Haiku: about 1.7 s a call with `--setting-sources ""`, 3.4 s without, and
without it the operator's global CLAUDE.md reached the model. `--tools ""`
because a translation needs none; the cache folder as working directory so
no project CLAUDE.md is found. Lost: calling the API with `curl`, which
needs a key in the environment. `--bare` would also skip CLAUDE.md but
accepts only API-key auth.

### D3. The `:` line hands its text to `q:`

A model call takes seconds. On the `:` line it would block the editor, since
the line cannot be edited from a callback; in `q:` it runs in the
background and the result lands in a buffer. The key returns the
`'cedit'` key and sets a flag that `CmdwinEnter` reads.

### D4. Record only what ran, matched through the `:` history

A translation the operator discards teaches nothing. When `q:` closes or the
`:` line is left, the history number is noted and `v:errmsg` cleared; on the
next tick, a higher number whose entry is the translation (or the line as
the operator edited it) is a run, and an empty `v:errmsg` means it ran
without error. `changed` compares the origin buffer's `changedtick` across
the same moment, because a command with no error can still do nothing.
JSON Lines, not SQLite: Neovim has no SQLite without a
dependency, and the file stays readable and greppable.

### D5. Flags warn; nothing is blocked

The operator reads every line before Enter; a flag points at the lines that
need it most. The reading is approximate (split on `|`, match Ex command
names and their abbreviations, look for `system(` and the like).

### D6. Written here, not adopted

dtnewman/remember.nvim does the translation in a floating window, from two
commits seven months old. The core is a prompt, a call and a buffer edit;
what this plugin is for (in place in `q:`, history, retry on error) it does
not have, and a plugin runs with the operator's permissions, so reading it
fully costs about what writing this did.

### D7. No dependencies

`vim.system` for the call, `vim.json` for the file, `vim.ui.select` for the
picker (telescope or fzf-lua take it over when installed).


### D8. The reply is one JSON object: command, explanation, feedback flag

`{"command": "...", "explain": "...", "feedback": true|false}`. One call
gives the command, a short account for someone who cannot read Vimscript,
and whether the line was about the last run. A reply that is not JSON is
read as a bare command with no explanation. Lost: a second call to explain
(slower, and the same reply can say what it meant); keyword matching for
complaints ("didn't", "rerun"), which misses "no, only the second one" and
fires on "rerun the tests". From
[feedback-and-explain D1](../plans/2026-11-05-feedback-and-explain/feedback-and-explain.md).

### D9. The model sees the last run and judges whether the line is about it

Every request carries the last run of this Neovim session (instruction,
command, failed or not, changed the buffer or not). When the line is about
it, the model answers the original instruction, and starts with `undo` if
the last command changed text the wrong way. `<C-g>` on a failed command's
line is the same case, sent as "That failed. Fix it." From
feedback-and-explain D2.

### D10. A complaint marks the last run wrong by appending

The history stays append-only (§4). Each run has an `id`; a complaint
appends a mark naming it (`SCHEMA.md` §1), and reading the file applies the
marks, so a run the operator called wrong is never sent as an example. The
retry records `retry_of` and the original instruction, pairing what was
asked with what finally worked. A run that already failed is not marked
again. From feedback-and-explain D3.

### D11. The explanation sits beside the line, after the flags

`⚠ shell · opens htop in a terminal split`. `:Morla` shows the same text as
a message. The explanation is the model's account of its own command and
can be wrong with it; the flags are computed from the command and do not
depend on the model. From feedback-and-explain D4.

### D12. The buffer's lines go with each request, numbered

Up to 300 lines (`buffer_lines`): all of a shorter buffer, else a window
around the cursor. Without them the model guessed at text it could not see
(`Date:` for `**Date:**`) and wrote cursor-relative searches (`0/TODO/`,
which searches from the cursor, not the top); with them it addresses lines
by number (`7d`). Measured in `../tested/2026-11-05-1915-live.md`. This
replaces the first version's rule that only the cursor line and the
selection were sent: the lines go to the same Claude the operator already
uses, from a file open in their own editor. Lost: sending only the cursor
line, which kept requests small and failed on most structural edits. From
feedback-and-explain D5.


### D13. After a run from `q:`, `q:` opens again

The operator works in `q:`: run, look, say what went wrong, run again.
Reopening saves the `q:` keystroke each time, and puts the run's line, with
its note (D14), in front of them for a complaint. Only when the run leaves
them in normal mode in a normal file buffer, so a command that opens a
terminal is not covered by `q:`. `stay = false` turns it off. From the
operator's first use (`../tested/2026-11-05-2010-live.md`).

### D14. Past commands carry their instruction in `q:`

`q:` holds only what ran, so a translation's English was gone once it ran.
The history file has both; on `CmdwinEnter` each line that matches a run's
command gets the instruction beside it, `✗` when the run failed or was
marked wrong. The latest run of a command wins. Lost: adding the
instruction to the `:` history as its own line, which Enter would run as a
command.

Also from that use: when a reply is not JSON, the bare-command reading
(D8) refuses a line that reads as English, so a model's explanation of why
it cannot answer is never run as a command.

---

<!-- pinned from repo-template md/governance/ARCHITECTURE.md @ 0232674; refresh from the template, do not edit by hand -->
## About this file (repo-template `0232674`)

**What this file is for.** How the thing is built: the parts, what flows
between them, where the boundaries are, and the decisions that shaped it
with their reasons. A reader who is about to change how the parts fit reads
this first. It describes what is built; where it describes a target instead,
the status line says so and names what gates the build.

**Changed by:** a design decision.

**Belongs here:** the parts and their responsibilities; the data and
control flow between them; the interfaces at the boundaries; the invariants
the design keeps; each design decision with the alternatives considered and
why they lost; the milestones, if the architecture is being built in
stages.

**Does not:** how to use the thing (`../docs/`), the file formats
(`SCHEMA.md`), the rules of conduct (`POLICY.md`), the order of work
(`../plans/`).

**Form.**

```
# <name>: architecture

> Status: <draft vN | built> · YYYY-MM-DD · <describes what is built | the target, gated by ...>

## 1. Thesis
<one paragraph: what the thing is, in a sentence a reader can test the rest against>

## 2. Parts
## 3. Flow
## 4. Boundaries and invariants
## 5. Decisions
### D1. <decision>
<the choice, the alternatives, why>
```

Sections and decisions are numbered so other documents cite them
(`ARCHITECTURE §4`, `ARCHITECTURE D3`). A plan's decision, once accepted
and built, moves here under the next number.
