module LN (
    input clk,
    input rst_n,
    input in_valid,
    input signed [7:0] in_data,

    output logic out_valid,
    output logic signed [7:0] out_data
);

logic [4:0] input_index;
logic [5:0] output_index;
logic signed [7:0] input_buffer[0:7];
logic signed [11:0] mean;
logic signed [8:0] regis_pipe_1[0:7];
logic signed [7:0] regis_pipe_2[0:7];
logic signed [8:0] transit;
logic signed [7:0] transit_out;
logic signed [11:0] variance;
logic signed [7:0] variance_temp;
logic signed [7:0] mean_temp;
logic [9:0] pattern;

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        mean <= 'b0;
        for(int i=0;i<8;i++)
        begin
            input_buffer[i] <= 'b0;
        end
        input_index <= 'b0;
        output_index <= 'b0;
    end else
    begin

        if(input_index == 0)
        begin
            mean <= in_data;
            variance <= (transit[8] == 1)? -transit : transit;
        end
        else
        begin
            mean <= mean + in_data;
            variance <= variance + ((regis_pipe_1[input_index][8] == 1) ? -regis_pipe_1[input_index]:regis_pipe_1[input_index]);
        end
        if(in_valid || out_valid) 
        begin
            input_buffer[input_index] <= in_data;
            output_index <= output_index + 1;
            input_index <= (input_index+1)%8;
            output_index <= (output_index<16)? output_index + 1: 16;
        end

    end
end

assign mean_temp = mean / 8;
assign variance_temp = variance/8;
assign transit = input_buffer[0] - mean_temp;

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        for(int i=0;i<8;i++)
        begin
            regis_pipe_1[i] <= 'b0;
        end
    end else if(input_index == 0)
    begin
        for(int i=0;i<8;i++)
        begin
            regis_pipe_1[i] <= input_buffer[i] - mean_temp;
        end
    end
end

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        for(int i=0;i<8;i++)
        begin
            regis_pipe_2[i] <= 'b0;
        end
    end else if(input_index == 0)
    begin
        for(int i=0;i<8;i++)
        begin
            regis_pipe_2[i] <= regis_pipe_1[i] / variance_temp;
        end
    end
end

assign transit_out = regis_pipe_1[0] / variance_temp;

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        out_data <= 'b0;
        out_valid <= 'b0;
        pattern <= 'b0;
    end else if(output_index == 16)
    begin
        out_valid <= 1;
        if(input_index == 0)
        begin
            out_data <= transit_out;
            pattern <= pattern + 1;
        end
        else
        begin
            out_data <= regis_pipe_2[input_index];
        end
        if(pattern == 1000 && input_index == 0) 
        begin
            out_data <= 0;
            out_valid <= 0;
        end
    end
end

endmodule