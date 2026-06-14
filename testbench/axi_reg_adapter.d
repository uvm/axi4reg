module axi_reg_adapter;

import uvm;
import uvm.reg;
import esdl;
import axi_seq;


class axi_reg_adapter: uvm_reg_adapter
{

  mixin uvm_object_utils;

  this(string name = "reg2axi_adapter") {
    super(name);
    this.provides_responses = true;
  }

  override uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw) {
    // uvm_info("REG2BUS", "Mapping a reg op to axi transaction", UVM_NONE);
    axi_seq_item!(32, 32)  trans;
      
    trans = axi_seq_item!(32, 32).type_id.create("reg2bus AXI");
    trans.addr = cast(uint) rw.addr;
    trans.burst = toubvec!2(0b01);	// INCR
    trans.length = 0;
    trans.size = toubvec!2(0b10);
    trans.last = true;
    trans.rwdata = cast(uint) rw.data;
    trans.strb = toubvec!4(0xf);
    if (rw.kind == UVM_READ) trans.op = OP.READ;
    else trans.op = OP.WRITE;
    return trans;
      
  } // reg2bus
   

  override void bus2reg(uvm_sequence_item bus_item,
			ref uvm_reg_bus_op rw) {
      
    axi_seq_item!(32, 32) trans =
      cast(axi_seq_item!(32, 32)) bus_item;

    
    if (trans is null) {
      uvm_fatal("NOT_REG_TYPE","Incorrect bus item type. " ~
		"Expecting ahb_transfer");
      return;
    }

    rw.kind = (trans.op == OP.READ) ? UVM_READ : UVM_WRITE;
    rw.addr = trans.addr;
    rw.data = trans.rwdata;
    // $display("Exploring axi item ", trans.get_full_name());
    // $display("rw.data: %h for kind %h @%h at time %t", rw.data, rw.kind, rw.addr, $time);
    rw.status = UVM_IS_OK;
      
  } // bus2reg
   
}

