# darksouls2-mac

**Dark Souls II (the original 2014 release), running natively on Apple silicon Macs.**

No emulator, no Wine, no virtual machine. The game's 32-bit Windows code is
statically recompiled into native ARM64 code with
[x86recomp](https://github.com/aplaino/x86recomp), and the Windows APIs it
calls (Direct3D 9, DirectInput, XInput, DirectSound, the C runtime,
Steamworks, ...) are reimplemented on top of macOS, Metal and SDL3.
The sibling project for the first game is
[darksouls-mac](https://github.com/aplaino/darksouls-mac).

This repository contains **no game files**. You need your own copy of the
game; the build reads it from your disk and generates everything else.

### Which version of the game works

The current Steam build of the original **Dark Souls II** (in-game
"Ver. 1.12 / Calibrations 1.15"), whose `Game/DarkSoulsII.exe` has SHA-256
`b3bc34364642320dfdf184b92838bba9f4b3c4b67098d731fddc0cc0537bf34d`
(`tools/lift.sh` checks it and stops if it differs).

**Scholar of the First Sin is a different game** (64-bit, Direct3D 11) and
does not work.

## Status

Early, but playable: title screen, menus, character creation, and play in
the first areas.

- A steady 60 fps (the game's own limit) on an M-series Mac
- Metal renderer at the display's full resolution
- Sound and music (FMOD through DirectSound)
- Keyboard and mouse, and controllers
- Offline only: Steam is stood in for by an offline implementation, so
  online play, messages and achievements are unavailable and the game runs
  in offline mode

Known issues:

- The opening movie is skipped (there is no WMV decoder yet).
- Short hitches while an area loads, as new shaders are translated to
  Metal on the main thread.
- Shadows sometimes look wrong.
- Quitting can end with a crash report from the game's worker threads.

## Building

Requirements: macOS on Apple silicon, Xcode command line tools, Homebrew
`cmake`, `ninja`, `llvm@22`, `sdl3`, and the game installed (the folder
that contains `Game/`).

```sh
git clone --recursive https://github.com/aplaino/darksouls2-mac.git
cd darksouls2-mac
echo 'DARKSOULS2_GAME_DIR="/path/to/Dark Souls II"' > tools/local.env
cmake --preset release
cmake --build out/build/release --target recomp_lift
tools/lift.sh      # translates your DarkSoulsII.exe into generated/
tools/build.sh
tools/run.sh
```

The symbol tables in `symbols/` (function addresses and names from an
analysis of the executable) and the manifests in `manifest/` are what the
lifter needs besides your executable. `tools/find_entries.py` and
`tools/complete_jumptables.py` regenerate the parts of them that the
anti-tamper wrapper (Arxan) hides from that analysis.

## Legal

Dark Souls II is a trademark of its owners; this project is not affiliated
with or endorsed by them. It distributes no game code or data: you need
your own copy of the game.
