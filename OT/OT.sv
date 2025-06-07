module LN (
    input clk,
    input rst_n,
    input in_valid,
    input signed [7:0] in_data,

    output logic out_valid,
    output logic signed [7:0] out_data
);

logic signed [7:0] regis_pipe_1[0:7];
logic signed [8:0] regis_pipe_2[0:7];
logic [4:0] input_index;
logic [5:0] output_index;
logic signed [8:0] minus_mean;
logic signed [11:0] sum;
logic signed [11:0] sum_absolute;
logic signed [7:0] mean;
logic signed [7:0] mean_temp;
logic signed [11:0] variance;
logic signed [7:0] variance_temp;
logic [9:0] pattern;

always_ff @(posedge clk,negedge rst_n) 
begin
    if(!rst_n)
    begin
        input_index <= 'b0;
        output_index <= 'b0;
        for(int i=0;i<8;i++)
        begin
            regis_pipe_1[i] <= 'b0;
        end
    end else
    begin
        for(int i=0;i<7;i++)
        begin
            regis_pipe_1[i+1] <= regis_pipe_1[i];
        end
        if(in_valid) regis_pipe_1[0] <= in_data;

        if(in_valid || out_valid)
        begin 
            input_index <= (input_index+1)%8;
            output_index <= (output_index<16)? output_index + 1: 16;
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
    end else
    begin
        regis_pipe_2[0] <= minus_mean;
        for(int i =0;i<7;i++)
        begin
            regis_pipe_2[i+1] <= regis_pipe_2[i];
        end
    end
end


assign mean = sum / 8;
assign variance = sum_absolute / 8;
assign minus_mean = regis_pipe_1[7] - ((input_index == 0) ? mean : mean_temp);


always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        sum <= 'b0;
        sum_absolute <= 'b0;
        mean_temp <= 'b0;
    end
    else 
    begin
        if(input_index == 0) 
        begin
            sum <= in_data;
            sum_absolute <= (minus_mean[8] == 1)? -minus_mean : minus_mean;
            mean_temp <= mean;
            variance_temp <= variance;
        end else 
        begin
            sum <= sum + in_data;
            sum_absolute <= sum_absolute + ((minus_mean[8] == 1)? -minus_mean : minus_mean);
        end
    end
end

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 0;
        out_data <= 'b0;
        pattern <= 'b0;
    end else if(output_index == 16)
    begin
        out_valid <= 1;
        if(input_index == 0)
        begin
            out_data <= regis_pipe_2[7] / variance;
            pattern <= pattern + 1;
        end else
        begin
            out_data <= regis_pipe_2[7] / variance_temp;
        end
        if(pattern == 1000 && input_index == 0) 
        begin
            out_data <= 0;
            out_valid <= 0;
        end
    end
end

endmodule
