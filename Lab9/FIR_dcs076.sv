module FIR(
    // Input signals
    clk,
    rst_n,
    in_valid,
    weight_valid,
    x,
    b0,
    b1,
    b2,
    b3,
    // Output signals
    out_valid,
    y
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid, weight_valid;
input [15:0] x, b0, b1, b2, b3;

output logic out_valid;
output logic [33:0] y;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [15:0] regs_b0,regs_b1,regs_b2,regs_b3;
logic [33:0] regs_DFF1,regs_DFF2,regs_DFF3;
logic [33:0] D1,D2,D3,D4;
logic [9:0] counter;
logic [15:0] regs_x;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 0;
        y <= 34'b0;
        counter <= 10'b0;
        regs_b0 <= 16'b0;
        regs_b1 <= 16'b0;
        regs_b2 <= 16'b0;
        regs_b3 <= 16'b0;
    end else if(weight_valid)
    begin
        regs_b0 <= b0;
        regs_b1 <= b1;
        regs_b2 <= b2;
        regs_b3 <= b3;
    end
    else begin 
         regs_x <= x;
        if(in_valid)
        begin
            regs_DFF1 <= D1;
            regs_DFF2 <= D2;
            regs_DFF3 <= D3;
            // regs_DFF4 <= D4;
            counter <= counter + 1;
        end
        if(counter > 3)
        begin
            out_valid <= 1;
            y <= D4;
        end
    end 
end

always_comb
begin
    D1 = regs_b3*regs_x;
    D2 = regs_DFF1 + regs_b2*regs_x;
    D3 = regs_DFF2 + regs_b1*regs_x;
    D4 = regs_DFF3 + regs_b0*regs_x;
end

endmodule