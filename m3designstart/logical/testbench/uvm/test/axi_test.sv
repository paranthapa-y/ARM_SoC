class axi_test extends base_test;

    `uvm_component_utils(axi_test)

    tracker_env env;

    function new(string name="apb_test",
                 uvm_component parent);

        super.new(name,parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

	uvm_config_db#(bit)::set(this,"*","a",0);
	uvm_config_db#(bit)::set(this,"*","b",0);
	uvm_config_db#(bit)::set(this,"*","c",1);

    endfunction

endclass
