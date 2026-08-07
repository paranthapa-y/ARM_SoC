class generic_monitor extends uvm_monitor;

    `uvm_component_utils(generic_monitor)

    // Analysis port used by all derived monitors
    uvm_analysis_port #(generic_transaction) ap;

    // Constructor
    function new(string name = "generic_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);
    endfunction

endclass
