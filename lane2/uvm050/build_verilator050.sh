#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/uvm050/build_verilator050.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build/run automation script.
# ======================================================================
# Build Verilator 5.050 (mandated primary) from source. ~20-30 min on 2 cores.
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get install -y flex bison ccache help2man libfl-dev g++ autoconf git >/dev/null
git clone --branch v5.050 --depth 1 https://github.com/verilator/verilator /home/claude/verilator_src
cd /home/claude/verilator_src && autoconf && ./configure && make -j"$(nproc)" && make install
verilator --version   # -> Verilator 5.050
