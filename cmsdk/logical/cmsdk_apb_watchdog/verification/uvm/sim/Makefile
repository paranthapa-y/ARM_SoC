#-----------------------------------------------------------------------------
# Makefile for cmsdk_apb_watchdog UVM verification
# QuestaSim 2021.2_1
#-----------------------------------------------------------------------------

# Tool locations
QUESTA_HOME  := /home/paranthapa/Downloads/questasim
UVM_HOME     := $(QUESTA_HOME)/verilog_src/uvm-1.2
UVM_DPI_LIB  := $(QUESTA_HOME)/uvm-1.2/linux_x86_64/uvm_dpi

# Questa's bundled gcc-7.4.0 can't link against modern glibc (.relr.dyn
# relocations unsupported by its old ld). Point DPI auto-compile at the
# system compiler instead. Override on the command line if needed:
#   make gui DPI_CPP_PATH=/usr/bin/gcc-12
DPI_CPP_PATH ?= /usr/bin/gcc

# DUT/TB
TOPLEVEL := tb_top
FILELIST := filelist.f

#########################################################
# Tests available
# make run TESTNAME=<testname>
# make gui TESTNAME=<testname>
#########################################################
DEFAULT_TEST := wdog_lock_test
TESTNAME     ?= $(DEFAULT_TEST)
VERBOSITY    ?= UVM_MEDIUM

# UVM options
UVM_ARGS = +UVM_TESTNAME=$(TESTNAME) \
           +UVM_VERBOSITY=$(VERBOSITY)

# Simulation library
WORKLIB := work

# Logs
COMP_LOG   := compile.log
SIM_LOG    := sim_$(TESTNAME).log
TRANSCRIPT := transcript

.PHONY: all comp run gui gui_run clean

#-----------------------------------------------------------------------------
# Default target
#-----------------------------------------------------------------------------
all: run

#-----------------------------------------------------------------------------
# Compile DUT and UVM testbench
#-----------------------------------------------------------------------------
comp:
	@echo "[Cleaning and creating work library...]"
	@rm -rf $(WORKLIB) modelsim.ini
	@vlib $(WORKLIB)
	@vmap $(WORKLIB) $(WORKLIB)
	@echo "[Pointing DPI auto-compile at $(DPI_CPP_PATH)...]"
	@if [ ! -f modelsim.ini ]; then vmap -c >/dev/null 2>&1 || true; fi
	@sed -i '/^DpiCppPath/d' modelsim.ini
	@sed -i '/^\[vsim\]/a DpiCppPath = $(DPI_CPP_PATH)' modelsim.ini
	@echo "[Compiling UVM testbench...]" | tee $(COMP_LOG)
	@vlog -sv -mfcu -work $(WORKLIB) \
	+incdir+$(UVM_HOME)/src \
	$(UVM_HOME)/src/uvm_pkg.sv \
	-f $(FILELIST) \
	| tee -a $(COMP_LOG) | tee -a $(TRANSCRIPT)

#-----------------------------------------------------------------------------
# Run simulation in command-line mode
#-----------------------------------------------------------------------------
run: comp
	@echo "[Running TESTNAME=$(TESTNAME) in command-line mode...]" | tee $(SIM_LOG)
	@vsim -c -voptargs=+acc -sv_lib $(UVM_DPI_LIB) $(WORKLIB).$(TOPLEVEL) \
	$(UVM_ARGS) \
	-do "run -all; quit -f" \
	| tee -a $(SIM_LOG) | tee -a $(TRANSCRIPT)

#-----------------------------------------------------------------------------
# Run simulation in GUI mode
#
# Automatically:
# 1. Opens Questa GUI
# 2. Adds all signals to Wave window
# 3. Runs simulation completely
# 4. Keeps GUI open for interactive waveform inspection
#-----------------------------------------------------------------------------
gui: comp
	@echo "[Running TESTNAME=$(TESTNAME) in Questa GUI...]" | tee $(SIM_LOG)
	@vsim -gui -voptargs=+acc -sv_lib $(UVM_DPI_LIB) $(WORKLIB).$(TOPLEVEL) \
	$(UVM_ARGS) \
	-do "add wave -position insertpoint sim:/tb_top/apb_vif/*; add wave -position insertpoint sim:/tb_top/u_dut/*; run -all"

#-----------------------------------------------------------------------------
# Run GUI mode and automatically quit after the test runs
#-----------------------------------------------------------------------------
gui_run: comp
	@echo "[Running TESTNAME=$(TESTNAME) in GUI mode and quitting automatically...]" | tee $(SIM_LOG)
	@vsim -gui -voptargs=+acc -sv_lib $(UVM_DPI_LIB) $(WORKLIB).$(TOPLEVEL) \
	$(UVM_ARGS) \
	-do "add wave -r /*; run -all; quit -f"

#-----------------------------------------------------------------------------
# Clean simulation files
#-----------------------------------------------------------------------------
clean:
	@echo "[Cleaning simulation files...]"
	@rm -rf $(WORKLIB)
	@rm -f modelsim.ini $(TRANSCRIPT) tr_db.log vsim.wlf $(COMP_LOG) sim_*.log
	@echo "[Clean complete]"