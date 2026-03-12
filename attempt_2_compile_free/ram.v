module ram (
    input  wire        clk,
    input  wire        we,       
    input  wire [7:0]  addr,     
    input  wire [7:0]  din,      
    output wire [7:0]  dout      
);
    // 缩减到 32 字节。对于跑马灯和简单运算绰绰有余
    reg [7:0] memory [0:64]; 

    always @(posedge clk) begin
        if (we) memory[addr] <= din;
    end

    assign dout = memory[addr]; 
endmodule