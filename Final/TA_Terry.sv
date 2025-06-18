module TA(
    clk, 
	rst_n, 
	// input 
	i_valid, 
	i_length,
	m_ready,
	// virtual memory
	m_data,
	m_read,
	m_addr,
	// output 
	o_valid, 
	o_data 
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n; 
// input
input i_valid; 
input [1:0] i_length;
input m_ready;
// virtual memory
input [31:0] m_data; 
output logic m_read;
output logic  [5:0] m_addr; 
// output 
output logic o_valid; 
output logic [40:0] o_data;

integer i, j, l, n, idx;

// input mode register
logic [1:0] in_mode;
logic [5:0] size, size_next;
logic [9:0] count;
// memory reading register
logic memory_reading, m_phase, m_finish, m_read_next;
logic [2:0] m_count;

// RAT
logic [3:0] token_prev [0:7];
logic [6:0] sum_row;
assign sum_row = token_prev[7] + token_prev[6] + token_prev[5] + token_prev[4] + token_prev[3] + token_prev[2] + token_prev[1] + token_prev[0];
logic [3:0] mean_row;
assign mean_row = sum_row >> 3;
logic [3:0] rat [0:7];
logic [3:0] i_token [0:31][0:7];

// token * weight
typedef enum logic [1:0] { 
	IDLE = 2'b00,
	Q = 2'b01,
	K = 2'b10,
	V = 2'b11
} m_state;
m_state ms;
logic [3:0] mat_col [0:7];
logic [4:0] p_count;
logic [10:0] q [0:31][0:7];
logic [10:0] k [0:31][0:7];
logic [10:0] v [0:31][0:7];
logic new_col;
assign new_col = (p_count == (size - 1));
logic [10:0] result1;
logic [3:0] a [0:7];
logic [3:0] b [0:7];

// k^T * q
logic kq_phase, kq_finish;
logic [25:0] scores [0:31][0:31];
logic [4:0] row_count, col_count;
logic [36:0] result2;
logic [36:0] c [0:7];
logic [36:0] d [0:7];

// CAT
logic cat_phase, cat_finish;
logic [44:0] sum_col;
logic [41:0] mean_col;
logic [4:0] process_count; // row wise
logic [4:0] cat_count; // column wise
logic flag; // flag = 0: accumulate; flag = 1: threshold

// output
logic out_phase, out_finish;
logic [40:0] outvec [0:7];
logic [5:0] slt_count;
logic [2:0] out_count;

// memory reading phase
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		m_read <= 0;
		m_addr <= 0;
		count <= 0;
		m_count <= 0;
		p_count <= 0;
		ms <= IDLE;
		m_phase <= 0;
		in_mode <= 0;
		size <= 0;
	end else begin
		m_read <= m_read_next;
		size <= size_next;

		// start reading
		if (i_valid) begin
			in_mode <= i_length;
		end else if (m_ready) begin
			memory_reading <= 1;
		end else begin
			memory_reading <= 0;
		end

		if (count == size * 25 && m_phase) begin
			m_phase <= 0;
			m_finish <= 1;
			count <= 0;
		end
		else if (memory_reading) begin
			m_phase <= 1;
			m_addr <= 0;
		end
		else if (m_phase) begin 
			count <= count + 1;
		end else begin
			count <= 0;
		end
		if (m_finish) m_finish <= 0;

		// control "counts" and address
		if (m_phase && count < size) m_addr <= count + 1;
		else if (count == size) begin
			p_count <= 0;
		end else if (m_phase) begin
			p_count <= (p_count + 1) % size;
			m_count <= (new_col) ? (m_count + 1) : m_count;
			m_addr <= (p_count == size - 2) ? (m_addr + 1) : m_addr;
		end

		// control which matrix to store
		if (count >= size * 25) ms <= IDLE;
		else if (count >= size * 17) ms <= V;
		else if (count >= size * 9) ms <= K;
		else if (count >= size) ms <= Q;
		else ms <= IDLE;

		// input matrix
		if (count < size) begin
			// i_token Matrix
			{token_prev[7], token_prev[6], token_prev[5], token_prev[4], token_prev[3], token_prev[2], token_prev[1], token_prev[0]} <= m_data;
		end else begin
			// weight Matrix
			{mat_col[7], mat_col[6], mat_col[5], mat_col[4], mat_col[3], mat_col[2], mat_col[1], mat_col[0]} <= m_data;
		end

		// RAT process
		if (count > 0 && count < size + 1) begin
			for (n = 0; n < 8; n = n + 1) begin
				i_token[count-1][n] <= rat[n];
			end
		end

		// MM process
		if (m_phase) begin
			case (ms)
				Q: q[p_count][m_count] <= result1;
				K: k[p_count][m_count] <= result1;
				V: v[p_count][m_count] <= result1;
				default: begin end
			endcase
		end
	end
end
// memory reading phase
always_comb begin
	size_next = size;
	case (in_mode)
		'b00: size_next = 4;
		'b01: size_next = 8;
		'b10: size_next = 16;
		'b11: size_next = 32;
	endcase

	m_read_next = m_read;
	if (count == size * 25 && m_phase) begin
		m_read_next = 0;
	end else if (memory_reading || m_phase) begin
		m_read_next = 1;
	end

	// RAT
	for (i = 0; i < 8; i = i + 1) begin
		if (token_prev[i] < mean_row) begin
			rat[i] = 0;
		end else begin
			rat[i] = token_prev[i];
		end
	end

	// first MM
	for (l = 0; l < 8; l = l + 1) begin
		a[l] = i_token[p_count][l];
		b[l] = mat_col[l];
	end
	result1 = a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3] + a[4]*b[4] + a[5]*b[5] + a[6]*b[6] + a[7]*b[7];
