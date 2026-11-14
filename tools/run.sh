#!/bin/bash
# run.sh: start the game, logging to logs/run-<time>.log.
#   tools/run.sh [extra args]        DARKSOULS2_TRACE=1 tools/run.sh   (verbose HLE)
set -uo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$here/tools/local.env" ] && . "$here/tools/local.env"
: "${DARKSOULS2_GAME_DIR:?set DARKSOULS2_GAME_DIR to the folder with Game/}"
bin="$here/out/build/release/darksouls2"
[ -x "$bin" ] || { echo "no binary: $bin (build first)"; exit 1; }
mkdir -p "$here/logs"
log="$here/logs/run-$(date +%H%M%S).log"
echo "darksouls2: logging to $log"
"$bin" --game-dir "$DARKSOULS2_GAME_DIR" "$@" 2>&1 | tee "$log"
