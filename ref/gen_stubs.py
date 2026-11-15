#!/usr/bin/env python3
"""Writes stubs.inc for steam_api.c: one function per vtable slot of each
interface, which logs "<Interface>::#<slot>" and exits (the reference run
stops where the runtime's HLE would be fatal), and the vtables of them.
Slots with an implementation in steam_api.c (IMPL) point at it instead."""
import sys
IFACES = ['ISteamClient', 'ISteamUser', 'ISteamFriends', 'ISteamUtils', 'ISteamUserStats',
          'ISteamApps', 'ISteamNetworking', 'ISteamMatchmaking']
IMPL = {('ISteamClient', 21), ('ISteamUtils', 9), ('ISteamUtils', 10), ('ISteamUser', 1), ('ISteamUser', 2),
        ('ISteamFriends', 0), ('ISteamApps', 4)}
SLOTS = 128
out = []
for i in IFACES:
    for n in range(SLOTS):
        if (i, n) not in IMPL:
            out.append(f'static void {i}_{n}(void) {{ Missing("{i}", {n}, __builtin_return_address(0)); }}')
    out.append(f'static void* {i}_vtbl[{SLOTS}] = {{' +
               ', '.join(f'(void*){i}_{n}' for n in range(SLOTS)) + '};')
    out.append(f'static struct {{ void** vtbl; }} {i}_obj = {{ {i}_vtbl }};')
open(sys.argv[1], 'w').write('\n'.join(out) + '\n')
