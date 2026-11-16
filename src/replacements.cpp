// Replacements of lifted functions (manifest `replace` lines): the lifter
// emits their bodies as f_<VA>_lifted and the game calls these instead.

#include "runtime/lifted.h"

namespace recomp::gen {

void f_00E2E9A0(Ctx& c);

// 0x00E2E7F0 and 0x00E2E880: two of the copies of the timers' random-
// interval helper (__thiscall: the generator state in ecx, the bound on
// the stack, the interval in xmm0), whose bodies Arxan replaced with
// jumps into an integrity guard that checksums the image and then runs the
// helper. The image is never modified here (the game runs lifted code,
// not those bytes), so the check only costs time: 50-90 ms on the main
// thread each time the timer fires, a hitch every few tens of seconds.
// 0x00E2E9A0 is a byte-identical copy of the helper left as it was.
void f_00E2E7F0(Ctx& c) { f_00E2E9A0(c); }
void f_00E2E880(Ctx& c) { f_00E2E9A0(c); }

}  // namespace recomp::gen
