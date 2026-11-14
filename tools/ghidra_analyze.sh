#!/bin/sh
# ghidra_analyze.sh: Ghidra's auto-analysis of the game's modules, once, into
# the projects in ghidra/ that ghidra_export.sh reads.
#   usage: tools/ghidra_analyze.sh [darksouls2 fmodex fmod_event]
set -e
R=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$R/tools/local.env" ] && . "$R/tools/local.env"
: "${DARKSOULS2_GAME_DIR:?set DARKSOULS2_GAME_DIR to the folder with Game/}"
H=/opt/homebrew/opt/ghidra/libexec/support/analyzeHeadless
export GHIDRA_HEADLESS_MAXMEM=${GHIDRA_HEADLESS_MAXMEM:-24G}

analyze_one() {
  project=$1 file=$2 mod=$3
  mkdir -p "$R/ghidra" "$R/logs"
  echo "== analyze $mod $(date +%T)"
  "$H" "$R/ghidra" "$project" -import "$file" -overwrite \
    -log "$R/logs/ghidra-analyze-$mod.log" > "$R/logs/ghidra-analyze-$mod.out" 2>&1
  echo "rc=$? $(grep -h -E "Total Time|REPORT: Analysis" "$R/logs/ghidra-analyze-$mod.out" | tr -s ' ' | tr "\n" " ")"
}

[ $# -eq 0 ] && set -- darksouls2 fmodex fmod_event
for m in "$@"; do
  case $m in
    darksouls2) analyze_one ds2-darksouls2 "$DARKSOULS2_GAME_DIR/Game/DarkSoulsII.exe" darksouls2 ;;
    fmodex)     analyze_one ds2-fmodex "$DARKSOULS2_GAME_DIR/Game/fmodex.dll" fmodex ;;
    fmod_event) analyze_one ds2-fmod_event "$DARKSOULS2_GAME_DIR/Game/fmod_event.dll" fmod_event ;;
    *) echo "unknown module $m"; exit 1 ;;
  esac
done
