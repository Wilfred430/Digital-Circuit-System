
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
logic [3:0] regis[2];
integer next;
integer next_silde;
logic pre_dvalid;
logic finish;

typedef enum logic [2:0]
{
	S_wait_input1,
	S_wait_input2,
	S_send_data,
	S_idle,
	S_get_dout,
	S_out
} state_t ;

state_t current_state_1,current_state_2,next_state_2;
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
					.dbusy(0),
					.dvalid(dvalid_t),
					.dout(dout_t)
);

always_ff @(posedge clk_1,negedge rst_n)
begin
    if(!rst_n)
	begin
        current_state_1 <= S_wait_input1;
		next_silde <= 0;
		sready_t <= 0;
		din_t <= 4'b0;
	end else
	begin
		case(current_state_1)
			S_wait_input1:begin
				if(in_valid) current_state_1 <= S_wait_input2;
				next_silde <= 0;
			end
			S_wait_input2:begin
				current_state_1 <= S_send_data;
			end
			S_send_data:begin
				if(sidle_t)
				begin
					sready_t <= 1;
					din_t <= regis[next_silde];
					next_silde <= next_silde + 1;
				end
				else
				begin
					sready_t <= 1;
				end
				if(next_silde > 1)
				begin
					current_state_1 <= S_wait_input1;
				end
			end
			default:begin
				current_state_1 <= S_wait_input1;
			end
		endcase
	end
end

always_ff @(posedge clk_1,negedge rst_n)
begin
	if(!rst_n)
	begin
		next <= 0;
		regis[0] <= 4'b0;
		regis[1] <= 4'b0;
	end 
	else if(in_valid && (current_state_1 == S_wait_input1 || current_state_1 == S_wait_input2))
	begin
		regis[next] <= in_data;
		next <= (next == 0) ? next+1 : 0; 
	end else begin end
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

always_comb
begin
    next_state_2 = current_state_2;
	case(current_state_2)
		S_idle:begin
			if(!pre_dvalid && dvalid_t) next_state_2 = S_get_dout;
		end
		S_get_dout:begin
			if(!pre_dvalid && dvalid_t) next_state_2 = S_out;
		end
		S_out:begin
			next_state_2 = S_idle;
		end
		default:begin
			next_state_2 = S_idle;
		end
	endcase

	pre_dvalid = dvalid_t;
end

always_ff @(posedge clk_2,negedge rst_n)
begin
	if(!rst_n)
	begin
		out_valid <= 0;
		out_data <= 5'b0;
		finish <= 0;
	end else if(finish) 
	begin
		finish <= 0;
		out_valid <= 0;
		out_data <= 5'b0;
	end
	else if(current_state_2 == S_out)
	begin
		out_valid <= 1;
		out_data <= regis[0] + regis[1];
		finish <= 1;
	end else begin end
end
		
endmodule