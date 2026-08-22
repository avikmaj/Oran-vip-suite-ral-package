// ======================================================================
//  File   : lane2/uvm050/vpi_stub.cc
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : vpi_get_vlog_info stub enabling full Accellera UVM link on Verilator 5.050.
// ======================================================================
#include "vpi_user.h"
extern "C" PLI_INT32 vpi_get_vlog_info(p_vpi_vlog_info info){
  static char prod[]="Verilator"; static char ver[]="5.050";
  static char* av[1]={0};
  if(info){ info->argc=0; info->argv=av; info->product=prod; info->version=ver; }
  return 1;
}
