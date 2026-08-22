#!/usr/bin/env bash
# ======================================================================
#  File   : components/laa/run.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build/run automation script.
# ======================================================================
set -u
S="laa"; TEST="${1:-smoke}"; SEED="${2:-1}"; N="${3:-300}"
D="$(cd "$(dirname "$0")" && pwd)"; GEN="/home/claude/oran_vip_suite/gen"; OUT="$D/sim_out"; mkdir -p "$OUT"
STIM="$OUT/${S}_${TEST}_seed${SEED}.hex"; LOG="$OUT/${TEST}_seed${SEED}.log"
RES="$OUT/result_${TEST}_seed${SEED}.json"; MDIR="$OUT/obj_${TEST}_${SEED}"
python3 "$GEN/gen_stim.py" --spec "$D/spec.json" --seed "$SEED" --n "$N" --out "$STIM" || exit 2
verilator --cc --exe --build -j 0 --timing --coverage -Wno-CONSTRAINTIGN -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-UNUSEDSIGNAL -Wno-fatal \
  --Mdir "$MDIR" -o simv --top-module ${S}_tb_top \
  "$D/sim_main.cpp" "$D/rtl/${S}_pkg.sv" "$D/rtl/${S}_codec.sv" "$D/tb/${S}_tb_top.sv" > "$OUT/${TEST}_seed${SEED}.compile.log" 2>&1 || { echo "COMPILE FAIL"; tail -15 "$OUT/${TEST}_seed${SEED}.compile.log"; exit 3; }
( cd "$OUT" && "$MDIR/simv" +STIM="$STIM" +verilator+seed+"$SEED" ) > "$LOG" 2>&1; SRC=$?
python3 "$GEN/adjudicate.py" --spec "$D/spec.json" --log "$LOG" --sim-exit "$SRC" --test "$TEST" --seed "$SEED" --out "$RES"
