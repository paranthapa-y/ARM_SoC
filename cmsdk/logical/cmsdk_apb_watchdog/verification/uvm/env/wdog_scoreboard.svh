`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_wdog)

//-----------------------------------------------------------------------------
// Reference model + scoreboard, in one component (basic-TB scope -- a larger
// environment would split these, but the model is small enough that keeping
// it together avoids a needless extra class for now).
//
// Two independently-fed analysis ports, matching the two-agent plan:
//   apb_imp  <- wdog_apb_agent.monitor    (register writes/reads, PCLK)
//   wdog_imp <- wdog_domain_agent.monitor (one snapshot per WDOGCLK edge)
//
// The register-file half of the model (m_load/m_inten/m_resen/m_locked/
// m_itcr/m_itop) is purely reactive to APB writes -- a snapshot is enough.
// The counter half (m_value/m_ris/m_res_model) is TIME-EVOLVING: it must
// tick forward on every WDOGCLK edge alongside the DUT, independent of
// whether an APB access ever occurs, or it cannot predict WDOGVALUE/
// WDOGINT/WDOGRES at all. This is the live-vs-reactive distinction from
// the architecture discussion that motivated building an RM here instead
// of relying on assertions alone for these three registers.
//
// CDC-latency handling: an APB write to WDOGLOAD/WDOGCONTROL/WDOGINTCLR
// takes a few WDOGCLK edges to actually reach the counter in the DUT (the
// toggle-synchronizer handshake in cmsdk_apb_watchdog_frc.v). Rather than
// requiring the model and DUT to match on the very next edge (the
// same-$time anti-pattern), a short SETTLE_WINDOW of WDOGCLK ticks after
// such a write downgrades a mismatch to an informational message instead
// of a hard error, then reverts to strict checking once the window closes.
//
// Known residual (basic-TB scope, not pursued further): the window only
// covers "model already updated, DUT hasn't caught up yet." On rare tick/
// transaction phase alignments the opposite can happen right at a write's
// own transaction boundary -- the DUT's toggle-sync happens to resolve
// before this write's own analysis-port event has even been processed by
// apb_write() -- producing a single-tick false mismatch. Confirmed by
// hand-tracing against the sanity sequence: fixing it generally would need
// timestamp-ordering the two analysis streams against each other, which
// is more machinery than a basic TB warrants for one borderline tick.
//-----------------------------------------------------------------------------
class wdog_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(wdog_scoreboard)

  uvm_analysis_imp_apb  #(wdog_apb_item,    wdog_scoreboard) apb_imp;
  uvm_analysis_imp_wdog #(wdog_domain_item, wdog_scoreboard) wdog_imp;

  // ---- Register file (PCLK-domain, reactive) ----
  bit [31:0] m_load      = 32'hFFFFFFFF;
  bit        m_inten     = 1'b0;
  bit        m_resen     = 1'b0;
  bit        m_locked    = 1'b0;
  bit        m_itcr      = 1'b0;
  bit [1:0]  m_itop      = 2'b00;
  bit [3:0]  m_ecorevnum = 4'h0;

  // ---- Counter model (WDOGCLK-domain, live) ----
  bit [31:0] m_value     = 32'hFFFFFFFF;
  bit        m_ris       = 1'b0;
  bit        m_res_model = 1'b0;
  // "carry" = counter read zero as of the END of the PREVIOUS tick --
  // mirrors carry_msb (reg_carry[1]) in the RTL, which is itself a
  // registered signal one tick behind the value hitting zero. wdog_ris
  // and i_wdog_res are both driven from the OLD (pre-this-edge) carry and
  // OLD wdog_ris, not the freshly-computed ones -- collapsing that into
  // the same tick (an earlier version of this model did) makes every
  // state transition land one tick early relative to the DUT.
  bit        m_carry     = 1'b0;

  int unsigned m_settle_ticks = 0;
  localparam int unsigned SETTLE_WINDOW = 6;

  int unsigned m_pass_count = 0;
  int unsigned m_fail_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_imp  = new("apb_imp",  this);
    wdog_imp = new("wdog_imp", this);
  endfunction

  //---------------------------------------------------------------------
  // APB side: update the register-file model on writes, check predicted
  // read data on reads.
  //---------------------------------------------------------------------
  function void write_apb(wdog_apb_item item);
    if (item.write) apb_write(item);
    else             apb_read_check(item);
  endfunction

  function void apb_write(wdog_apb_item item);
    case (item.addr)
      WDOG_LOAD: begin
        if (!m_locked) begin
          m_load  = item.wdata;
          m_value = item.wdata;          // TRM: write reloads the counter immediately
          m_settle_ticks = SETTLE_WINDOW;
        end
      end
      WDOG_CONTROL: begin
        if (!m_locked) begin
          bit new_inten = item.wdata[0];
          if (new_inten && !m_inten) begin
            m_value = m_load;            // 0->1 INTEN reloads from WDOGLOAD (WDOG_CTRL_02)
            m_settle_ticks = SETTLE_WINDOW;
          end
          m_inten = new_inten;
          m_resen = item.wdata[1];
          if (!m_resen)
            m_res_model = 1'b0;          // RESEN=0 masks/clears WDOGRES (RTL: ~wdog_res_en term)
        end
      end
      WDOG_INTCLR: begin
        if (!m_locked) begin
          m_ris   = 1'b0;
          m_carry = 1'b0;
          m_value = m_load;
          m_settle_ticks = SETTLE_WINDOW;
          // NOTE: does NOT clear m_res_model. TRM never documents how a
          // latched WDOGRES condition clears (GAP-10 in the doc-only
          // plan); the RTL only clears it via RESEN=0 or WDOGRESn, never
          // via WDOGINTCLR, so the model follows that.
        end
      end
      WDOG_LOCK: begin
        // Never gated by wdog_locked itself -- otherwise there would be no
        // way to unlock (see GAP-9 in the doc-only plan).
        m_locked = (item.wdata == 32'h1ACCE551) ? 1'b0 : 1'b1;
      end
      WDOG_ITCR: if (!m_locked) m_itcr = item.wdata[0];
      WDOG_ITOP: if (!m_locked) m_itop = item.wdata[1:0];
      default: ; // reserved / read-only regions -- writes have no effect
    endcase
  endfunction

  function void apb_read_check(wdog_apb_item item);
    bit [31:0] expected;
    bit        skip = 1'b0;
    bit        settling = (m_settle_ticks > 0);

    case (item.addr)
      WDOG_LOAD:    expected = m_load;
      WDOG_VALUE:   expected = m_value;
      WDOG_CONTROL: expected = {30'b0, m_resen, m_inten};
      WDOG_RIS:     expected = {31'b0, m_ris};
      WDOG_MIS:     expected = {31'b0, (m_ris & m_inten)};
      WDOG_LOCK:    expected = {31'b0, m_locked};
      WDOG_ITCR:    expected = {31'b0, m_itcr};
      WDOG_PID0:    expected = 32'h00000024;
      WDOG_PID1:    expected = 32'h000000B8;
      WDOG_PID2:    expected = 32'h0000001B;
      WDOG_PID3:    expected = {24'b0, m_ecorevnum, 4'h0};
      WDOG_PID4:    expected = 32'h00000004;
      WDOG_PID5:    expected = 32'h00000000;
      WDOG_PID6:    expected = 32'h00000000;
      WDOG_PID7:    expected = 32'h00000000;
      WDOG_CID0:    expected = 32'h0000000D;
      WDOG_CID1:    expected = 32'h000000F0;
      WDOG_CID2:    expected = 32'h00000005;
      WDOG_CID3:    expected = 32'h000000B1;
      default:      skip = 1'b1; // WDOGINTCLR read value undocumented (GAP-2); WDOGITOP is WO
    endcase

    if (skip) return;

    if (item.rdata === expected) begin
      m_pass_count++;
      `uvm_info("SB_APB", $sformatf("PASS addr=0x%0h %s", {item.addr,2'b00}, item.convert2string()), UVM_HIGH)
    end else if (settling) begin
      `uvm_info("SB_SETTLE", $sformatf("addr=0x%0h expected=0x%0h got=0x%0h -- inside CDC settle window, not scored",
                 {item.addr,2'b00}, expected, item.rdata), UVM_MEDIUM)
    end else begin
      m_fail_count++;
      `uvm_error("SB_APB", $sformatf("MISMATCH addr=0x%0h expected=0x%0h got=0x%0h",
                 {item.addr,2'b00}, expected, item.rdata))
    end
  endfunction

  //---------------------------------------------------------------------
  // WDOGCLK side: advance the live counter model one tick, then check the
  // DUT's WDOGINT/WDOGRES against it.
  //---------------------------------------------------------------------
  function void write_wdog(wdog_domain_item item);
    bit exp_int, exp_res;
    bit settling;

    m_ecorevnum = item.ecorevnum;

    if (!item.wdogresn) begin
      // WDOGRESn is its own async-reset domain: it resets the counter and
      // the interrupt/reset latches, but NOT WDOGLOAD/WDOGCONTROL/WDOGLOCK
      // (those live in the PRESETn/PCLK domain -- RTL-confirmed).
      m_value     = 32'hFFFFFFFF;
      m_ris       = 1'b0;
      m_res_model = 1'b0;
      m_carry     = 1'b0;
      m_settle_ticks = 0;
      return;
    end

    if (m_settle_ticks > 0) m_settle_ticks--;
    settling = (m_settle_ticks > 0);

    if (item.wdogclken && !m_itcr) begin
      // wdog_ris/i_wdog_res both latch from the OLD (pre-this-tick) carry
      // and OLD wdog_ris together -- NOT the carry this same tick just
      // produced. Concretely: tick where the counter reads zero -> m_carry
      // goes high; NEXT tick, that now-old m_carry sets m_ris; the tick
      // AFTER that, old_carry(0, already consumed) means no res yet -- res
      // only fires when a SECOND zero-crossing's old_carry lines up with
      // old_ris already being 1, i.e. two consecutive unserviced misses
      // (TRM Figure 4-15, not the looser opening-prose reading -- GAP-1).
      // Hand-verified against the simulated waveform: this staged version
      // lands wdog_ris/i_wdog_res transitions at the same simulated
      // instants as the DUT; an earlier version that latched everything
      // in the same tick the counter reached zero was one tick early on
      // every transition.
      bit old_carry = m_carry;
      bit old_ris   = m_ris;

      m_ris = old_carry | old_ris;
      if (old_carry && old_ris && m_resen) m_res_model = 1'b1;
      if (!m_resen) m_res_model = 1'b0;

      // Once WDOGRES has latched, the counter freezes at its reload value
      // and never resumes -- RTL: count_stop is forced by i_wdog_res and
      // takes priority over load_req_w, so even a fresh WDOGLOAD write
      // cannot restart it. Only RESEN->0 or WDOGRESn clears i_wdog_res
      // (and so m_res_model above), which is also the only thing that
      // un-freezes this. In a real system WDOGRES is wired to the system
      // reset generator (TRM 4.7.2), so in practice the watchdog expects
      // the ensuing system reset to be what clears it, not further
      // software register writes -- see GAP-10.
      if (m_inten && !m_res_model) begin
        if (m_value == 32'h0) begin
          m_value = m_load;
          m_carry = 1'b1;
        end else begin
          m_value = m_value - 1'b1;
          m_carry = 1'b0;
        end
      end

      exp_int = m_ris & m_inten;
      exp_res = m_res_model;

      if (item.wdogint === exp_int && item.wdogres === exp_res) begin
        m_pass_count++;
      end else if (settling) begin
        `uvm_info("SB_SETTLE", $sformatf("wdog tick: expected int=%0b res=%0b got %s -- inside CDC settle window",
                   exp_int, exp_res, item.convert2string()), UVM_MEDIUM)
      end else begin
        m_fail_count++;
        `uvm_error("SB_WDOG", $sformatf("wdog tick MISMATCH: expected int=%0b res=%0b got %s",
                   exp_int, exp_res, item.convert2string()))
      end
    end else if (item.wdogclken && m_itcr) begin
      // Integration test mode: outputs are forced by WDOGITOP, the counter
      // is not driving them -- checked structurally (assertion-style),
      // independent of the live counter model above.
      exp_int = m_itop[1];
      exp_res = m_itop[0];
      if (item.wdogint === exp_int && item.wdogres === exp_res) begin
        m_pass_count++;
      end else begin
        m_fail_count++;
        `uvm_error("SB_ITCR", $sformatf("integration-test-mode MISMATCH: expected int=%0b res=%0b got %s",
                   exp_int, exp_res, item.convert2string()))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB_SUMMARY", $sformatf("scoreboard checks: %0d passed, %0d failed",
               m_pass_count, m_fail_count), UVM_LOW)
  endfunction

endclass : wdog_scoreboard
