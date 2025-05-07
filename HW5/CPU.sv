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
//================================================================
// declaration
//================================================================
logic [2:0] rs,rt,rd,funct;
logic I,R;
logic signed [15:0] register [6];
logic signed [62:0] result;
//================================================================
// DESIGN
//================================================================

always_comb begin
    rs = 0;
    rt = 0;
    rd = 0;
    funct = 0;

    casex(instruction[25:21])
        5'b10001: rs = 0;
        5'b10010: rs = 1;
        5'b01000: rs = 2;
        5'b10111: rs = 3;
        5'b11111: rs = 4;
        5'b10000: rs = 5;
        default: rs = 0;
    endcase

    casex(instruction[20:16])
        5'b10001: rt = 0;
        5'b10010: rt = 1;
        5'b01000: rt = 2;
        5'b10111: rt = 3;
        5'b11111: rt = 4;
        5'b10000: rt = 5;
        default: rt = 0;
    endcase

    casex(instruction[15:11])
        5'b10001: rd = 0;
        5'b10010: rd = 1;
        5'b01000: rd = 2;
        5'b10111: rd = 3;
        5'b11111: rd = 4;
        5'b10000: rd = 5;
        default: rd = 0;
    endcase

    casex(instruction[5:0])
        6'b100000: funct = 0;
        6'b011000: funct = 1;
        6'b000000: funct = 2;
        6'b000010: funct = 3;
        6'b110001: funct = 4;
        6'b110010: funct = 5;
        default: funct = 0;
    endcase
end

always_comb
begin
    result = 63'b0;
    casex(instruction[31:26])
            6'b000000: begin
                if(funct == 0)
                begin
                    result = register[rs] + register[rt];
                end
                else if(funct == 1)
                begin
                    result = (register[rs] * register[rt]) >> 15;
                end
                else if(funct == 2) result = register[rt] << instruction[10:6];
                else if(funct == 3) result = register[rt] >> instruction[10:6];
                else if(funct == 4)
                begin 
                    result = (register[rt]>=0)? register[rt] : 16'b0;
                end
                else if(funct == 5)
                begin
                    if($signed(register[rt]) > 0)
                    begin
                        result = register[rt];
                    end
                    else 
                    begin
                        result = (register[rs] * register[rt]) >> 15;
                    end
                end
                else begin end
            end
            6'b001000: 
            begin
                result = register[rs] + instruction[15:0];
            end
            default: begin end
    endcase
end

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        R<=0;
        I<=0;
        out_valid <= 0;
        instruction_fail <= 0;
        for(int i=0;i<6;i++)
        begin
            register[i] <= 0;
        end
    end
    else if(in_valid)
    begin
        instruction_fail <= 0;
        casex(instruction[31:26])
            6'b000000: begin
                out_valid <= 1;
                R<=1;
                I<=0;
                register[rd] <= result;
            end
            6'b001000: begin
                R<=0;
                I<=1;
                register[rt] <= result;
            end
            default: begin
                instruction_fail <= 1;
            end
        endcase
    end else 
    begin     
        out_valid <= 0;
        instruction_fail <= 0;    
        for(int i=0;i<6;i++)
        begin
            register[i] <= 0;
        end
    end
end

assign out_0 = register[0];
assign out_1 = register[1];
assign out_2 = register[2];
assign out_3 = register[3];
assign out_4 = register[4];
assign out_5 = register[5];

endmodule
