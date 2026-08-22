// ======================================================================
//  File   : lane2/components/mmwave/mmwave_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mmwave Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module mmwave_l2a_tb_top;
  import muvm_pkg::*; import mmwave_l2a_pkg::*;
  muvm_creator_t #(mmwave_test) c_test;
  muvm_creator_t #(mmwave_env) c_env;
  muvm_creator_t #(mmwave_agent) c_agent;
  muvm_creator_t #(mmwave_sqr) c_sqr;
  muvm_creator_t #(mmwave_driver) c_driver;
  muvm_creator_t #(mmwave_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("mmwave_test", c_test);
    c_env=new(); muvm_factory::register("mmwave_env", c_env);
    c_agent=new(); muvm_factory::register("mmwave_agent", c_agent);
    c_sqr=new(); muvm_factory::register("mmwave_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("mmwave_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("mmwave_scoreboard", c_scoreboard);
    muvm_root::run_test("mmwave_test");
    $finish;
  end
endmodule
