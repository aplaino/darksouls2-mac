// darksouls2: Dark Souls II (PC, the 2022 build), natively.
//
//   darksouls2 [--game-dir DIR] [-- GAME ARGS...]
//
// DIR is the game install: the folder holding Game/ (DarkSoulsII.exe, the
// .bdt archives, the FMOD DLLs). Defaults to $DARKSOULS2_GAME_DIR.
// Arguments after `--` go on the game's own command line. Set
// DARKSOULS2_TRACE=1 to log every HLE call.

#include <sys/stat.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

#include "runtime/log.h"
#include "runtime/runtime.h"

int main(int argc, char** argv) {
  std::string game_dir, game_args;
  if (const char* e = std::getenv("DARKSOULS2_GAME_DIR")) game_dir = e;
  for (int i = 1; i < argc; i++) {
    if (!std::strcmp(argv[i], "--game-dir") && i + 1 < argc) {
      game_dir = argv[++i];
    } else if (!std::strcmp(argv[i], "--")) {
      for (i++; i < argc; i++) {
        if (!game_args.empty()) game_args += ' ';
        bool quote = std::strpbrk(argv[i], " \t") != nullptr;
        if (quote) game_args += '"';
        game_args += argv[i];
        if (quote) game_args += '"';
      }
    } else {
      std::fprintf(stderr, "usage: %s [--game-dir DIR] [-- GAME ARGS...]\n", argv[0]);
      return 2;
    }
  }
  if (game_dir.empty()) {
    std::fprintf(stderr, "darksouls2: pass --game-dir or set DARKSOULS2_GAME_DIR\n");
    return 2;
  }
  while (game_dir.size() > 1 && game_dir.back() == '/') game_dir.pop_back();
  if (const char* t = std::getenv("DARKSOULS2_TRACE")) recomp::g_trace = *t && *t != '0';

  const std::string exe = game_dir + "/Game/DarkSoulsII.exe";
  struct stat st;
  if (stat(exe.c_str(), &st) != 0) {
    std::fprintf(stderr, "darksouls2: %s not found\n", exe.c_str());
    return 2;
  }

  recomp::GameConfig game;
  game.id = "darksouls2";
  // The Steam install path; DarkSoulsII.exe lives in Game/ and is started there.
  game.guest_dir = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Dark Souls II";
  game.exe_name = "Game\\DarkSoulsII.exe";
  game.current_dir = game.guest_dir + "\\Game";
  game.total_phys_mb = 4096;
  game.video_memory_mb = 1024;
#if defined(__APPLE__)
  // The Metal renderer (as for the other D3D9 games on this runtime).
  setenv("DARKSOULS2_GFX", "metal", 0);
#endif
  // FMOD: lifted as modules (GameConfig::lifted_dlls) so their imports
  // don't need HLE reimplementations. Both sit next to the exe in Game/;
  // the loader matches them by file name, so the game's static imports
  // find the mapped images.
  game.lifted_dlls = {{"Game\\fmodex.dll", 0}, {"Game\\fmod_event.dll", 0x11000000}};
  return recomp::RunProcess(game, exe, game_dir, game_args);
}
