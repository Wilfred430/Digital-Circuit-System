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
output logic [5:0] m_addr;
// output
output logic o_valid;
output logic [40:0] o_data;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------

// FSM
typedef enum logic [3:0] 
{
        S_IDLE,
        S_INPUT, // input i_token
        S_CALCULATE_Q, // MM q
        S_CALCULATE_K_TRANS,
        S_CALCULATE_V,
        S_CALCULATE_SCORE,
        S_SCORE_CAT,
        S_CALCULATE_O_TOKEN,
        S_OUTPUT
} state_t;

state_t current_state, next_state;

// input_length
logic [5:0] i_token_length;
// main input matrix
logic [3:0] i_token [0:31][0:7];
logic [3:0] WQ [0:7][0:7];
logic [3:0] WK [0:7][0:7];
logic [3:0] WV [0:7][0:7];
// main operation matrix
logic [10:0] q_matrix[0:31][0:7];
logic [10:0] k_trans_matrix[0:7][0:31];
logic [10:0] v_matrix[0:31][0:7];
logic [24:0] score_matrix [0:31][0:31];
logic [40:0] o_token [0:31];

// threshold
logic [4:0] RAT; 
logic [30:0] CAT;

// timer
logic [5:0] input_index;
integer q_index;
integer k_trans_index;
integer v_index;
integer score_index;
integer CAT_index;
integer o_token_index;
integer out_index;
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
        S_IDLE: if(m_ready) next_state = S_INPUT;
        S_INPUT: if(input_index == (i_token_length + 24)) next_state = S_CALCULATE_Q;
        S_CALCULATE_Q: if(q_index == (i_token_length * 8)) next_state = S_CALCULATE_K_TRANS;
        S_CALCULATE_K_TRANS: if(k_trans_index == (i_token_length * 8)) next_state = S_CALCULATE_V;
        S_CALCULATE_V: if(v_index == (i_token_length * 8)) next_state = S_CALCULATE_SCORE;
        S_CALCULATE_SCORE: if(score_index == (i_token_length * i_token_length)) next_state = S_SCORE_CAT;
        S_SCORE_CAT: if(CAT_index == i_token_length) next_state = S_CALCULATE_O_TOKEN;
        S_CALCULATE_O_TOKEN: if(o_token_index == 8) next_state = S_OUTPUT;
        S_OUTPUT: if(out_index == 8) next_state = S_IDLE;
        default: next_state = S_IDLE;
        endcase        
end

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                i_token_length <= 'b0;
        end else if(i_valid)
        begin
                case(i_length)
                'd0: i_token_length <= 'd4;
                'd1: i_token_length <= 'd8;
                'd2: i_token_length <= 'd16;
                'd3: i_token_length <= 'd32;
                default: i_token_length <= 'd0;
                endcase
        end
end


// assign 

always_ff @(posedge clk,negedge rst_n) 
begin
        if(!rst_n)
        begin
                m_addr <= 'b0;
                m_read <= 'b0;
                input_index <= 'b0;
        end else if(current_state == S_INPUT)
        begin
                m_read <= 'b1;
                m_addr <= input_index;
                input_index <= input_index + 1;
        end else if(current_state == S_IDLE || current_state == S_CALCULATE_Q)
        begin
                m_read <= 'b0;
                m_addr <= 'b0;
                input_index <= 'b0;
        end
end

