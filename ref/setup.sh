#!/bin/zsh
# setup.sh: the ds2ref CrossOver bottle, a development reference for the
# native port (never shipped): the same game files (APFS clones of
# DARKSOULS2_GAME_DIR, no extra space) and Steam answered by ref/steam_api
# (the runtime's offline answers, plus a watcher of the game state the native
# run is compared on; it logs to the bottle's C:\ds2ref.log).
set -e
cd ${0:a:h}
source ../tools/local.env
CX=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin
BOTTLE=~/Library/Application\ Support/CrossOver/Bottles/ds2ref
[[ -d $BOTTLE ]] || $CX/cxbottle --bottle ds2ref --create --template win10_64
if [[ ! -d $BOTTLE/drive_c/DarkSoulsII/Game ]]; then
  mkdir -p $BOTTLE/drive_c/DarkSoulsII
  cp -cR $DARKSOULS2_GAME_DIR/Game $DARKSOULS2_GAME_DIR/DLC $BOTTLE/drive_c/DarkSoulsII/
fi
python3 gen_stubs.py stubs.inc
i686-w64-mingw32-gcc -O2 -shared -o steam_api.dll steam_api.c -static-libgcc -Wl,--kill-at -lpsapi
cp steam_api.dll $BOTTLE/drive_c/windows/syswow64/
echo "setup.sh: ready (ref/run.sh)"
