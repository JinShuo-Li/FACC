module top_soc (
    input  wire       clk,       // 连引脚 J5
    input  wire       rst_n,     // 连引脚 J9
    input  wire [3:0] sw,        // 拨码开关，其中 sw[3] 控制下载模式
    output reg  [7:0] led,       // 8 个 LED
    output wire       uart_tx,   // 连串口 RXD (M4)
    input  wire       uart_rx    // 连串口 TXD (P3)
);

    wire [7:0] rx_data;
    wire       rx_done;
    uart_rx u_uart_rx (.clk(clk), .rst_n(rst_n), .rx_pin(uart_rx), .rx_data(rx_data), .rx_done(rx_done));

    wire        cpu_rst_n;
    wire        iram_we;
    wire [7:0]  iram_waddr;
    wire [15:0] iram_wdata;
    
    bootloader u_boot (
        .clk(clk), .rst_n(rst_n),
        .boot_en(sw[3]),          
        .rx_done(rx_done), .rx_data(rx_data),
        .cpu_rst_n(cpu_rst_n),    
        .iram_we(iram_we), .iram_addr(iram_waddr), .iram_wdata(iram_wdata)
    );

    wire [7:0]  cpu_pc;
    wire [15:0] cpu_inst;
    
    iram u_iram (
        .clk(clk),
        .we(iram_we), .waddr(iram_waddr), .wdata(iram_wdata), 
        .raddr(cpu_pc), .rdata(cpu_inst)                      
    );

    wire [7:0] ram_addr, ram_wdata, ram_rdata, io_addr, io_wdata;
    wire       ram_we, io_we;
    reg  [7:0] io_rdata;

    cpu_core u_cpu (
        .clk(clk), .rst_n(cpu_rst_n), 
        .rom_addr(cpu_pc), .rom_data(cpu_inst), 
        .ram_addr(ram_addr), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata), .ram_we(ram_we),
        .io_addr(io_addr), .io_wdata(io_wdata), .io_rdata(io_rdata), .io_we(io_we)
    );

    ram u_ram (.clk(clk), .we(ram_we), .addr(ram_addr), .din(ram_wdata), .dout(ram_rdata));
    
    wire tx_busy;
    wire tx_start = (io_we && io_addr == 8'h01);
    uart_tx u_uart_tx (.clk(clk), .rst_n(rst_n), .tx_start(tx_start), .tx_data(io_wdata), .tx_pin(uart_tx), .tx_busy(tx_busy));

    reg rx_ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_ready <= 1'b0;
        else if (rx_done && !sw[3]) rx_ready <= 1'b1; 
        else if (io_we && io_addr == 8'h05) rx_ready <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) led <= 8'h00;
        else if (io_we && io_addr == 8'h00) led <= io_wdata;
    end

    always @(*) begin
        case (io_addr)
            8'h02: io_rdata = {7'd0, tx_busy};
            8'h03: io_rdata = {4'd0, sw};
            8'h04: io_rdata = rx_data;
            8'h05: io_rdata = {7'd0, rx_ready};
            default: io_rdata = 8'h00;
        endcase
    end
endmodule