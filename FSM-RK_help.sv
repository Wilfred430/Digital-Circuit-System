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
parameter BEQ=2'b00,
          BNE=2'b01,
          BLT=2'b10,
          BGE=2'b11;
//FSM
logic [1:0] current_state;
logic [1:0] next_state;

//input
logic taken;

//---------------------------------------------------------------------
//   YOUR DESIGN
//---------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= BEQ;
        state <= 2'b0;
        pred_taken <= 0;
    end
    else begin
        current_state <= next_state;

        if (in_valid) begin
            if ((current_state == BEQ) || (current_state == BNE)) pred_taken <= 0;
            else pred_taken <= 1;

            state <= current_state;
        end
        else begin
        end
    end
end

always_comb begin
    if (!rst_n) begin
        taken = 0;
        next_state = BEQ;
    end     
    else begin
        if (in_valid) begin
            case (op)
            BEQ: begin
                     if (A == B) taken = 1;
                     else taken = 0;
                 end 
            BNE: begin
                     if (A != B) taken = 1;
                     else taken = 0;
                 end
            BLT: begin
                     if (A < B) taken = 1;
                     else taken = 0;
                 end
            BGE: begin
                     if (A >= B) taken = 1;
                     else taken = 0;
                 end
            endcase
        end
        else begin
        end

        case (current_state)
        BEQ: begin
                 if (taken) next_state = BNE;
                 else next_state = BEQ;
             end
        BNE: begin
                 if (taken) next_state = BGE;
                 else next_state = BEQ;
             end
        BLT: begin
                 if (taken) next_state = BGE;
                 else next_state = BEQ;
             end
        BGE: begin
                 if (taken) next_state = BGE;
                 else next_state = BLT;
             end
        endcase
    end
end

endmodule