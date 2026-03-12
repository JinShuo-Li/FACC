module cpu_core (
    input  wire        clk,        // 系统时钟
    input  wire        rst_n,      // 复位信号，低电平有效

    // 指令存储器 (ROM) 接口 - 哈佛架构
    output wire [7:0]  rom_addr,   // 输出给 ROM 的指令地址 (支持 256 条指令)
    input  wire [15:0] rom_data,   // 从 ROM 读取的 16 位指令

    // 数据存储器 (RAM) 接口
    output wire [7:0]  ram_addr,   // 输出给 RAM 的数据地址
    output wire [7:0]  ram_wdata,  // 写入 RAM 的数据
    input  wire [7:0]  ram_rdata,  // 从 RAM 读取的数据
    output reg         ram_we,     // RAM 写使能信号 (Write Enable)

    // 外设 (IO) 接口 (用于串口等)
    output wire [7:0]  io_addr,    // IO 端口地址
    output wire [7:0]  io_wdata,   // 输出到 IO 的数据
    input  wire [7:0]  io_rdata,   // 从 IO 读取的数据
    output reg         io_we       // IO 写使能
);

    // =================================================================
    // 1. 内部寄存器定义
    // =================================================================
    reg [7:0] pc;                  // 程序计数器 (Program Counter)
    reg [7:0] regs [0:3];          // 4个8位通用寄存器: R0, R1, R2, R3
    reg       flag_z;              // 零标志位 (Zero Flag)

    // =================================================================
    // 2. 指令译码 (连线解析)
    // =================================================================
    wire [3:0] opcode = rom_data[15:12]; // 高4位是操作码
    wire [1:0] rd     = rom_data[11:10]; // 目标寄存器索引
    wire [1:0] rs     = rom_data[9:8];   // 源寄存器索引
    wire [7:0] imm    = rom_data[7:0];   // 低8位是立即数或地址

    // 将地址和数据输出直接映射 (组合逻辑)
    assign rom_addr  = pc;
    assign ram_addr  = imm;
    assign ram_wdata = regs[rd];
    assign io_addr   = imm;
    assign io_wdata  = regs[rd];

    // =================================================================
    // 3. ALU 算术逻辑与控制单元 (时序逻辑)
    // =================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时，清空PC、寄存器、标志位和写使能
            pc      <= 8'd0;
            flag_z  <= 1'b0;
            ram_we  <= 1'b0;
            io_we   <= 1'b0;
            regs[0] <= 8'd0; regs[1] <= 8'd0; 
            regs[2] <= 8'd0; regs[3] <= 8'd0;
        end else begin
            // 默认状态：不写 RAM，不写 IO，PC 自动加 1
            ram_we <= 1'b0;
            io_we  <= 1'b0;
            pc     <= pc + 1'b1;

            // 根据操作码执行对应动作
            case (opcode)
                4'b0001: begin // LDI Rd, imm (加载立即数)
                    regs[rd] <= imm;
                end
                
                4'b0010: begin // LOAD Rd, addr (从 RAM 读数据)
                    regs[rd] <= ram_rdata;
                end
                
                4'b0011: begin // STOR Rd, addr (写数据到 RAM)
                    ram_we <= 1'b1; // 拉高 RAM 写使能
                end
                
                4'b0100: begin // MOV Rd, Rs (寄存器间复制)
                    regs[rd] <= regs[rs];
                end
                
                4'b0101: begin // ADD Rd, Rs (加法 - 我们的微型 ALU)
                    regs[rd] <= regs[rd] + regs[rs];
                    flag_z   <= ((regs[rd] + regs[rs]) == 8'd0) ? 1'b1 : 1'b0;
                end
                
                4'b0110: begin // SUB Rd, Rs (减法 - 我们的微型 ALU)
                    regs[rd] <= regs[rd] - regs[rs];
                    flag_z   <= ((regs[rd] - regs[rs]) == 8'd0) ? 1'b1 : 1'b0;
                end
                
                4'b0111: begin // AND Rd, Rs (按位与 - 我们的微型 ALU)
                    regs[rd] <= regs[rd] & regs[rs];
                    flag_z   <= ((regs[rd] & regs[rs]) == 8'd0) ? 1'b1 : 1'b0;
                end
                
                4'b1000: begin // JMP addr (无条件跳转)
                    pc <= imm; // 修改 PC 为目标地址
                end
                
                4'b1001: begin // JZ addr (如果 Z 标志位为1，则跳转)
                    if (flag_z) pc <= imm;
                end
                
                4'b1010: begin // IN Rd, port (从外设读)
                    regs[rd] <= io_rdata;
                end
                
                4'b1011: begin // OUT Rd, port (写出到外设)
                    io_we <= 1'b1; // 拉高 IO 写使能
                end
                
                default: begin
                    // 未知指令，不做任何操作 (可以当成 NOP)
                end
            endcase
        end
    end

endmodule