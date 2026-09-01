class wdog_apb_reg_adapter extends uvm_reg_adapter;

  `uvm_object_utils(wdog_apb_reg_adapter)

  function new(string name = "wdog_apb_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    wdog_apb_item item = wdog_apb_item::type_id::create("item");

    item.write = (rw.kind == UVM_WRITE);
    item.addr = rw.addr >> 2;
    item.wdata = rw.data;
    return item;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);
    wdog_apb_item item;

    if (!$cast(item, bus_item)) begin
      `uvm_fatal("WDOG_APB_ADAPTER",
                 "bus2reg received an item of the wrong type")
    end

    rw.kind = item.write ? UVM_WRITE : UVM_READ;
    rw.addr = item.addr << 2;
    rw.data = item.write ? item.wdata : item.rdata;
    rw.status = UVM_IS_OK;
  endfunction

endclass : wdog_apb_reg_adapter