#!/bin/zsh
# run.sh [seconds]: starts the reference run in the ds2ref bottle, stops it
# after `seconds` (default 60) and prints the watcher's log. DXVK: wined3d
# has no timestamp queries, which the game uses without checking.
cd ${0:a:h}
CX=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin
BOTTLE=~/Library/Application\ Support/CrossOver/Bottles/ds2ref
rm -f $BOTTLE/drive_c/ds2ref.log
CX_GRAPHICS_BACKEND=dxvk $CX/wine --bottle ds2ref --workdir 'C:\DarkSoulsII\Game' 'C:\DarkSoulsII\Game\DarkSoulsII.exe' \
  > ../logs/ref-wine.log 2>&1 &
sleep ${1:-60}
$CX/wineserver --bottle ds2ref -k 2>/dev/null || $CX/wine --bottle ds2ref wineboot -k
cat $BOTTLE/drive_c/ds2ref.log
