module CPU(
    //INPUT
    clk,
    rst_n,
    in_valid,
    instruction,

    //OUTPUT
    out_valid,
    instruction_fail,
    out_0,
    out_1,
    out_2,
    out_3,
    out_4,
    out_5
);
// INPUT
input clk;
input rst_n;
input in_valid;
input [31:0] instruction;

// OUTPUT
output logic out_valid, instruction_fail;
output logic [15:0] out_0, out_1, out_2, out_3, out_4, out_5;

//register
logic signed [15:0] reg_10001, reg_10010, reg_01000, reg_10111, reg_11111, reg_10000;

//instruction
logic [5:0] opcode, funct;
logic [4:0] rs, rt, rd, shamt;
logic [15:0] immediate;

//logic declaration
logic signed [62:0] rs_reg, rt_reg, rd_reg;
//================================================================
// DESIGN
//================================================================
assign opcode = instruction[31:26];
assign rs = instruction[25:21];
assign rt = instruction[20:16];
assign rd = instruction[15:11];
assign shamt = instruction[10:6];
assign funct = instruction[5:0];
assign immediate = instruction[15:0];

always_comb begin
    if (!rst_n) begin
        rs_reg = 'bx;
        rt_reg = 'bx;
        rd_reg = 'bx;
    end
    else if (in_valid) begin
        //rs
        casez (rs)
            5'b10001: rs_reg = reg_10001;
            5'b10010: rs_reg = reg_10010;
            5'b01000: rs_reg = reg_01000;
            5'b10111: rs_reg = reg_10111;
            5'b11111: rs_reg = reg_11111;
            5'b10000: rs_reg = reg_10000;
            default: rs_reg = 'bx;
        endcase

        //rt
        casez (rt)
            5'b10001: rt_reg = reg_10001;
            5'b10010: rt_reg = reg_10010;
            5'b01000: rt_reg = reg_01000;
            5'b10111: rt_reg = reg_10111;
            5'b11111: rt_reg = reg_11111;
            5'b10000: rt_reg = reg_10000;
            default: rt_reg = 'bx;
        endcase

        //operation
        casez (opcode)
            //R-type
            6'b0000000: begin
                //operation
                casez (funct)
                    6'b100000: rd_reg = rs_reg + rt_reg;
                    6'b011000: rd_reg = (rs_reg * rt_reg) >> 15;
                    6'b000000: rd_reg = rt_reg << shamt;
                    6'b000010: rd_reg = rt_reg >> shamt;
                    6'b110001: begin
                        if (rt_reg < 0) rd_reg = 0;
                        else rd_reg = rt_reg;
                    end
                    6'b110010: begin
                        if (rt_reg < 0) rd_reg = (rs_reg * rt_reg) >> 15;
                        else rd_reg = rt_reg;
                    end
                    default: rd_reg = 'bx;
                endcase
            end
            //I-type
            6'b001000: begin
                rd_reg = 'bx;
            end
            default: begin
                rd_reg = 'bx;
            end
        endcase
    end
    else begin
        rs_reg = 'bx;
        rt_reg = 'bx;
        rd_reg = 'bx;
    end
end

//register
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_10001 <= 0;
        reg_10010 <= 0;
        reg_01000 <= 0;
        reg_10111 <= 0;
        reg_11111 <= 0;
        reg_10000 <= 0;
    end
    else if (in_valid) begin
        casez (opcode)
            6'b000000: begin // R-type
                casez (rd)
                    5'b10001: reg_10001 <= rd_reg;
                    5'b10010: reg_10010 <= rd_reg;
                    5'b01000: reg_01000 <= rd_reg;
                    5'b10111: reg_10111 <= rd_reg;
                    5'b11111: reg_11111 <= rd_reg;
                    5'b10000: reg_10000 <= rd_reg;
                    default: begin end
                endcase
            end
            6'b001000: begin // I-type
                casez (rt)
                    5'b10001: reg_10001 <= rs_reg + immediate;
                    5'b10010: reg_10010 <= rs_reg + immediate;
                    5'b01000: reg_01000 <= rs_reg + immediate;
                    5'b10111: reg_10111 <= rs_reg + immediate;
                    5'b11111: reg_11111 <= rs_reg + immediate;
                    5'b10000: reg_10000 <= rs_reg + immediate;
                    default: begin end
                endcase
            end
            default: begin end
        endcase
    end
    else begin
        reg_10001 <= 0;
        reg_10010 <= 0;
        reg_01000 <= 0;
        reg_10111 <= 0;
        reg_11111 <= 0;
        reg_10000 <= 0;
    end
end

assign out_0 = reg_10001;
assign out_1 = reg_10010;
assign out_2 = reg_01000;
assign out_3 = reg_10111;
assign out_4 = reg_11111;
assign out_5 = reg_10000;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        instruction_fail <= 0;
        out_valid <= 0;
    end
    else if (in_valid) begin
        //instruction fail or not
        if ((opcode != 6'b0) && (opcode != 6'b001000)) begin
            instruction_fail <= 1;
            out_valid <= 1;
        end
        else begin
            instruction_fail <= 0;
            out_valid <= 1;
        end
    end
    else begin
        instruction_fail <= 0;
        out_valid <= 0;
    end
end

endmodule