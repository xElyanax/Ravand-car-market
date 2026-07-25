#!/bin/zsh
set -e

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

PORT=41828
echo "Starting Ravand release preview at http://127.0.0.1:${PORT}"
(sleep 1; open "http://127.0.0.1:${PORT}") &
exec python3 preview_server.py "${PORT}"
