module Seq (
    // Input signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] card,
    // Output signals
    output logic win,
    output logic lose,
    output logic [4:0] sum
);

//---------------------------------------------------------------------
//   REG AND WIRE DECLARATION                         
//---------------------------------------------------------------------
logic [4:0] trans; // 用于临时存储 card 的值

//---------------------------------------------------------------------
//   YOUR DESIGN                        
//---------------------------------------------------------------------
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        // 复位时初始化所有信号
        sum <= 5'b0;
        win <= 0;
        lose <= 0;
        trans <= 0;
    end
    else begin
        if(in_valid)
        begin
        // 更新 sum
        if (sum <= 16)
            sum <= sum + (card > 10 ? 10: card);

        // 检查是否输或赢
        if (sum + (card > 10 ? 10: card) > 21) begin
            lose <= 1;
            win <= 0;
        end
        else if (sum+(card > 10 ? 10: card) > 16 && sum+(card > 10 ? 10: card)<= 21) begin
            win <= 1;
            lose <= 0;
        end

        // 如果已经赢了或输了，重置状态
        if (win || lose) begin
            sum <= 5'b0;
            win <= 0;
            lose <= 0;
        end
        end
    end
end

endmodule