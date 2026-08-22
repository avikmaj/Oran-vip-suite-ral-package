// ======================================================================
//  File   : lane2/components/splane/splane_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : splane Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module splane_l2a_tb_top;
  import muvm_pkg::*; import splane_l2a_pkg::*;
  muvm_creator_t #(splane_test) c_test;
  muvm_creator_t #(splane_env) c_env;
  muvm_creator_t #(splane_agent) c_agent;
  muvm_creator_t #(splane_sqr) c_sqr;
  muvm_creator_t #(splane_driver) c_driver;
  muvm_creator_t #(splane_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("splane_test", c_test);
    c_env=new(); muvm_factory::register("splane_env", c_env);
    c_agent=new(); muvm_factory::register("splane_agent", c_agent);
    c_sqr=new(); muvm_factory::register("splane_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("splane_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("splane_scoreboard", c_scoreboard);
    muvm_root::run_test("splane_test");
    $finish;
  end
endmodule
