SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(shell pwd)/../rtl/*.sv \
				  $(shell pwd)/../rtl/mac/*.sv \
				  $(shell pwd)/../rtl/eth_pcs/*.sv \
				  $(shell pwd)/../rtl/package/*.sv
TOPLEVEL = tbench_mac_pcs 
MODULE = test_mac_pcs

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ns

EXTRA_ARGS += -DPMA_DATA_SHIFT --sv -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --trace
#EXTRA_ARGS += --sv -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --trace

# changes in Makefile now rebuild sim_build folder
CUSTOM_COMPILE_DEPS = ./Makefile 

include $(shell cocotb-config --makefiles)/Makefile.sim