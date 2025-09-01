SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(shell pwd)/../rtl/*.sv \
				  $(shell pwd)/../rtl/*.svh
TOPLEVEL = custom_eth_core_wrapper
MODULE = tb_wrapper

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ns

EXTRA_ARGS += --sv -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --trace

include $(shell cocotb-config --makefiles)/Makefile.sim