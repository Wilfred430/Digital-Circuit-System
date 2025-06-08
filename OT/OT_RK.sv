module LN(
    //OUTPUT
    clk,
    rst_n,
    in_valid,
    in_data,

    //INPUT
    out_valid,
    out_data
);

// INPUT
input clk;
input rst_n;
input in_valid;
input signed [7:0] in_data;

// OUTPUT
output logic out_valid;
output logic signed [7:0] out_data;

//LOGIC
logic signed [8:0] shift_reg_1 [0:7];
logic signed [8:0] shift_reg_2 [0:7];
logic o_flag;

logic signed [11:0] average_temp;
logic signed [8:0] average;
logic signed [8:0] average_reg;

logic signed [8:0] avg_diff;
logic signed [8:0] avg_diff_abs;

logic signed [11:0] variance_temp;
logic signed [8:0] variance;
logic signed [8:0] variance_reg;
logic [3:0] count;
//================================================================
// DESIGN
//================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) shift_reg_1 <= '{default:0};
    else begin
        for(int i=0;i<7;i++)
        begin
            shift_reg_1[i+1] <= shift_reg_1[i]; 
        end

        if(in_valid) shift_reg_1[0] <= in_data;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) count <= 0;
    else if (in_valid || (!in_valid && o_flag)) begin
        count <= (count == 15) ? 0 : (count+1);
    end
    else count <= 0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) average_temp <= 0;
    else begin
        case (count)
        'd0,'d8: average_temp <= in_data;
        'd1, 'd2, 'd3, 'd4, 'd5, 'd6, 'd7,'d9, 'd10, 'd11, 'd12, 'd13, 'd14, 'd15: average_temp <= average_temp + in_data;
        default: average_temp <= average_temp;
        endcase
    end
end

assign average = average_temp / 8;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) average_reg <= '{default:0};
    else begin
        case (count)
        'd8, 'd0: average_reg <= average;
        default: average_reg <= average_reg;
        endcase
    end
end

assign avg_diff = (count == 8 || count == 0) ? shift_reg_1[7] - average : shift_reg_1[7] - average_reg;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) shift_reg_2 <= '{default:0};
    else begin
        shift_reg_2[0] <= avg_diff;
        for(int i=0;i<7;i++)
        begin
            shift_reg_2[i+1] <= shift_reg_2[i];
        end
    end
end

assign avg_diff_abs = avg_diff[8] ? -avg_diff : avg_diff;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) variance_temp <= 0;
    else begin
        case (count)
        'd8: variance_temp <= avg_diff_abs;
        'd9, 'd10, 'd11, 'd12, 'd13, 'd14, 'd15: variance_temp <= variance_temp + avg_diff_abs;

        'd0: variance_temp <= avg_diff_abs;
        'd1, 'd2, 'd3, 'd4, 'd5, 'd6, 'd7: variance_temp <= variance_temp + avg_diff_abs;
        default: variance_temp <= variance_temp;
        endcase
    end
end

assign variance = variance_temp / 8;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) variance_reg <= 0;
    else begin
        case (count)
        'd8, 'd0: variance_reg <= variance;
        default: variance_reg <= variance_reg;
        endcase
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) o_flag <= 1'b0;
    else if (in_valid && count == 15) o_flag <= 1'b1;
    else if (!in_valid && count == 15) o_flag <= 1'b0;
    else o_flag <= o_flag;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 1'b0;
    else if (o_flag) out_valid <= 1'b1;
    else out_valid <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) out_data <= 0;
    else begin
        if (o_flag) begin
            case (count)
            'd8, 'd0: out_data <= shift_reg_2[7] / variance;
            default: out_data <= shift_reg_2[7] / variance_reg;
            endcase
        end
        else out_data <= 0;
    end
end

endmodule