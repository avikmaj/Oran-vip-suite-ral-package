// ======================================================================
//  File   : lane2/common/muvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : UVM-1.1-compatible SUBSET that elaborates+runs on Verilator: object/component/phasing/factory(+override)/config_db/analysis-port/run_test.
// ======================================================================
//======================================================================
// muvm_pkg.sv — UVM-1.1-compatible SUBSET that ELABORATES AND RUNS on
// the 5.020 class subset (full Accellera UVM does not — measured PKGNODECL).
// Provides the structural UVM layer: object, component, phasing, factory
// (with override), config_db, analysis port, sequence_item/sequencer/driver/
// monitor/agent/env/scoreboard/test, and run_test() driver.
// Executed evidence, not inference. Native randomize()/covergroup/concurrent-
// SVA are NOT here (Verilator-unsupported) — those live in Lane-2B (venue).
//======================================================================
package muvm_pkg;

  // ---------------- object ----------------
  virtual class muvm_object;
    string m_name;
    function new(string name=""); m_name=name; endfunction
    virtual function string get_name(); return m_name; endfunction
  endclass

  // ---------------- component + phasing ----------------
  virtual class muvm_component extends muvm_object;
    muvm_component m_parent;
    muvm_component m_children[$];
    function new(string name="", muvm_component parent=null);
      super.new(name); m_parent=parent;
      if (parent!=null) parent.m_children.push_back(this);
    endfunction
    virtual function void build_phase();   endfunction
    virtual function void connect_phase(); endfunction
    virtual task          run_phase();     endtask
    virtual function void report_phase();  endfunction
    // recursive traversal
    function void build_all();   build_phase(); foreach (m_children[i]) m_children[i].build_all();   endfunction
    function void connect_all(); foreach (m_children[i]) m_children[i].connect_all(); connect_phase(); endfunction
    function void report_all();  foreach (m_children[i]) m_children[i].report_all(); report_phase();  endfunction
    function void flatten(ref muvm_component list[$]);
      list.push_back(this); foreach (m_children[i]) m_children[i].flatten(list);
    endfunction
  endclass

  // ---------------- factory (creatable + override) ----------------
  virtual class muvm_creator;
    pure virtual function muvm_component create(string name, muvm_component parent);
  endclass
  class muvm_creator_t #(type T=muvm_component) extends muvm_creator;
    virtual function muvm_component create(string name, muvm_component parent);
      T t; t = new(name, parent); return t;
    endfunction
  endclass
  class muvm_factory;
    static muvm_creator m_reg[string];
    static function void register(string tn, muvm_creator c); m_reg[tn]=c; endfunction
    static function void set_override(string orig, muvm_creator c); m_reg[orig]=c; endfunction
    static function muvm_component create(string tn, string name, muvm_component parent);
      if (m_reg.exists(tn)) return m_reg[tn].create(name,parent);
      $display("MUVM_FATAL: factory has no type '%s'", tn); return null;
    endfunction
  endclass

  // ---------------- config_db ----------------
  class muvm_config_db #(type T=int);
    static T m_store[string];
    static function void set(string scope, string field, T value); m_store[{scope,".",field}]=value; endfunction
    static function bit  get(string scope, string field, ref T value);
      if (m_store.exists({scope,".",field})) begin value=m_store[{scope,".",field}]; return 1; end
      return 0;
    endfunction
  endclass

  // ---------------- analysis port (mon -> subscribers) ----------------
  virtual class muvm_subscriber #(type T=muvm_object) extends muvm_component;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    pure virtual function void write(T t);
  endclass
  class muvm_analysis_port #(type T=muvm_object);
    muvm_subscriber #(T) m_subs[$];
    function void connect(muvm_subscriber #(T) s); m_subs.push_back(s); endfunction
    function void write(T t); foreach (m_subs[i]) m_subs[i].write(t); endfunction
  endclass

  // ---------------- run_test ----------------
  class muvm_root;
    static task run_test(string test_type);
      muvm_component top; muvm_component all[$];
      top = muvm_factory::create(test_type, "uvm_test_top", null);
      if (top==null) begin $display("MUVM_FATAL: no test '%s'", test_type); return; end
      top.build_all();
      top.connect_all();
      top.flatten(all);
      foreach (all[i]) begin
        automatic int k=i;
        fork all[k].run_phase(); join_none
      end
      wait fork;
      top.report_all();
    endtask
  endclass

endpackage
