SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(shell pwd)/../rtl/*.sv \
				  $(shell pwd)/../rtl/*.svh
TOPLEVEL = tbench_mac_pcs 
MODULE = test_mac_pcs

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ns

EXTRA_ARGS += --sv -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --trace

include $(shell cocotb-config --makefiles)/Makefile.sim