end

// KQ phase and CAT phase
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		// KQ
		kq_phase <= 0;
		kq_finish <= 0;
		row_count <= 0;
		col_count <= 0;
		// CAT
		cat_phase <= 0;
		cat_finish <= 0;
		process_count <= 0;
		cat_count <= 0;
		flag <= 0;
	end else begin
		// switch to KQ phase
		if (m_finish && !kq_phase) begin
			kq_phase <= 1;
		end else if (kq_finish) begin
			kq_finish <= 0;
		end

		// switch to CAT phase
		if (row_count == size - 1 && col_count == size - 1) begin
			kq_finish <= 1;
			kq_phase <= 0;
		end

		// switch to SLT phase
		if (kq_finish) begin
			cat_phase <= 1;
		end else if (cat_finish) begin
			cat_finish <= 0;
			process_count <= 0;
			cat_count <= 0;
		end

		// KQ process
		if (kq_phase) begin
			scores[row_count][col_count] <= result2;
			row_count <= (row_count + 1) % size;
			col_count <= (row_count == size - 1) ? ((col_count + 1) % size) : col_count;
		end

		// CAT process
		if (cat_phase) begin
			// 0 -> sum; 1 -> CAT
			case (flag)
				0: begin
					sum_col <= (process_count == 0) ? scores[process_count][cat_count] : (sum_col + scores[process_count][cat_count]);
				end
				1: begin
					scores[process_count][cat_count] <= (scores[process_count][cat_count] < mean_col) ? 0 : scores[process_count][cat_count];
					cat_count <= (process_count == size - 1) ? (cat_count + 1) : cat_count;
				end
			endcase
			if (process_count == size - 1) flag <= !flag;

			process_count <= (process_count + 1) % size;
			if (cat_count == size - 1 && process_count == size - 1 && flag) begin
				cat_finish <= 1;
				cat_phase <= 0;
			end
		end
	end
end
// KQ phase and CAT phase
always_comb begin
	// second MM
	for (j = 0; j < 8; j = j + 1) begin
		c[j] = k[col_count][j];
		d[j] = q[row_count][j];
	end
	result2 = c[0]*d[0] + c[1]*d[1] + c[2]*d[2] + c[3]*d[3] + c[4]*d[4] + c[5]*d[5] + c[6]*d[6] + c[7]*d[7];
	// CAT
	mean_col = sum_col >> (in_mode + 2);
end

// OUT phase
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		o_valid <= 0;
		o_data <= 0;
		out_phase <= 0;
		out_finish <= 0;
		slt_count <= 0;
		{outvec[0], outvec[1], outvec[2], outvec[3], outvec[4], outvec[5], outvec[6], outvec[7]} <= 0;
	end else begin

		// control o_valid
		if (cat_finish) begin
			out_phase <= 1;
		end else if (out_finish) begin
			out_finish <= 0;
			out_phase <= 0;
			o_valid <= 1;
			o_data <= outvec[0];
			out_count <= 0;
		end

		// output
		if (o_valid) begin
			if (out_count == 7) begin
				o_valid <= 0;
				o_data <= 0;
				out_count <= 0;
				slt_count <= 0;
				{outvec[0], outvec[1], outvec[2], outvec[3], outvec[4], outvec[5], outvec[6], outvec[7]} <= 0;
			end else begin
				o_data <= outvec[out_count + 1];
				out_count <= out_count + 1;
			end
		end

		// SLT
		if (out_phase && !out_finish) begin
			for (idx = 0; idx < 8; idx = idx + 1) begin
				outvec[idx] <= outvec[idx] + scores[size-1][slt_count] * v[slt_count][idx];
			end
			slt_count <= (slt_count + 1) % size;
			if (slt_count == size - 1) begin
				out_finish <= 1;
			end
		end
	end
end


endmodule


