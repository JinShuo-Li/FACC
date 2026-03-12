module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,  
    input  wire [7:0] tx_data,   
    output reg        tx_pin,    
    output reg        tx_busy    
);
    parameter BAUD_DIV = 1250;   

    reg [10:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg [8:0]  shift_reg;        

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_pin   <= 1'b1;    
            tx_busy  <= 1'b0;
            baud_cnt <= 11'd0;
            bit_cnt  <= 4'd0;
        end else begin
            if (tx_start && !tx_busy) begin
                tx_busy   <= 1'b1;
                shift_reg <= {tx_data, 1'b0}; 
                baud_cnt  <= 11'd0;
                bit_cnt   <= 4'd0;
            end else if (tx_busy) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 11'd0;
                    if (bit_cnt == 4'd9) begin 
                        tx_busy <= 1'b0;       
                        tx_pin  <= 1'b1;
                    end else begin
                        tx_pin    <= shift_reg[0]; 
                        shift_reg <= {1'b1, shift_reg[8:1]}; 
                        bit_cnt   <= bit_cnt + 1'b1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end
        end
    end
endmodule