//----------------------------------------------------------------------------- 
// Base class for RAL-driven sequences.
// Derived sequences use ral_model register read/write APIs; RAL converts those
// operations into APB items through the environment's register adapter.
// This class only validates that the RAL handle is supplied; it generates no
// stimulus by itself.
//----------------------------------------------------------------------------- 
class wdog_reg_base_seq extends uvm_reg_sequence;

  `uvm_object_utils(wdog_reg_base_seq)

  register_map ral_model;

  function new(string name = "wdog_reg_base_seq");
    super.new(name);
  endfunction

  task body();
    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end
  endtask

endclass : wdog_reg_base_seq
