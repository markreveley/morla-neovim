# morla-neovim

Plain English in Neovim's command-line window, turned into an Ex command in
place. Open `q:`, type what you want, press `<C-g>`, read the command that
replaces your words, press Enter. Nothing runs until you do.

```
:q:
delete every line containing TODO          <C-g>
g/TODO/d                                    morla

open a vertical split with a terminal in ~/dev/repos/x running htop
vertical new | lcd ~/dev/repos/x | terminal htop      ⚠ shell
```

- **In place.** The translation replaces the line in `q:`, so you can edit
  it like any other line before running it.
- **Context.** The request carries the file you came from, its filetype, the
  cursor line, your last visual selection, the buffer list and your recent
  `:` commands.
- **History.** Each translation that runs is appended to a JSON Lines file.
  The ones that ran without error go with later requests as examples, the
  same project and filetype first. `:MorlaHistory` picks one and puts it on
  the `:` line.
- **Fix on error.** If a translation fails, open `q:`, move to it, and press
  `<C-g>`: the request carries the error and asks for a fix.
- **Flags.** A command that runs the shell, writes or deletes files, touches
  many files or runs Lua gets a `⚠` beside it.

Requests go through `claude -p` (Claude Code's print mode) with Haiku, using
your existing Claude login; no API key. A translation takes 2 to 4 seconds.

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
| `q:`, normal or insert | `<C-g>` translates the line under the cursor |
| `:` line | `<C-g>` opens `q:` with the line and translates it there |
| `:Morla <instruction>` | translates and puts the command on the `:` line |
| `:MorlaHistory` | picks a past translation and puts it on the `:` line |

## What is where

| path | holds |
|---|---|
| `plugin/`, `lua/morla/` | the plugin; the parts are listed in [`ARCHITECTURE §2`](md/governance/ARCHITECTURE.md) |
| `tests/` | `run.lua` (unit) and `e2e.sh` (a headless Neovim driven through its socket, with a fake `claude`) |
| `AGENTS.md` | working rules for agents and people; `CLAUDE.md` imports it |
| `next-agents.md`, `next-operator.md` | where the last thread stopped |
| `md/` | every document about the repo; [`md/README.md`](md/README.md) lists the folders |

The layout follows [repo-template](https://github.com/markreveley/repo-template).

## License

MIT, in `LICENSE`.
