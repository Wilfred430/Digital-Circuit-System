module Fifo( 
    clk, 
    rst_n, 
    write_valid,
    write_data,
    read_valid, 
    write_full, 
    write_success,
    read_empty,  
    read_success,
    read_data
);
input clk, rst_n;
input write_valid, read_valid;
input [7:0] write_data;
output logic write_full, write_success, read_empty, read_success;
output logic [7:0] read_data;

logic [7:0] Depth_data[0:9];
logic [3:0] Seq;

initial 
begin
	Depth_data[0] = 8'b0;
    Depth_data[1] = 8'b0;
    Depth_data[2] = 8'b0;
    Depth_data[3] = 8'b0;
    Depth_data[4] = 8'b0;
    Depth_data[5] = 8'b0;
    Depth_data[6] = 8'b0;
    Depth_data[7] = 8'b0;
    Depth_data[8] = 8'b0;
    Depth_data[9] = 8'b0;
end

always_ff @(posedge clk , negedge rst_n) begin
    if (!rst_n) begin
        write_full <= 1'b0;
        write_success <= 1'b0;
        read_empty <= 1'b0;
        read_success <= 1'b0;
        read_data <= 8'b0;

        Seq <= 4'b0;
    end
    else begin
        if (!write_valid && read_valid) begin
            write_full <= 1'b0;
            write_success <= 1'b0;
            if (Seq != 0) begin
                read_data <= Depth_data[0];
                read_success <= 1'b1;
                read_empty <= 1'b0;

                Depth_data[0] <= Depth_data[1];
                Depth_data[1] <= Depth_data[2];
                Depth_data[2] <= Depth_data[3];
                Depth_data[3] <= Depth_data[4];
                Depth_data[4] <= Depth_data[5];
                Depth_data[5] <= Depth_data[6];
                Depth_data[6] <= Depth_data[7];
                Depth_data[7] <= Depth_data[8];
                Depth_data[8] <= Depth_data[9];
                Depth_data[9] <= 8'b0;

                Seq <= Seq - 1;
            end
            else begin
                read_data <= 8'b0;
                read_success <= 1'b0;
                read_empty <= 1'b1;
            end
        end        
		else begin
            write_full <= 1'b0;
            write_success <= 1'b0;
            read_empty <= 1'b0;
            read_success <= 1'b0;
            read_data <= 8'b0;
        end
        if (read_valid && write_valid) begin
            if (Seq != 0) begin
                read_data <= Depth_data[0];
                read_success <= 1'b1;
                read_empty <= 1'b0;

                if (Seq == 1) begin
                    Depth_data[0] <= write_data;
                end
                else if (Seq == 2) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= write_data;
                end
                else if (Seq == 3) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= write_data;
                end
                else if (Seq == 4) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= write_data;
                end
                else if (Seq == 5) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= Depth_data[4];
                    Depth_data[4] <= write_data;
                end
                else if (Seq == 6) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= Depth_data[4];
                    Depth_data[4] <= Depth_data[5];
                    Depth_data[5] <= write_data;
                end
                else if (Seq == 7) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= Depth_data[4];
                    Depth_data[4] <= Depth_data[5];
                    Depth_data[5] <= Depth_data[6];
                    Depth_data[6] <= write_data;
                end
                else if (Seq == 8) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= Depth_data[4];
                    Depth_data[4] <= Depth_data[5];
                    Depth_data[5] <= Depth_data[6];
                    Depth_data[6] <= Depth_data[7];
                    Depth_data[7] <= write_data;
                end
                else if (Seq == 9) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= Depth_data[4];
                    Depth_data[4] <= Depth_data[5];
                    Depth_data[5] <= Depth_data[6];
                    Depth_data[6] <= Depth_data[7];
                    Depth_data[7] <= Depth_data[8];
                    Depth_data[8] <= write_data;
                end
                else if (Seq == 10) begin
                    Depth_data[0] <= Depth_data[1];
                    Depth_data[1] <= Depth_data[2];
                    Depth_data[2] <= Depth_data[3];
                    Depth_data[3] <= Depth_data[4];
                    Depth_data[4] <= Depth_data[5];
                    Depth_data[5] <= Depth_data[6];
                    Depth_data[6] <= Depth_data[7];
                    Depth_data[7] <= Depth_data[8];
                    Depth_data[8] <= Depth_data[9];
                    Depth_data[9] <= write_data;
                end
                write_success <= 1'b1;
                write_full <= 1'b0;
            end
            else begin
                read_data <= 8'b0;
                read_success <= 1'b0;
                read_empty <= 1'b1;

                Depth_data[0] <= write_data;
                write_success <= 1'b1;
                write_full <= 1'b0;
                Seq <= 4'b0001;
            end
        end
        if (!read_valid && write_valid) begin
            read_empty <= 1'b0;
            read_success <= 1'b0;
            read_data <= 8'b0;

            if (Seq < 10) begin
                Depth_data[Seq] <= write_data;
                write_success <= 1'b1;
                write_full <= 1'b0;
                Seq <= Seq + 1;
            end
            else begin
                write_success <= 1'b0;
                write_full <= 1'b1;
            end
        end
    end
end

endmodule