class apb_test extends base_test;

    `uvm_component_utils(apb_test)

   

    function new(string name="apb_test",
                 uvm_component parent);

        super.new(name,parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

	uvm_config_db#(bit)::set(this,"*","a",0);
	uvm_config_db#(bit)::set(this,"*","b",1);
	uvm_config_db#(bit)::set(this,"*","c",0);

    endfunction

endclass
