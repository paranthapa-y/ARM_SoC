class apb_monitor extends generic_monitor;

    `uvm_component_utils(apb_monitor)

    //------------------------------------------------------------
    // Virtual Interface
    //------------------------------------------------------------
    virtual apb_if vif;


    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------
    function new(string name="apb_monitor",
                 uvm_component parent);
        super.new(name,parent);
	$display("[%0t] APB_MONITOR CREATED", $time);
    endfunction


    //------------------------------------------------------------
    // Build Phase
    //------------------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual apb_if)::get(this,"","apb_vif",vif))
            `uvm_fatal("NOVIF","Cannot get apb_if");

    endfunction


    //------------------------------------------------------------
    // Run Phase
    //------------------------------------------------------------
    task run_phase(uvm_phase phase);

        fork
            monitor_i_bus();
            monitor_d_bus();
            monitor_s_bus();
        join

    endtask


    //------------------------------------------------------------
    // Common Transaction Creator
    //------------------------------------------------------------
    function automatic generic_transaction create_transaction(
        generic_transaction::bus_type_e bus,
        logic [31:0] addr,
        logic [1:0]  resp
    );

        generic_transaction tr;

        tr = generic_transaction::type_id::create("tr");

        tr.timestamp = $time;
        tr.bus       = bus;
        tr.address   = addr;
        tr.response  = resp;

        return tr;

    endfunction


    //------------------------------------------------------------
    // Instruction Bus
    //------------------------------------------------------------
    task monitor_i_bus();

        generic_transaction tr;

        forever begin

            @(posedge vif.PCLK);

            if(vif.i_psel &&
               vif.i_penable &&
               vif.i_pready) begin

                tr = create_transaction(
                        generic_transaction::I_BUS,
                        vif.i_paddr,
                        {1'b0,vif.i_pslverr});

                tr.write = vif.i_pwrite;

                if(vif.i_pwrite)
                    tr.wdata = vif.i_pwdata;
                else begin
                    tr.rdata       = vif.i_prdata;
                    tr.instruction = vif.i_prdata;
                end

                ap.write(tr);

            end

        end

    endtask


    //------------------------------------------------------------
    // Data Bus
    //------------------------------------------------------------
    task monitor_d_bus();

        generic_transaction tr;

        forever begin

            @(posedge vif.PCLK);

            if(vif.d_psel &&
               vif.d_penable &&
               vif.d_pready) begin

                tr = create_transaction(
                        generic_transaction::D_BUS,
                        vif.d_paddr,
                        {1'b0,vif.d_pslverr});

                tr.write = vif.d_pwrite;

                if(vif.d_pwrite)
                    tr.wdata = vif.d_pwdata;
                else
                    tr.rdata = vif.d_prdata;

                ap.write(tr);

            end

        end

    endtask


    //------------------------------------------------------------
    // System Bus
    //------------------------------------------------------------
    task monitor_s_bus();

        generic_transaction tr;

        forever begin

            @(posedge vif.PCLK);

            if(vif.s_psel &&
               vif.s_penable &&
               vif.s_pready) begin

                tr = create_transaction(
                        generic_transaction::S_BUS,
                        vif.s_paddr,
                        {1'b0,vif.s_pslverr});

                tr.write = vif.s_pwrite;

                if(vif.s_pwrite)
                    tr.wdata = vif.s_pwdata;
                else
                    tr.rdata = vif.s_prdata;

                ap.write(tr);

            end

        end

    endtask

endclass
