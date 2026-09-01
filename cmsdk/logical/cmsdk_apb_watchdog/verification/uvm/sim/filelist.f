// DUT
+incdir+../../../verilog
../../../verilog/cmsdk_apb_watchdog_frc.v
../../../verilog/cmsdk_apb_watchdog.v

// Testbench (wdog_pkg.sv `includes the agents/env/seqlib/tests sources
// itself via relative paths, so only the interfaces + package + top need
// listing here)
../agents/wdog_apb_agent/wdog_apb_if.sv
../agents/wdog_domain_agent/wdog_domain_if.sv
../ral/watchdog_ral.sv
../pkg/wdog_pkg.sv
../tb/tb_top.sv