assign RAT = (m_data[31:28] + m_data[27:24] + m_data[23:20] + m_data[19:16] + m_data[15:12] + m_data[11:8] + m_data[7:4] + m_data[3:0]) / 8;

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                i_token <= '{default:0};
                WK <= '{default:0};
                WQ <= '{default:0};
                WV <= '{default:0};
        end else if(current_state == S_INPUT)
        begin
                if(m_addr < i_token_length)
                begin
                        i_token[m_addr][7] <= (m_data[31:28] >= RAT) ? m_data[31:28] : 'b0;
                        i_token[m_addr][6] <= (m_data[27:24] >= RAT) ? m_data[27:24] : 'b0;
                        i_token[m_addr][5] <= (m_data[23:20] >= RAT) ? m_data[23:20] : 'b0;
                        i_token[m_addr][4] <= (m_data[19:16] >= RAT) ? m_data[19:16] : 'b0;
                        i_token[m_addr][3] <= (m_data[15:12] >= RAT) ? m_data[15:12] : 'b0;
                        i_token[m_addr][2] <= (m_data[11:8] >= RAT) ? m_data[11:8] : 'b0;
                        i_token[m_addr][1] <= (m_data[7:4] >= RAT) ? m_data[7:4] : 'b0;
                        i_token[m_addr][0] <= (m_data[3:0] >= RAT) ? m_data[3:0] : 'b0;
                end 
                else if(m_addr < i_token_length + 8)
                begin
                        WQ[7][m_addr - i_token_length] <= m_data[31:28];
                        WQ[6][m_addr - i_token_length] <= m_data[27:24];
                        WQ[5][m_addr - i_token_length] <= m_data[23:20];
                        WQ[4][m_addr - i_token_length] <= m_data[19:16];
                        WQ[3][m_addr - i_token_length] <= m_data[15:12];
                        WQ[2][m_addr - i_token_length] <= m_data[11:8];
                        WQ[1][m_addr - i_token_length] <= m_data[7:4];
                        WQ[0][m_addr - i_token_length] <= m_data[3:0];         
                end 
                else if(m_addr < i_token_length + 16)
                begin
                        WK[7][m_addr - i_token_length - 8] <= m_data[31:28];
                        WK[6][m_addr - i_token_length - 8] <= m_data[27:24];
                        WK[5][m_addr - i_token_length - 8] <= m_data[23:20];
                        WK[4][m_addr - i_token_length - 8] <= m_data[19:16];
                        WK[3][m_addr - i_token_length - 8] <= m_data[15:12];
                        WK[2][m_addr - i_token_length - 8] <= m_data[11:8];
                        WK[1][m_addr - i_token_length - 8] <= m_data[7:4];
                        WK[0][m_addr - i_token_length - 8] <= m_data[3:0];
                end 
                else
                begin
                        WV[7][m_addr - i_token_length - 16] <= m_data[31:28];
                        WV[6][m_addr - i_token_length - 16] <= m_data[27:24];
                        WV[5][m_addr - i_token_length - 16] <= m_data[23:20];
                        WV[4][m_addr - i_token_length - 16] <= m_data[19:16];
                        WV[3][m_addr - i_token_length - 16] <= m_data[15:12];
                        WV[2][m_addr - i_token_length - 16] <= m_data[11:8];
                        WV[1][m_addr - i_token_length - 16] <= m_data[7:4];
                        WV[0][m_addr - i_token_length - 16] <= m_data[3:0];
                end
        end else if(current_state == S_IDLE)
        begin
                i_token <= '{default:0};
                WK <= '{default:0};
                WQ <= '{default:0};
                WV <= '{default:0};
        end
end

// calculate q matrix
integer q_row;
integer q_col;
assign q_row = q_index >> 3;
assign q_col = q_index % 8;

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                q_matrix <= '{default:0};
                q_index <= 'd0;
        end else if(current_state == S_CALCULATE_Q) 
        begin
                q_matrix[q_row][q_col] <= (i_token[q_row][0] * WQ[0][q_col])+(i_token[q_row][1] * WQ[1][q_col])+(i_token[q_row][2] * WQ[2][q_col])
                                          + (i_token[q_row][3] * WQ[3][q_col])+(i_token[q_row][4] * WQ[4][q_col])+(i_token[q_row][5] * WQ[5][q_col])
                                          + (i_token[q_row][6] * WQ[6][q_col])+(i_token[q_row][7] * WQ[7][q_col]);
                q_index <= q_index + 1;
        end else if(current_state == S_IDLE)
        begin
                q_matrix <= '{default:0};
                q_index <= 'd0;
        end
end

// calculate k matrix and transpose it
integer k_row;
integer k_col;
assign k_row = k_trans_index >> 3;
assign k_col = k_trans_index % 8;

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                k_trans_matrix <= '{default:0};
                k_trans_index <= 'd0;
        end else if(current_state == S_CALCULATE_K_TRANS)
        begin
                k_trans_matrix[k_col][k_row] <= (i_token[k_row][0] * WK[0][k_col]) + (i_token[k_row][1] * WK[1][k_col]) + (i_token[k_row][2] * WK[2][k_col])
                                                + (i_token[k_row][3] * WK[3][k_col]) + (i_token[k_row][4] * WK[4][k_col]) + (i_token[k_row][5] * WK[5][k_col])
                                                + (i_token[k_row][6] * WK[6][k_col]) + (i_token[k_row][7] * WK[7][k_col]);
                k_trans_index <= k_trans_index + 1;
        end else if(current_state == S_IDLE)
        begin
                k_trans_matrix <= '{default:0};
                k_trans_index <= 'd0;
        end
end

