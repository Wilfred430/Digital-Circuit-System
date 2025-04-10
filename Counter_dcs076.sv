module Counter(
    // Input signals
    input clk, 
    input rst_n, 
    input in_valid,  
    input [4:0] in_num,  
    // Output signals
    output logic [4:0] out_num
);

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [4:0] in_reg;

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers
        in_reg <= 5'b0;
        out_num <= 5'b0;
    end
    else begin
        // Input register logic
        if (in_valid)
		begin
            in_reg <= in_num;
            out_num <= 5'b0;
		end
        else if (out_num < in_reg)
            out_num <= out_num + 1;
		else begin end
    end
end

endmodule
