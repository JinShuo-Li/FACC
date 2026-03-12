module bootloader (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        boot_en,    // 下载模式开关
    input  wire        rx_done,    // 收到字节提示
    input  wire [7:0]  rx_data,    // 收到的 8 位数据

    output wire        cpu_rst_n,  // 接管 CPU 复位
    output reg         iram_we,    
    output reg  [7:0]  iram_addr,  
    output reg  [15:0] iram_wdata  
);
    assign cpu_rst_n = boot_en ? 1'b0 : rst_n; // 下载时强制复位CPU

    reg byte_sel;        
    reg [7:0] high_byte; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            iram_we    <= 1'b0;
            iram_addr  <= 8'd0;
            byte_sel   <= 1'b0;
        end else if (!boot_en) begin
            iram_we    <= 1'b0;
            iram_addr  <= 8'd0;
            byte_sel   <= 1'b0;
        end else begin
            iram_we <= 1'b0; 
            if (rx_done) begin
                if (byte_sel == 1'b0) begin
                    high_byte <= rx_data;
                    byte_sel  <= 1'b1; 
                end else begin
                    iram_wdata <= {high_byte, rx_data};
                    iram_we    <= 1'b1;
                    byte_sel   <= 1'b0; 
                end
            end else if (iram_we) begin
                iram_addr <= iram_addr + 1'b1;
            end
        end
    end
endmodule