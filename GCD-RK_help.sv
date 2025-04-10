module GCD(
    // Input signals
        clk,
        rst_n,
        in_valid,
        in_data,
    // Output signals
        out_valid,
        out_data
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [3:0] in_data;

output logic out_valid;
output logic [4:0] out_data;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
//comb
logic [4:0] array_b[0:3];
logic [3:0] odd[0:7];
logic [3:0] even[0:7];
logic [2:0] next_state;
int odd_num;
int even_num;

//seq
logic [3:0] array_a[0:7];
logic [4:0] num_0;
logic [4:0] num_1;
logic [4:0] gcd[0:2];
logic [2:0] current_state;
int fsm_num;
int index;
logic in_finish;

parameter IDLE = 3'b000,
          CHECK = 3'b001,
          SWAP = 3'b011,
          MINUS = 3'b010,
          STORAGE = 3'b110,
          OUT = 3'b100;

//---------------------------------------------------------------------
//   Your design
//---------------------------------------------------------------------
always_comb begin
    if (!in_valid) begin
        if (!rst_n) begin
            array_b[0] = 5'b0;
            array_b[1] = 5'b0;
            array_b[2] = 5'b0;
            array_b[3] = 5'b0;
            odd[0] = 4'b0;
            odd[1] = 4'b0;
            odd[2] = 4'b0;
            odd[3] = 4'b0;
            odd[4] = 4'b0;
            odd[5] = 4'b0;
            odd[6] = 4'b0;
            odd[7] = 4'b0;
            even[0] = 4'b0;
            even[1] = 4'b0;
            even[2] = 4'b0;
            even[3] = 4'b0;
            even[4] = 4'b0;
            even[5] = 4'b0;
            even[6] = 4'b0;
            even[7] = 4'b0;
            odd_num = 0;
            even_num = 0;
            next_state = 3'b000;
        end
        else begin
            if (in_finish) begin
                if (even_num + odd_num != 8) begin
                    //identify odd & even
                    if (array_a[0] % 2 != 0) begin
                        odd[odd_num] = array_a[0];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[0];
                        even_num = even_num + 1;
                    end

                    if (array_a[1] % 2 != 0) begin
                        odd[odd_num] = array_a[1];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[1];
                        even_num = even_num + 1;
                    end

                    if (array_a[2] % 2 != 0) begin
                        odd[odd_num] = array_a[2];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[2];
                        even_num = even_num + 1;
                    end

                    if (array_a[3] % 2 != 0) begin
                        odd[odd_num] = array_a[3];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[3];
                        even_num = even_num + 1;
                    end

                    if (array_a[4] % 2 != 0) begin
                        odd[odd_num] = array_a[4];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[4];
                        even_num = even_num + 1;
                    end

                    if (array_a[5] % 2 != 0) begin
                        odd[odd_num] = array_a[5];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[5];
                        even_num = even_num + 1;
                    end

                    if (array_a[6] % 2 != 0) begin
                        odd[odd_num] = array_a[6];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[6];
                        even_num = even_num + 1;
                    end

                    if (array_a[7] % 2 != 0) begin
                        odd[odd_num] = array_a[7];
                        odd_num = odd_num + 1;
                    end
                    else begin
                        even[even_num] = array_a[7];
                        even_num = even_num + 1;
                    end
                end
                else begin
                end

                //assign value to array_b
                if (even_num + odd_num == 8) begin
                    if ((even_num == 8) || (even_num == 7) || (even_num == 6)) begin
                        array_b[0] = even[0] + even[1];
                        array_b[1] = even[2] + even[3];
                        array_b[2] = even[4] + even[5];
                    end
                    else if ((even_num == 5) || (even_num == 4)) begin
                        array_b[0] = even[0] + even[1];
                        array_b[1] = even[2] + even[3];
                        array_b[2] = odd[0] + odd[1];
                    end
                    else if ((even_num == 3) || (even_num == 2)) begin
                        array_b[0] = even[0] + even[1];
                        array_b[1] = odd[0] + odd[1];
                        array_b[2] = odd[2] + odd[3];
                    end
                    else if ((even_num == 1) || (even_num == 0)) begin
                        array_b[0] = odd[0] + odd[1];
                        array_b[1] = odd[2] + odd[3];
                        array_b[2] = odd[4] + odd[5];
                    end
                    else begin
                        array_b[0] = even[0] + even[1];
                        array_b[1] = even[2] + even[3];
                        array_b[2] = even[4] + even[5];
                    end
                end
                else begin
                end
            end
            else begin
                array_b[0] = 5'b0;
                array_b[1] = 5'b0;
                array_b[2] = 5'b0;
                array_b[3] = 5'b0;
                odd[0] = 4'b0;
                odd[1] = 4'b0;
                odd[2] = 4'b0;
                odd[3] = 4'b0;
                odd[4] = 4'b0;
                odd[5] = 4'b0;
                odd[6] = 4'b0;
                odd[7] = 4'b0;
                even[0] = 4'b0;
                even[1] = 4'b0;
                even[2] = 4'b0;
                even[3] = 4'b0;
                even[4] = 4'b0;
                even[5] = 4'b0;
                even[6] = 4'b0;
                even[7] = 4'b0;
                odd_num = 0;
                even_num = 0;
                next_state = 3'b000;
            end
        end

        //FSM
        case (current_state)
        //initialize
        IDLE: begin
            if (array_b[3] != 0 ||  ((array_b[0] == 0) || (array_b[1] == 0) || (array_b[2] == 0))) next_state = IDLE;
            else next_state = CHECK;
        end

        //compare size
        CHECK: begin
            if (num_0 < num_1) next_state = SWAP;
            else next_state = MINUS;
        end

        //change num_0 & num_1
        SWAP: begin
              next_state = CHECK;
        end

        //num_0-num_1
        MINUS: begin
               if (num_0 - num_1 != 0) next_state = CHECK;
               else next_state = STORAGE;
        end

        //storage GCD
        STORAGE: begin
                 if (fsm_num == 3) next_state = OUT;
                 else next_state = IDLE;
        end

        //ready to output
        OUT: begin
            array_b[3] = gcd[2];
            if (index == 4) begin
                next_state = IDLE;
            end
            else next_state = OUT;
        end
        default: begin
        end
        endcase
    end
    else begin
        array_b[0] = 5'b0;
        array_b[1] = 5'b0;
        array_b[2] = 5'b0;
        array_b[3] = 5'b0;
        odd[0] = 4'b0;
        odd[1] = 4'b0;
        odd[2] = 4'b0;
        odd[3] = 4'b0;
        odd[4] = 4'b0;
        odd[5] = 4'b0;
        odd[6] = 4'b0;
        odd[7] = 4'b0;
        even[0] = 4'b0;
        even[1] = 4'b0;
        even[2] = 4'b0;
        even[3] = 4'b0;
        even[4] = 4'b0;
        even[5] = 4'b0;
        even[6] = 4'b0;
        even[7] = 4'b0;
        odd_num = 0;
        even_num = 0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    //initialize when reset
    if (!rst_n) begin
        current_state <= IDLE;
        index <= 0;
        out_valid <= 0;
        out_data <= 5'b0;
        fsm_num <= 0;
        num_0 <= 5'b0;
        num_1 <= 5'b0;
        gcd[0] <= 5'b0;
        gcd[1] <= 5'b0;
        gcd[2] <= 5'b0;
        in_finish <= 0;
    end
    else begin
        //input 8 numbers
        if (in_valid) begin
            array_a[index] <= in_data;
            if (index + 1 == 8) begin
                index <= 0;
                in_finish <= 1;
            end
            else index <= index + 1;
        end
        else begin
            //FSM
            current_state <= next_state;

            if (current_state == IDLE) begin
                if (array_b[3] != 0) begin
                    fsm_num <= 0;
                    num_0 <= 5'b0;
                    num_1 <= 5'b0;
                    gcd[0] <= 5'b0;
                    gcd[1] <= 5'b0;
                    gcd[2] <= 5'b0;
                    out_valid <= 0;
                    index <= 0;
                    in_finish <= 0;
                end
                else begin
                    if ((array_b[0] != 0) && (array_b[1] != 0) && (array_b[2] != 0)) begin
                        if (fsm_num == 0) begin
                            num_0 <= array_b[0];
                            num_1 <= array_b[1];
                        end
                        else if (fsm_num == 1) begin
                            num_0 <= array_b[0];
                            num_1 <= array_b[2];
                        end
                        else if (fsm_num == 2) begin
                            num_0 <= gcd[0];
                            num_1 <= gcd[1];
                        end else begin end
                    end
                    else begin
                    end
                end
            end

            else if (current_state == SWAP) begin
                num_1 <= num_0;
                num_0 <= num_1;
            end

            else if (current_state == MINUS) begin
                if (num_0 - num_1 != 0) num_0 <= num_0 - num_1;
                else begin
                end
            end

            //output 4 numbers
            else if (current_state == STORAGE) begin
                gcd[fsm_num] <= num_0;
                fsm_num <= fsm_num + 1;
            end

            else if (current_state == OUT) begin
                out_data <= array_b[index];
                index <= index + 1;
                if (index <= 3) begin
                    out_valid <= 1;
                end
                else begin
                    out_valid <= 0;
                    fsm_num <= 0;
                    num_0 <= 5'b0;
                    num_1 <= 5'b0;
                    gcd[0] <= 5'b0;
                    gcd[1] <= 5'b0;
                    gcd[2] <= 5'b0;
                    index <= 0;
                end
            end
            else begin
            end
        end
    end
end

endmodule
