// ======================================================================
//  File   : lane2/lane2b_native/suite/suite_commercial.f
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Desc   : COMMERCIAL-sim filelist (VCS / Questa / Xcelium). Uses the
//           VENDOR built-in UVM (-ntb_opts uvm-1.2 / -uvm). Do NOT also
//           compile $UVM_HOME/src/uvm_pkg.sv here -> double-define breaks
//           name resolution. All 13 leaf packages compiled + imported
//           DIRECTLY (no re-export chain).
// ======================================================================
ecpri_transport_uvm_pkg.sv
cpri_eth_uvm_pkg.sv
uplane_uvm_pkg.sv
cplane_uvm_pkg.sv
splane_uvm_pkg.sv
mplane_uvm_pkg.sv
beamforming_uvm_pkg.sv
compression_uvm_pkg.sv
prach_uvm_pkg.sv
mimo_massive_uvm_pkg.sv
bwp_uvm_pkg.sv
mmwave_uvm_pkg.sv
laa_uvm_pkg.sv
oran_uvm_tb_top.sv
