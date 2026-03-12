module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_pin,    
    output reg  [7:0] rx_data,   
    output reg        rx_done    
);
    parameter BAUD_DIV = 1250;       
    parameter BAUD_DIV_HALF = 625;   

    reg rx_d0, rx_d1, rx_d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0 <= 1'b1; rx_d1 <= 1'b1; rx_d2 <= 1'b1; 
        end else begin
            rx_d0 <= rx_pin; 
            rx_d1 <= rx_d0;
            rx_d2 <= rx_d1;
        end
    end
    wire rx_fall = (~rx_d1) & rx_d2; 

    reg        rx_en;         
    reg [10:0] baud_cnt;      
    reg [3:0]  bit_cnt;       
    reg [7:0]  rx_data_reg;   

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_en    <= 1'b0;
            baud_cnt <= 11'd0;
            bit_cnt  <= 4'd0;
            rx_done  <= 1'b0;
            rx_data  <= 8'd0;
        end else begin
            rx_done <= 1'b0; 
            if (!rx_en && rx_fall) begin
                rx_en    <= 1'b1;
                baud_cnt <= 11'd0;
                bit_cnt  <= 4'd0;
            end else if (rx_en) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 11'd0;
                    if (bit_cnt == 4'd8) begin
                        rx_en   <= 1'b0;        
                        rx_done <= 1'b1;        
                        rx_data <= rx_data_reg; 
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1; 
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                    if (baud_cnt == BAUD_DIV_HALF - 1) begin
                        if (bit_cnt == 4'd0) begin
                            if (rx_d1 == 1'b1) rx_en <= 1'b0; 
                        end else begin
                            rx_data_reg <= {rx_d1, rx_data_reg[7:1]};
                        end
                    end
                end
            end
        end
    end
endmodule