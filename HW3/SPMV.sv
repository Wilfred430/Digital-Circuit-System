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

logic [15:0] mult_result; 
logic [4:0] row_reg;      
logic weight_valid_d;    

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
        mult_result <= 0;
        row_reg <= 0;
        weight_valid_d <= 0;
        for (i = 0; i < 32; i = i + 1) 
		begin
            result[i] <= 18'b0;
            vector_in[i] <= 8'b0;
        end
    end
    else if (out_finish) 
	begin
        out_valid <= 0;
        out_finish <= 0;
        out_row <= 5'b0;
        out_data <= 21'b0;
        next <= 0;
        pre_lead <= 0;
        mult_result <= 0;
        row_reg <= 0;
        weight_valid_d <= 0;
        for (i = 0; i < 32; i = i + 1) 
		begin
            result[i] <= 18'b0;
            vector_in[i] <= 8'b0;
        end
    end
    else 
	begin
        if (weight_valid) 
		begin
            mult_result <= in_data * vector_in[in_col];
            row_reg <= in_row;
            weight_valid_d <= 1;
        end else 
		begin
            weight_valid_d <= 0;
        end

        if (weight_valid_d) 
		begin
            result[row_reg] <= result[row_reg] + mult_result;
            pre_lead <= 1;
        end

        if (in_valid) 
		begin
            vector_in[in_row] <= in_data;
        end
        else if (pre_lead && !weight_valid && !weight_valid_d) 
		begin
            case (next)
                5'd31: 
				begin
                    out_finish <= 1;
                    out_valid <= 0;
                    out_data <= result[next];
                    out_row <= next;
                end
                default: 
				begin
                    out_valid <= 1;
                    out_data <= result[next];
                    out_row <= next;
                    case (result[next+1])
                        18'b0: 
						begin
                            if (next + 2 > 31) 
							begin
                                next <= next + 1;
                            end else 
							begin
                                next <= next + 2;
                            end
                        end
                        default: 
						begin
                            next <= next + 1;
                        end
                    endcase
                end
            endcase
        end
    end
end

endmodule