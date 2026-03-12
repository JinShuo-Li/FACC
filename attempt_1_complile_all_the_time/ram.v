module ram (
    input  wire        clk,
    input  wire        we,       // 写使能
    input  wire [7:0]  addr,
    input  wire [7:0]  din,
    output wire [7:0]  dout
);
    // 定义 256 个 8 位宽的存储单元
    reg [7:0] memory [0:255];

    // 同步写
    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= din;
        end
    end

    // 异步读 (组合逻辑，配合单周期 CPU)
    assign dout = memory[addr];

endmodule