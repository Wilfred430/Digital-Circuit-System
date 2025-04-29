module MAC(
    // Input signals
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    input  logic        in_mode,
    input  logic [0:7][3:0] in_act,
    input  logic [0:8][3:0] in_wgt,
    // Output signals
    output logic [3:0]  out_act_idx,
    output logic [3:0]  out_wgt_idx,
    output logic [3:0]  out_idx,
    output logic        out_valid,
    output logic [0:7][11:0] out_data,
    output logic        out_finish
);

//--------------------------------------------------------------------------------------
//   FSM STATE DEFINITION
//--------------------------------------------------------------------------------------
typedef enum logic [1:0] {
    S_IDLE,         // Wait for input
    S_INPUT,        // Read input data
    S_COMPUTE,      // Compute results
    S_OUTPUT        // Output results
} state_t;

//--------------------------------------------------------------------------------------
//   REG AND WIRE DECLARATION
//--------------------------------------------------------------------------------------
// FSM state registers
state_t current_state, next_state;

// Control signals
logic work_type;               // 0: matrix multiplication, 1: CNN
logic [3:0] input_counter;     // Counts input rows (0-7)
logic [3:0] output_counter;    // Counts output rows (0-7)

// Data storage
logic [3:0] activation [0:9][0:9];  // Activation matrix with padding for CNN
logic [3:0] weight [0:7][0:7];      // Weight matrix for matrix multiplication
logic [3:0] weight_cnn [0:2][0:2];  // Weight matrix for CNN (3x3)
logic [11:0] result [0:7][0:7];     // Result matrix

//--------------------------------------------------------------------------------------
//   FSM STATE TRANSITION
//--------------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= S_IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    // Default: stay in current state
    next_state = current_state;
    
    case (current_state)
        S_IDLE: begin
            if (in_valid)
                next_state = S_INPUT;
        end
        
        S_INPUT: begin
            if (input_counter == 7)  // After reading 8 rows (0-7)
                next_state = S_COMPUTE;
        end
        
        S_COMPUTE: begin
            // Move to output state immediately after computation
            next_state = S_OUTPUT;
        end
        
        S_OUTPUT: begin
            if (output_counter == 7 && out_valid)  // After outputting 8 rows (0-7)
                next_state = S_IDLE;
        end
        
        default: next_state = S_IDLE;
    endcase
end

//--------------------------------------------------------------------------------------
//   DATAPATH: COUNTERS AND CONTROL SIGNALS
//--------------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all control signals and counters
        input_counter <= 4'd0;
        output_counter <= 4'd0;
        work_type <= 1'b0;
        out_valid <= 1'b0;
        out_finish <= 1'b0;
        out_act_idx <= 4'd0;
        out_wgt_idx <= 4'd0;
        out_idx <= 4'd0;
        out_data <= '{default:12'd0};
    end else begin
        case (current_state)
            S_IDLE: begin
                // Reset counters and control signals
                input_counter <= 4'd0;
                output_counter <= 4'd0;
                out_valid <= 1'b0;
                out_finish <= 1'b0;
                
                // Latch operation mode when input is valid
                if (in_valid) begin
                    work_type <= in_mode;
                end
            end
            
            S_INPUT: begin
                // Set indices for input phase
                out_act_idx <= {1'b0, input_counter};
                out_wgt_idx <= {1'b0, input_counter};
                
                // Increment input counter
                if (input_counter < 8)
                    input_counter <= input_counter + 4'd1;
            end
            
            S_COMPUTE: begin
                // No control signals to update during compute
            end
            
            S_OUTPUT: begin
                // Set output signals
                out_valid <= 1'b1;
                out_idx <= {1'b0, output_counter};
                
                // Output data for current row
                for (int i = 0; i < 8; i++) begin
                    out_data[i] <= result[output_counter][i];
                end
                
                // Set finish flag on last row
                if (output_counter == 7)
                    out_finish <= 1'b1;
                else
                    output_counter <= output_counter + 4'd1;
            end
            
            default: begin
                // Default behavior
            end
        endcase
    end
end

//--------------------------------------------------------------------------------------
//   DATAPATH: DATA STORAGE
//--------------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Clear all data storage
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                if (i < 10 && j < 10)
                    activation[i][j] <= 4'd0;
                if (i < 8 && j < 8)
                    weight[i][j] <= 4'd0;
                if (i < 3 && j < 3)
                    weight_cnn[i][j] <= 4'd0;
            end
        end
    end else if (current_state == S_INPUT) begin
        // Store input data based on operation mode
        if (!work_type) begin
            // Matrix multiplication mode
            for (int j = 0; j < 8; j++) begin
                activation[input_counter][j] <= in_act[j];
                weight[input_counter][j] <= in_wgt[j];
            end
        end else begin
            // CNN mode - store with padding
            for (int j = 0; j < 8; j++) begin
                activation[input_counter+1][j+1] <= in_act[j];
            end
            
            // Store CNN weights in 3x3 kernel
            for (int j = 0; j < 9; j++) begin
                weight_cnn[j/3][j%3] <= in_wgt[j];
            end
        end
    end else if (current_state == S_IDLE && next_state == S_IDLE) begin
        // Clear storage when returning to idle
        for (int i = 0; i < 10; i++) begin
            for (int j = 0; j < 10; j++) begin
                if (i < 10 && j < 10)
                    activation[i][j] <= 4'd0;
                if (i < 8 && j < 8)
                    weight[i][j] <= 4'd0;
                if (i < 3 && j < 3)
                    weight_cnn[i][j] <= 4'd0;
            end
        end
    end
end

//--------------------------------------------------------------------------------------
//   COMPUTATION LOGIC
//--------------------------------------------------------------------------------------
always_comb begin
    // Initialize result matrix
    for (int t = 0; t < 8; t++) begin
        for (int k = 0; k < 8; k++) begin
            result[t][k] = 12'd0;
        end
    end
    
    // Compute based on operation mode
    if (current_state == S_COMPUTE) begin
        if (!work_type) begin
            // Matrix multiplication: result[t][k] = Σ activation[t][n] × weight[n][k]
            for (int t = 0; t < 8; t++) begin
                for (int k = 0; k < 8; k++) begin
                    for (int n = 0; n < 8; n++) begin
                        result[t][k] = result[t][k] + activation[t][n] * weight[n][k];
                    end
                end
            end
        end else begin
            // CNN: result[t][k] = Σ activation[t+n][k+m] × weight_cnn[n][m]
            for (int t = 0; t < 8; t++) begin
                for (int k = 0; k < 8; k++) begin
                    for (int n = 0; n < 3; n++) begin
                        for (int m = 0; m < 3; m++) begin
                            result[t][k] = result[t][k] + activation[t+n][k+m] * weight_cnn[n][m];
                        end
                    end
                end
            end
        end
    end
end

endmodule