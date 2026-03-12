module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,  // 触发发送信号
    input  wire [7:0] tx_data,   // 要发送的数据
    output reg        tx_pin,    // 连接到开发板的物理 TX 引脚
    output reg        tx_busy    // 状态标志：是否正在发送
);
    parameter BAUD_DIV = 1250;   // 12MHz / 9600

    reg [10:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg [8:0]  shift_reg;        // 包含起始位和数据位

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_pin   <= 1'b1;    // 串口空闲时为高电平
            tx_busy  <= 1'b0;
            baud_cnt <= 11'd0;
            bit_cnt  <= 4'd0;
        end else begin
            if (tx_start && !tx_busy) begin
                tx_busy   <= 1'b1;
                shift_reg <= {tx_data, 1'b0}; // 拼装起始位(0)和数据位
                baud_cnt  <= 11'd0;
                bit_cnt   <= 4'd0;
            end else if (tx_busy) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 11'd0;
                    if (bit_cnt == 4'd9) begin // 1个起始位 + 8个数据位 发完了
                        tx_busy <= 1'b0;       // 发送停止位(拉高)
                        tx_pin  <= 1'b1;
                    end else begin
                        tx_pin    <= shift_reg[0]; // 发送最低位
                        shift_reg <= {1'b1, shift_reg[8:1]}; // 右移
                        bit_cnt   <= bit_cnt + 1'b1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end
        end
    end
endmodule