module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_pin,    // 物理引脚: 接收外界电信号的耳朵
    output reg  [7:0] rx_data,   // 听懂后拼装好的 8 位数据
    output reg        rx_done    // 听完一个字节后，举起 1 个时钟周期的牌子 (高电平脉冲)
);
    parameter BAUD_DIV = 1250;       // 12MHz / 9600
    parameter BAUD_DIV_HALF = 625;   // 半个波特率周期 (用于正中间采样)

    // ==========================================
    // 1. 消除亚稳态与起始位检测 (非常核心的硬件过滤技术)
    // ==========================================
    reg rx_d0, rx_d1, rx_d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0 <= 1'b1; rx_d1 <= 1'b1; rx_d2 <= 1'b1; // 空闲时串口线是高电平
        end else begin
            rx_d0 <= rx_pin; // 连续采样 3 次
            rx_d1 <= rx_d0;
            rx_d2 <= rx_d1;
        end
    end
    // 当上一拍是 1，这一拍是 0 时，说明检测到了起始位的下降沿！
    wire rx_fall = (~rx_d1) & rx_d2; 

    // ==========================================
    // 2. 接收状态机与正中间采样
    // ==========================================
    reg        rx_en;         // 是否正在接收中
    reg [10:0] baud_cnt;      // 节拍计时器
    reg [3:0]  bit_cnt;       // 数数：现在接收到第几个 bit 了
    reg [7:0]  rx_data_reg;   // 临时组装数据的草稿纸

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_en    <= 1'b0;
            baud_cnt <= 11'd0;
            bit_cnt  <= 4'd0;
            rx_done  <= 1'b0;
            rx_data  <= 8'd0;
        end else begin
            rx_done <= 1'b0; // 默认放下完成牌子

            if (!rx_en && rx_fall) begin
                // 听到起始位下降沿！马上开始专注接收
                rx_en    <= 1'b1;
                baud_cnt <= 11'd0;
                bit_cnt  <= 4'd0;
            end else if (rx_en) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    // 一个完整的波特率周期走完了
                    baud_cnt <= 11'd0;
                    if (bit_cnt == 4'd8) begin
                        // 8 个数据位全部收完啦！
                        rx_en   <= 1'b0;        // 结束接收状态
                        rx_done <= 1'b1;        // 举起接收完成的牌子！
                        rx_data <= rx_data_reg; // 把草稿纸上的数据正式输出
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1; // 准备收下一个 bit
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                    
                    // 【核心魔法】当节拍走到正中间时，进行稳定采样！
                    if (baud_cnt == BAUD_DIV_HALF - 1) begin
                        if (bit_cnt == 4'd0) begin
                            // 采样起始位，如果是高电平说明是杂音干扰，立刻放弃接收
                            if (rx_d1 == 1'b1) rx_en <= 1'b0; 
                        end else begin
                            // 采样数据位 (串口是低位先发，所以把新听到的比特塞进最高位，然后整体右移)
                            rx_data_reg <= {rx_d1, rx_data_reg[7:1]};
                        end
                    end
                end
            end
        end
    end
endmodule