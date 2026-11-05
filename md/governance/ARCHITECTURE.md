# morla-neovim: architecture

> Status: built · 2026-11-05 · describes what is built (first version)

## 1. Thesis

morla turns a plain-English instruction into one Ex command line, in place,
in the window where Ex commands are already edited (`q:`), and never runs it:
the operator reads the line and presses Enter. Each translation that runs is
kept, and the ones that ran without error teach the next request.

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
   cursor line, last visual selection (up to 20 lines), the listed buffers,
   the last 20 `:` commands, the working directory.
3. `history.examples` picks up to 8 past translations that ran without
   error, the same project and filetype first.
4. If the line is the command that last failed, the request asks for a fix
   and carries the error and the original instruction.
5. `client.translate` runs `claude -p` with the request on stdin, off the
   main loop. A mark at the end of the line says it is working.
6. The reply replaces the line. A mark beside it shows `⚠` and the flags,
   or `morla`.
7. When `q:` closes or the `:` line is left, the `:` history number says
   whether a command ran. If it is the translation, or the operator's edit
   of it, a record is appended with `ok` taken from `v:errmsg` (D4).

## 4. Boundaries and invariants

- morla never runs a command. Enter is the operator's.
- The history file is only appended to.
- The model sees the cursor line and the last selection, not whole files.
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

The operator's Claude login, no API key. Measured on 5 Nov 2026 with
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
without error. JSON Lines, not SQLite: Neovim has no SQLite without a
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
