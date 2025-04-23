module MAC(
        // Input signals
        clk,
        rst_n,
        in_valid,
        in_mode,
        in_act,
        in_wgt,
        // Output signals
        out_act_idx,
        out_wgt_idx,
        out_idx,
        out_valid,
        out_data,
        out_finish
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, in_valid, in_mode;
input [0:7][3:0] in_act;
input [0:8][3:0] in_wgt;
output logic [3:0] out_act_idx, out_wgt_idx, out_idx;
output logic out_valid, out_finish;
output logic [0:7][11:0] out_data;

//---------------------------------------------------------------------
//   REG AND WIRE DECLARATION
//---------------------------------------------------------------------
logic [4:0] i;
logic work_type;
logic [3:0]
//---------------------------------------------------------------------
//   YOUR DESIGN
//---------------------------------------------------------------------

// register in_mode signal
assign work_type = (in_valid)? in_mode : work_type;

// reset all output signal
always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                out_act_idx <= 4'bX;
                out_wgt_idx <= 4'bX;
                out_idx <= 4'b0;
                out_valid <= 1'b0;
                out_finish <= 1'b0;
                for(i=0;i<8;i=i+1)
                begin
                        out_data <= 12'b0;
                end
        end else if(out_finish)
        begin
                out_act_idx <= 4'bX;
                out_wgt_idx <= 4'bX;
                out_idx <= 4'b0;
                out_valid <= 1'b0;
                out_finish <= 1'b0;
                for(i=0;i<8;i=i+1)
                begin
                        out_data <= 12'b0;
                end
        end
        else begin end
end

// design CNN
always_ff @(posedge clk,negedge rst_n)
begin
        if(work_type)
        begin
        end
end

// design matrix multiplication
always_ff @(posedge clk,negedge rst_n)
begin
        if(!work_type)
        begin
        end
end

endmodule