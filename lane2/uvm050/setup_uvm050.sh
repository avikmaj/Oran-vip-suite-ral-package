#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/uvm050/setup_uvm050.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build/run automation script.
# ======================================================================
# Reproduce UVM-on-Verilator-5.050. Requires Verilator 5.050 built (build_verilator050.sh).
set -e
UVMDIR="${1:-/tmp/uvmtest/uvm}"
[ -d "$UVMDIR" ] || git clone --depth 1 https://github.com/accellera-official/uvm-core.git "$UVMDIR"
# Patch 1: no-op HDL backdoor (replace vendor #error) — matches uvm_dpi.h signatures
python3 - "$UVMDIR" <<'PY'
import sys; U=sys.argv[1]; f=U+"/src/dpi/uvm_hdl.c"; s=open(f).read()
stub='extern "C" {\n  int uvm_hdl_check_path(char* p){(void)p;return 0;}\n  int uvm_hdl_deposit(char* p, p_vpi_vecval v){(void)p;(void)v;return 0;}\n  int uvm_hdl_force(char* p, p_vpi_vecval v){(void)p;(void)v;return 0;}\n  int uvm_hdl_read(char* p, p_vpi_vecval v){(void)p;(void)v;return 0;}\n  int uvm_hdl_release_and_read(char* p, p_vpi_vecval v){(void)p;(void)v;return 0;}\n  int uvm_hdl_release(char* p){(void)p;return 0;}\n}\n'
if '#error "hdl vendor backend is missing"' in s: open(f,"w").write(s.replace('#error "hdl vendor backend is missing"',stub)); print("patched uvm_hdl.c")
f2=U+"/src/dpi/uvm_dpi.cc"; s2=open(f2).read()
if '#include "uvm_hdl_polling.c"' in s2: open(f2,"w").write(s2.replace('#include "uvm_hdl_polling.c"','/* polling disabled */')); print("patched uvm_dpi.cc")
PY
echo "UVM_HOME=$UVMDIR ready. vpi_stub.cc provides vpi_get_vlog_info."
