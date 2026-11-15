// steam_api.dll for the Dark Souls II reference run under CrossOver (a
// development tool, never shipped): the same offline answers as the
// runtime's HLE (x86recomp src/runtime/hle/steam_api.cpp), so both runs see
// the same Steam. A method without an answer logs its slot and exits.
//
// A watcher thread logs, whenever one changes, the game state the native
// run is being compared on (WATCH below), to C:\ds2ref.log.

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <windows.h>

static FILE* g_log;
static CRITICAL_SECTION g_log_mu;

static void Log(const char* f, ...) {
  EnterCriticalSection(&g_log_mu);
  if (!g_log) g_log = fopen("C:\\ds2ref.log", "w");
  fprintf(g_log, "[%8lu] ", GetTickCount());
  va_list ap;
  va_start(ap, f);
  vfprintf(g_log, f, ap);
  va_end(ap);
  fputc('\n', g_log);
  fflush(g_log);
  LeaveCriticalSection(&g_log_mu);
}

static void __attribute__((noreturn)) Missing(const char* iface, int slot, void* ret) {
  Log("unimplemented %s::#%d (return address %p)", iface, slot, ret);
  ExitProcess(3);
}

// ---- implemented methods (thiscall: this in ecx, the callee pops)
static void __attribute__((thiscall)) ISteamClient_21(void* self, void* hook) { (void)self, (void)hook; }
static uint32_t g_app_id;
static uint32_t __attribute__((thiscall)) ISteamUtils_9(void* self) { (void)self; return g_app_id; }
static void __attribute__((thiscall)) ISteamUtils_10(void* self, int pos) { (void)self, (void)pos; }
static int __attribute__((thiscall)) ISteamUser_1(void* self) { (void)self; return 0; }
static uint64_t* __attribute__((thiscall)) ISteamUser_2(void* self, uint64_t* out) {
  (void)self;
  *out = 0x0110000100000001ull;
  return out;
}
static const char* __attribute__((thiscall)) ISteamFriends_0(void* self) { (void)self; return "Player"; }
static const char* __attribute__((thiscall)) ISteamApps_4(void* self) { (void)self; return "english"; }
// The DLC licences are in the install, as for the native run.
static int __attribute__((thiscall)) ISteamApps_6(void* self, uint32_t app) {
  (void)self;
  Log("BIsSubscribedApp(%u)", app);
  return 1;
}
static int __attribute__((thiscall)) ISteamApps_7(void* self, uint32_t app) {
  (void)self;
  Log("BIsDlcInstalled(%u)", app);
  return 1;
}

#include "stubs.inc"

// ---- the watcher
static uint32_t Peek(uint32_t va) {
  return va && !IsBadReadPtr((void*)va, 4) ? *(volatile uint32_t*)va : 0;
}
static uint32_t PeekByte(uint32_t va) {
  return va && !IsBadReadPtr((void*)va, 1) ? *(volatile uint8_t*)va : 0;
}
static DWORD WINAPI Watch(void* arg) {
  (void)arg;
  uint32_t last[8] = {0};
  for (;;) {
    uint32_t v[8];
    const uint32_t mgr = Peek(0x1550414);
    v[0] = mgr;
    v[1] = mgr ? Peek(mgr + 0xCCC) : 0;
    const uint32_t reg = Peek(0x15515D4);
    v[2] = reg;
    const uint32_t obj = reg ? Peek(reg + 0x20) : 0;
    v[3] = obj;
    v[4] = obj ? PeekByte(obj + 4) : 0;
    const uint32_t sub = obj ? Peek(obj + 8) : 0;
    v[5] = sub;
    v[6] = sub ? Peek(sub + 0x24) : 0;
    v[7] = reg ? Peek(reg + 0x18) : 0;
    if (memcmp(v, last, sizeof v)) {
      Log("mgr %08X mgr+CCC %08X reg %08X reg+20 %08X flag %u sub %08X state %u reg+18 %08X",
          v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
      memcpy(last, v, sizeof v);
    }
    Sleep(1);
  }
}

// ---- exports (cdecl)
// CCallbackBase: {vtable, uint8 m_nCallbackFlags, int m_iCallback}.
__declspec(dllexport) int SteamAPI_RestartAppIfNecessary(uint32_t app) {
  Log("RestartAppIfNecessary(%u)", app);
  g_app_id = app;
  return 0;
}
__declspec(dllexport) int SteamAPI_Init(void) {
  Log("Init");
  CreateThread(NULL, 0, Watch, NULL, 0, NULL);
  return 1;
}
__declspec(dllexport) void SteamAPI_Shutdown(void) {}
__declspec(dllexport) void SteamAPI_RunCallbacks(void) {}
__declspec(dllexport) void SteamAPI_RegisterCallback(uint8_t* cb, int id) {
  cb[4] |= 1;
  *(int*)(cb + 8) = id;
}
__declspec(dllexport) void SteamAPI_UnregisterCallback(uint8_t* cb) { cb[4] &= ~1; }
__declspec(dllexport) void SteamAPI_RegisterCallResult(void* cb, uint64_t call) { (void)cb, (void)call; }
__declspec(dllexport) void SteamAPI_UnregisterCallResult(void* cb, uint64_t call) { (void)cb, (void)call; }
__declspec(dllexport) void* SteamClient(void) { return &ISteamClient_obj; }
__declspec(dllexport) void* SteamUser(void) { return &ISteamUser_obj; }
__declspec(dllexport) void* SteamFriends(void) { return &ISteamFriends_obj; }
__declspec(dllexport) void* SteamUtils(void) { return &ISteamUtils_obj; }
__declspec(dllexport) void* SteamUserStats(void) { return &ISteamUserStats_obj; }
__declspec(dllexport) void* SteamApps(void) { return &ISteamApps_obj; }
__declspec(dllexport) void* SteamNetworking(void) { return &ISteamNetworking_obj; }
__declspec(dllexport) void* SteamMatchmaking(void) { return &ISteamMatchmaking_obj; }

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, void* r) {
  (void)h, (void)r;
  if (reason == DLL_PROCESS_ATTACH) InitializeCriticalSection(&g_log_mu);
  return TRUE;
}
