//-----------------------------------------------------------------------------
// Standalone UVM testbench top for cmsdk_apb_watchdog. Generates PCLK and a
// WDOGCLK synchronous to it (divide-by-2, per TRM Table 4-24 / WDOG_SIG_01 --
// "WDOGCLK is synchronous to PCLK"), instantiates the DUT and both agent
// interfaces, and hands their virtual interfaces to the UVM env via
// config_db before calling run_test().
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import wdog_pkg::*;

module tb_top;

  bit PCLK;
  bit WDOGCLK;

  initial PCLK = 1'b0;
  always #5 PCLK = ~PCLK;          // 100 MHz

  // WDOGCLK: same 20ns period as a PCLK divide-by-2 (still "synchronous to
  // PCLK" per TRM Table 4-24 / WDOG_SIG_01), but generated as its own
  // free-running clock with a phase offset rather than toggled inside
  // PCLK's own `always @(posedge PCLK)` block. Chaining WDOGCLK's edge off
  // a PCLK-triggered NBA put both stages of the DUT's toggle
  // synchronizers (load_req_tog_p/w, int_clr_tog_p/w) in the same delta
  // region on some edges, letting a synchronizer settle in zero real
  // cycles instead of one -- the sync pulse it depends on (e.g.
  // int_clr_pulse for WDOGINTCLR) then never appears, so a serviced
  // interrupt silently never clears. Found by hitting exactly that while
  // bringing the sanity sequence up.
  initial WDOGCLK = 1'b0;
  initial #3 forever #10 WDOGCLK = ~WDOGCLK;

  wdog_apb_if    apb_vif (.PCLK(PCLK));
  wdog_domain_if wdog_vif(.WDOGCLK(WDOGCLK));

  cmsdk_apb_watchdog u_dut (
    .PCLK      (PCLK),
    .PRESETn   (apb_vif.PRESETn),
    .PENABLE   (apb_vif.PENABLE),
    .PSEL      (apb_vif.PSEL),
    .PADDR     (apb_vif.PADDR),
    .PWRITE    (apb_vif.PWRITE),
    .PWDATA    (apb_vif.PWDATA),

    .WDOGCLK   (WDOGCLK),
    .WDOGCLKEN (wdog_vif.WDOGCLKEN),
    .WDOGRESn  (wdog_vif.WDOGRESn),

    .ECOREVNUM (wdog_vif.ECOREVNUM),

    .PRDATA    (apb_vif.PRDATA),

    .WDOGINT   (wdog_vif.WDOGINT),
    .WDOGRES   (wdog_vif.WDOGRES)
  );

  initial begin
    uvm_config_db#(virtual wdog_apb_if.DRIVER)::set(null, "*", "vif", apb_vif);
    uvm_config_db#(virtual wdog_apb_if.MONITOR)::set(null, "*", "vif", apb_vif);
    uvm_config_db#(virtual wdog_domain_if.DRIVER)::set(null, "*", "vif", wdog_vif);
    uvm_config_db#(virtual wdog_domain_if.MONITOR)::set(null, "*", "vif", wdog_vif);
    run_test();
  end

  // Simulation watchdog (for the testbench, not the DUT) so a stuck
  // sequence/objection doesn't hang the run indefinitely.
  initial begin
    #100us;
    `uvm_fatal("TB_TIMEOUT", "simulation exceeded 100us without finishing")
  end

endmodule : tb_top
