class ahb_monitor extends generic_monitor;

    `uvm_component_utils(ahb_monitor)

    //------------------------------------------------------------
    // Virtual Interface
    //------------------------------------------------------------
    virtual ahb_if vif;

   
    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------
    function new(string name="ahb_monitor",
                 uvm_component parent);
        super.new(name,parent);
    endfunction


    //------------------------------------------------------------
    // Build Phase
    //------------------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);
        if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",vif))
            `uvm_fatal("NOVIF","Cannot get ahb_if");

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
        logic [1:0] resp
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
//------------------------------------------------------------
// Instruction Bus
//------------------------------------------------------------
task monitor_i_bus();

    generic_transaction pending_q[$];
    generic_transaction tr;

    forever begin

        @(posedge vif.HCLK);

        //----------------------------------------------------
        // Complete oldest transfer
        //----------------------------------------------------
        if(vif.HREADYI && pending_q.size() != 0) begin

            tr = pending_q.pop_front();

            tr.rdata       = vif.HRDATAI;
            tr.instruction = vif.HRDATAI;
            tr.response    = vif.HRESPI;

            ap.write(tr);

        end

        //----------------------------------------------------
        // Accept new address phase
        //----------------------------------------------------
        if(vif.HREADYI &&
           (vif.HTRANSI inside {2'b10,2'b11})) begin

            tr = create_transaction(
                    generic_transaction::I_BUS,
                    vif.HADDRI,
                    2'b00);

            tr.write = 1'b0;

            pending_q.push_back(tr);

        end

    end

endtask

    //------------------------------------------------------------
    // Data Bus
    //------------------------------------------------------------
//------------------------------------------------------------
// Data Bus
//------------------------------------------------------------
task monitor_d_bus();

    generic_transaction pending_q[$];
    generic_transaction tr;

    forever begin

        @(posedge vif.HCLK);

        //----------------------------------------------------
        // Complete previous transfer
        //----------------------------------------------------
        if(vif.HREADYD && pending_q.size() != 0) begin

            tr = pending_q.pop_front();

            tr.response = vif.HRESPD;

            if(tr.write)
                tr.wdata = vif.HWDATAD;
            else
                tr.rdata = vif.HRDATAD;

            ap.write(tr);

        end

        //----------------------------------------------------
        // Accept new address
        //----------------------------------------------------
        if(vif.HREADYD &&
           (vif.HTRANSD inside {2'b10,2'b11})) begin

            tr = create_transaction(
                    generic_transaction::D_BUS,
                    vif.HADDRD,
                    2'b00);

            tr.write = vif.HWRITED;

            pending_q.push_back(tr);

        end

    end

endtask

    //------------------------------------------------------------
    // System Bus
    //------------------------------------------------------------
//------------------------------------------------------------
// System Bus
//------------------------------------------------------------
task monitor_s_bus();

    generic_transaction pending_q[$];
    generic_transaction tr;

    forever begin

        @(posedge vif.HCLK);

        //----------------------------------------------------
        // Complete previous transfer
        //----------------------------------------------------
        if(vif.HREADYS && pending_q.size() != 0) begin

            tr = pending_q.pop_front();

            tr.response = vif.HRESPS;

            if(tr.write)
                tr.wdata = vif.HWDATAS;
            else
                tr.rdata = vif.HRDATAS;

            ap.write(tr);

        end

        //----------------------------------------------------
        // Accept new address
        //----------------------------------------------------
        if(vif.HREADYS &&
           (vif.HTRANSS inside {2'b10,2'b11})) begin

            tr = create_transaction(
                    generic_transaction::S_BUS,
                    vif.HADDRS,
                    2'b00);

            tr.write = vif.HWRITES;

            pending_q.push_back(tr);

        end

    end

endtask

endclass
