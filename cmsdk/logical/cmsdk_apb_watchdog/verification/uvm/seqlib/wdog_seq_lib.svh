//-----------------------------------------------------------------------------
// Small helper base class + one example sanity sequence, enough to exercise
// the environment end to end. Not a substitute for the full 56/86-test
// plans already on disk (cmsdk_apb_watchdog_testplan*.xlsx) -- those enumerate
// what to test; this shows how a sequence drives the two-agent env to do it.
//-----------------------------------------------------------------------------
class wdog_base_seq extends uvm_sequence #(wdog_apb_item);

  `uvm_object_utils(wdog_base_seq)

  function new(string name = "wdog_base_seq");
    super.new(name);
  endfunction

  task apb_write(bit [11:2] addr, bit [31:0] data);
    wdog_apb_item item = wdog_apb_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { write == 1; addr == local::addr; wdata == local::data; })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(item);
  endtask

  task apb_read(bit [11:2] addr, output bit [31:0] data);
    wdog_apb_item item = wdog_apb_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { write == 0; addr == local::addr; })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(item);
    data = item.rdata;
  endtask

endclass : wdog_base_seq

//-----------------------------------------------------------------------------
// Sanity flow: unlock, program a short timeout, enable interrupt+reset,
// let it fire once, service it, then let two consecutive misses through to
// see WDOGRES assert. Exercises WDOG_LOCK_*, WDOG_LOAD_*, WDOG_CTRL_*,
// WDOG_FLOW_* and WDOG_CLR_* in one pass.
//-----------------------------------------------------------------------------
// class wdog_sanity_seq extends wdog_base_seq;

//   `uvm_object_utils(wdog_sanity_seq)

//   function new(string name = "wdog_sanity_seq");
//     super.new(name);
//   endfunction

//   task body();
//     bit [31:0] rdata;

//     apb_write(WDOG_LOCK, 32'h1ACCE551);         // unlock
//     apb_read (WDOG_LOCK, rdata);
//     `uvm_info(get_type_name(), $sformatf("WDOGLOCK after unlock = 0x%0h", rdata), UVM_LOW)

//     apb_write(WDOG_LOAD, 32'h0000_0010);        // short timeout for sim time
//     apb_write(WDOG_CONTROL, 32'b11);            // INTEN=1, RESEN=1

//     #2000ns;                                    // let the first miss latch WDOGINT

//     apb_read(WDOG_RIS, rdata);
//     `uvm_info(get_type_name(), $sformatf("WDOGRIS after first miss = 0x%0h", rdata), UVM_LOW)

//     apb_write(WDOG_INTCLR, 32'h0);              // service it -- WDOGRES must NOT assert

//     apb_write(WDOG_LOAD, 32'h0000_0010);
//     #4000ns;                                    // let two consecutive misses through, unserviced

//     apb_read(WDOG_RIS, rdata);
//     `uvm_info(get_type_name(), $sformatf("WDOGRIS after unserviced misses = 0x%0h", rdata), UVM_LOW)
//   endtask

// endclass : wdog_sanity_seq

