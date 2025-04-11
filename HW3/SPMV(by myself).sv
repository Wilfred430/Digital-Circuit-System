module SPMV(
    input clk, rst_n,
    // input 
    input in_valid, weight_valid,
    input [4:0] in_row, in_col,
    input [7:0] in_data,
    // output
    output logic out_valid,
    output logic [4:0] out_row,
    output logic [20:0] out_data,
    output logic out_finish
);

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [7:0] vector_in [0:31];
logic [17:0] result [0:31];
logic [5:0] i;
logic [4:0] next;
logic pre_lead;

logic [5:0] non_zero [0:32];
logic [5:0] max_nonzero;

//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) 
	begin
        out_valid <= 0;
        out_finish <= 0;
        out_row <= 5'b0;
        out_data <= 21'b0;
        next <= 0;
        pre_lead <= 0;
        max_nonzero <= 6'b0;
        for (i = 0; i < 32; i = i + 1) 
		begin
            result[i] <= 18'b0;
            vector_in[i] <= 8'b0;
            non_zero[i] <= 6'b111111;
        end
        non_zero[32] <= 6'b111111;
    end
    else if (out_finish) 
	begin
        out_valid <= 0;
        out_finish <= 0;
        out_row <= 5'b0;
        out_data <= 21'b0;
        next <= 0;
        pre_lead <= 0;
        max_nonzero <= 6'b0;
        for (i = 0; i < 32; i = i + 1) 
		begin
            result[i] <= 18'b0;
            vector_in[i] <= 8'b0;
            non_zero[i] <= 6'b111111;
        end
        non_zero[32] <= 6'b111111;
    end
    else 
	begin
        if (in_valid) 
		begin
            vector_in[in_row] <= in_data;
        end
        else if (weight_valid) 
		begin
            pre_lead <= 1;
            result[in_row] <= result[in_row] + in_data * vector_in[in_col];
            if(non_zero[max_nonzero] != in_row && in_data != 0 && vector_in[in_col] != 0)
            begin
                non_zero[max_nonzero] <= in_row;
                non_zero[max_nonzero+1] <= in_row;
                max_nonzero <= max_nonzero + 1;
            end
        end
        else if (pre_lead && !weight_valid ) 
		begin
            out_valid <= 1;
            if(max_nonzero == 0)
            begin
                out_finish <= 1;
            end
            else if(next == (max_nonzero-1))
            begin
                out_finish <= 1;
                out_row <= non_zero[next];
                out_data <= result[non_zero[next]];
            end
            else 
            begin
                out_row <= non_zero[next];
                out_data <= result[non_zero[next]];
                next <= next + 1;
            end
        end else begin end
    end
end

endmodule