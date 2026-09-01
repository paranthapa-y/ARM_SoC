//----------------------------------------------------------------------------- 
// Base sequence for direct APB stimulus.
// apb_write() generates one APB write item with a constrained address and data.
// apb_read() generates one APB read item and returns the sampled read data.
// Use this class when a scenario needs bus transactions without RAL.
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
