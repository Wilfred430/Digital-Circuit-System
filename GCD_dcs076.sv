module GCD (
    input clk, rst_n, in_valid,
    input [3:0] in_data,
    output logic out_valid,
    output logic [4:0] out_data
);

logic [2:0] odd_num, even_num,slot_num;
logic [3:0] input_num;
logic [4:0] tmp_odd, tmp_even, GCD;
logic [4:0] array_B [0:2];
logic [1:0] state;     
logic [3:0] div_table [0:5] = {2, 3, 5, 7, 11, 13};
logic [3:0] a, b, c;
logic access;
logic refresh;

parameter IDLE = 2'b00, CASE1 = 2'b01, CASE2 = 2'b10, FINISH = 2'b11; 

always_ff @(posedge clk, negedge rst_n) 
begin
    if (!rst_n) begin
        out_valid <= 0;
        out_data <= 5'b0;
        odd_num <= 3'b0;
        even_num <= 3'b0;
        tmp_even <= 5'b0;
        tmp_odd <= 5'b0;
        array_B[0] <= 5'b0;
        array_B[1] <= 5'b0;
        array_B[2] <= 5'b0;
        slot_num <= 3'b0;
        input_num <= 4'b0;
        access <= 0;
        refresh <= 0;
        state <= IDLE;
    end
    else begin
        if (in_valid && slot_num < 3) begin
            state <= IDLE; 
            input_num <= input_num + 1;
            if (in_data % 2 == 0) begin
                if (even_num == 1) begin 
                    array_B[slot_num] <= tmp_even + in_data;
                    slot_num <= slot_num + 1;
                    tmp_even <= 5'b0;
                    even_num <= 0;
                end
                else begin
                    tmp_even <= tmp_even + in_data;
                    even_num <= even_num + 1;
                end
            end
            else begin
                if (odd_num == 1) begin 
                    array_B[slot_num] <= tmp_odd + in_data;
                    slot_num <= slot_num + 1;
                    tmp_odd <= 5'b0;
                    odd_num <= 0;
                end
                else begin
                    tmp_odd <= tmp_odd + in_data;
                    odd_num <= odd_num + 1;
                end
            end
        end
        else if (in_valid && input_num < 7)
        begin
            input_num <= input_num + 1;
        end
        else if (refresh) begin
            out_valid <= 0;
            out_data <= 5'b0;
            odd_num <= 3'b0;
            even_num <= 3'b0;
            tmp_even <= 5'b0;
            tmp_odd <= 5'b0;
            array_B[0] <= 5'b0;
            array_B[1] <= 5'b0;
            array_B[2] <= 5'b0;
            slot_num <= 3'b0;
            input_num <= 4'b0;
            access <= 0;
            refresh <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (slot_num == 3 && input_num >= 7) begin
                        access <= 1; 
                        out_valid <= 1;
                        out_data <= array_B[0];
                        state <= CASE1;
                    end
                end
                CASE1: begin
                    out_valid <= 1;
                    out_data <= array_B[1];
                    state <= CASE2;
                end
                CASE2: begin
                    out_valid <= 1;
                    out_data <= array_B[2];
                    state <= FINISH;
                end
                FINISH: begin
                    out_valid <= 1;
                    out_data <= GCD;
                    refresh <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
end

always_comb begin

    GCD = 1;

    if (access) begin
        logic [3:0] count_2, count_3, count_5, count_7, count_11, count_13;
        logic [4:0] temp_B0, temp_B1, temp_B2;

        count_2 = 0;
        count_3 = 0;
        count_5 = 0;
        count_7 = 0;
        count_11 = 0;
        count_13 = 0;

        temp_B0 = array_B[0];
        temp_B1 = array_B[1];
        temp_B2 = array_B[2];
        if (temp_B0 % 2 == 0 && temp_B1 % 2 == 0 && temp_B2 % 2 == 0) begin
            temp_B0 = temp_B0 / 2;
            temp_B1 = temp_B1 / 2;
            temp_B2 = temp_B2 / 2;
            count_2 = count_2 + 1;
            if (temp_B0 % 2 == 0 && temp_B1 % 2 == 0 && temp_B2 % 2 == 0) begin
                temp_B0 = temp_B0 / 2;
                temp_B1 = temp_B1 / 2;
                temp_B2 = temp_B2 / 2;
                count_2 = count_2 + 1;
                if (temp_B0 % 2 == 0 && temp_B1 % 2 == 0 && temp_B2 % 2 == 0) begin
                    temp_B0 = temp_B0 / 2;
                    temp_B1 = temp_B1 / 2;
                    temp_B2 = temp_B2 / 2;
                    count_2 = count_2 + 1;
                    if (temp_B0 % 2 == 0 && temp_B1 % 2 == 0 && temp_B2 % 2 == 0) begin
                        count_2 = count_2 + 1;
                    end
                end
            end
        end

        temp_B0 = array_B[0];
        temp_B1 = array_B[1];
        temp_B2 = array_B[2];
        if (temp_B0 % 3 == 0 && temp_B1 % 3 == 0 && temp_B2 % 3 == 0) begin
            temp_B0 = temp_B0 / 3;
            temp_B1 = temp_B1 / 3;
            temp_B2 = temp_B2 / 3;
            count_3 = count_3 + 1;
            if (temp_B0 % 3 == 0 && temp_B1 % 3 == 0 && temp_B2 % 3 == 0) begin
                count_3 = count_3 + 1;
            end
        end

        temp_B0 = array_B[0];
        temp_B1 = array_B[1];
        temp_B2 = array_B[2];
        if (temp_B0 % 5 == 0 && temp_B1 % 5 == 0 && temp_B2 % 5 == 0) begin
            count_5 = count_5 + 1;
        end

        temp_B0 = array_B[0];
        temp_B1 = array_B[1];
        temp_B2 = array_B[2];
        if (temp_B0 % 7 == 0 && temp_B1 % 7 == 0 && temp_B2 % 7 == 0) begin
            count_7 = count_7 + 1;
        end

        temp_B0 = array_B[0];
        temp_B1 = array_B[1];
        temp_B2 = array_B[2];
        if (temp_B0 % 11 == 0 && temp_B1 % 11 == 0 && temp_B2 % 11 == 0) begin
            count_11 = count_11 + 1;
        end

        temp_B0 = array_B[0];
        temp_B1 = array_B[1];
        temp_B2 = array_B[2];
        if (temp_B0 % 13 == 0 && temp_B1 % 13 == 0 && temp_B2 % 13 == 0) begin
            count_13 = count_13 + 1;
        end

        GCD = 1;
        if (count_2 == 1) GCD = GCD * 2;
        else if (count_2 == 2) GCD = GCD * 4;
        else if (count_2 == 3) GCD = GCD * 8;
        else if (count_2 == 4) GCD = GCD * 16;

        if (count_3 == 1) GCD = GCD * 3;
        else if (count_3 == 2) GCD = GCD * 9;

        if (count_5 == 1) GCD = GCD * 5;

        if (count_7 == 1) GCD = GCD * 7;

        if (count_11 == 1) GCD = GCD * 11;

        if (count_13 == 1) GCD = GCD * 13;
    end
end
endmodule