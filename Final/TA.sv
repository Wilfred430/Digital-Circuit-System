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

type
 

always_ff @(posedge clk, negedge rst_n)
begin
	
end



endmodule
