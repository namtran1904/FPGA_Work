module uart_rx(input wire clk,
               input wire rst,
               input wire rx_pin,
               output reg rx_done,
               output reg [7:0]uart_byte
);
               reg [7:0]data_buffer_temp;
               reg [16:0]baud_count;
               reg [3:0]bit_idx;
               reg [1:0]state;

               parameter CLK_PER_BIT = 2812;
               parameter HALF_CLK_PER_BIT = 2812/2;
               parameter IDLE = 2'b00;
               parameter START = 2'b01;
               parameter DATA = 2'b10;
               parameter STOP = 2'b11;

always@(posedge clk or posedge rst) begin
    if (rst) begin
        rx_done<=1'b0;
        baud_count<=1'b0;
        bit_idx<=1'b0;
        state<=IDLE;
    end
    else begin

        case(state)
        IDLE: begin
            baud_count<=1'b0;
            bit_idx<=1'b0;
            rx_done<=1'b0;
            if (rx_pin == 1'b0) begin
                state<=START;
            end
        end

        START: begin
            baud_count<=baud_count+1'b1;
            if (baud_count == HALF_CLK_PER_BIT-1)begin
               if(rx_pin == 1'b0) begin
                baud_count<=1'b0;
                state<=DATA;
               end
               if(rx_pin == 1'b1) begin
                state<=IDLE;
                baud_count<=1'b0;
               end
            end
        end

        DATA: begin
            baud_count<=baud_count+1'b1;
            if (baud_count == CLK_PER_BIT-1) begin
                data_buffer_temp[bit_idx]<=rx_pin;
                baud_count<=1'b0;
                if (bit_idx < 7) begin
                    bit_idx<=bit_idx+1'b1;
                end
                else begin
                    bit_idx<=1'b0;
                    state<=STOP;
                end
            end
        end

        STOP: begin
            baud_count<=baud_count+1'b1;
            if (baud_count == CLK_PER_BIT-1) begin
                rx_done<=1'b1;
                uart_byte<=data_buffer_temp;
                state<=IDLE;
            end
        end

        endcase
    end
end
endmodule