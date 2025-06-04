
`include "Handshake_syn.v"

module CDC(
	// Input signals
	clk_1,
	clk_2,
	rst_n,
	in_valid,
	in_data,
	// Output signals
	out_valid,
	out_data
);

input clk_1; 
input clk_2;			
input rst_n;
input in_valid;
input[3:0]in_data;

output logic out_valid;
output logic [4:0]out_data; 			

// ---------------------------------------------------------------------
// logic declaration                 
// ---------------------------------------------------------------------	
logic [3:0] regis [2];
logic [3:0] out_interact [2];
integer next;

typedef enum logic [2:0]
{
	S_wait_input1,
	S_wait_input2,
	S_send_data,
	S_keep_send,
	S_idle,
	S_get_dout_1,
	S_get_dout_2,
	S_out
} state_t ;

state_t current_state_1,current_state_2,next_state_2,next_state_1;
logic sidle_t;
logic sready_t;
logic [3:0] din_t;
logic dvalid_t;
logic [3:0] dout_t;

// ---------------------------------------------------------------------
// design              
// ---------------------------------------------------------------------
Handshake_syn sync(
					.sclk(clk_1), 
					.dclk(clk_2), 
					.rst_n(rst_n),
					.sready(sready_t), 
					.din(din_t), 
					.sidle(sidle_t),
					.dbusy(1'b0),
					.dvalid(dvalid_t),
					.dout(dout_t)
);

always_comb
begin
	next_state_1 = current_state_1;
			case(current_state_1)
			S_wait_input1:begin
				if(in_valid)
				begin
					next_state_1 = S_wait_input2;
				end
			end
			S_wait_input2:begin
				next_state_1 = S_send_data;
			end
			S_send_data:begin
				if(next < 2) 
				begin
					next_state_1 = S_keep_send;
				end
				else
				begin
					next_state_1 = S_wait_input1;
				end
			end
			S_keep_send:begin
				if(sidle_t)
				begin
					next_state_1 = S_send_data;
				end
			end
			default:begin
				next_state_1 = S_wait_input1;
			end
		endcase
end

always_ff @(posedge clk_1,negedge rst_n)
begin
	if(!rst_n)
	begin
		current_state_1 <= S_wait_input1;
	end else
	begin
		current_state_1<= next_state_1;
	end
end

always_ff @(posedge clk_1,negedge rst_n)
begin
	if(!rst_n)
	begin
		next <= 0;
		regis[0] <= 4'b0;
		regis[1] <= 4'b0;
		sready_t <= 0;
		din_t <= 4'b0;
	end else
	begin
		case(current_state_1)
			S_wait_input1:begin
				next <= 0;
				if(in_valid)
				begin
					regis[0] <= in_data;
				end
			end
			S_wait_input2:begin
				next <= 0;
				if(in_valid)
				begin
					regis[1] <= in_data;
				end
			end
			S_send_data:begin
				if(sidle_t)
				begin
					sready_t <= 1;
					if(next == 0)
					begin
						din_t <= regis[0];
					end else if(next == 1)
					begin
						din_t <= regis[1];
					end else
					begin
						din_t <= 4'b0;
					end
					next <= next + 1;
				end else if(!sidle_t)
				begin
					din_t <= 4'b0;
					sready_t <= 0;
				end
			end
			S_keep_send:begin
				din_t <= 4'b0;
				sready_t <= 0;
			end
			default:begin
			end
		endcase
	end
end

always_comb
begin
    next_state_2 = current_state_2;
	case(current_state_2)
		S_idle:begin
			if(next == 1 && dvalid_t) next_state_2 = S_get_dout_1;
		end
		S_get_dout_1:begin
			if(!dvalid_t) next_state_2 = S_get_dout_2;
		end
		S_get_dout_2:begin
			if(dvalid_t) next_state_2 = S_out;
		end
		S_out:begin
			next_state_2 = S_idle;
		end
		default:begin
			next_state_2 = S_idle;
		end
	endcase
end

always_ff @(posedge clk_2,negedge rst_n)
begin
	if(!rst_n)
	begin
		current_state_2 <= S_idle;
	end else 
	begin 
		current_state_2 <= next_state_2;
	end
end

always_ff @(posedge clk_2,negedge rst_n)
begin
	if(!rst_n)
	begin
		out_valid <= 0;
		out_data <= 5'b0;
		out_interact[0] <= 4'b0;
		out_interact[1] <= 4'b0;
	end else 
	begin 
		case(current_state_2)
		S_idle:begin
			out_valid <= 0;
			out_data <= 5'b0;
			out_interact[0] <= 4'b0;
			out_interact[1] <= 4'b0;
		end
		S_get_dout_1:begin
			if(dvalid_t) 
			begin
				out_interact[0] <= dout_t;
			end
		end
		S_get_dout_2:begin
			if(dvalid_t)
			begin
				out_interact[1] <= dout_t;
			end
		end
		S_out:begin
			out_data <= out_interact[0] + out_interact[1];
			out_valid <= 1;
		end
		default:begin
		end
	endcase
	end
end
		
endmodule