class generic_transaction extends uvm_sequence_item;

typedef enum {I_BUS, D_BUS, S_BUS} bus_type_e;

bus_type_e bus;

time timestamp;

bit [31:0] address;

bit write;

bit [31:0] wdata;

bit [31:0] rdata;

bit [1:0] response;

bit [31:0] instruction;

`uvm_object_utils_begin(generic_transaction)

    `uvm_field_enum(bus_type_e,bus,UVM_ALL_ON)
    `uvm_field_int(timestamp,UVM_ALL_ON)
    `uvm_field_int(address,UVM_ALL_ON)
    `uvm_field_int(write,UVM_ALL_ON)
    `uvm_field_int(wdata,UVM_ALL_ON)
    `uvm_field_int(rdata,UVM_ALL_ON)
    `uvm_field_int(response,UVM_ALL_ON)
    `uvm_field_int(instruction,UVM_ALL_ON)

`uvm_object_utils_end

function new(string name="ahb_transaction");
    super.new(name);
endfunction

endclass
