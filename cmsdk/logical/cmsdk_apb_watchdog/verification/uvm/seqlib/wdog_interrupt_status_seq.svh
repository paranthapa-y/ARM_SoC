//----------------------------------------------------------------------------- 
// WDOGRIS / WDOGMIS interrupt-status sequence.
// Generates RAL writes to unlock, load, and enable watchdog interrupts, waits
// for timeout, then reads both raw and masked interrupt-status registers to
// confirm that the timeout is reported and visible when INTEN is enabled.
//----------------------------------------------------------------------------- 
class wdog_interrupt_status_seq extends wdog_reg_base_seq;
  `uvm_object_utils(wdog_interrupt_status_seq)

  function new(string name = "wdog_interrupt_status_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t ris;
    uvm_reg_data_t mis;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Checking WDOGRIS / WDOGMIS interrupt status", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0001), .parent(this));

    #3000ns;

    ral_model.WDOGRIS.read(.status(status), .value(ris), .parent(this));
    ral_model.WDOGMIS.read(.status(status), .value(mis), .parent(this));

    `uvm_info(get_type_name(), $sformatf("WDOGRIS = 0x%08h", ris), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("WDOGMIS = 0x%08h", mis), UVM_LOW)

    if (ris == 0) begin
      `uvm_error(get_type_name(), "WDOGRIS did not assert after watchdog timeout")
    end

    if (mis == 0) begin
      `uvm_error(get_type_name(), "WDOGMIS did not assert when INTEN=1")
    end
  endtask
endclass : wdog_interrupt_status_seq
