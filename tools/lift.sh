#!/bin/bash
# lift.sh: the game's code, from your own DarkSoulsII.exe (the 2022 build),
# translated to C++ in generated/: the lifted executable (recomp_lift, with
# the symbols in symbols/ and this port's changes in
# manifest/darksouls2.manifest) plus the two FMOD DLLs it imports (lifted as
# modules, so their code is native too instead of being reimplemented in
# the HLE).
# Run it after the first build (which makes the lifter) and again after
# changing a manifest; then build again.
#   DARKSOULS2_GAME_DIR: the game's folder (the one with Game/), from the
#   environment or tools/local.env.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$here/tools/local.env" ] && . "$here/tools/local.env"
: "${DARKSOULS2_GAME_DIR:?set DARKSOULS2_GAME_DIR to the folder with Game/}"
exe="$DARKSOULS2_GAME_DIR/Game/DarkSoulsII.exe"
[ -f "$exe" ] || { echo "no Game/DarkSoulsII.exe in $DARKSOULS2_GAME_DIR"; exit 1; }
want=b3bc34364642320dfdf184b92838bba9f4b3c4b67098d731fddc0cc0537bf34d
have=$(shasum -a 256 "$exe" | cut -d' ' -f1)
[ "$have" = "$want" ] || { echo "DarkSoulsII.exe is not the supported build (SHA-256 $have, want $want)"; exit 1; }
lift="${LIFTER:-$here/out/build/release/x86recomp/tools/lifter/recomp_lift}"
[ -x "$lift" ] || { echo "build the lifter first (cmake --preset release && cmake --build out/build/release --target recomp_lift): no $lift"; exit 1; }

mods=()
for m in fmodex fmod_event; do
  [ -d "$here/symbols/$m" ] || continue
  base=()
  [ "$m" = "fmod_event" ] && base=(--base 11000000)
  mods+=(--module "$m.dll" --symbols "$here/symbols/$m"
         --manifest "$here/manifest/$m.manifest" ${base[@]+"${base[@]}"})
done

# The lifter reads the modules by file name from its working directory, so
# it runs in work/lift/, where they are links into the game tree.
mkdir -p "$here/work/lift"
for f in DarkSoulsII.exe fmodex.dll fmod_event.dll; do
  ln -sf "$DARKSOULS2_GAME_DIR/Game/$f" "$here/work/lift/$f"
done

echo "lift.sh: lifting DarkSoulsII.exe"
# --optnone-x87-over: functions dense with x87 code take clang a very long
# time to optimise; they are compiled as is. --stack-flow: Arxan writes
# jumps, calls and branches as pushes and rets (push X; ret, push X; jmp F).
(cd "$here/work/lift" && "$lift" --exe DarkSoulsII.exe --symbols "$here/symbols/darksouls2" \
  --manifest "$here/manifest/darksouls2.manifest" --out "$here/generated" --optnone-x87-over 4000 \
  --stack-flow \
  "${mods[@]}" "$@")
echo "lift.sh: done"
