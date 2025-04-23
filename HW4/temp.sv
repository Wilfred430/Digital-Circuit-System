module MAC (
    // Input signals
    input logic clk,          // 時鐘信號，驅動所有時序邏輯
    input logic rst_n,        // 異步低電平有效的重置信號，重置所有內部狀態
    input logic in_valid,     // 輸入有效信號，指示輸入數據（in_mode, in_act, in_wgt）有效
    input logic in_mode,      // 模式選擇信號，0 表示矩陣乘法模式，1 表示卷積模式
    input logic [0:7][3:0] in_act, // 激活矩陣輸入，8x4 位元數據（用於乘法或卷積）
    input logic [0:8][3:0] in_wgt, // 權重矩陣輸入，9x4 位元數據（用於乘法或卷積）
    // Output signals
    output logic [3:0] out_act_idx, // 激活矩陣的當前處理索引，指示正在處理的行
    output logic [3:0] out_wgt_idx, // 權重矩陣的當前處理索引，指示正在處理的列
    output logic [3:0] out_idx,     // 輸出矩陣的當前行索引，指示正在輸出的行
    output logic out_valid,         // 輸出有效信號，指示 out_data 數據有效
    output logic out_finish,        // 處理完成信號，指示整個計算和輸出過程完成
    output logic [0:7][11:0] out_data // 輸出數據，8x12 位元矩陣，每行表示計算結果
);

//---------------------------------------------------------------------
//   REG AND WIRE DECLARATION
//---------------------------------------------------------------------
// 內部變量，用於控制模式和狀態
logic mode;                  // 當前模式，0 表示矩陣乘法，1 表示卷積（時序變量）
logic [3:0] index;           // 輸出索引，記錄當前正在輸出的行（時序變量）

// 矩陣乘法模式下的數據存儲
logic [3:0] act_mul [0:7][0:7]; // 激活矩陣（8x8），用於矩陣乘法
logic [3:0] wgt_mul [0:7][0:7]; // 權重矩陣（8x8），用於矩陣乘法

// 卷積模式下的數據存儲
logic [3:0] act_con [0:9][0:9]; // 激活矩陣（10x10），用於卷積，包含邊界填充
logic [3:0] wgt_con [0:2][0:2]; // 權重矩陣（3x3），用於卷積

// 計算結果存儲
logic [11:0] out [0:7][0:7];    // 計算結果矩陣（8x8），用於存儲乘法或卷積結果

// 控制信號
logic process_finish; // 組合邏輯變量，指示整個處理流程是否完成
logic out_ready;      // 組合邏輯變量，指示計算是否完成並準備輸出
logic in_act_finish;  // 時序變量，指示激活矩陣輸入是否完成
logic in_wgt_finish;  // 時序變量，指示權重矩陣輸入是否完成
logic mode_sel;       // 時序變量，指示模式是否已選擇（1 表示已選擇）

