// Replacements of lifted functions (manifest `replace` lines): the lifter
// emits their bodies as f_<VA>_lifted and the game calls these instead.

#include "runtime/lifted.h"

namespace recomp::gen {

void f_00E2E9A0(Ctx& c);

// Copies of the random-interval helper the timers in 0x00E2EA30 call
// (__thiscall: the generator state in ecx, the bound on the stack, the
// interval in xmm0), whose bodies Arxan replaced with
// jumps into an integrity guard that checksums the image and then runs the
// helper. The image is never modified here (the game runs lifted code,
// not those bytes), so the check only costs time: 50-90 ms on the main
// thread each time the timer fires, a hitch every few tens of seconds.
// 0x00E2E9A0 is one of the byte-identical copies left as they were.
void f_00E2D5F0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2DCB0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2DDD0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E250(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E370(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E5B0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E6D0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E760(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E7F0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E880(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E910(Ctx& c) { f_00E2E9A0(c); }

}  // namespace recomp::gen
