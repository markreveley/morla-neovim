#!/usr/bin/env bash
# Stands in for `claude -p` in tests/e2e.sh: saves the request and its
# arguments, replies with the contents of $MORLA_TEST_DIR/reply.txt.
set -eu
cat > "$MORLA_TEST_DIR/request.txt"
printf '%s\n' "$@" > "$MORLA_TEST_DIR/args.txt"
cat "$MORLA_TEST_DIR/reply.txt"
