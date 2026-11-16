#!/bin/bash
# bench.sh [runs]: the port's frame rate, CPU and memory, standing still for
# 60 s where a new game starts (Things Betwixt), on High with the port's
# defaults. Each run starts from nothing in a sandbox (its own data folder,
# so no save of yours is touched): New Game with Enter, the intro skipped
# with Escape, then no input. Hidden window, no sound, at the display's
# full resolution. Results in bench/results/<time>/.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$here/tools/local.env" ] && . "$here/tools/local.env"
: "${DARKSOULS2_GAME_DIR:?set DARKSOULS2_GAME_DIR (tools/local.env)}"
runs=${1:-3}
bin="$here/out/build/release/darksouls2"
out="$here/bench/results/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

# Enter through the title, the menus and New Game; Escape skips the intro.
input="$out/input.txt"
for t in 40 48 56 64 72 80; do echo "$t key Return"; done > "$input"
for t in 100 104; do echo "$t key Escape"; done >> "$input"
from=140 to=200  # the measured window, seconds since the first event pump

for i in $(seq 1 "$runs"); do
  sandbox=$(mktemp -d)
  log="$out/run$i.log"
  XDG_DATA_HOME="$sandbox" SDL_AUDIO_DRIVER=dummy RECOMP_AUDIO_MUTE=1 \
    DARKSOULS2_HIDDEN=1 DARKSOULS2_FPS_REPORT=1 DARKSOULS2_TEST_INPUT="$input" \
    "$bin" --game-dir "$DARKSOULS2_GAME_DIR" > "$log" 2>&1 &
  wrapper=$!
  sleep 2
  pid=$(pgrep -P "$wrapper" -x darksouls2 || echo "$wrapper")
  # CPU time (process user + system) at the window's edges, from the
  # start of the game's own clock (its first fps line is at about t=1 s).
  sleep $((from - 1))
  c0=$(ps -o time= -p "$pid" | awk -F'[:.]' '{print ($1 * 60 + $2) + ("0." $3)}')
  sleep $((to - from))
  c1=$(ps -o time= -p "$pid" | awk -F'[:.]' '{print ($1 * 60 + $2) + ("0." $3)}')
  kill "$pid" 2>/dev/null || true
  wait "$wrapper" 2>/dev/null || true
  rm -rf "$sandbox"
  echo "$c0 $c1 $((to - from))" > "$out/run$i.cpu"
  echo "bench.sh: run $i done"
done

python3 - "$out" "$runs" "$from" "$to" <<'EOF'
import re, sys, statistics as st
out, runs, lo, hi = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
rows = []
for i in range(1, runs + 1):
    fps, p99, gpu, mem = [], [], [], []
    for line in open(f"{out}/run{i}.log", errors="replace"):
        m = re.search(r"fps: ([\d.]+) at t=([\d.]+) s .*?p99 ([\d.]+) .*?GPU ([\d.]+) ms.*?footprint (\d+) MB", line)
        if m and lo <= float(m.group(2)) <= hi:
            fps.append(float(m.group(1))); p99.append(float(m.group(3)))
            gpu.append(float(m.group(4))); mem.append(int(m.group(5)))
    c0, c1, secs = map(float, open(f"{out}/run{i}.cpu").read().split())
    if not fps:
        print(f"run {i}: no frames measured (did it reach the game?)")
        continue
    rows.append((st.mean(fps), 1000 / max(p99), min(fps), (c1 - c0) / secs, st.mean(gpu), max(mem)))
    r = rows[-1]
    print(f"run {i}: {r[0]:.2f} fps (1% low {r[1]:.1f}, worst second {r[2]:.1f}), "
          f"{r[3]:.2f} cores, GPU {r[4]:.2f} ms/frame, {r[5]} MB")
if rows:
    print(f"mean of {len(rows)}: {st.mean(r[0] for r in rows):.2f} fps, "
          f"1% low {st.mean(r[1] for r in rows):.1f}, {st.mean(r[3] for r in rows):.2f} cores, "
          f"GPU {st.mean(r[4] for r in rows):.2f} ms/frame, {max(r[5] for r in rows)} MB")
EOF
