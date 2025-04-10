//---------------------------------------------------------------------
//   REG AND WIRE DECLARATION
//---------------------------------------------------------------------
logic [4:0] count;
logic [4:0] count_next;
logic finish; //if previous loop's sum > 16
logic [4:0] card_value;
//---------------------------------------------------------------------
//   YOUR DESIGN
//---------------------------------------------------------------------
always @* begin
    //input exists and previous loop's sum <= 16
    if(in_valid && !finish) begin
        if((card == 11) || (card == 12) || (card == 13))
            card_value = 10;
        else
            card_value = card;
        count_next = count + card_value;
    end

    //previous loop's sum > 16
    else if (finish) begin
        card_value = 0;
        count_next = 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    //initialize all parameters when reset
    if (!rst_n) begin
        win <= 1'b0;
        lose <= 1'b0;
        sum <= 5'b00000;
        finish <= 1'b0;
        count <= 5'b00000;
    end

    //when positive edge
    else begin
        //previous loop's sum <= 16
        sum <= count_next;
        count <= count_next;
        if (!finish) begin
            //current loop's sum > 16
            if (count_next > 16) begin
                finish <= 1'b1;
                if (count_next <= 21)
                    win <= 1'b1;
                else
                    lose <= 1'b1;
            end
            else begin
                win <= 1'b0;
                lose <= 1'b0;
            end
        end

        //previous loop's sum > 16
        else if (finish) begin
            win <= 1'b0;
            lose <= 1'b0;
        end
    end
end

endmodule