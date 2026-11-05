# Schema

> Status: in force · 2026-11-05 · the history file and the options

## 1. The history file

`stdpath('data')/morla/history.jsonl` (option `history_file`): one JSON
object per line, never rewritten. A line is a **run**, appended when a
translation runs (ARCHITECTURE D4), or a **mark**, appended when the
operator says a run was wrong (ARCHITECTURE D10). Example,
`tests/fixtures/history.jsonl`, loaded by `tests/run.lua`: a run, a failed
run, a mark on the first run, and the retry that replaced it.

```json
{"id":"20261105T180211-a1-1","ts":"2026-11-05T18:02:11Z","cwd":"~/dev/repos/notes","filetype":"markdown","instruction":"delete every line containing TODO","generated":"g/TODO.*/d","command":"g/TODO.*/d","explain":"deletes every line with TODO","ok":true}
{"id":"20261105T180440-b2-2","ts":"2026-11-05T18:04:40Z","cwd":"~/dev/repos/notes","filetype":"markdown","instruction":"sort the selected lines","generated":"'<,'>sort u","command":"'<,'>sort","explain":"sorts the selection, dropping duplicates","ok":false,"error":"E20: Mark not set"}
{"ts":"2026-11-05T18:05:02Z","marks":"20261105T180211-a1-1","ok":false,"note":"deleted the headings too"}
{"id":"20261105T180519-c3-3","ts":"2026-11-05T18:05:19Z","cwd":"~/dev/repos/notes","filetype":"markdown","instruction":"delete every line containing TODO","generated":"undo | g/^- TODO/d","command":"undo | g/^- TODO/d","explain":"undoes that, then deletes only TODO list items","retry_of":"20261105T180211-a1-1","ok":true}
```

A run:

| field | type | meaning |
|---|---|---|
| `id` | string | unique; what a mark names. Absent in runs the first version wrote |
| `ts` | string | when it ran, UTC, ISO 8601 |
| `cwd` | string | Neovim's working directory, `~` for home |
| `filetype` | string | filetype of the window `q:` was opened from; `""` for none |
| `instruction` | string | what the operator asked for; for a retry, the original instruction, not the complaint |
| `generated` | string | the model's command |
| `command` | string | what ran: `generated`, or the operator's edit of it |
| `explain` | string | the model's plain-English account of the command; absent when the reply had none |
| `ok` | boolean | `v:errmsg` was empty after it ran |
| `error` | string | `v:errmsg`, present only when `ok` is false |
| `changed` | boolean | the origin buffer's `changedtick` moved; absent when the buffer was gone |
| `retry_of` | string | the `id` of the run this one replaced after a complaint |

A mark:

| field | type | meaning |
|---|---|---|
| `ts` | string | when the operator complained |
| `marks` | string | the `id` of the run it marks |
| `ok` | boolean | always `false` |
| `note` | string | the operator's words |

On reading, a mark sets its run's `ok` to false and adds its `note`. A line
that is not JSON, or is neither a run (with `instruction` and `command`)
nor a mark, is skipped.

## 2. Options

`require('morla').setup(opts)`; every key is optional. Defaults in
`lua/morla/config.lua`.

| key | default | meaning |
|---|---|---|
| `cmd` | `claude -p --model sonnet --tools "" --setting-sources "" …` | the model call, as a list; morla appends `--system-prompt <text>`. Replaces the default whole |
| `timeout` | `60000` | ms before the call is stopped |
| `stay` | `true` | after a command from `q:` runs, open `q:` again, if back in a normal file buffer |
| `key` | `"<C-g>"` | translate in `q:`; on the `:` line, hand the line to `q:`. `false` for no key |
| `history_file` | see §1 | |
| `examples` | `8` | past runs sent with a request |
| `recent_commands` | `20` | `:` history lines sent |
| `selection_lines` | `20` | lines of the last visual selection sent |
| `buffer_lines` | `300` | lines of the buffer sent, numbered: all of it if it fits, else a window around the cursor. `0` sends none |

## 3. Readers

The operator's Neovim config reads §2, the commands `:Morla` and
`:MorlaHistory`, and `require('morla').open()` (no arguments: open `q:`
ready to type, from the last file window when in a side panel); morla itself reads §1. A change to either is a breaking
change and is named in the commit's first line.

---

<!-- pinned from repo-template md/governance/SCHEMA.md @ 0232674; refresh from the template, do not edit by hand -->
## About this file (repo-template `0232674`)

**What this file is for.** The formats and contracts of the data the repo
holds or emits: file layouts, frontmatter fields, identifiers, JSON shapes,
CLI arguments and exit codes, anything another program reads. Changing it is
a breaking change for whatever reads the data, so the file says who that is.

**Changed by:** a breaking change, announced to whatever reads the data.

**Belongs here:** each format with an example that validates; every field
with whether it is required and what values it takes; the identifier rules;
the parsed shape a reader gets; the error and problem codes; the readers
the contract binds (downstream repos, CI, a viewer).

**Does not:** how to write the data by hand (`../docs/`); why the format is
as it is (`ARCHITECTURE.md`, decisions); rules about the data's content
rather than its form (`POLICY.md`).

**Form.** One section per format, each opening with a complete example
taken from a file that exists in the repo and is checked by its tests, then
the fields as a table. A "Readers" section at the end names what breaks
when the schema changes and how a change is announced.
