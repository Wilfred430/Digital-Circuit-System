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

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, in_valid, in_mode;
input [0:7][3:0] in_act;
input [0:8][3:0] in_wgt;
output logic [3:0] out_act_idx, out_wgt_idx, out_idx;
output logic out_valid, out_finish;
output logic [0:7][11:0] out_data;

//---------------------------------------------------------------------
//   REG AND WIRE DECLARATION
//---------------------------------------------------------------------
integer mode;
integer index;

logic [3:0] act_mul [0:7][0:7];
logic [3:0] wgt_mul [0:7][0:7];

logic [3:0] act_con [0:9][0:9];
logic [3:0] wgt_con [0:2][0:2];
logic [11:0] out [0:7][0:7];

logic process_finish; //comb
logic out_ready; //comb
logic in_act_finish; //seq
logic in_wgt_finish; //seq
logic mode_sel; //seq

//FSM
parameter IDLE = 2'b00,
          INACT = 2'b01,
          INWGT = 2'b11,
          OUT = 2'b10;
logic [1:0] current_state;
logic [1:0] next_state;

//---------------------------------------------------------------------
//   YOUR DESIGN
//---------------------------------------------------------------------
always_comb begin
    //reset or not started or process finished
    if (!rst_n || !mode_sel || process_finish) begin
        //output matrix initialization
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                out[i][j] = 0;
            end
        end
        //comb flag initialization
        out_ready = 0;
        //FSM initialization
        next_state = IDLE;
    end

    //calculating
    else if (in_act_finish && in_wgt_finish) begin
        case (mode)
        //multiplication
        0: begin
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    out[i][j] = 0;
                    for (int k = 0; k < 8; k++) begin
                        out[i][j] = out[i][j] + (act_mul[i][k] * wgt_mul[j][k]);
                    end
                end
            end
            out_ready = 1;
        end
        //convolution
        1: begin
            //multiplication of partial act & wgt matrics
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    out[i][j] = 0;
                    for (int m = 0; m < 3; m++) begin
                        for (int n = 0; n < 3; n++) begin
                            out[i][j] = out[i][j] + (act_con[i+m][j+n] * wgt_con[m][n]);
                        end
                    end
                end
            end
            out_ready = 1;
        end
        default: begin
            out_ready = 1;
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    out[i][j] = 0;
                end
            end
        end
        endcase
    end

    else begin
        out_ready = 0;
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                out[i][j] = 0;
            end
        end
    end

    //FSM
    case (current_state)
        //initial state or wait for calculate
        IDLE: begin
            //not started or process finished or calculate not finished
            if (!mode_sel || process_finish || (!out_ready && (in_act_finish && in_wgt_finish))) next_state = IDLE;
            //calculate finished
            else if (out_ready) next_state = OUT;
            //start process
            else next_state = INACT;
        end

        //input act matrix
        INACT: begin
            //act matrix input not finished
            if (!in_act_finish) next_state = INACT;
            //act matrix input finished
            else begin
                //wgt matrix input not finished
                if (!in_wgt_finish) next_state = INWGT;
                //wgt matrix input finished
                else next_state = IDLE;
            end
        end

        //input wgt matrix
        INWGT: begin
            //wgt matrix input not finished
            if (!in_wgt_finish) next_state = INWGT;
            //wgt matrix input finished
            else begin
                //act matrix input not finished
                if (!in_act_finish) next_state = INACT;
                //act matrix input finished
                else next_state = IDLE;
            end
        end

        //output matrix
        OUT: begin
            //output not finished
            if (!process_finish) next_state = OUT;
            //output finished
            else next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    //reset
    if (!rst_n) begin
        //output signals
        out_act_idx <= 'bx;
        out_wgt_idx <= 'bx;
        out_idx <= 0;
        out_finish <= 0;
        out_valid <= 0;
        out_data <= '{default:0};

        //seq variables
        mode <= 0;
        mode_sel <= 0;

        current_state <= IDLE;

        act_mul <= '{default:0};
        wgt_mul <= '{default:0};
        act_con <= '{default:0};
        wgt_con <= '{default:0};

        in_act_finish <= 0;
        in_wgt_finish <= 0;
        process_finish <= 0;
        index <= 0;
    end
    else begin
        //select mode
        if (in_valid) begin
            //seq variables
            mode <= in_mode;
            mode_sel <= 1;

            act_mul <= '{default:0};
            wgt_mul <= '{default:0};
            act_con <= '{default:0};
            wgt_con <= '{default:0};

            in_act_finish <= 0;
            in_wgt_finish <= 0;
            process_finish <= 0;
            index <= 0;

            //output signals
            out_valid <= 0;
            out_data <= '{default:0};
            out_act_idx <= 'bx;
            out_wgt_idx <= 'bx;
            out_idx <= 0;
            out_finish <= 0;
        end

        //FSM: from input until output complete
        else begin
            current_state <= next_state;

            case (current_state)
                //initial state or wait for calculate
                IDLE: begin
                    //not started or process finished
                    if (!mode_sel || process_finish) begin
                        //output signals
                        out_act_idx <= 'bx;
                        out_wgt_idx <= 'bx;
                        out_idx <= 0;
                        out_finish <= 0;
                        out_valid <= 0;
                        out_data <= '{default:0};

                        //seq variables
                        mode <= 0;
                        mode_sel <= 0;

                        act_mul <= '{default:0};
                        wgt_mul <= '{default:0};
                        act_con <= '{default:0};
                        wgt_con <= '{default:0};

                        in_act_finish <= 0;
                        in_wgt_finish <= 0;
                        process_finish <= 0;
                        index <= 0;
                    end

                    //calculate not finished
                    else if (!out_ready && (in_act_finish && in_wgt_finish)) begin
                        //output signals
                        out_act_idx <= 'bx;
                        out_wgt_idx <= 'bx;
                        out_idx <= 0;
                        out_finish <= 0;
                        out_valid <= 0;
                        out_data <= '{default:0};

                        //seq variables
                        mode <= mode;
                        mode_sel <= 1;

                        in_act_finish <= 1;
                        in_wgt_finish <= 1;
                        process_finish <= 0;
                        index <= 0;

                        act_mul <= act_mul;
                        wgt_mul <= wgt_mul;
                        act_con <= act_con;
                        wgt_con <= wgt_con;
                    end
                    
                    //start process
                    else begin
                        //output signals
                        out_act_idx <= 0;
                        out_wgt_idx <= 'bx;
                        out_valid <= 0;
                        out_data <= '{default:0};
                        out_idx <= 0;
                        out_finish <= 0;

                        //seq variables
                        mode <= mode;
                        mode_sel <= mode_sel;

                        act_mul <= act_mul;
                        wgt_mul <= wgt_mul;
                        act_con <= act_con;
                        wgt_con <= wgt_con;

                        in_act_finish <= in_act_finish;
                        in_wgt_finish <= in_wgt_finish;
                        process_finish <= 0;
                        index <= 0;
                    end
                end

                //input act matrix
                INACT: begin
                    //output signals
                    out_idx <= 0;
                    out_valid <= 0;
                    out_data <= '{default:0};
                    out_finish <= 0;

                    process_finish <= 0;

                    case (mode)
                    //multiplication
                    0: begin
                        //read act matrix by row
                        if (!in_act_finish) begin
                            if (out_act_idx <= 7) begin
                                for (int i = 0; i < 8; i++) begin
                                    act_mul[out_act_idx][i] <= in_act[i];
                                end
                                out_act_idx <= out_act_idx + 1;
                                out_wgt_idx <= 'bx;
                            end
                            else begin
                                in_act_finish <= 1;
                                if (!in_wgt_finish) begin
                                    out_act_idx <= 'bx;
                                    out_wgt_idx <= 8;
                                end
                                else begin
                                    out_act_idx <= 'bx;
                                    out_wgt_idx <= 'bx;
                                end
                            end
                        end
                        else begin
                        end
                    end
                    //convolution
                    1: begin
                        //read act matrix by row
                        if (!in_act_finish) begin
                            if (out_act_idx <= 7) begin
                                for (int i = 0; i < 8; i++) begin
                                    act_con[out_act_idx+1][i+1] <= in_act[i];
                                end
                                out_act_idx <= out_act_idx + 1;
                                out_wgt_idx <= 'bx;
                            end
                            else begin
                                in_act_finish <= 1;
                                out_act_idx <= 'bx;
                                out_wgt_idx <= 'bx;
                            end
                        end
                        else begin
                        end
                    end
                    default: begin
                        out_act_idx <= 'bx;
                        out_wgt_idx <= 'bx;
                    end
                    endcase
                end

                //input wgt matrix
                INWGT: begin
                    out_idx <= 0;
                    out_valid <= 0;
                    out_data <= '{default:0};
                    out_finish <= 0;

                    process_finish <= 0;

                    case (mode)
                    //multiplication
                    0: begin
                        //read wgt matrix by col
                        if (!in_wgt_finish) begin
                            if (out_wgt_idx != 0) begin
                                for (int i = 0; i < 8; i++) begin
                                    wgt_mul[out_wgt_idx-8][i] <= in_wgt[i];
                                end
                                out_wgt_idx <= out_wgt_idx + 1;
                                out_act_idx <= 'bx;
                            end
                            else begin
                                in_wgt_finish <= 1;
                                if (!in_act_finish) begin
                                    out_act_idx <= 0;
                                    out_wgt_idx <= 'bx;
                                end
                                else begin
                                    out_act_idx <= 'bx;
                                    out_wgt_idx <= 'bx;
                                end
                            end
                        end
                        else begin
                        end
                    end
                    //convolution
                    1: begin
                        //read wgt matrix by col
                        if (!in_wgt_finish) begin
                            wgt_con[0][0] <= in_wgt[0];
                            wgt_con[0][1] <= in_wgt[1];
                            wgt_con[0][2] <= in_wgt[2];
                            wgt_con[1][0] <= in_wgt[3];
                            wgt_con[1][1] <= in_wgt[4];
                            wgt_con[1][2] <= in_wgt[5];
                            wgt_con[2][0] <= in_wgt[6];
                            wgt_con[2][1] <= in_wgt[7];
                            wgt_con[2][2] <= in_wgt[8];
                            in_wgt_finish <= 1;

                            if (!in_act_finish) begin
                                out_act_idx <= 0;
                                out_wgt_idx <= 'bx;
                            end
                            else begin
                                out_act_idx <= 'bx;
                                out_wgt_idx <= 'bx;
                            end
                        end
                        else begin
                        end
                    end
                    default: begin
                        out_act_idx <= 'bx;
                        out_wgt_idx <= 'bx;
                    end
                    endcase
                end

                //output matrix
                OUT: begin
                        out_data[0] <= out[index][0];
                        out_data[1] <= out[index][1];
                        out_data[2] <= out[index][2];
                        out_data[3] <= out[index][3];
                        out_data[4] <= out[index][4];
                        out_data[5] <= out[index][5];
                        out_data[6] <= out[index][6];
                        out_data[7] <= out[index][7];
                        out_idx <= index;
                        out_valid <= 1;
                        out_act_idx <= 'bx;
                        out_wgt_idx <= 'bx;

                        index <= index + 1;

                        if (index < 7) begin
                            process_finish <= 0;
                            out_finish <= 0;
                        end
                        else if (index == 7) begin
                            process_finish <= 1;
                            out_finish <= 1;
                        end
                        else begin
                        end
                end

                default:begin
                    out_idx <= 0;
                    out_valid <= 0;
                    out_data <= '{default:0};
                    out_finish <= 0;
                    out_act_idx <= 'bx;
                    out_wgt_idx <= 'bx;

                    process_finish <= 0;
                end
            endcase
        end
    end
end

endmodule