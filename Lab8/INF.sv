module INF(
	// input signal
	clk,
	rst_n,
	in_valid,
	in_mode,
	in_addr,
	in_data,
	// input axi 
	ar_ready,
	r_data,
	r_valid,
	aw_ready,
	w_ready,
	// output signals
	out_valid,
	out_data,
	// output axi
	ar_addr,
	ar_valid,
	r_ready,
	aw_addr,
	aw_valid,
	w_data,
	w_valid
);
//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, in_valid, in_mode;
input [3:0] in_addr;
input [7:0] in_data, r_data; 
input ar_ready, r_valid, aw_ready, w_ready;
output logic out_valid;
output logic [7:0] out_data, w_data;
output logic [3:0] ar_addr, aw_addr;
output logic ar_valid, r_ready, aw_valid, w_valid;
//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
typedef enum logic [2:0]
{
    S_IDLE,
    S_AR,
    S_AW,
    S_R,
    S_W,
    S_OUTPUT
} state_t ;

state_t current_state,next_state;
logic [7:0] regis [0:3];
integer Counter,data_Counter,out_Counter;
logic temp_mode;
logic [3:0] temp_addr;
//---------------------------------------------------------------------
//   YOUR DESIGN
//---------------------------------------------------------------------

always_ff @(posedge clk,negedge rst_n)
begin
    if(!rst_n)
	begin
        current_state <= S_IDLE;
	end else
	begin
        current_state <= next_state;
	end
end

always_comb
begin
    next_state = current_state;
    case(current_state)
        S_IDLE: begin
            if(in_valid)
            begin
                if(in_mode)
                    next_state = S_AW;
                else
                    next_state = S_AR; 
            end
        end
        S_AR: begin
            if(ar_valid && ar_ready)
                next_state = S_R;
        end
        S_AW: begin
            if(aw_valid && aw_ready)
                next_state = S_W;
        end
        S_R: begin
            if(r_valid && r_ready && data_Counter == 3)
                next_state = S_OUTPUT;
        end
        S_W: begin
            if(w_valid && w_ready && Counter == 3)
                next_state = S_OUTPUT;
        end
        S_OUTPUT: begin
			if(Counter == 4 && !temp_mode)
				next_state = S_IDLE;
			else if(out_Counter == 4 && temp_mode)
				next_state = S_IDLE;
        end
        default: begin
            next_state = S_IDLE;
		end
    endcase
end

always_ff @(posedge clk, negedge rst_n)
begin
    if(!rst_n)
    begin
		temp_mode <= 1'bx;
		temp_addr <= 3'b0;
		Counter <= 3'b0;
		data_Counter <= 3'b0;
		out_Counter <= 3'b0;
		regis[0] <= 8'b0;
		regis[1] <= 8'b0;
		regis[2] <= 8'b0;
		regis[3] <= 8'b0;
		out_valid <= 0;
		out_data <= 8'b0;
		ar_valid <= 0;
		ar_addr <= 4'b0;
		r_ready <= 0;
		aw_addr <= 4'b0;
		aw_valid <= 0;
		w_data <= 8'b0;
		w_valid <= 0;
    end
    else
    begin
		case(current_state)
			S_IDLE:begin
				if(in_valid)
				begin
					temp_mode <= in_mode;
					temp_addr <= in_addr;
					if(in_mode)
					begin
						regis[0] <= in_data;
						data_Counter <= data_Counter + 1;
					end
				end
			end
			S_AR:begin
				if(!in_valid)
				begin
					ar_valid <= 1;
					ar_addr <= temp_addr;
				end
				if(ar_ready)
				begin
					ar_addr <= 4'b0;
					ar_valid <= 0;
				end
			end
			S_AW:begin
				if(!in_valid)
				begin
					aw_valid <= 1;
					aw_addr <= temp_addr;
					if(aw_ready)
					begin
						w_valid <= 1;
						w_data <= regis[0];
						aw_valid <= 0;
						aw_addr <= 4'b0;
					end
				end else
				begin
					if(temp_mode)
					begin
						regis[data_Counter] <= in_data;
						data_Counter <= data_Counter + 1;
						if(aw_ready)
							aw_valid <= 0;
					end
				end
			end
			S_R:begin
				r_ready <= 1;
				if(r_valid)
				begin
					regis[data_Counter] <= r_data;
					data_Counter <= data_Counter+1;
					if(data_Counter == 3)
					begin
						r_ready <= 0;
					end
				end
			end
			S_W:begin
				if(w_ready)
				begin
					w_data <= regis[Counter+1];
					Counter <= Counter+1;
					if(Counter == 3)
					begin
						w_valid <= 0;
						w_data <= 8'b0;
					end
				end
			end
			S_OUTPUT:begin
				if(!temp_mode)
				begin
					out_valid <= 1;
					out_data <= regis[Counter];
					Counter <= Counter + 1;
					if(Counter == 4)
					begin
						out_data <= 8'b0;
						Counter <= 3'b0;
						data_Counter <= 3'b0;
						out_valid <= 0;
						regis[0] <= 8'b0;
						regis[1] <= 8'b0;
						regis[2] <= 8'b0;
						regis[3] <= 8'b0;
					end
				end
				else if(temp_mode)begin
					out_valid <= 1;
					out_data <= 4'b0;
					out_Counter <= out_Counter + 1;
					if(out_Counter == 4)
					begin
						Counter <= 3'b0;
						data_Counter <= 3'b0;
						out_valid <= 0;
						out_Counter <= 3'b0;
					end
				end
			end
			default:begin
				
			end
		endcase
    end
end

endmodule
