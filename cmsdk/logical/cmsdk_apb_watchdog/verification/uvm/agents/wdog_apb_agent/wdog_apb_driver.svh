//-----------------------------------------------------------------------------
// Drives basic APB3 SETUP/ACCESS transfers (no PSTRB/PREADY/PSLVERR on this
// slave -- see TRM Figure 4-14, confirmed against the RTL port list).
// Also owns PRESETn: it is idle-high, driven low only by the reset task
// invoked from the test/sequence at the start of a run.
//-----------------------------------------------------------------------------
class wdog_apb_driver extends uvm_driver #(wdog_apb_item);

  `uvm_component_utils(wdog_apb_driver)

  virtual wdog_apb_if.DRIVER vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wdog_apb_if.DRIVER)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wdog_apb_driver: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.PRESETn <= 1'b1;
    vif.drv_cb.PSEL    <= 1'b0;
    vif.drv_cb.PENABLE <= 1'b0;
    vif.drv_cb.PWRITE  <= 1'b0;
    vif.drv_cb.PADDR   <= '0;
    vif.drv_cb.PWDATA  <= '0;

    do_reset();

    forever begin
      wdog_apb_item item;
      seq_item_port.get_next_item(item);
      drive_item(item);
      seq_item_port.item_done(item);
    end
  endtask

  // SETUP phase (PENABLE=0) then ACCESS phase (PENABLE=1), one PCLK each --
  // the minimum legal APB transfer since this slave never asserts PREADY.
  task drive_item(wdog_apb_item item);
    @(vif.drv_cb);
    vif.drv_cb.PSEL    <= 1'b1;
    vif.drv_cb.PENABLE <= 1'b0;
    vif.drv_cb.PWRITE  <= item.write;
    vif.drv_cb.PADDR   <= item.addr;
    vif.drv_cb.PWDATA  <= item.write ? item.wdata : '0;

    @(vif.drv_cb);
    vif.drv_cb.PENABLE <= 1'b1;

    @(vif.drv_cb);
    if (!item.write)
      item.rdata = vif.drv_cb.PRDATA;

    vif.drv_cb.PSEL    <= 1'b0;
    vif.drv_cb.PENABLE <= 1'b0;
  endtask

  // Active-low PRESETn pulse. Runs automatically once at the start of
  // run_phase; also callable again mid-test (e.g. from a reset sequence)
  // via the agent/driver handle for WDOG_RST-style tests.
  task do_reset(int unsigned cycles = 4);
    vif.drv_cb.PRESETn <= 1'b0;
    repeat (cycles) @(vif.drv_cb);
    vif.drv_cb.PRESETn <= 1'b1;
    @(vif.drv_cb);
  endtask

endclass : wdog_apb_driver