integer v_row;
integer v_col;
assign v_row = v_index >> 3;
assign v_col = v_index % 8;

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                v_matrix <= '{default:0};
                v_index <= 'd0;
        end else if(current_state == S_CALCULATE_V)
        begin
                v_matrix[v_row][v_col] <= (i_token[v_row][0] * WV[0][v_col]) + (i_token[v_row][1] * WV[1][v_col]) + (i_token[v_row][2] * WV[2][v_col])
                                          + (i_token[v_row][3] * WV[3][v_col]) + (i_token[v_row][4] * WV[4][v_col]) + (i_token[v_row][5] * WV[5][v_col])
                                          + (i_token[v_row][6] * WV[6][v_col]) + (i_token[v_row][7] * WV[7][v_col]);
                v_index <= v_index + 1;
        end else if(current_state == S_IDLE)
        begin
                v_matrix <= '{default:0};
                v_index <= 'd0;
        end
end

integer score_row;
integer score_col;
assign score_row = score_index / i_token_length;
assign score_col = score_index % i_token_length;

always_comb 
begin
        CAT = 'd0;
        if(current_state == S_SCORE_CAT)
        begin
                for(int i=0;i<i_token_length;i++)
                begin
                        CAT = CAT + score_matrix[i][CAT_index];
                end
                CAT = CAT / i_token_length;
        end
end

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                score_matrix <= '{default:0};
                score_index <= 'd0;
                CAT_index <= 'd0;
        end else if(current_state == S_CALCULATE_SCORE)
        begin
                score_matrix[score_row][score_col] <= (q_matrix[score_row][0] * k_trans_matrix[0][score_col]) + (q_matrix[score_row][1] * k_trans_matrix[1][score_col])
                                                        + (q_matrix[score_row][2] * k_trans_matrix[2][score_col]) + (q_matrix[score_row][3] * k_trans_matrix[3][score_col]) 
                                                        + (q_matrix[score_row][4] * k_trans_matrix[4][score_col]) + (q_matrix[score_row][5] * k_trans_matrix[5][score_col])
                                                        + (q_matrix[score_row][6] * k_trans_matrix[6][score_col]) + (q_matrix[score_row][7] * k_trans_matrix[7][score_col]);
                score_index <= score_index + 1;
        end else if(current_state == S_SCORE_CAT)
        begin
                score_matrix[i_token_length-1][CAT_index] <= (score_matrix[i_token_length-1][CAT_index] >= CAT)? score_matrix[i_token_length-1][CAT_index] : 'd0;
                CAT_index <= CAT_index + 1;
        end else if(current_state == S_IDLE)
        begin
                score_matrix <= '{default:0};
                score_index <= 'd0;
                CAT_index <= 'd0;
        end
end

