module uart_tx(input wire clk,
               input wire rst,
               input wire tx_start,
               input wire [7:0]uart_byte,
               output reg tx_busy, // 0 là đang rảnh (không gửi data), 1 là bận (đang gửi data)
               output reg tx_pin // 1 là đang ở mức cao( trạng thái nghỉ), 0 là đang ở mức thấp (trạng thái gửi)
);
               reg [9:0]data_buffer;
               reg [16:0]baud_count;
               reg [3:0]bit_idx;
               reg state;
               
               parameter CLK_PER_BIT = 2812;
               parameter UART_BUSY=1'b1;
               parameter UART_NOT_BUSY=1'b0;
               

always@(posedge clk or posedge rst) begin
    if(rst) begin
        tx_busy<=1'b0;
        tx_pin<=1'b1;
        baud_count<=1'b0;
        bit_idx<=1'b0;
        state<=UART_NOT_BUSY;
    end
    else begin
            case(state)
            UART_NOT_BUSY: begin
                tx_busy<=1'b0;
                tx_pin<=1'b1;
                baud_count<=1'b0;
                bit_idx<=1'b0;
            if (tx_start) begin
                data_buffer<={1'b1,uart_byte,1'b0};
                tx_busy<=1'b1;
                tx_pin<=1'b0;
                bit_idx<=1'b1;
                state<=UART_BUSY;
            end
            end
            UART_BUSY: begin
                if (baud_count<CLK_PER_BIT-1'd1)begin
                    baud_count<=baud_count+1;
                end
                else begin
                    baud_count<=1'b0;
                    tx_pin<=data_buffer[bit_idx];
                    if (bit_idx<9) begin
                       bit_idx<=bit_idx+1'b1;
                    end
                    else begin
                        bit_idx<=0;
                        tx_busy<=1'b0;
                        state<=UART_NOT_BUSY;
                    end
                end
            end
            endcase
        end
end
endmodule
