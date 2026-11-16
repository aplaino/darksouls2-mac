#!/bin/bash
# app.sh: makes out/DarkSoulsII.app, a self-contained bundle of the built
# game (the binary and its runtime libraries inside; the path of the game
# folder in Resources). With --install it is copied to /Applications, where
# Spotlight, Launchpad and the Dock find it.
#   tools/app.sh [--install] && open out/DarkSoulsII.app
#   open --env DARKSOULS2_TRACE=1 -a "DarkSoulsII"     (switches as with run.sh)
# Launched through LaunchServices (open, Finder, the Dock), macOS lets the
# game take keyboard focus; started in the background from a terminal, it
# leaves the keyboard with the terminal. Logs go to ~/Library/Logs/DarkSoulsII.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$here/tools/local.env" ] && . "$here/tools/local.env"
: "${DARKSOULS2_GAME_DIR:?set DARKSOULS2_GAME_DIR (tools/local.env) to the folder with Game/}"
game_dir=$(cd "$DARKSOULS2_GAME_DIR" && pwd)
build="$here/out/build/release"
app="$here/out/DarkSoulsII.app"
bin="$build/darksouls2"
[ -x "$bin" ] || { echo "app.sh: build first (tools/build.sh): no $bin"; exit 1; }

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Frameworks" "$app/Contents/Resources"
cat > "$app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>DarkSoulsII</string>
  <key>CFBundleIdentifier</key><string>local.darksouls2-mac</string>
  <key>CFBundleName</key><string>Dark Souls II</string>
  <key>CFBundleDisplayName</key><string>Dark Souls II</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

# The binary finds its runtime libraries through an rpath into the build
# tree; inside the bundle they sit in Frameworks/, with every library they
# load through @rpath (Homebrew's stay where Homebrew put them). cp -c
# clones on APFS (no extra space).
fw="$app/Contents/Frameworks"
rpath_deps() { otool -L "$1" | awk 'NR > 1 && $1 ~ /^@rpath\// {sub("@rpath/", "", $1); print $1}'; }
add_lib() {
  [ -f "$fw/$1" ] && return
  [ -f "$build/x86recomp/$1" ] || { echo "app.sh: no $1"; exit 1; }
  cp -cL "$build/x86recomp/$1" "$fw/$1"
  local dep
  for dep in $(rpath_deps "$fw/$1"); do add_lib "$dep"; done
}
cp -c "$bin" "$app/Contents/MacOS/game"
for dep in $(rpath_deps "$bin"); do add_lib "$dep"; done
install_name_tool -rpath "$build/x86recomp" "@executable_path/../Frameworks" "$app/Contents/MacOS/game" 2>/dev/null
printf '%s' "$game_dir" > "$app/Contents/Resources/game-dir"
# No run paths of the machine that built it.
for lib in "$fw"/*.dylib; do
  for rp in $(otool -l "$lib" | awk '/cmd LC_RPATH/ {r = 1} r && $1 == "path" {print $2; r = 0}'); do
    case $rp in @*) ;; *) install_name_tool -delete_rpath "$rp" "$lib" ;; esac
  done
done
codesign --force -s - "$fw"/*.dylib "$app/Contents/MacOS/game" 2>/dev/null

cat > "$app/Contents/MacOS/DarkSoulsII" <<EOF
#!/bin/bash
contents=\$(cd "\$(dirname "\$0")/.." && pwd)
game_dir=\$(cat "\$contents/Resources/game-dir")
# The Metal performance HUD (fps, frame time, GPU time) in the top-right
# corner; open --env MTL_HUD_ENABLED=0 turns it off.
export MTL_HUD_ENABLED="\${MTL_HUD_ENABLED-1}"
logs="\$HOME/Library/Logs/DarkSoulsII"
mkdir -p "\$logs"
if [ ! -f "\$game_dir/Game/DarkSoulsII.exe" ]; then
  osascript -e "display alert \"Dark Souls II\" message \"The game files are not at \$game_dir. Build the app again with the game's new folder.\""
  exit 1
fi
exec "\$contents/MacOS/game" --game-dir "\$game_dir" "\$@" > "\$logs/run-\$(date +%Y%m%d-%H%M%S).log" 2>&1
EOF
chmod +x "$app/Contents/MacOS/DarkSoulsII"
echo "app.sh: $app"

if [ "${1-}" = "--install" ]; then
  rm -rf "/Applications/DarkSoulsII.app"
  cp -cR "$app" /Applications/
  echo "app.sh: installed /Applications/DarkSoulsII.app"
fi
