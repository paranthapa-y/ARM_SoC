class tracker_env extends uvm_env;

    `uvm_component_utils(tracker_env)

    ahb_monitor ahb_mon;
    ahb_logger  logger;
    apb_monitor apb_mon;
    axi_monitor axi_mon; 
    bit a;
    bit b;
    bit c;
    function new(string name="tracker_env",
                 uvm_component parent);

        super.new(name,parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

	if(!uvm_config_db #(bit)::get(this,"","a",a))
		`uvm_fatal(get_type_name(),"Error in getting a")

	if(!uvm_config_db #(bit)::get(this,"","b",b))
		`uvm_fatal(get_type_name(),"Error in getting b")
	if(!uvm_config_db #(bit)::get(this,"","c",c))
		`uvm_fatal(get_type_name(),"Error in getting c")
	if(a) begin
   	     ahb_mon = ahb_monitor::type_id::create("ahb_monitor",this);
     end

     if(b) begin
	    apb_mon = apb_monitor::type_id::create("apb_monitor",this);
	end
	if(c) begin
		axi_mon = axi_monitor::type_id::create("axi_monitor", this);
	end

        logger  = ahb_logger ::type_id::create("logger",this);

    endfunction


    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);
	if(a)
       		 ahb_mon.ap.connect(logger.analysis_export);

	if(b)
       		 apb_mon.ap.connect(logger.analysis_export);
    endfunction


    function void end_of_elaboration_phase(uvm_phase phase);
	    uvm_top.print_topology();
    endfunction


endclass
