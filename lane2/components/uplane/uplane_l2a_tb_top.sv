// ======================================================================
//  File   : lane2/components/uplane/uplane_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : uplane Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module uplane_l2a_tb_top;
  import muvm_pkg::*; import uplane_l2a_pkg::*;
  muvm_creator_t #(uplane_test) c_test;
  muvm_creator_t #(uplane_env) c_env;
  muvm_creator_t #(uplane_agent) c_agent;
  muvm_creator_t #(uplane_sqr) c_sqr;
  muvm_creator_t #(uplane_driver) c_driver;
  muvm_creator_t #(uplane_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("uplane_test", c_test);
    c_env=new(); muvm_factory::register("uplane_env", c_env);
    c_agent=new(); muvm_factory::register("uplane_agent", c_agent);
    c_sqr=new(); muvm_factory::register("uplane_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("uplane_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("uplane_scoreboard", c_scoreboard);
    muvm_root::run_test("uplane_test");
    $finish;
  end
endmodule
