`include "Handshake_syn.v"

module CDC(
        // Input signals
        clk_1,
        clk_2,
        rst_n,
        in_valid,
        in_data,
        // Output signals
        out_valid,
        out_data
);

input clk_1;
input clk_2;
input rst_n;
input in_valid;
input[3:0]in_data;

output logic out_valid;
output logic [4:0]out_data;

// ---------------------------------------------------------------------
// logic declaration
// ---------------------------------------------------------------------
parameter S_WAIT_INPUT1 = 3'b000,
          S_WAIT_INPUT2 = 3'b001,
          S_SEND_DATA = 3'b011,
          S_WAIT_IDLE = 3'b101,
          S_IDLE = 3'b111,
          S_GET_DOUT1 = 3'b110,
          S_GET_DOUT2 = 3'b010,
          S_OUT = 3'b100;
logic [2:0] next_state1;
logic [2:0] current_state1;
logic [2:0] next_state2;
logic [2:0] current_state2;

logic [3:0] in_data1, in_data2;
logic [3:0] dout1, dout2;
int count;

logic sready;
logic [3:0] d_in;
logic sidle;
logic dvalid;
logic [3:0] dout;
// ---------------------------------------------------------------------
// design
// ---------------------------------------------------------------------
Handshake_syn sync(
    .sclk(clk_1),
    .dclk(clk_2),
    .rst_n(rst_n),
    .sready(sready),
    .din(d_in),
    .sidle(sidle),
    .dbusy(1'b0),  // As suggested in the lab, set to 0 to simplify
    .dvalid(dvalid),
    .dout(dout)
);
//FSM clk_1
always_comb begin
    next_state1 = current_state1;
    if(!rst_n) next_state1 = S_WAIT_INPUT1;
    else begin
        case (current_state1)
            S_WAIT_INPUT1: begin
                if (in_valid) next_state1 = S_WAIT_INPUT2;
                else next_state1 = current_state1;
            end
            S_WAIT_INPUT2: next_state1 = S_SEND_DATA;
            S_SEND_DATA: begin
                if (count < 2) next_state1 = S_WAIT_IDLE;
                else next_state1 = S_WAIT_INPUT1;
            end
            S_WAIT_IDLE: begin
                if (sidle) next_state1 = S_SEND_DATA;
                else next_state1 = current_state1;
            end
        endcase
    end
end

//FSM clk_2
always_comb begin
    next_state2 = current_state2;
    if(!rst_n) next_state2 = S_IDLE;
    else begin
        case (current_state2)
            S_IDLE: begin
                if (dvalid && count == 1) next_state2 = S_GET_DOUT1;
                else next_state2 = current_state2;
            end
            S_GET_DOUT1: begin
                if (dvalid) next_state2 = current_state2;
                else next_state2 = S_GET_DOUT2;
            end
            S_GET_DOUT2: begin
                if (dvalid) next_state2 = S_OUT;
                else next_state2 = current_state2;
            end
            S_OUT: next_state2 = S_IDLE;
        endcase
    end
end

always_ff @(posedge clk_1 or negedge rst_n) begin
    if (!rst_n) begin
        current_state1 <= S_WAIT_INPUT1;
        in_data1 <= 0;
        in_data2 <= 0;
        count <= 0;
        sready <= 1'b0;
        d_in <= 0;
    end
    else begin
        current_state1 <= next_state1;
        case (current_state1)
            S_WAIT_INPUT1: begin
                count <= 0;
                if (in_valid) in_data1 <= in_data;
                else in_data1 <= in_data1;
            end
            S_WAIT_INPUT2: begin
                count <= 0;
                if (in_valid) in_data2 <= in_data;
                else in_data2 <= in_data2;
            end
            S_SEND_DATA: begin
                if (sidle) begin
                    sready <= 1'b1;
                    if (count == 0) d_in <= in_data1;
                    else if (count == 1)d_in <= in_data2;
                    else d_in <= 0;
                    count <= count + 1;
                end
                else if (!sidle) begin
                    d_in <= 0;
                    sready <= 1'b0;
                    count <= count;
                end
                else begin end
            end
            S_WAIT_IDLE: begin
                d_in <= 0;
                sready <= 1'b0;
                count <= count;
            end
        endcase
    end
end

always_ff @(posedge clk_2 or negedge rst_n) begin
    if (!rst_n) begin
        current_state2 <= S_IDLE;
        dout1 <= 0;
        dout2 <= 0;
        out_data <= 0;
        out_valid <= 0;
    end
    else begin
        current_state2 <= next_state2;
        case (current_state2)
            S_IDLE: begin
                dout1 <= 0;
                dout2 <= 0;
                out_data <= 0;
                out_valid <= 1'b0;
            end
            S_GET_DOUT1: begin
                if (dvalid) dout1 <= dout;
                else dout1 <= dout1;
            end
            S_GET_DOUT2: begin
                if (dvalid) dout2 <= dout;
                else dout2 <= dout2;
            end
            S_OUT: begin
                out_data <= dout1 + dout2;
                out_valid <= 1'b1;
            end
        endcase
    end
end

endmodule