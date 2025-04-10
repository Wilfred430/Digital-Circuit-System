module FSM(
    // Input signals
    clk,
    rst_n,
    in_valid,
    op,
    A,
    B,
    // Output signals
    pred_taken,
    state
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [1:0] op;
input [3:0] A, B;
output logic pred_taken;
output logic [1:0] state;

//---------------------------------------------------------------------
//   REG AND WIRE DECLARATION                         
//---------------------------------------------------------------------
parameter BEQ = 2'b00, BNE = 2'b01, BLT = 2'b10, BGE = 2'b11;
logic taken;
logic [1:0] next_state;

//---------------------------------------------------------------------
//   YOUR DESIGN                        
//---------------------------------------------------------------------

always_comb begin
    case(op)
        BEQ: taken = (A == B);
        BNE: taken = (A != B);
        BLT: taken = (A < B);
        BGE: taken = (A >= B);
        default: taken = 1'b0;
    endcase
    
    // 2-bit predictor state machine
    case(state)
        2'b00: next_state = (in_valid && taken) ? 2'b01 : 2'b00;    // Strong not-taken
        2'b01: next_state = (in_valid && taken) ? 2'b11 : 2'b00;    // Weak not-taken
        2'b10: next_state = (in_valid && taken) ? 2'b11 : 2'b00;    // Weak taken
        2'b11: next_state = (in_valid && !taken) ? 2'b10 : 2'b11;   // Strong taken
        default: next_state = 2'b00;
    endcase
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state <= 2'b00;         // Reset to strong not-taken
        pred_taken <= 1'b0;
    end
    else if(in_valid) begin
        state <= next_state;
        pred_taken <= (next_state[1]);  // Predict taken when in states 10 or 11
    end
end

endmodule