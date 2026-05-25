DFLAGS = -relocation-model=pic -w -O3 --release --boundscheck=off --allinst

VERBOSITY = DEBUG

DUTLIB = obj_dir/DVaxi_regs.a

TBSRC = ../testbench/axi_seq.d ../testbench/axi_tb.d \
	../testbench/axi_drv.d ../testbench/axi_mon.d \
	../testbench/axi_agnt.d ../testbench/axi_env.d \
	../testbench/axi_scrb.d ../testbench/axi_test.d

all: axi_test

clean:
	rm -rf axi_test* euvm_dir obj_dir axi_regs.fst

run: axi_test
	./axi_test +UVM_TESTNAME=axi_test.axi_dir_test +UVM_VERBOSITY=$(VERBOSITY) # +UVM_OBJECTION_TRACE

$(DUTLIB): ../rtl/axi_regs.sv
	verilator -I../rtl -Wno-WIDTH -Wno-CASEINCOMPLETE --trace-fst --cc --euvm $^
	make -C obj_dir -f DVaxi_regs.mk DVaxi_regs.a

axi_test:  $(TBSRC) $(DUTLIB)
	ldc2 $(DFLAGS) -Ieuvm_dir -link-defaultlib-shared -of$@ $^ -L-luvm-ldc-shared -L-lesdl-ldc-shared \
		-L-lphobos2-ldc-shared -L-ldl -L-lstdc++
