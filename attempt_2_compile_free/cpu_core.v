module cpu_core (
    input  wire        clk,        // 系统时钟
    input  wire        rst_n,      // 复位信号，低电平有效

    // 指令存储器 (I-RAM) 接口
    output wire [7:0]  rom_addr,   // 输出给 I-RAM 的指令地址 (PC)
    input  wire [15:0] rom_data,   // 从 I-RAM 读取的 16 位指令

    // 数据存储器 (RAM) 接口
    output wire [7:0]  ram_addr,   // 输出给 RAM 的数据地址
    output wire [7:0]  ram_wdata,  // 写入 RAM 的数据
    input  wire [7:0]  ram_rdata,  // 从 RAM 读取的数据
    output reg         ram_we,     // RAM 写使能

    // 外设 (IO) 接口
    output wire [7:0]  io_addr,    // IO 端口地址
    output wire [7:0]  io_wdata,   // 输出到 IO 的数据
    input  wire [7:0]  io_rdata,   // 从 IO 读取的数据
    output reg         io_we       // IO 写使能
);

    reg [7:0] pc;
    reg [7:0] regs [0:3];
    reg       flag_z;

    wire [3:0] opcode = rom_data[15:12];
    wire [1:0] rd     = rom_data[11:10];
    wire [1:0] rs     = rom_data[9:8];
    wire [7:0] imm    = rom_data[7:0];

    assign rom_addr  = pc;
    assign ram_addr  = imm;
    assign ram_wdata = regs[rd];
    assign io_addr   = imm;
    assign io_wdata  = regs[rd];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc      <= 8'd0;
            flag_z  <= 1'b0;
            ram_we  <= 1'b0;
            io_we   <= 1'b0;
            regs[0] <= 8'd0; regs[1] <= 8'd0; 
            regs[2] <= 8'd0; regs[3] <= 8'd0;
        end else begin
            ram_we <= 1'b0;
            io_we  <= 1'b0;
            pc     <= pc + 1'b1;

            case (opcode)
                4'b0001: regs[rd] <= imm;                           // LDI
                4'b0010: regs[rd] <= ram_rdata;                     // LOAD
                4'b0011: ram_we <= 1'b1;                            // STOR
                4'b0100: regs[rd] <= regs[rs];                      // MOV
                4'b0101: begin                                      // ADD
                    regs[rd] <= regs[rd] + regs[rs];
                    flag_z   <= ((regs[rd] + regs[rs]) == 8'd0) ? 1'b1 : 1'b0;
                end
                4'b0110: begin                                      // SUB
                    regs[rd] <= regs[rd] - regs[rs];
                    flag_z   <= ((regs[rd] - regs[rs]) == 8'd0) ? 1'b1 : 1'b0;
                end
                4'b0111: begin                                      // AND
                    regs[rd] <= regs[rd] & regs[rs];
                    flag_z   <= ((regs[rd] & regs[rs]) == 8'd0) ? 1'b1 : 1'b0;
                end
                4'b1000: pc <= imm;                                 // JMP
                4'b1001: if (flag_z) pc <= imm;                     // JZ
                4'b1010: regs[rd] <= io_rdata;                      // IN
                4'b1011: io_we <= 1'b1;                             // OUT
                default: ; // NOP
            endcase
        end
    end
endmodule