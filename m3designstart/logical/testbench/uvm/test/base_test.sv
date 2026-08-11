class base_test extends uvm_test;

    `uvm_component_utils(base_test)

    tracker_env env;

    function new(string name="base_test",
                 uvm_component parent);

        super.new(name,parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

	uvm_config_db#(bit)::set(this,"*","a",1);
	uvm_config_db#(bit)::set(this,"*","b",0);
        env = tracker_env::type_id::create("env",this);

    endfunction

    task run_phase(uvm_phase phase);

	    phase.raise_objection(this);
    endtask
endclass
