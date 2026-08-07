class ahb_logger extends uvm_subscriber #(generic_transaction);

    `uvm_component_utils(ahb_logger)

    //--------------------------------------------------------
    // File Handle
    //--------------------------------------------------------
    integer fd;

    //--------------------------------------------------------
    // Constructor
    //--------------------------------------------------------
    function new(string name="ahb_logger",
                 uvm_component parent);

        super.new(name,parent);

    endfunction


    //--------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        fd = $fopen("processor_log.txt","w");

        if(fd == 0)
            `uvm_fatal("FILE","Cannot open ahb_log.txt")

    endfunction


    //--------------------------------------------------------
    // Header
    //--------------------------------------------------------
    function void start_of_simulation_phase(uvm_phase phase);

        super.start_of_simulation_phase(phase);

        $fdisplay(fd,"----------------------------------------------------------------------------------------------");
        $fdisplay(fd,"TIME\t\tBUS\tTYPE\tADDRESS\t\tDATA\t\tINSTRUCTION\tRESP");
        $fdisplay(fd,"----------------------------------------------------------------------------------------------");

    endfunction


    //--------------------------------------------------------
    // Write Function
    //--------------------------------------------------------
    virtual function void write(generic_transaction t);

        string bus_name;
        string rw;

        //-----------------------------
        // Bus Name
        //-----------------------------
        case(t.bus)

            generic_transaction::I_BUS : bus_name = "I";
            generic_transaction::D_BUS : bus_name = "D";
            generic_transaction::S_BUS : bus_name = "S";

        endcase

        //-----------------------------
        // Read/Write
        //-----------------------------
        if(t.write)
            rw = "WRITE";
        else
            rw = "READ";

        //-----------------------------
        // Print
        //-----------------------------
        $fdisplay(fd,
                  "%0t\t%s\t%s\t0x%08h\t0x%08h\t0x%08h\t%0d",
                  t.timestamp,
                  bus_name,
                  rw,
                  t.address,
                  t.write ? t.wdata : t.rdata,
                  t.instruction,
                  t.response);

    endfunction


    //--------------------------------------------------------
    // Close File
    //--------------------------------------------------------
    function void final_phase(uvm_phase phase);

        super.final_phase(phase);

        $fclose(fd);

    endfunction

endclass