//---------------------------------------------------------------------
//   COMBINATIONAL LOGIC
//---------------------------------------------------------------------
always_comb begin
    // 情況 1：重置、未選擇模式或處理完成
    if (!rst_n || !mode_sel || process_finish) begin
        // 初始化輸出矩陣 out 為 0，避免未定義值
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                out[i][j] = 0;
            end
        end
        // 設置 out_ready 為 0，表示尚未準備好輸出
        out_ready = 0;
    end
    // 情況 2：激活矩陣和權重矩陣輸入完成，開始計算
    else if (in_act_finish && in_wgt_finish) begin
        case (mode)
            // 模式 0：矩陣乘法
            0: begin
                // 執行矩陣乘法：out[i][j] = Σ(act_mul[i][k] * wgt_mul[j][k])
                for (int i = 0; i < 8; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        out[i][j] = 0; // 初始化當前元素
                        for (int k = 0; k < 8; k++) begin
                            out[i][j] = out[i][j] + (act_mul[i][k] * wgt_mul[j][k]);
                        end
                    end
                end
                // 計算完成，設置 out_ready 為 1
                out_ready = 1;
            end
            // 模式 1：卷積
            1: begin
                // 執行卷積：out[i][j] = Σ(act_con[i+m][j+n] * wgt_con[m][n])
                for (int i = 0; i < 8; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        out[i][j] = 0; // 初始化當前元素
                        for (int m = 0; m < 3; m++) begin
                            for (int n = 0; n < 3; n++) begin
                                out[i][j] = out[i][j] + (act_con[i+m][j+n] * wgt_con[m][n]);
                            end
                        end
                    end
                end
                // 計算完成，設置 out_ready 為 1
                out_ready = 1;
            end
            // 非法模式：初始化 out 並設置 out_ready 為 0
            default: begin
                out_ready = 0;
                for (int i = 0; i < 8; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        out[i][j] = 0;
                    end
                end
            end
        endcase
    end
    // 情況 3：其他情況（輸入未完成或正在處理）
    else begin
        // 設置 out_ready 為 0，表示未準備好輸出
        out_ready = 0;
        // 初始化輸出矩陣 out 為 0
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                out[i][j] = 0;
            end
        end
    end
end

//---------------------------------------------------------------------
//   SEQUENTIAL LOGIC
//---------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    // 情況 1：異步重置
    if (!rst_n) begin
        // 重置輸出信號
        out_act_idx <= 'bx; // 激活矩陣索引設為未定義
        out_wgt_idx <= 'bx; // 權重矩陣索引設為未定義
        out_idx <= 0;       // 輸出行索引設為 0
        out_finish <= 0;    // 處理完成信號設為 0
        out_valid <= 0;     // 輸出有效信號設為 0
        out_data <= '{default:0}; // 輸出數據初始化為 0

        // 重置時序變量
        mode <= 0;          // 模式設為 0（矩陣乘法）
        mode_sel <= 0;      // 模式選擇設為 0（未選擇）

        // 初始化存儲矩陣
        act_mul <= '{default:0}; // 矩陣乘法激活矩陣初始化為 0
        wgt_mul <= '{default:0}; // 矩陣乘法權重矩陣初始化為 0
        act_con <= '{default:0}; // 卷積激活矩陣初始化為 0
        wgt_con <= '{default:0}; // 卷積權重矩陣初始化為 0

        // 重置控制信號
        in_act_finish <= 0; // 激活矩陣輸入完成設為 0
        in_wgt_finish <= 0; // 權重矩陣輸入完成設為 0
        process_finish <= 0;// 處理完成設為 0
        index <= 0;         // 輸出索引設為 0
    end
    // 情況 2：正常時序邏輯
    else begin
        // 情況 2.1：輸入有效，選擇模式並初始化
        if (in_valid) begin
            // 更新時序變量
            mode <= in_mode;    // 根據輸入設置模式（0 或 1）
            mode_sel <= 1;      // 設置模式已選擇

            // 初始化存儲矩陣
            act_mul <= '{default:0};
            wgt_mul <= '{default:0};
            act_con <= '{default:0};
            wgt_con <= '{default:0};

            // 重置控制信號
            in_act_finish <= 0;
            in_wgt_finish <= 0;
            process_finish <= 0;
            index <= 0;

            // 更新輸出信號
            out_valid <= 0;
            out_data <= '{default:0};
            out_act_idx <= 0;   // 開始處理激活矩陣，從第 0 行開始
            out_wgt_idx <= 'bx; // 權重索引暫時未定義
            out_idx <= 0;
            out_finish <= 0;
        end
        // 情況 2.2：處理輸入和輸出流程
        else begin
            // 情況 2.2.1：未選擇模式或處理完成，重置所有狀態
            if (!mode_sel || process_finish) begin
                out_act_idx <= 'bx;
                out_wgt_idx <= 'bx;
                out_idx <= 0;
                out_finish <= 0;
                out_valid <= 0;
                out_data <= '{default:0};

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
            // 情況 2.2.2：計算未完成，保持當前狀態
            else if (!out_ready && (in_act_finish && in_wgt_finish)) begin
                out_act_idx <= 'bx;
                out_wgt_idx <= 'bx;
                out_idx <= 0;
                out_finish <= 0;
                out_valid <= 0;
                out_data <= '{default:0};

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
            // 情況 2.2.3：計算完成，開始輸出
            else if (out_ready) begin
                // 逐行輸出計算結果
                out_data[0] <= out[index][0];
                out_data[1] <= out[index][1];
                out_data[2] <= out[index][2];
                out_data[3] <= out[index][3];
                out_data[4] <= out[index][4];
                out_data[5] <= out[index][5];
                out_data[6] <= out[index][6];
                out_data[7] <= out[index][7];
                out_idx <= index;   // 設置當前輸出行索引
                out_valid <= 1;     // 指示輸出數據有效
                out_act_idx <= 'bx; // 索引設為未定義（計算已完成）
                out_wgt_idx <= 'bx;

                index <= index + 1; // 增加輸出索引

                // 檢查輸出是否完成
                if (index < 7) begin
                    process_finish <= 0;
                    out_finish <= 0;
                end
                else if (index == 7) begin
                    process_finish <= 1; // 全部輸出完成
                    out_finish <= 1;     // 指示處理完成
                end
                else begin
                    // 空分支，確保語法完整
                end
            end
            // 情況 2.2.4：處理輸入階段
            else begin
                case (mode)
                    // 模式 0：矩陣乘法
                    0: begin
                        // 階段 1：同時讀取激活矩陣和權重矩陣（尚未完成）
                        if (!in_act_finish && !in_wgt_finish) begin
                            if (out_act_idx <= 7) begin
                                // 逐行讀取激活矩陣
                                for (int i = 0; i < 8; i++) begin
                                    act_mul[out_act_idx][i] <= in_act[i];
                                end
                                out_act_idx <= out_act_idx + 1;
                                out_wgt_idx <= 'bx;
                            end
                            else begin
                                // 激活矩陣輸入完成，準備讀取權重矩陣
                                in_act_finish <= 1;
                                out_act_idx <= 'bx;
                                out_wgt_idx <= 8;
                            end
                        end
                        // 階段 2：激活矩陣已完成，讀取權重矩陣
                        else if (in_act_finish && !in_wgt_finish) begin
                            if (out_wgt_idx != 0) begin
                                // 逐列讀取權重矩陣
                                for (int i = 0; i < 8; i++) begin
                                    wgt_mul[out_wgt_idx-8][i] <= in_wgt[i];
                                end
                                out_wgt_idx <= out_wgt_idx + 1;
                                out_act_idx <= 'bx;
                            end
                            else begin
                                // 權重矩陣輸入完成
                                in_wgt_finish <= 1;
                                out_act_idx <= 'bx;
                                out_wgt_idx <= 'bx;
                            end
                        end
                        // 階段 3：輸入完成，等待計算
                        else begin
                            out_act_idx <= 'bx;
                            out_wgt_idx <= 'bx;
                        end
                    end
                    // 模式 1：卷積
                    1: begin
                        // 階段 1：同時讀取激活矩陣和權重矩陣（尚未完成）
                        if (!in_act_finish && !in_wgt_finish) begin
                            if (out_act_idx <= 7) begin
                                // 逐行讀取激活矩陣，偏移 1 以留出邊界
                                for (int i = 0; i < 8; i++) begin
                                    act_con[out_act_idx+1][i+1] <= in_act[i];
                                end
                                out_act_idx <= out_act_idx + 1;
                                out_wgt_idx <= 'bx;
                            end
                            else begin
                                // 激活矩陣輸入完成
                                in_act_finish <= 1;
                                out_act_idx <= 'bx;
                                out_wgt_idx <= 'bx;
                            end
                        end
                        // 階段 2：激活矩陣已完成，讀取權重矩陣
                        else if (in_act_finish && !in_wgt_finish) begin
                            // 讀取 3x3 權重矩陣
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
                        end
                        // 階段 3：輸入完成，等待計算
                        else begin
                            out_act_idx <= 'bx;
                            out_wgt_idx <= 'bx;
                        end
                    end
                    // 非法模式：重置輸出信號
                    default: begin
                        out_act_idx <= 'bx;
                        out_wgt_idx <= 'bx;
                        out_idx <= 0;
                        out_finish <= 0;
                        out_valid <= 0;
                        out_data <= '{default:0};
                    end
                endcase
            end
        end
    end
end

endmodule