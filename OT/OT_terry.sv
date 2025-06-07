module LN (
    input clk,
    input rst_n,
    input in_valid,
    input signed [7:0] in_data,

    output logic out_valid,
    output logic signed [7:0] out_data
);

logic [4:0] input_index;
logic signed [7:0] input_buffer[0:7];
logic signed [11:0] mean;
logic signed [8:0] regis_pipe_1[0:7];
logic signed [8:0] transit;
logic signed [11:0] variance;
logic signed [8:0] mean_temp;
logic signed [7:0] output_buffer[0:7];

logic [4:0] count;

assign mean_temp = mean / 8;
assign transit = input_buffer[0] - mean_temp;

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
    end else
    begin
        if(in_valid) input_buffer[input_index] <= in_data;
        if(input_index == 0)
        begin
            mean <= in_data;
            variance <= (transit < 0)? -transit : transit;
        end
        else
        begin
            mean <= mean + in_data;
            variance <= variance + ((regis_pipe_1[input_index][8] == 1)? -regis_pipe_1[input_index]:regis_pipe_1[input_index]);
        end
        if(in_valid || out_valid) input_index <= (input_index+1)%8;
    end
end


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
            output_buffer[i] <= regis_pipe_1[i] / (variance / 8);
        end
    end
end

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        out_data <= 'b0;
        out_valid <= 'b0;

        count <= 0;
    end else
    begin
        if (in_valid) count <= (count == 16) ? count : (count + 1);
        else if (out_valid) count <= count - 1;

        if (count == 16) 
        begin
            out_valid <= 1;
        end else if (!in_valid && count == 0)
        begin
            out_valid <= 0;
        end

        if (!in_valid && count == 0) out_data <= 0;
        else if (count == 16 || out_valid)
        begin
            if (input_index == 0) out_data <= regis_pipe_1[0] / (variance / 8);
            else out_data <= output_buffer[input_index];
        end else begin end
    end
end

endmodule
