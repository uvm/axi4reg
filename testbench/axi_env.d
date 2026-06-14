module axi_env;

import esdl;
import uvm.reg;
import axi_agnt;
import axi_seq;
import axi_agnt;
import uvm;

import axi_reg_adapter: axi_reg_adapter;
import axi_regs_model: axi_regs;

class axi_environment(int DW, int AW): uvm_env
{
  mixin uvm_component_utils;

  // Components of the enviorment
  @UVM_BUILD axi_agent!(DW, AW) agent;
   
   
   // new - constructor
  this(string name, uvm_component parent) {
    super(name, parent);
  }

}
alias reg2axi_seq_t=uvm_reg_sequence!(uvm_sequence!(axi_seq_item!(32, 32)));

class axi_reg_env: uvm_component
{
  mixin uvm_component_utils;

  axi_regs                regmodel; 

  uvm_reg_sequence!(uvm_sequence!uvm_reg_item)             seq;
  reg2axi_seq_t                reg2axi_seq;

  @UVM_BUILD {
    uvm_sequencer!(uvm_reg_item) reg_seqr;
    axi_reg_agent!(32, 32)       agent;
    uvm_reg_predictor!(axi_seq_item!(32, 32))   axi2reg_predictor;
  }

  // axi_if             vif;

  this(string name, uvm_component parent=null) {
    super(name, parent);
  }

  override void build_phase(uvm_phase phase) {
    if (regmodel is null) {
      regmodel = cast(axi_regs) axi_regs.type_id.create("regmodel");
      regmodel.build();
      regmodel.lock_model();
    }

    reg2axi_seq = new reg2axi_seq_t();

    // string hdl_root = "tbd";
    // $value$plusargs("ROOT_HDL_PATH=%s",hdl_root);
    // regmodel.set_hdl_path_root(hdl_root);
  }

  override void connect_phase(uvm_phase phase) {
    // agent.driver.make_full_duplex();
    auto reg2axi  = axi_reg_adapter.type_id.create("reg2axi", this);
    regmodel.default_map.set_sequencer(reg_seqr, null);
    regmodel.get_default_map.set_auto_predict(1);

    reg2axi_seq.reg_seqr = reg_seqr;

    

    reg2axi_seq.adapter  = reg2axi;

    axi2reg_predictor.map = regmodel.default_map;
    axi2reg_predictor.adapter = reg2axi;
    regmodel.default_map.set_auto_predict(false);
    agent.collector.item_col_port.connect(axi2reg_predictor.bus_in);

    // agent.driver.seq_item_port.connect(reg_seqr.seq_item_export);

    // Connect virtual interface in driver to actual interface
  }

  override void run_phase(uvm_phase phase) {
    import std.format: format;
    phase.raise_objection(this);
    phase.get_objection.set_drain_time(this, 1000.nsec);
    if (seq is null) {
      uvm_report_fatal("NO_SEQUENCE","Env's sequence is not defined. Nothing to do. Exiting.");
      return;
    }

    uvm_info("START_SEQ", "Starting sequence '" ~ seq.get_name() ~ "'", UVM_NONE);

    seq.model = regmodel;
    
    uvm_info("START_SEQ", format("we will test %d registers", regmodel.get_registers().length), UVM_NONE);

    foreach (r; regmodel.get_registers()) {
      uvm_info("START_SEQ", format("register has %d bytes", r.get_n_bytes()), UVM_NONE);
    }

    fork({reg2axi_seq.start(agent.seqr);});

    seq.start(null);
    
    phase.drop_objection(this);
  }
}
