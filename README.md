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

Playable from the start: title screen, menus, the intro movie, character
creation and the first areas, saving, loading and quitting.

- A steady 60 fps (the game's own limit) on High at the display's full
  resolution (see Performance)
- Metal renderer, beyond the game's own High: its 2048 and 1024 shadow maps
  at twice the resolution, and 16x anisotropic filtering
- The intro movie, played into the game's own video renderer (ffmpeg
  decodes the WMV); Escape skips it, as in the original
- Sound and music (FMOD through DirectSound)
- Keyboard and mouse, and controllers
- Offline only: Steam is stood in for by an offline implementation, so
  online play, messages and achievements are unavailable and the game runs
  in offline mode

Known issues:

- Short hitches while an area loads, as new shaders are translated to
  Metal on the main thread; in play, a brief one about once a minute (the
  game waiting on its physics jobs) and a longer one (about 150 ms) every
  few minutes, an anti-tamper check behind some of the game's state
  handlers.
- Button prompts show a controller's buttons with keyboard and mouse. The
  port no longer reports a controller when none is connected; whether the
  original PC release shows keyboard prompts here is not settled yet.
- A save made with DLC present may report the DLC as missing on loading
  (choose No to keep the items); new saves load normally.

## Performance

`bench/bench.sh` starts a new game in a sandbox (no save of yours is
touched), skips the intro and stands still where the game starts, Things
Betwixt, for 60 s; hidden window, no sound, High settings, the port's
defaults. On an M5 Pro (macOS 26.6.2) at 3024x1964 Retina (the game at
3600x2338), plugged in, three runs:

| | |
|---|---|
| Frame rate | 59.99 fps (the game's cap) every run |
| 1% low | 54.4 fps |
| CPU | 1.15 cores |
| GPU | 11.3 ms a frame |
| Memory | 2.0 GB |

A comparison with CrossOver like the first game's is not possible yet: the
game renders black there with DXVK, and wined3d lacks the timestamp
queries it needs.

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
tools/run.sh       # or: tools/app.sh --install, then open Dark Souls II
```

`tools/app.sh` makes `out/DarkSoulsII.app`, a bundle of the built game and
its runtime libraries that Finder, Spotlight and the Dock can launch (logs
in `~/Library/Logs/DarkSoulsII`); `--install` copies it to /Applications.
It records where the game folder is when it is built.

The symbol tables in `symbols/` (function addresses and names from an
analysis of the executable) and the manifests in `manifest/` are what the
lifter needs besides your executable. `tools/find_entries.py` and
`tools/complete_jumptables.py` regenerate the parts of them that the
anti-tamper wrapper (Arxan) hides from that analysis.

## Legal

Dark Souls II is a trademark of its owners; this project is not affiliated
with or endorsed by them. It distributes no game code or data: you need
your own copy of the game.
