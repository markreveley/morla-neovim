#!/usr/bin/env bash
# End to end: a headless Neovim driven through its socket, with
# tests/fake-claude.sh in place of `claude -p`. Run: tests/e2e.sh
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
MORLA_TEST_DIR=$(mktemp -d)
export MORLA_TEST_DIR
d=$MORLA_TEST_DIR sock=$MORLA_TEST_DIR/sock fails=0
trap 'nvim --server "$sock" --remote-send "<C-\\><C-n>:qa!<CR>" >/dev/null 2>&1 || true; rm -rf "$d"' EXIT

printf '# Notes\nTODO one\nkeep\nTODO two\n' > "$d/notes.md"
nvim --headless --clean --listen "$sock" \
  -c "set rtp^=$repo" -c 'runtime plugin/morla.lua' \
  -c "lua require('morla').setup({ cmd = { 'bash', '$repo/tests/fake-claude.sh' }, history_file = '$d/history.jsonl' })" \
  "$d/notes.md" >/dev/null 2>&1 &
for _ in $(seq 50); do [ -S "$sock" ] && break; sleep 0.1; done

has() { if grep -q -- "$1" "$2"; then echo 0; else echo 1; fi; }
hasx() { if grep -qx -- "$1" "$2"; then echo 0; else echo 1; fi; }
send() { nvim --server "$sock" --remote-send "$1"; }
ev() { nvim --server "$sock" --remote-expr "$1"; }
check() { # name, got, want
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: want [$3] got [$2]"; fails=$((fails + 1)); fi
}

vt() { ev "get(get(nvim_buf_get_extmarks(0, -1, [line('.')-1, 0], [line('.')-1, -1], {'details': v:true}), 0, [0, 0, 0, {'virt_text': [['']]}])[3].virt_text[0], 0)"; }
last() { ev "json_decode(readfile('$d/history.jsonl')[-1]).$1"; }

# 1. q:, type an instruction, <C-g>: the line becomes the command, in place,
#    with the explanation beside it.
echo '{"command": "g/TODO/d", "explain": "deletes every line with TODO", "feedback": false}' > "$d/reply.txt"
send 'q:idelete the TODO lines<C-g>'
sleep 1
check 'q: line translated in place' "$(ev "getline('.')")" 'g/TODO/d'
check 'explanation beside it' "$(vt)" '  deletes every line with TODO'
check 'still in q:' "$(ev 'getcmdwintype()')" ':'
check 'request carries the instruction' "$(has 'Instruction: delete the TODO lines' "$d/request.txt")" 0
check 'request carries the origin file' "$(has 'Current file: .*notes.md (filetype markdown' "$d/request.txt")" 0
check 'system prompt passed' "$(hasx '--system-prompt' "$d/args.txt")" 0
check 'no last run before the first' "$(has 'Last command run' "$d/request.txt")" 1

# 2. Enter runs it; the history records it as ok, with an id and the explanation.
send '<Esc><CR>'
sleep 0.5
check 'command ran' "$(ev "join(getline(1, '\$'), ',')")" '# Notes,keep'
check 'history records it' "$(last ok)" 'true'
check 'record keeps the explanation' "$(last explain)" 'deletes every line with TODO'
check 'record says the buffer changed' "$(last changed)" 'true'
first_id=$(last id)

# 3. From the : line: <C-g> hands the line to q: and translates there. A
#    plain reply (not JSON) still works.
echo '1d' > "$d/reply.txt"
send ':delete the first line<C-g>'
sleep 1
check ': line goes to q: and translates' "$(ev "getline('.')")" '1d'
send '<CR>'
sleep 0.5
check 'second command ran' "$(ev "join(getline(1, '\$'), ',')")" 'keep'
check 'past success sent as an example' "$(has 'Command: g/TODO/d' "$d/request.txt")" 0
check 'last run sent with the request' "$(has 'Result: ran without error' "$d/request.txt")" 0

# 4. A complaint: the model flags feedback; the last run is marked wrong and
#    the retry answers the original instruction.
echo '{"command": "undo", "explain": "undoes the last change", "feedback": true}' > "$d/reply.txt"
send "q:ithat deleted the wrong line<C-g>"
sleep 1
check 'retry in place' "$(ev "getline('.')")" 'undo'
send '<Esc><CR>'
sleep 0.5
check 'retry ran (undo brings the line back)' "$(ev "join(getline(1, '\$'), ',')")" '# Notes,keep'
check 'retry keeps the original instruction' "$(last instruction)" 'delete the first line'
second_id=$(ev "json_decode(readfile('$d/history.jsonl')[-3]).id")
check 'retry points at the run it replaces' "$(last retry_of)" "$second_id"
check 'the replaced run is marked wrong' "$(ev "json_decode(readfile('$d/history.jsonl')[-2]).marks")" "$second_id"
check 'the first run is not marked' "$(ev "len(filter(readfile('$d/history.jsonl'), 'v:val =~ \"\\\"marks\\\":\\\"$first_id\"'))")" '0'

# 5. A command that fails is recorded; <C-g> on its line asks for a fix.
echo '{"command": "nosuchcommand", "explain": "breaks", "feedback": false}' > "$d/reply.txt"
send 'q:ibreak something<C-g>'
sleep 1
send '<Esc><CR>'
sleep 0.5
check 'failure recorded' "$(last ok)" 'false'
echo '{"command": "echo \"fixed\"", "explain": "prints fixed", "feedback": true}' > "$d/reply.txt"
send 'q:k<C-g>'
sleep 1
check 'fix request says so' "$(has 'Instruction: That failed. Fix it.' "$d/request.txt")" 0
check 'fix request carries the error' "$(has 'Result: failed: E492' "$d/request.txt")" 0
check 'a failed run changed nothing' "$(last changed)" 'false'
check 'fixed command in place' "$(ev "getline('.')")" 'echo "fixed"'
check 'a failed run is not marked again' "$(ev "json_decode(readfile('$d/history.jsonl')[-1]).command")" 'nosuchcommand'

# 6. Risky commands get a flag ahead of the explanation.
echo '{"command": "%!sort", "explain": "sorts the file", "feedback": false}' > "$d/reply.txt"
send '<Esc>Gosort the file<C-g>'
sleep 1
check 'risk flag shown' "$(vt)" '  ⚠ shell · sorts the file'

echo "e2e: $fails failed"
[ "$fails" -eq 0 ]
