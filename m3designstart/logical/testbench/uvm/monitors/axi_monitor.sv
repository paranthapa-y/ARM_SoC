class axi_monitor extends generic_monitor;

    `uvm_component_utils(axi_monitor)

    //------------------------------------------------------------
    // Virtual Interface
    //------------------------------------------------------------
    virtual axi_if vif;


    //------------------------------------------------------------
    // Pending Read Transaction
    //------------------------------------------------------------
    typedef struct {

        time          timestamp;
        logic [31:0]  address;

    } axi_read_pending_t;


    //------------------------------------------------------------
    // Pending Write Transaction
    //------------------------------------------------------------
typedef struct {

    time          timestamp;

    logic [31:0]  address;

    logic [31:0]  data;

    bit           addr_valid;
    bit           data_valid;

} axi_write_pending_t;

    //------------------------------------------------------------
    // Pending Read Tables
    //------------------------------------------------------------
    axi_read_pending_t i_read_pending[int];
    axi_read_pending_t d_read_pending[int];
    axi_read_pending_t s_read_pending[int];


    //------------------------------------------------------------
    // Pending Write Tables
    //------------------------------------------------------------
    axi_write_pending_t d_write_pending[int];
    axi_write_pending_t s_write_pending[int];


    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------
    function new(string name="axi_monitor",
                 uvm_component parent);

        super.new(name,parent);

    endfunction


    //------------------------------------------------------------
    // Build Phase
    //------------------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual axi_if)::get(this,"","axi_vif",vif))
            `uvm_fatal("NOVIF","Cannot get axi_if");

    endfunction


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
task run_phase(uvm_phase phase);

    fork

        // Instruction Bus
        monitor_i_ar();
        monitor_i_r();

        // Data Bus
        monitor_d_aw();
        monitor_d_w();
        monitor_d_b();
        monitor_d_ar();
        monitor_d_r();

        // System Bus
        monitor_s_aw();
        monitor_s_w();
        monitor_s_b();
        monitor_s_ar();
        monitor_s_r();

    join

endtask
//------------------------------------------------------------
// Instruction Read Address Channel
//------------------------------------------------------------
   task monitor_i_ar();

    forever begin

        @(posedge vif.ACLK);

        if (vif.i_arvalid && vif.i_arready) begin

            i_read_pending[vif.i_arid].timestamp = $time;
            i_read_pending[vif.i_arid].address   = vif.i_araddr;

        end

    end

  endtask

  //------------------------------------------------------------
