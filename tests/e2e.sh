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

send() { nvim --server "$sock" --remote-send "$1"; }
ev() { nvim --server "$sock" --remote-expr "$1"; }
check() { # name, got, want
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: want [$3] got [$2]"; fails=$((fails + 1)); fi
}

# 1. q:, type an instruction, <C-g>: the line becomes the command, in place.
echo 'g/TODO/d' > "$d/reply.txt"
send 'q:idelete the TODO lines<C-g>'
sleep 1
check 'q: line translated in place' "$(ev "getline('.')")" 'g/TODO/d'
check 'still in q:' "$(ev 'getcmdwintype()')" ':'
grep -q 'Instruction: delete the TODO lines' "$d/request.txt"; check 'request carries the instruction' $? 0
grep -q 'Current file: .*notes.md (filetype markdown' "$d/request.txt"; check 'request carries the origin file' $? 0
grep -qx -- '--system-prompt' "$d/args.txt"; check 'system prompt passed' $? 0

# 2. Enter runs it; the history records it as ok.
send '<Esc><CR>'
sleep 0.5
check 'command ran' "$(ev "join(getline(1, '\$'), ',')")" '# Notes,keep'
check 'history records it' "$(ev "json_decode(readfile('$d/history.jsonl')[-1]).ok")" 'true'

# 3. From the : line: <C-g> hands the line to q: and translates there.
echo '1d' > "$d/reply.txt"
send ':delete the first line<C-g>'
sleep 1
check ': line goes to q: and translates' "$(ev "getline('.')")" '1d'
send '<CR>'
sleep 0.5
check 'second command ran' "$(ev "join(getline(1, '\$'), ',')")" 'keep'
grep -q 'Command: g/TODO/d' "$d/request.txt"; check 'past success sent as an example' $? 0

# 4. A command that fails is recorded, and <C-g> on it asks for a fix.
echo 'nosuchcommand' > "$d/reply.txt"
send 'q:ibreak something<C-g>'
sleep 1
send '<Esc><CR>'
sleep 0.5
check 'failure recorded' "$(ev "json_decode(readfile('$d/history.jsonl')[-1]).ok")" 'false'
echo 'echo "fixed"' > "$d/reply.txt"
send 'q:k<C-g>'
sleep 1
grep -q 'This command failed: nosuchcommand' "$d/request.txt"; check 'fix request carries the failure' $? 0
grep -q 'Instruction: break something' "$d/request.txt"; check 'fix request keeps the instruction' $? 0
check 'fixed command in place' "$(ev "getline('.')")" 'echo "fixed"'

# 5. Risky commands get a flag beside the line.
echo '%!sort' > "$d/reply.txt"
send '<Esc>Gosort the file<C-g>'
sleep 1
check 'risk flag shown' "$(ev "nvim_buf_get_extmarks(0, -1, [line('.')-1, 0], [line('.')-1, -1], {'details': v:true})[0][3].virt_text[0][0]")" '  ⚠ shell'

echo "e2e: $fails failed"
[ "$fails" -eq 0 ]
