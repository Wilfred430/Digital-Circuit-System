module MAC(
        // Input signals
        clk,
        rst_n,
        in_valid,
        in_mode,
        in_act,
        in_wgt,
        // Output signals
        out_act_idx,
        out_wgt_idx,
        out_idx,
        out_valid,
        out_data,
        out_finish
);

//--------------------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//--------------------------------------------------------------------------------------
input clk, rst_n, in_valid, in_mode;
input [0:7][3:0] in_act;
input [0:8][3:0] in_wgt;
output logic [3:0] out_act_idx, out_wgt_idx, out_idx;
output logic out_valid, out_finish;
output logic [0:7][11:0] out_data;

//--------------------------------------------------------------------------------------
//   REG AND WIRE DECLARATION
//--------------------------------------------------------------------------------------
logic [3:0] i;
logic [3:0] z;
logic [3:0] j;
logic [3:0] t;
logic [3:0] k;
logic [3:0] m;
logic [3:0] n;
logic work_type;
logic input_start;
logic input_end;
logic [3:0] next;
logic [3:0] output_next;
logic [3:0] activation [0:9][0:9];
logic [3:0] weight [0:7][0:7];
logic [11:0] result [0:7][0:7];
//--------------------------------------------------------------------------------------
//   YOUR DESIGN
//--------------------------------------------------------------------------------------

// register in_mode signal

// reset all output signal
always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                out_act_idx <= 4'bX;
                out_wgt_idx <= 4'bX;
                out_idx <= 4'b0;
                out_valid <= 1'b0;
                out_finish <= 1'b0;
                next <= 4'b0;
                output_next<=4'b0;
                input_start <= 0;
                for(i=0;i<8;i=i+1)
                begin
                        out_data <= 12'b0;
                end
		end else if(in_valid)
		begin
			work_type <= in_mode;
		end
		else if(out_finish)
        begin
                out_act_idx <= 4'bX;
                out_wgt_idx <= 4'bX;
                out_idx <= 4'b0;
                out_valid <= 1'b0;
                out_finish <= 1'b0;
                next <= 0;
                output_next<=4'b0;
                input_start <= 0;
				work_type <= 'bX;
                for(i=0;i<8;i=i+1)
                begin
                        out_data <= 12'b0;
                end
        end
        else if(((!work_type) || (work_type)) && next < 8)
        begin
                input_start <= 1;
                out_act_idx <= {1'b0,next};
                out_wgt_idx <= {1'b0,next};
                next <= next+1;
        end
        else if(input_end)
        begin
                out_valid <= 1;
                for(i=0;i<8;i=i+1)
                begin
                        out_data[i] <= result[output_next][i];
                end
                out_idx <= {1'b0,output_next};
                output_next <= output_next+1;
                out_finish <= (output_next == 7)? 1:0;
        end 
        else
        begin end
end

always_ff @(posedge clk,negedge rst_n)
begin
        if(input_start)
        begin
                for(j=0;j<8;j=j+1)
                begin
                        if(!work_type)
                        begin
                                activation[next-1][j] <= in_act[j];
                        end
                        else
                        begin
                                activation[next-1+1][j+1] <= in_act[j];
                        end
                        weight[next-1][j] <= in_wgt[j];
                end
                input_end <= (next == 8)? 1 : 0;
        end 
        else
        begin
                input_end <= 0;
                for(z=0;z<10;z=z+1)
                begin
                        for(j=0;j<10;j=j+1)
                        begin
                                activation[z][j] <= 4'b0;
                                if(j<8 && z<8)
                                begin 
                                    weight[z][j] <= 4'b0; 
                                end
                        end
                end        
        end
end

always_comb
begin
        // matrix multiplication
        if(!work_type && input_end)
        begin
                for(t=0;t<8;t=t+1)
                begin
                        for(k=0;k<8;k=k+1)
                        begin
                                for(n=0;n<8;n=n+1)
                                begin
                                        result[t][k] = result[t][k] + activation[t][n] * weight[n][k];
                                end
                        end
                end
        end
        // CNN operation
        else if(work_type && input_end)
        begin
                for(t=0;t<8;t=t+1)
                begin
                        for(k=0;k<8;k=k+1)
                        begin
                                for(n=0;n<3;n=n+1)
                                begin
                                        for(m=0;m<3;m=m+1)
                                        begin
                                                result[t][k] = result[t][k] + activation[t+n][k+m] * weight[n][m];
                                        end
                                end
                        end
                end
        end
        else
        begin
                for(t=0;t<8;t=t+1)
                begin
                        for(k=0;k<8;k=k+1)
                        begin
                                result[t][k] = 12'b0;
                        end
                end
        end
end  

endmodule