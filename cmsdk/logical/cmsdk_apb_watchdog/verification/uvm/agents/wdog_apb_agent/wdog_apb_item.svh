//-----------------------------------------------------------------------------
// One APB register access (read or write) to cmsdk_apb_watchdog.
// `addr` is PADDR[11:2] (word address) to match the DUT port directly.
//-----------------------------------------------------------------------------
class wdog_apb_item extends uvm_sequence_item;

  rand bit         write;
  rand bit [11:2]  addr;
  rand bit [31:0]  wdata;
       bit [31:0]  rdata;   // filled in by the driver/monitor on reads

  `uvm_object_utils_begin(wdog_apb_item)
    `uvm_field_int(write, UVM_ALL_ON)
    `uvm_field_int(addr,  UVM_ALL_ON)
    `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "wdog_apb_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%0h wdata=0x%0h rdata=0x%0h",
                      write ? "WR" : "RD", {addr, 2'b00}, wdata, rdata);
  endfunction

endclass : wdog_apb_item
