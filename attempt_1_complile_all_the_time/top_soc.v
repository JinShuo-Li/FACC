module top_soc (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] sw,
    output reg  [7:0] led,
    output wire       uart_tx,   // 物理引脚: 发送 (连到模块 RXD)
    input  wire       uart_rx    // 【新增】物理引脚: 接收 (连到模块 TXD)
);

    wire [7:0]  rom_addr, ram_addr, ram_wdata, ram_rdata, io_addr, io_wdata;
    wire [15:0] rom_data;
    wire        ram_we, io_we;
    reg  [7:0]  io_rdata;

    cpu_core u_cpu (
        .clk(clk), .rst_n(rst_n),
        .rom_addr(rom_addr), .rom_data(rom_data),
        .ram_addr(ram_addr), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata), .ram_we(ram_we),
        .io_addr(io_addr), .io_wdata(io_wdata), .io_rdata(io_rdata), .io_we(io_we)
    );

    rom u_rom (.addr(rom_addr), .data(rom_data));
    ram u_ram (.clk(clk), .we(ram_we), .addr(ram_addr), .din(ram_wdata), .dout(ram_rdata));

    wire tx_busy;
    wire tx_start = (io_we && io_addr == 8'h01);
    uart_tx u_uart_tx (.clk(clk), .rst_n(rst_n), .tx_start(tx_start), .tx_data(io_wdata), .tx_pin(uart_tx), .tx_busy(tx_busy));

    // ==========================================
    // 【新增】实例化耳朵 (uart_rx) 及其数据锁存器
    // ==========================================
    wire [7:0] rx_data;
    wire       rx_done;
    uart_rx u_uart_rx (.clk(clk), .rst_n(rst_n), .rx_pin(uart_rx), .rx_data(rx_data), .rx_done(rx_done));

    // 非常关键：耳朵听到数据的牌子 (rx_done) 只举起 1 个时钟周期，CPU 根本来不及看。
    // 我们必须在大厅里设一个信箱指示灯 (rx_ready)。只要有信，灯就一直亮着。
    // CPU 读取完信件后，通过向端口 0x05 写任意数据来关掉指示灯。
    reg rx_ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_ready <= 1'b0;
        else if (rx_done) rx_ready <= 1'b1; // 来信了，亮灯
        else if (io_we && io_addr == 8'h05) rx_ready <= 1'b0; // CPU 下令灭灯
    end

    // I/O 写操作 (输出)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) led <= 8'h00;
        else if (io_we && io_addr == 8'h00) led <= io_wdata;
    end

    // I/O 读操作 (输入地址映射升级)
    always @(*) begin
        case (io_addr)
            8'h02: io_rdata = {7'd0, tx_busy};    // 0x02: TX 忙碌状态
            8'h03: io_rdata = {4'd0, sw};         // 0x03: 拨码开关
            8'h04: io_rdata = rx_data;            // 【新增】0x04: 读取接收到的信件(数据)
            8'h05: io_rdata = {7'd0, rx_ready};   // 【新增】0x05: 读取信箱指示灯状态 (1有信, 0没信)
            default: io_rdata = 8'h00;
        endcase
    end
endmodule