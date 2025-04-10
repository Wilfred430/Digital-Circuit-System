module Fifo
{
    // input
    logic input clk;
    logic input rst_n;
    logic input read_valid;
    logic input write_valid;
    logic input [7:0] write_data;
    // output
    logic output [7:0] read_data;
    logic output read_success;
    logic output read_empty;
    logic output write_success;
    logic output write_full;
};

always_ff @(posedge clk, negedge rst_n) 
begin

    if(!rst_n)
    begin
        read_data = 8'b0;
        read_success = 0;
        read_empty = 0;
        write_success = 0;
        write_full = 0;
    end

    if(re)
        if(write)

    else if (write)
    
end



endmodule