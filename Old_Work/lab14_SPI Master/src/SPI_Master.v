module SPI_Master(input wire clk,
                  input wire rst,
                  input wire spi_start,
                  output reg spi_busy,
                  input wire [7:0]tx_data,
                  output reg [7:0]rx_data,

                  output reg spi_clk,
                  input wire MISO,
                  output reg spi_cs,
                  output reg MOSI
);                
                  reg [7:0]spi_buffer_temp;
                  reg [4:0]baud_count;
                  reg[3:0]bit_idx;
                  reg [1:0]state;

                  parameter SPI_CLOCK = 27;
                  parameter SPI_HALF_CLOCK = 27/2;
                  parameter IDLE = 2'b00;
                  parameter START = 2'b01;
                  parameter TRANSFER = 2'b10;
                  parameter STOP = 2'b11; 

always@(posedge clk or posedge rst) begin
    if (rst) begin
        spi_busy<=1'b0;
        spi_clk<=1'b0;
        spi_cs<=1'b1;
        MOSI<=0;

        spi_buffer_temp<=0;
        baud_count<=0;
        bit_idx<=7;
        state<=IDLE;
    end
    else begin
        case(state)

        IDLE: begin
            spi_busy<=1'b0;
            spi_cs<=1'b1;
            spi_clk<=1'b0;
            if (spi_start) begin

                spi_busy<=1'b1;
                spi_cs<=1'b0;

                baud_count<=0;
                bit_idx<=7;

                spi_buffer_temp<=tx_data;
                state<=START;
            end
        end

        START: begin
            spi_clk<=1'b0;
            MOSI<=spi_buffer_temp[bit_idx];

            if (baud_count<SPI_CLOCK-1) begin
                baud_count<=baud_count+1;
            end
            else begin
                baud_count<=0;
                state<=TRANSFER;
            end
        end

        TRANSFER: begin
            baud_count<=baud_count+1;
            if(baud_count == SPI_HALF_CLOCK-1) begin
                spi_clk<=1'b1;
                rx_data[bit_idx]<=MISO;
            end
            if (baud_count == SPI_CLOCK-1)begin
                baud_count<=0;
                spi_clk<=1'b0;
                if (bit_idx == 0) begin
                    state<=STOP;
                end
                else begin
                    bit_idx<=bit_idx-1;
                    MOSI<=spi_buffer_temp[bit_idx-1];
                end
            end
        end

        STOP: begin
            baud_count<=baud_count+1;
            if (baud_count == SPI_CLOCK) begin
                spi_cs<=1'b1;
                spi_clk<=1'b0;
                spi_busy<=1'b0;
                state<=IDLE;
            end
        end

        endcase
    end
end
endmodule