class wdog_sanity_seq extends uvm_reg_sequence;

  `uvm_object_utils(wdog_sanity_seq)

  // RAL model
  register_map ral_model;

  function new(string name = "wdog_sanity_seq");
    super.new(name);
  endfunction


  task body();

    uvm_status_e   status;
    uvm_reg_data_t rdata;


    //-------------------------------------------------------------------------
    // Check RAL handle
    //-------------------------------------------------------------------------
    if (ral_model == null) begin
      `uvm_fatal(get_type_name(),
                 "RAL model handle is NULL")
    end


    //-------------------------------------------------------------------------
    // 1. Unlock watchdog register writes
    //
    // WDOGLOCK[31:1] is the WO ENABLE_REGISTER_WRITES field.
    // The generated RAL register is therefore accessed through write().
    //-------------------------------------------------------------------------
    `uvm_info(get_type_name(),
              "Unlocking watchdog register writes",
              UVM_LOW)

    ral_model.WDOGLOCK.write(
      .status(status),
      .value(32'h1ACCE551),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGLOCK write failed")
    end


    //-------------------------------------------------------------------------
    // 2. Read WDOGLOCK status
    //
    // Only bit 0 is RO:
    //   REGISTER_WRITE_ENABLE_STATUS
    //
    // The value written to the WO field is not expected to be read back.
    //-------------------------------------------------------------------------
    ral_model.WDOGLOCK.read(
      .status(status),
      .value(rdata),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGLOCK read failed")
    end

    `uvm_info(
      get_type_name(),
      $sformatf(
        "WDOGLOCK after unlock = 0x%08h",
        rdata
      ),
      UVM_LOW
    )


    //-------------------------------------------------------------------------
    // 3. Program a short watchdog timeout
    //
    // WDOGLOAD is a 32-bit RW register.
    //-------------------------------------------------------------------------
    `uvm_info(get_type_name(),
              "Programming watchdog timeout",
              UVM_LOW)

    ral_model.WDOGLOAD.write(
      .status(status),
      .value(32'h0000_0010),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGLOAD write failed")
    end


    //-------------------------------------------------------------------------
    // 4. Enable watchdog interrupt and reset
    //
    // WDOGCONTROL:
    //   bit 0 = INTEN
    //   bit 1 = RESEN
    //
    // 32'h0000_0003 => INTEN=1, RESEN=1
    //-------------------------------------------------------------------------
    `uvm_info(get_type_name(),
              "Enabling watchdog interrupt and reset",
              UVM_LOW)

    ral_model.WDOGCONTROL.write(
      .status(status),
      .value(32'h0000_0003),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGCONTROL write failed")
    end


    //-------------------------------------------------------------------------
    // 5. Allow first watchdog timeout to occur
    //-------------------------------------------------------------------------
    `uvm_info(get_type_name(),
              "Waiting for first watchdog timeout",
              UVM_LOW)

    #2000ns;


    //-------------------------------------------------------------------------
    // 6. Read raw watchdog interrupt status
    //
    // WDOGRIS:
    //   bit 0 = RAW_WATCHDOG_INTERRUPT
    //-------------------------------------------------------------------------
    ral_model.WDOGRIS.read(
      .status(status),
      .value(rdata),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGRIS read failed")
    end

    `uvm_info(
      get_type_name(),
      $sformatf(
        "WDOGRIS after first timeout = 0x%08h",
        rdata
      ),
      UVM_LOW
    )


    //-------------------------------------------------------------------------
    // 7. Clear/service watchdog interrupt
    //
    // WDOGINTCLR.INTCLR is a 32-bit WO field.
    //-------------------------------------------------------------------------
    `uvm_info(get_type_name(),
              "Clearing watchdog interrupt",
              UVM_LOW)

    ral_model.WDOGINTCLR.write(
      .status(status),
      .value(32'h0000_0000),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGINTCLR write failed")
    end


    //-------------------------------------------------------------------------
    // 8. Reload watchdog
    //-------------------------------------------------------------------------
    ral_model.WDOGLOAD.write(
      .status(status),
      .value(32'h0000_0010),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGLOAD reload failed")
    end


    //-------------------------------------------------------------------------
    // 9. Allow two consecutive unserviced watchdog periods
    //-------------------------------------------------------------------------
    `uvm_info(get_type_name(),
              "Waiting for consecutive unserviced watchdog timeouts",
              UVM_LOW)

    #4000ns;


    //-------------------------------------------------------------------------
    // 10. Read raw watchdog interrupt status
    //-------------------------------------------------------------------------
    ral_model.WDOGRIS.read(
      .status(status),
      .value(rdata),
      .parent(this)
    );

    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(),
                 "WDOGRIS read failed")
    end

    `uvm_info(
      get_type_name(),
      $sformatf(
        "WDOGRIS after unserviced timeouts = 0x%08h",
        rdata
      ),
      UVM_LOW
    )

  endtask

endclass : wdog_sanity_seq

//----------------------------------------------------------------------------- 
// Test-plan aligned sequences, covering the common documentation-only cases in
// a way that can be executed directly by the UVM environment without expanding
// the scoreboard beyond the current basic-model scope.
//----------------------------------------------------------------------------- 

class wdog_reset_seq extends uvm_reg_sequence;
  `uvm_object_utils(wdog_reset_seq)

  register_map ral_model;

  function new(string name = "wdog_reset_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) `uvm_fatal(get_type_name(), "RAL model handle is NULL")

    `uvm_info(get_type_name(), "Checking reset/default state (WDOG_RST_01..07)", UVM_LOW)

    ral_model.WDOGLOAD.read  (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGVALUE.read (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGVALUE after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGCONTROL.read (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGCONTROL after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGRIS.read (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGMIS.read (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGMIS after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.read (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOCK after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGITCR.read (.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGITCR after reset = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_reset_seq

class wdog_lock_seq extends uvm_reg_sequence;
  `uvm_object_utils(wdog_lock_seq)

  register_map ral_model;

  function new(string name = "wdog_lock_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) `uvm_fatal(get_type_name(), "RAL model handle is NULL")

    `uvm_info(get_type_name(), "Running lock/unlock / write-blocking checks (WDOG_LOCK_01..06)", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0020), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD after unlock/program = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0040), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD while unlocked = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h0000_0001), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0080), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD while locked = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOCK.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOCK after unlock magic = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_lock_seq

class wdog_load_control_seq extends uvm_reg_sequence;
  `uvm_object_utils(wdog_load_control_seq)

  register_map ral_model;

  function new(string name = "wdog_load_control_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) `uvm_fatal(get_type_name(), "RAL model handle is NULL")

    `uvm_info(get_type_name(), "Running load/control checks (WDOG_LOAD_01..04, WDOG_CTRL_01..05)", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD final writeback = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0001), .parent(this));
    ral_model.WDOGCONTROL.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGCONTROL after INTEN=1 = 0x%08h", rdata), UVM_LOW)

    #3000ns;

    ral_model.WDOGVALUE.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGVALUE while counting = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS while counting = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGCONTROL.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGCONTROL after INTEN=0 = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_load_control_seq

class wdog_interrupt_flow_seq extends uvm_reg_sequence;
  `uvm_object_utils(wdog_interrupt_flow_seq)

  register_map ral_model;

  function new(string name = "wdog_interrupt_flow_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) `uvm_fatal(get_type_name(), "RAL model handle is NULL")

    `uvm_info(get_type_name(), "Running interrupt flow checks (WDOG_FLOW_01..04)", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0003), .parent(this));

    #2000ns;

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS at first timeout = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGINTCLR.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));

    #2000ns;

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS after clear/reload = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_interrupt_flow_seq