always_ff @(posedge clk,negedge rst_n)
begin
        if(!rst_n)
        begin
                o_token_index <='d0;
                o_token <= '{default:0};
        end else if(current_state == S_CALCULATE_O_TOKEN)
        begin
                if(i_token_length == 4)
                begin
                o_token[o_token_index] <= (score_matrix[i_token_length-1][0] * v_matrix[0][o_token_index])
                                        + (score_matrix[i_token_length-1][1] * v_matrix[1][o_token_index])
                                        + (score_matrix[i_token_length-1][2] * v_matrix[2][o_token_index])
                                        + (score_matrix[i_token_length-1][3] * v_matrix[3][o_token_index]);
                end
                else if(i_token_length == 8)
                begin
                o_token[o_token_index] <= (score_matrix[i_token_length-1][0] * v_matrix[0][o_token_index])
                                        + (score_matrix[i_token_length-1][1] * v_matrix[1][o_token_index])
                                        + (score_matrix[i_token_length-1][2] * v_matrix[2][o_token_index])
                                        + (score_matrix[i_token_length-1][3] * v_matrix[3][o_token_index])
                                        + (score_matrix[i_token_length-1][4] * v_matrix[4][o_token_index])
                                        + (score_matrix[i_token_length-1][5] * v_matrix[5][o_token_index])
                                        + (score_matrix[i_token_length-1][6] * v_matrix[6][o_token_index])
                                        + (score_matrix[i_token_length-1][7] * v_matrix[7][o_token_index]);
                end
                else if(i_token_length == 16)
                begin
                o_token[o_token_index] <= (score_matrix[i_token_length-1][0]  * v_matrix[0][o_token_index])
                                        + (score_matrix[i_token_length-1][1]  * v_matrix[1][o_token_index])
                                        + (score_matrix[i_token_length-1][2]  * v_matrix[2][o_token_index])
                                        + (score_matrix[i_token_length-1][3]  * v_matrix[3][o_token_index])
                                        + (score_matrix[i_token_length-1][4]  * v_matrix[4][o_token_index])
                                        + (score_matrix[i_token_length-1][5]  * v_matrix[5][o_token_index])
                                        + (score_matrix[i_token_length-1][6]  * v_matrix[6][o_token_index])
                                        + (score_matrix[i_token_length-1][7]  * v_matrix[7][o_token_index])
                                        + (score_matrix[i_token_length-1][8]  * v_matrix[8][o_token_index])
                                        + (score_matrix[i_token_length-1][9]  * v_matrix[9][o_token_index])
                                        + (score_matrix[i_token_length-1][10] * v_matrix[10][o_token_index])
                                        + (score_matrix[i_token_length-1][11] * v_matrix[11][o_token_index])
                                        + (score_matrix[i_token_length-1][12] * v_matrix[12][o_token_index])
                                        + (score_matrix[i_token_length-1][13] * v_matrix[13][o_token_index])
                                        + (score_matrix[i_token_length-1][14] * v_matrix[14][o_token_index])
                                        + (score_matrix[i_token_length-1][15] * v_matrix[15][o_token_index]);
                end
                else if(i_token_length == 32)
                begin
                o_token[o_token_index] <= (score_matrix[i_token_length-1][0]  * v_matrix[0][o_token_index])
                                        + (score_matrix[i_token_length-1][1]  * v_matrix[1][o_token_index])
                                        + (score_matrix[i_token_length-1][2]  * v_matrix[2][o_token_index])
                                        + (score_matrix[i_token_length-1][3]  * v_matrix[3][o_token_index])
                                        + (score_matrix[i_token_length-1][4]  * v_matrix[4][o_token_index])
                                        + (score_matrix[i_token_length-1][5]  * v_matrix[5][o_token_index])
                                        + (score_matrix[i_token_length-1][6]  * v_matrix[6][o_token_index])
                                        + (score_matrix[i_token_length-1][7]  * v_matrix[7][o_token_index])
                                        + (score_matrix[i_token_length-1][8]  * v_matrix[8][o_token_index])
                                        + (score_matrix[i_token_length-1][9]  * v_matrix[9][o_token_index])
                                        + (score_matrix[i_token_length-1][10] * v_matrix[10][o_token_index])
                                        + (score_matrix[i_token_length-1][11] * v_matrix[11][o_token_index])
                                        + (score_matrix[i_token_length-1][12] * v_matrix[12][o_token_index])
                                        + (score_matrix[i_token_length-1][13] * v_matrix[13][o_token_index])
                                        + (score_matrix[i_token_length-1][14] * v_matrix[14][o_token_index])
                                        + (score_matrix[i_token_length-1][15] * v_matrix[15][o_token_index])
                                        + (score_matrix[i_token_length-1][16] * v_matrix[16][o_token_index])
                                        + (score_matrix[i_token_length-1][17] * v_matrix[17][o_token_index])
                                        + (score_matrix[i_token_length-1][18] * v_matrix[18][o_token_index])
                                        + (score_matrix[i_token_length-1][19] * v_matrix[19][o_token_index])
                                        + (score_matrix[i_token_length-1][20] * v_matrix[20][o_token_index])
                                        + (score_matrix[i_token_length-1][21] * v_matrix[21][o_token_index])
                                        + (score_matrix[i_token_length-1][22] * v_matrix[22][o_token_index])
                                        + (score_matrix[i_token_length-1][23] * v_matrix[23][o_token_index])
                                        + (score_matrix[i_token_length-1][24] * v_matrix[24][o_token_index])
                                        + (score_matrix[i_token_length-1][25] * v_matrix[25][o_token_index])
                                        + (score_matrix[i_token_length-1][26] * v_matrix[26][o_token_index])
                                        + (score_matrix[i_token_length-1][27] * v_matrix[27][o_token_index])
                                        + (score_matrix[i_token_length-1][28] * v_matrix[28][o_token_index])
                                        + (score_matrix[i_token_length-1][29] * v_matrix[29][o_token_index])
                                        + (score_matrix[i_token_length-1][30] * v_matrix[30][o_token_index])
                                        + (score_matrix[i_token_length-1][31] * v_matrix[31][o_token_index]);
                end
                o_token_index <= o_token_index + 1;
        end else if(current_state == S_IDLE)
        begin
                o_token_index <='d0;
                o_token <= '{default:0};
        end
end

always_ff @(posedge clk,negedge rst_n)begin
        if(!rst_n)
        begin
                o_valid <= 0;
                o_data <= 'b0;
                out_index <= 'd0;
        end
        else if(current_state == S_OUTPUT)
        begin
                o_valid <= 'b1;
                o_data <= o_token[out_index];
                out_index <= out_index + 1;
                if(out_index == 8) o_valid <= 'b0;
        end else if(current_state == S_IDLE)
        begin
                o_data <= 'b0;
                out_index <= 'b0;
        end
end

endmodule