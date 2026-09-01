module icode_tracker
(
    input           HCLK,
    input           HRESETn,

    // ICODE BUS
    input  [31:0]   HADDRI,
    input  [1:0]    HTRANSI,
    input  [2:0]    HSIZEI,
    input  [2:0]    HBURSTI,
    input  [3:0]    HPROTI,

    input           HREADYI,
    input  [31:0]   HRDATAI,
    input  [1:0]    HRESPI
);

////////////////////////////////////////////////////////////
//
// File Handle
//
////////////////////////////////////////////////////////////

integer fd;

////////////////////////////////////////////////////////////
//
// Pipeline Registers
//
////////////////////////////////////////////////////////////

reg         valid_d;

reg [31:0]  addr_d;
reg [2:0]   size_d;
reg [2:0]   burst_d;
reg [3:0]   prot_d;
reg [1:0]   trans_d;

////////////////////////////////////////////////////////////
//
// Open Trace File
//
////////////////////////////////////////////////////////////

initial
begin

    fd = $fopen("icode_trace.txt","w");

    if(fd == 0)
    begin
        $display("ERROR : Cannot open icode_trace.txt");
        $finish;
    end

    $fdisplay(fd,"");
    $fdisplay(fd,"===============================================================");
    $fdisplay(fd,"                Cortex-M3 ICODE BUS TRACE");
    $fdisplay(fd,"===============================================================");
    $fdisplay(fd,"");
    $fdisplay(fd,"TIME(ns)     ADDRESS      INSTRUCTION    HTRANS   HRESP");
    $fdisplay(fd,"---------------------------------------------------------------");

end

////////////////////////////////////////////////////////////
//
// Decode HTRANS
//
////////////////////////////////////////////////////////////

task print_htrans;

input [1:0] trans;

begin

    case(trans)

        2'b00 : $fwrite(fd,"IDLE");
        2'b01 : $fwrite(fd,"BUSY");
        2'b10 : $fwrite(fd,"NONSEQ");
        2'b11 : $fwrite(fd,"SEQ");

    endcase

end

endtask

////////////////////////////////////////////////////////////
//
// Decode HSIZE
//
////////////////////////////////////////////////////////////

task print_hsize;

input [2:0] size;

begin

    case(size)

        3'b000 : $fwrite(fd,"BYTE");
        3'b001 : $fwrite(fd,"HALFWORD");
        3'b010 : $fwrite(fd,"WORD");
        3'b011 : $fwrite(fd,"DWORD");
        default: $fwrite(fd,"OTHER");

    endcase

end

endtask

////////////////////////////////////////////////////////////
//
// ICODE TRACKER
//
////////////////////////////////////////////////////////////

always @(posedge HCLK or negedge HRESETn)
begin

    if(!HRESETn)
    begin

        valid_d <= 1'b0;

    end

    else
    begin

        //----------------------------------------------------
        // Previous transfer completed
        //----------------------------------------------------

        if(valid_d && HREADYI)
        begin

            $fwrite(fd,"%10t   ",$time);
            $fwrite(fd,"%08h   ",addr_d);
            $fwrite(fd,"%08h      ",HRDATAI);

            print_htrans(trans_d);

            if(HRESPI==2'b00)
                $fdisplay(fd,"      OKAY");
            else
                $fdisplay(fd,"      ERROR");

        end
        //----------------------------------------------------
        // Capture current address phase
        //----------------------------------------------------

        if(HREADYI)
        begin

            if(HTRANSI[1])   // NONSEQ or SEQ transfer
            begin

                valid_d <= 1'b1;

                addr_d  <= HADDRI;
                size_d  <= HSIZEI;
                burst_d <= HBURSTI;
                prot_d  <= HPROTI;
                trans_d <= HTRANSI;

            end
            else
            begin

                valid_d <= 1'b0;

            end

        end

    end

end

////////////////////////////////////////////////////////////
//
// Close Trace File
//
////////////////////////////////////////////////////////////

// Questa automatically closes files at the end of simulation,
// so this block is optional. Uncomment if your simulator supports
// the Verilog-2001 'final' construct.

/*
final
begin
    if(fd != 0)
        $fclose(fd);
end
*/

endmodule
