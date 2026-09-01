//-----------------------------------------------------------------------------
// UVM package for the cmsdk_apb_watchdog basic testbench.
//
// Two-agent architecture (as discussed/agreed):
//   wdog_apb_agent    -- active, drives+monitors the APB register interface
//   wdog_domain_agent -- active, drives WDOGCLKEN/WDOGRESn (WDOGCLK itself
//                         is free-running, generated in tb_top), monitors
//                         WDOGINT/WDOGRES every WDOGCLK edge
//   wdog_scoreboard    -- reference model (reactive register file + a live,
//                          WDOGCLK-ticking counter model) and comparison
//                          logic, fed by both agents' analysis ports
//-----------------------------------------------------------------------------
package wdog_pkg;

  import uvm_pkg::*;
  import watchdog_ral::*;
  `include "uvm_macros.svh"

  // Register word addresses (PADDR[11:2]) -- derived from
  // cmsdk_apb_watchdog_defs.v's address-decode macros, byte address >> 2.
  localparam bit [9:0] WDOG_LOAD    = 10'h000;
  localparam bit [9:0] WDOG_VALUE   = 10'h001;
  localparam bit [9:0] WDOG_CONTROL = 10'h002;
  localparam bit [9:0] WDOG_INTCLR  = 10'h003;
  localparam bit [9:0] WDOG_RIS     = 10'h004;
  localparam bit [9:0] WDOG_MIS     = 10'h005;
  localparam bit [9:0] WDOG_LOCK    = 10'h300;
  localparam bit [9:0] WDOG_ITCR    = 10'h3C0;
  localparam bit [9:0] WDOG_ITOP    = 10'h3C1;
  localparam bit [9:0] WDOG_PID4    = 10'h3F4;
  localparam bit [9:0] WDOG_PID5    = 10'h3F5;
  localparam bit [9:0] WDOG_PID6    = 10'h3F6;
  localparam bit [9:0] WDOG_PID7    = 10'h3F7;
  localparam bit [9:0] WDOG_PID0    = 10'h3F8;
  localparam bit [9:0] WDOG_PID1    = 10'h3F9;
  localparam bit [9:0] WDOG_PID2    = 10'h3FA;
  localparam bit [9:0] WDOG_PID3    = 10'h3FB;
  localparam bit [9:0] WDOG_CID0    = 10'h3FC;
  localparam bit [9:0] WDOG_CID1    = 10'h3FD;
  localparam bit [9:0] WDOG_CID2    = 10'h3FE;
  localparam bit [9:0] WDOG_CID3    = 10'h3FF;

  `include "../agents/wdog_apb_agent/wdog_apb_item.svh"
  `include "../ral/wdog_apb_reg_adapter.svh"
  `include "../ral/wdog_apb_reg_predictor.svh"
  `include "../agents/wdog_apb_agent/wdog_apb_driver.svh"
  `include "../agents/wdog_apb_agent/wdog_apb_monitor.svh"
  `include "../agents/wdog_apb_agent/wdog_apb_sequencer.svh"
  `include "../agents/wdog_apb_agent/wdog_apb_agent.svh"

  `include "../agents/wdog_domain_agent/wdog_domain_item.svh"
  `include "../agents/wdog_domain_agent/wdog_domain_driver.svh"
  `include "../agents/wdog_domain_agent/wdog_domain_monitor.svh"
  `include "../agents/wdog_domain_agent/wdog_domain_sequencer.svh"
  `include "../agents/wdog_domain_agent/wdog_domain_agent.svh"

  `include "../env/wdog_scoreboard.svh"
  `include "../env/wdog_env.svh"

  // Separate sequence files: low-level APB helper + RAL-backed sequences.
  `include "../seqlib/wdog_base_seq.svh"
  `include "../seqlib/wdog_reg_base_seq.svh"
  `include "../seqlib/wdog_sanity_seq.svh"
  `include "../seqlib/wdog_reset_seq.svh"
  `include "../seqlib/wdog_lock_seq.svh"
  `include "../seqlib/wdog_load_control_seq.svh"
  `include "../seqlib/wdog_interrupt_flow_seq.svh"
  `include "../seqlib/wdog_value_seq.svh"
  `include "../seqlib/wdog_interrupt_status_seq.svh"

  // Separate test files for readability and industry-style organization.
  `include "../tests/wdog_base_test.svh"
  `include "../tests/wdog_sanity_test.svh"
  `include "../tests/wdog_reset_test.svh"
  `include "../tests/wdog_lock_test.svh"
  `include "../tests/wdog_load_control_test.svh"
  `include "../tests/wdog_interrupt_flow_test.svh"
  `include "../tests/wdog_value_test.svh"
  `include "../tests/wdog_interrupt_status_test.svh"

endpackage : wdog_pkg
