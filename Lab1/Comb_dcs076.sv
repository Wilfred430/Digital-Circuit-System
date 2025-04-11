module Comb(
  // Input signals
	in_num0,
	in_num1,
	in_num2,
	in_num3,
  // Output signals
	out_num0,
	out_num1
);


//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [6:0] in_num0, in_num1, in_num2, in_num3;
output logic [7:0] out_num0, out_num1;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
  // result store
  logic [6:0] xnor_result;
  logic [6:0] or_result;
  logic [6:0] and_result;
  logic [6:0] xor_result;
  logic [6:0] large_1_num;
  logic [6:0] small_1_num;
  logic [6:0] large_2_num;
  logic [6:0] small_2_num;
  logic [7:0] adder_result;
  logic [6:0] gray_code;
//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------

always @(*) begin

 xnor_result = in_num0 ~^ in_num1;  
 or_result   = in_num1 | in_num3;   
 and_result  = in_num2 & in_num0;   
 xor_result  = in_num3 ^ in_num2; 

 large_1_num = (xnor_result > or_result) ? xnor_result : or_result;
small_1_num = (xnor_result > or_result) ? or_result : xnor_result;
 large_2_num = (and_result > xor_result) ? and_result : xor_result;
 small_2_num = (and_result > xor_result) ? xor_result : and_result;

 out_num0 = large_1_num + large_2_num;
 adder_result = small_1_num + small_2_num;

 out_num1 = adder_result ^ (adder_result >> 1);

end

endmodule