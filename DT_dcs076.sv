module DT(
    // Input signals
    input [19:0] in_n0,
    input [19:0] in_n1,
    input [19:0] in_n2,
    input [19:0] in_n3,
    // Output signals
    output logic [17:0] out_n0,
    output logic [17:0] out_n1,
    output logic [17:0] out_n2,
    output logic [17:0] out_n3,
    output logic [17:0] out_n4,

    output logic ack_n0,
    output logic ack_n1,
    output logic ack_n2,
    output logic ack_n3
);

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [1:0] condition_n0;
logic [1:0] condition_n1;
logic [1:0] condition_n2;
logic [1:0] condition_n3;
logic [1:0] condition_n4;

logic [15:0] data_n0;
logic [15:0] data_n1;
logic [15:0] data_n2;
logic [15:0] data_n3;
logic [15:0] data_n4;

logic conflict_n0;
logic conflict_n1;
logic conflict_n2;
logic conflict_n3;
logic conflict_n4;

//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------
always_comb begin
    // 初始化輸出和標誌
    out_n0 = {2'b00, 16'b0};
    out_n1 = {2'b00, 16'b0};
    out_n2 = {2'b00, 16'b0};
    out_n3 = {2'b00, 16'b0};
    out_n4 = {2'b00, 16'b0};

    ack_n0 = 0;
    ack_n1 = 0;
    ack_n2 = 0;
    ack_n3 = 0;

    conflict_n0 = 0;
    conflict_n1 = 0;
    conflict_n2 = 0;
    conflict_n3 = 0;
    conflict_n4 = 0;

    condition_n0 = 2'b00;
    condition_n1 = 2'b00;
    condition_n2 = 2'b00;
    condition_n3 = 2'b00;
    condition_n4 = 2'b00;

    data_n0 = 16'b0;
    data_n1 = 16'b0;
    data_n2 = 16'b0;
    data_n3 = 16'b0;
    data_n4 = 16'b0;

    // 處理輸入信號 in_n0
    if (in_n0[19] == 1) begin
        case (in_n0[18:16])
            3'b000: begin 
                if (conflict_n0 == 0) begin
                    condition_n0 = 2'b01;
                    data_n0 = in_n0[15:0];
                    conflict_n0 = 1;
                    ack_n0 = 1;
                end else begin
                    condition_n0 = 2'b10;
                    ack_n0 = 0;
                end
            end
            3'b001: begin 
                if (conflict_n1 == 0) begin
                    condition_n1 = 2'b01;
                    data_n1 = in_n0[15:0];
                    conflict_n1 = 1;
                    ack_n0 = 1;
                end else begin
                    condition_n1 = 2'b10;
                    ack_n0 = 0;
                end
            end
            3'b010: begin 
                if (conflict_n2 == 0) begin
                    condition_n2 = 2'b01;
                    data_n2 = in_n0[15:0];
                    conflict_n2 = 1;
                    ack_n0 = 1;
                end else begin
                    condition_n2 = 2'b10;
                    ack_n0 = 0;
                end
            end
            3'b011: begin 
                if (conflict_n3 == 0) begin
                    condition_n3 = 2'b01;
                    data_n3 = in_n0[15:0];
                    conflict_n3 = 1;
                    ack_n0 = 1;
                end else begin
                    condition_n3 = 2'b10;
                    ack_n0 = 0;
                end
            end
            3'b100: begin 
                if (conflict_n4 == 0) begin
                    condition_n4 = 2'b01;
                    data_n4 = in_n0[15:0];
                    conflict_n4 = 1;
                    ack_n0 = 1;
                end else begin
                    condition_n4 = 2'b10;
                    ack_n0 = 0;
                end
            end
            default: ack_n0 = 0;
        endcase
    end

    // 處理輸入信號 in_n1
    if (in_n1[19] == 1) begin
        case (in_n1[18:16])
            3'b000: begin 
                if (conflict_n0 == 0) begin
                    condition_n0 = 2'b01;
                    data_n0 = in_n1[15:0];
                    conflict_n0 = 1;
                    ack_n1 = 1;
                end else begin
                    condition_n0 = 2'b10;
                    ack_n1 = 0;
                end
            end
            3'b001: begin 
                if (conflict_n1 == 0) begin
                    condition_n1 = 2'b01;
                    data_n1 = in_n1[15:0];
                    conflict_n1 = 1;
                    ack_n1 = 1;
                end else begin
                    condition_n1 = 2'b10;
                    ack_n1 = 0;
                end
            end
            3'b010: begin 
                if (conflict_n2 == 0) begin
                    condition_n2 = 2'b01;
                    data_n2 = in_n1[15:0];
                    conflict_n2 = 1;
                    ack_n1 = 1;
                end else begin
                    condition_n2 = 2'b10;
                    ack_n1 = 0;
                end
            end
            3'b011: begin 
                if (conflict_n3 == 0) begin
                    condition_n3 = 2'b01;
                    data_n3 = in_n1[15:0];
                    conflict_n3 = 1;
                    ack_n1 = 1;
                end else begin
                    condition_n3 = 2'b10;
                    ack_n1 = 0;
                end
            end
            3'b100: begin 
                if (conflict_n4 == 0) begin
                    condition_n4 = 2'b01;
                    data_n4 = in_n1[15:0];
                    conflict_n4 = 1;
                    ack_n1 = 1;
                end else begin
                    condition_n4 = 2'b10;
                    ack_n1 = 0;
                end
            end
            default: ack_n1 = 0;
        endcase
    end

    // 處理輸入信號 in_n2
    if (in_n2[19] == 1) begin
        case (in_n2[18:16])
            3'b000: begin 
                if (conflict_n0 == 0) begin
                    condition_n0 = 2'b01;
                    data_n0 = in_n2[15:0];
                    conflict_n0 = 1;
                    ack_n2 = 1;
                end else begin
                    condition_n0 = 2'b10;
                    ack_n2 = 0;
                end
            end
            3'b001: begin 
                if (conflict_n1 == 0) begin
                    condition_n1 = 2'b01;
                    data_n1 = in_n2[15:0];
                    conflict_n1 = 1;
                    ack_n2 = 1;
                end else begin
                    condition_n1 = 2'b10;
                    ack_n2 = 0;
                end
            end
            3'b010: begin 
                if (conflict_n2 == 0) begin
                    condition_n2 = 2'b01;
                    data_n2 = in_n2[15:0];
                    conflict_n2 = 1;
                    ack_n2 = 1;
                end else begin
                    condition_n2 = 2'b10;
                    ack_n2 = 0;
                end
            end
            3'b011: begin 
                if (conflict_n3 == 0) begin
                    condition_n3 = 2'b01;
                    data_n3 = in_n2[15:0];
                    conflict_n3 = 1;
                    ack_n2 = 1;
                end else begin
                    condition_n3 = 2'b10;
                    ack_n2 = 0;
                end
            end
            3'b100: begin 
                if (conflict_n4 == 0) begin
                    condition_n4 = 2'b01;
                    data_n4 = in_n2[15:0];
                    conflict_n4 = 1;
                    ack_n2 = 1;
                end else begin
                    condition_n4 = 2'b10;
                    ack_n2 = 0;
                end
            end
            default: ack_n2 = 0;
        endcase
    end

    // 處理輸入信號 in_n3
    if (in_n3[19] == 1) begin
        case (in_n3[18:16])
            3'b000: begin 
                if (conflict_n0 == 0) begin
                    condition_n0 = 2'b01;
                    data_n0 = in_n3[15:0];
                    conflict_n0 = 1;
                    ack_n3 = 1;
                end else begin
                    condition_n0 = 2'b10;
                    ack_n3 = 0;
                end
            end
            3'b001: begin 
                if (conflict_n1 == 0) begin
                    condition_n1 = 2'b01;
                    data_n1 = in_n3[15:0];
                    conflict_n1 = 1;
                    ack_n3 = 1;
                end else begin
                    condition_n1 = 2'b10;
                    ack_n3 = 0;
                end
            end
            3'b010: begin 
                if (conflict_n2 == 0) begin
                    condition_n2 = 2'b01;
                    data_n2 = in_n3[15:0];
                    conflict_n2 = 1;
                    ack_n3 = 1;
                end else begin
                    condition_n2 = 2'b10;
                    ack_n3 = 0;
                end
            end
            3'b011: begin 
                if (conflict_n3 == 0) begin
                    condition_n3 = 2'b01;
                    data_n3 = in_n3[15:0];
                    conflict_n3 = 1;
                    ack_n3 = 1;
                end else begin
                    condition_n3 = 2'b10;
                    ack_n3 = 0;
                end
            end
            3'b100: begin 
                if (conflict_n4 == 0) begin
                    condition_n4 = 2'b01;
                    data_n4 = in_n3[15:0];
                    conflict_n4 = 1;
                    ack_n3 = 1;
                end else begin
                    condition_n4 = 2'b10;
                    ack_n3 = 0;
                end
            end
            default: ack_n3 = 0;
        endcase
    end

    // 設置輸出
    out_n0 = {condition_n0, data_n0};
    out_n1 = {condition_n1, data_n1};
    out_n2 = {condition_n2, data_n2};
    out_n3 = {condition_n3, data_n3};
    out_n4 = {condition_n4, data_n4};
end

endmodule