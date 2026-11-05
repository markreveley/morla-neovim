# morla-neovim

Plain English in Neovim's command-line window, turned into an Ex command in
place. Open `q:`, type what you want, press `<C-g>`. The command replaces
your words, with a plain-English account of what it does beside it. Press
Enter to run it. Nothing runs until you do. You don't need to read Vimscript.

```
q:
delete the second TODO line                    <C-g>
7d                                              deletes line 7, the second TODO

no, I meant the first one                      <C-g>
undo | 5d                                       undoes that, then deletes line 5

open a vertical split with a terminal in ~/dev/repos/x running htop
vertical new | lcd ~/dev/repos/x | terminal htop    ⚠ shell · opens htop in a split
```

- **In place.** The command replaces the line in `q:`; Enter runs it.
- **Explained.** Beside each command, a few words of plain English saying
  what it does. The words come from the model and can be wrong along with
  the command; the `⚠` flags do not depend on the model.
- **Say what went wrong.** If a command did the wrong thing, type what went
  wrong ("didn't work, rerun", "no, only the second one") and press `<C-g>`.
  The model sees the last command and whether it changed anything, and
  writes a new one, starting with `undo` when the last one changed text.
  The wrong one is marked in the history so it is never used as an example.
- **Errors.** If a command fails, open `q:`, move to it, and press `<C-g>`:
  the request carries the error and asks for a fix.
- **Context.** The request carries the file you came from with its line
  numbers (up to 300 lines around the cursor), your last visual selection,
  the buffer list and your recent `:` commands.
- **History.** Each command that runs is appended to a JSON Lines file. The
  ones you kept go with later requests as examples, the same project and
  filetype first. `:MorlaHistory` picks one and puts it on the `:` line.
- **Flags.** A command that runs the shell, writes or deletes files, touches
  many files or runs Lua gets a `⚠`.

Requests go through `claude -p` (Claude Code's print mode) with Sonnet,
using your existing Claude login; no API key. A translation takes 3 to 5
seconds.

## Install

Neovim 0.10 or later, and `claude` on your `PATH`. With lazy.nvim:

```lua
{ 'markreveley/morla-neovim', opts = {} }
```

Without a plugin manager, add this folder to `runtimepath`. Options
(`setup(opts)`) and the history format are in
[`md/governance/SCHEMA.md`](md/governance/SCHEMA.md). `:checkhealth morla`
checks the setup.

## Use

| where | what |
|---|---|
| `q:`, normal or insert | `<C-g>` translates the line under the cursor, or acts on a complaint about the last command |
| `:` line | `<C-g>` opens `q:` with the line and translates it there |
| `:Morla <instruction>` | translates and puts the command on the `:` line, the explanation as a message |
| `:MorlaHistory` | picks a past command and puts it on the `:` line |

## What is where

| path | holds |
|---|---|
| `plugin/`, `lua/morla/` | the plugin; the parts are listed in [`ARCHITECTURE §2`](md/governance/ARCHITECTURE.md) |
| `tests/` | `run.lua` (unit) and `e2e.sh` (a headless Neovim driven through its socket, with a fake `claude`) |
| `AGENTS.md` | working rules for agents and people; `CLAUDE.md` imports it |
| `next-agents.md`, `next-operator.md` | where the last thread stopped |
| `md/governance/` | `ARCHITECTURE.md` (design and decisions), `POLICY.md` (rules), `SCHEMA.md` (options, history file) |
| `md/plans/`, `md/tested/` | plans of work; reports of live runs against `claude -p` |
| `md/` | every document about the repo; [`md/README.md`](md/README.md) lists the folders |

The layout follows [repo-template](https://github.com/markreveley/repo-template).

## License

MIT, in `LICENSE`.
