// ======================================================================
//  File   : lane2/components/ecpri_transport/ecpri_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module ecpri_l2a_tb_top;
  import muvm_pkg::*;
  import ecpri_l2a_pkg::*;
  // factory creators (register subset types)
  muvm_creator_t #(ecpri_test)       c_test;
  muvm_creator_t #(ecpri_env)        c_env;
  muvm_creator_t #(ecpri_agent)      c_agent;
  muvm_creator_t #(ecpri_sqr)        c_sqr;
  muvm_creator_t #(ecpri_driver)     c_drv;
  muvm_creator_t #(ecpri_scoreboard) c_sb;
  initial begin
    c_test=new(); c_env=new(); c_agent=new(); c_sqr=new(); c_drv=new(); c_sb=new();
    muvm_factory::register("ecpri_test",       c_test);
    muvm_factory::register("ecpri_env",        c_env);
    muvm_factory::register("ecpri_agent",      c_agent);
    muvm_factory::register("ecpri_sqr",        c_sqr);
    muvm_factory::register("ecpri_driver",     c_drv);
    muvm_factory::register("ecpri_scoreboard", c_sb);
    muvm_root::run_test("ecpri_test");
    $finish;
  end
endmodule
