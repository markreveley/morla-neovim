# Schema

> Status: in force · 2026-11-05 · the history file and the options

## 1. The history file

`stdpath('data')/morla/history.jsonl` (option `history_file`): one JSON
object per line, appended when a translation runs (ARCHITECTURE D4), never
rewritten. Example, `tests/fixtures/history.jsonl`, loaded by
`tests/run.lua`:

```json
{"ts":"2026-11-05T18:02:11Z","cwd":"~/dev/repos/notes","filetype":"markdown","instruction":"delete every line containing TODO","generated":"g/TODO/d","command":"g/TODO/d","ok":true}
{"ts":"2026-11-05T18:04:40Z","cwd":"~/dev/repos/notes","filetype":"markdown","instruction":"sort the selected lines","generated":"'<,'>sort u","command":"'<,'>sort","ok":false,"error":"E20: Mark not set"}
```

| field | type | meaning |
|---|---|---|
| `ts` | string | when it ran, UTC, ISO 8601 |
| `cwd` | string | Neovim's working directory, `~` for home |
| `filetype` | string | filetype of the window `q:` was opened from; `""` for none |
| `instruction` | string | what the operator asked for |
| `generated` | string | the model's command |
| `command` | string | what ran: `generated`, or the operator's edit of it |
| `ok` | boolean | `v:errmsg` was empty after it ran |
| `error` | string | `v:errmsg`, present only when `ok` is false |

A line that is not JSON, or lacks `instruction` or `command`, is skipped on
reading.

## 2. Options

`require('morla').setup(opts)`; every key is optional. Defaults in
`lua/morla/config.lua`.

| key | default | meaning |
|---|---|---|
| `cmd` | `claude -p --model haiku --tools "" --setting-sources "" …` | the model call, as a list; morla appends `--system-prompt <text>`. Replaces the default whole |
| `timeout` | `60000` | ms before the call is stopped |
| `key` | `"<C-g>"` | translate in `q:`; on the `:` line, hand the line to `q:`. `false` for no key |
| `history_file` | see §1 | |
| `examples` | `8` | past translations sent with a request |
| `recent_commands` | `20` | `:` history lines sent |
| `selection_lines` | `20` | lines of the last visual selection sent |

## 3. Readers

The operator's Neovim config reads §2 and the commands `:Morla` and
`:MorlaHistory`; morla itself reads §1. A change to either is a breaking
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
