//----------------------------------------------------------------------------- 
// WDOGVALUE counter sequence.
// Generates RAL writes to unlock, load, and enable the watchdog, then reads
// WDOGVALUE shortly after enable and again near timeout to observe countdown
// behavior and confirm the counter does not remain at its reset value.
//----------------------------------------------------------------------------- 
class wdog_value_seq extends wdog_reg_base_seq;
  `uvm_object_utils(wdog_value_seq)

  function new(string name = "wdog_value_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Checking WDOGVALUE behavior", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0001), .parent(this));

    #100ns;
    ral_model.WDOGVALUE.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGVALUE after enable = 0x%08h", rdata), UVM_LOW)

    if (rdata == 32'hFFFF_FFFF) begin
      `uvm_error(get_type_name(), "WDOGVALUE did not start decrementing after enable")
    end

    #3000ns;
    ral_model.WDOGVALUE.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGVALUE near timeout = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_value_seq