// Instruction Read Data Channel
//------------------------------------------------------------
task monitor_i_r();

    generic_transaction tr;

    forever begin

        @(posedge vif.ACLK);

        if (vif.i_rvalid && vif.i_rready) begin

            // Create transaction using information saved by AR channel
            tr = create_transaction(
                    generic_transaction::I_BUS,
                    i_read_pending[vif.i_rid].address,
                    {1'b0, vif.i_rresp}
                 );

            tr.write       = 1'b0;
            tr.rdata       = vif.i_rdata;
            tr.instruction = vif.i_rdata;

            ap.write(tr);

            // Remove completed transaction
            if(vif.i_rlast)
                i_read_pending.delete(vif.i_rid);

        end

    end

endtask

//------------------------------------------------------------
// Data Write Address Channel
//------------------------------------------------------------
task monitor_d_aw();

    forever begin

        @(posedge vif.ACLK);

        if (vif.d_awvalid && vif.d_awready) begin

            d_write_pending[vif.d_awid].timestamp  = $time;
            d_write_pending[vif.d_awid].address    = vif.d_awaddr;
            d_write_pending[vif.d_awid].addr_valid = 1'b1;

        end

    end

endtask

//------------------------------------------------------------
// Data Write Data Channel
//------------------------------------------------------------
task monitor_d_w();

    forever begin

        @(posedge vif.ACLK);

        if (vif.d_wvalid && vif.d_wready) begin

            // We assume one outstanding write per ID.
            // WID is optional in AXI4, so use the AWID already stored.

            foreach(d_write_pending[id]) begin

                if(d_write_pending[id].addr_valid &&
                  !d_write_pending[id].data_valid) begin

                    d_write_pending[id].data       = vif.d_wdata;
                    d_write_pending[id].data_valid = 1'b1;

                    break;

                end

            end

        end

    end

endtask


//------------------------------------------------------------
// Data Write Response Channel
//------------------------------------------------------------
task monitor_d_b();

    generic_transaction tr;
    int id;

    forever begin

        @(posedge vif.ACLK);

        if(vif.d_bvalid && vif.d_bready) begin

            id = vif.d_bid;

            if(d_write_pending.exists(id)) begin

                if(d_write_pending[id].addr_valid &&
                   d_write_pending[id].data_valid) begin

                    tr = create_transaction(
                            generic_transaction::D_BUS,
                            d_write_pending[id].address,
                            {1'b0,vif.d_bresp});

                    tr.write = 1'b1;
                    tr.wdata = d_write_pending[id].data;

                    ap.write(tr);

                    d_write_pending.delete(id);

                end
            end

        end

    end

endtask


//------------------------------------------------------------
// Data Read Address Channel
//------------------------------------------------------------
task monitor_d_ar();

    forever begin

        @(posedge vif.ACLK);

        if(vif.d_arvalid && vif.d_arready) begin

            d_read_pending[vif.d_arid].timestamp = $time;
            d_read_pending[vif.d_arid].address   = vif.d_araddr;

        end

    end

endtask


//------------------------------------------------------------
// Data Read Data Channel
//------------------------------------------------------------
task monitor_d_r();

    generic_transaction tr;
    int id;

    forever begin

        @(posedge vif.ACLK);

        if(vif.d_rvalid && vif.d_rready) begin

            id = vif.d_rid;

            if(d_read_pending.exists(id)) begin

                tr = create_transaction(
                        generic_transaction::D_BUS,
                        d_read_pending[id].address,
                        {1'b0, vif.d_rresp});

                tr.write = 1'b0;
                tr.rdata = vif.d_rdata;

                ap.write(tr);

                if(vif.d_rlast)
                    d_read_pending.delete(id);

            end

        end

    end

endtask

//------------------------------------------------------------
// System Write Address Channel
//------------------------------------------------------------
task monitor_s_aw();

    forever begin

        @(posedge vif.ACLK);

        if(vif.s_awvalid && vif.s_awready) begin

            s_write_pending[vif.s_awid].timestamp  = $time;
            s_write_pending[vif.s_awid].address    = vif.s_awaddr;
            s_write_pending[vif.s_awid].addr_valid = 1'b1;

        end

    end

endtask

//------------------------------------------------------------
// System Write Data Channel
//------------------------------------------------------------
task monitor_s_w();

    forever begin

        @(posedge vif.ACLK);

        if(vif.s_wvalid && vif.s_wready) begin

            foreach(s_write_pending[id]) begin

                if(s_write_pending[id].addr_valid &&
                  !s_write_pending[id].data_valid) begin

                    s_write_pending[id].data       = vif.s_wdata;
                    s_write_pending[id].data_valid = 1'b1;

                    break;

                end

            end

        end

    end

endtask

//------------------------------------------------------------
// System Write Response Channel
//------------------------------------------------------------
task monitor_s_b();

    generic_transaction tr;
    int id;

    forever begin

        @(posedge vif.ACLK);

        if(vif.s_bvalid && vif.s_bready) begin

            id = vif.s_bid;

            if(s_write_pending.exists(id)) begin

                if(s_write_pending[id].addr_valid &&
                   s_write_pending[id].data_valid) begin

                    tr = create_transaction(
                            generic_transaction::S_BUS,
                            s_write_pending[id].address,
                            {1'b0,vif.s_bresp});

                    tr.write = 1'b1;
                    tr.wdata = s_write_pending[id].data;

                    ap.write(tr);

                    s_write_pending.delete(id);

                end
            end

        end

    end

endtask



//------------------------------------------------------------
// System Read Address Channel
//------------------------------------------------------------
task monitor_s_ar();

    forever begin

        @(posedge vif.ACLK);

        if(vif.s_arvalid && vif.s_arready) begin

            s_read_pending[vif.s_arid].timestamp = $time;
            s_read_pending[vif.s_arid].address   = vif.s_araddr;

        end

    end

endtask

//------------------------------------------------------------
// System Read Data Channel
//------------------------------------------------------------
task monitor_s_r();

    generic_transaction tr;
    int id;

    forever begin

        @(posedge vif.ACLK);

        if(vif.s_rvalid && vif.s_rready) begin

            id = vif.s_rid;

            if(s_read_pending.exists(id)) begin

                tr = create_transaction(
                        generic_transaction::S_BUS,
                        s_read_pending[id].address,
                        {1'b0,vif.s_rresp});

                tr.write = 1'b0;
                tr.rdata = vif.s_rdata;

                ap.write(tr);

                if(vif.s_rlast)
                    s_read_pending.delete(id);

            end

        end

    end

endtask


endclass
