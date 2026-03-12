module iram (
    input  wire        clk,
    input  wire        we,         
    input  wire [7:0]  waddr,      
    input  wire [15:0] wdata,      
    input  wire [7:0]  raddr,      
    output wire [15:0] rdata       
);
    // 缩减到 64 条指令，节省大量逻辑门
    reg [15:0] memory [0:127]; 

    always @(posedge clk) begin
        if (we) memory[waddr] <= wdata;
    end

    assign rdata = memory[raddr]; // 保持异步读，适配你的 CPU
endmodule